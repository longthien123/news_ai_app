import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../admin/domain/entities/news.dart';
import '../../domain/entities/user_preference.dart';
import '../services/auto_notification_service.dart';
import '../services/gemini_recommendation_service.dart';
import '../models/smart_notification_model.dart';
import '../../domain/entities/smart_notification.dart';

/// Service tự động trigger thông báo khi user vào app
/// Phân tích categories user đã đọc gần đây và gợi ý tin mới cùng category
class UserActivityTriggerService {
  final FirebaseFirestore firestore;
  final AutoNotificationService autoNotificationService;
  final GeminiRecommendationService geminiService;
  
  UserActivityTriggerService({
    required this.firestore,
    required this.autoNotificationService,
    required this.geminiService,
  });

  /// Trigger khi user vào app - phân tích và gợi ý tin mới
  Future<void> onUserOpenApp(String userId) async {
    try {
      print('🔥 User $userId opened app - triggering personalized recommendations...');
      
      // 1. Phân tích categories user quan tâm từ lịch sử đọc
      final favoriteCategories = await _analyzeFavoriteCategoriesFromHistory(userId);
      
      if (favoriteCategories.isEmpty) {
        print('⚠️ No reading history found, using default categories');
        await _triggerDefaultRecommendations(userId);
        return;
      }
      
      print('📊 User favorite categories: ${favoriteCategories.join(', ')}');
      
      // 2. Lấy tin mới chưa đọc thuộc categories yêu thích
      final unreadNews = await _getUnreadNewsByCategories(userId, favoriteCategories);
      
      if (unreadNews.isEmpty) {
        print('📰 No unread news in favorite categories');
        return;
      }
      
      print('📚 Found ${unreadNews.length} unread news in favorite categories');
      
      // 3. Tạo UserPreference từ phân tích
      final userPreference = await _buildUserPreferenceFromAnalysis(
        userId, 
        favoriteCategories
      );
      
      // 4. Trigger notifications cho tin phù hợp
      await _triggerPersonalizedNotifications(userId, unreadNews, userPreference);
      
      print('✅ Personalized recommendations completed for user $userId');
      
    } catch (e) {
      print('❌ Error in user activity trigger: $e');
    }
  }

  /// Phân tích categories yêu thích từ lịch sử đọc gần đây (sử dụng readingSessions)
  Future<List<String>> _analyzeFavoriteCategoriesFromHistory(String userId) async {
    try {
      // Lấy reading sessions (dùng collection có sẵn)
      final readHistorySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('readingSessions')
          .limit(50) // Lấy 50 tin gần nhất
          .get();
          
      if (readHistorySnapshot.docs.isEmpty) {
        print('📊 No readingSessions found for user $userId');
        return [];
      }
      
      print('📚 Found ${readHistorySnapshot.docs.length} reading sessions');
      
      // Đếm frequency của mỗi category
      final categoryCount = <String, int>{};
      
      for (final historyDoc in readHistorySnapshot.docs) {
        final data = historyDoc.data();
        final newsId = data['newsId'] as String?;
        
        if (newsId == null) continue;
        
        // Lấy thông tin news để biết category
        final newsDoc = await firestore.collection('news').doc(newsId).get();
        if (!newsDoc.exists) continue;
        
        final category = newsDoc.data()?['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }
      
      // Sắp xếp theo frequency và lấy top category
      final sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Chỉ lấy 1 category yêu thích nhất
      if (sortedCategories.isEmpty) {
        return [];
      }
      
      final topCategory = sortedCategories.first.key;
      
      print('📈 Category analysis: ${categoryCount.toString()}');
      print('🎯 Top favorite category: $topCategory (${sortedCategories.first.value} reads)');
      
      return [topCategory];
      
    } catch (e) {
      print('❌ Error analyzing favorite categories: $e');
      return [];
    }
  }

  /// Lấy tin mới chưa đọc thuộc categories yêu thích
  Future<List<News>> _getUnreadNewsByCategories(
    String userId, 
    List<String> favoriteCategories
  ) async {
    try {
      // Lấy danh sách tin đã đọc gần đây
      final readNewsIds = await _getReadNewsIds(userId);
      
      // Lấy tin mới (7 ngày qua) thuộc categories yêu thích - tăng để có nhiều tin hơn
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final unreadNewsList = <News>[];
      
      // Query từng category (bỏ filter createdAt để tránh lỗi index)
      for (final category in favoriteCategories) {
        final newsSnapshot = await firestore
            .collection('news')
            .where('category', isEqualTo: category)
            .limit(20) // Lấy 20 tin mới nhất theo category
            .get();
        
        for (final newsDoc in newsSnapshot.docs) {
          // Bỏ qua tin đã đọc
          if (readNewsIds.contains(newsDoc.id)) {
            continue;
          }
          
          final data = newsDoc.data();
          
          // Convert createdAt từ Timestamp hoặc String
          DateTime createdAt;
          final createdAtRaw = data['createdAt'];
          if (createdAtRaw is Timestamp) {
            createdAt = createdAtRaw.toDate();
          } else if (createdAtRaw is String) {
            createdAt = DateTime.parse(createdAtRaw);
          } else {
            createdAt = DateTime.now();
          }
          
          final news = News(
            id: newsDoc.id,
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            imageUrls: data['imageUrls'] != null 
                ? List<String>.from(data['imageUrls'])
                : (data['imageUrl'] != null ? [data['imageUrl']] : []),
            source: data['source'] ?? 'Unknown',
            category: data['category'] ?? 'Khác',
            createdAt: createdAt,
          );
          
          unreadNewsList.add(news);
        }
      }
      
      // Sắp xếp theo thời gian tạo
      unreadNewsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Remove duplicates (same newsId)
      final uniqueNews = <String, News>{};
      for (final news in unreadNewsList) {
        uniqueNews[news.id] = news;
      }
      
      final result = uniqueNews.values.toList();
      print('📊 Found ${result.length} unique unread news (from ${unreadNewsList.length} total)');
      
      return result;
      
    } catch (e) {
      print('❌ Error getting unread news: $e');
      return [];
    }
  }

  /// Lấy danh sách ID tin đã đọc gần đây từ readingSessions
  Future<Set<String>> _getReadNewsIds(String userId) async {
    try {
      final readHistorySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('readingSessions')
          .limit(100) // Lấy 100 sessions gần nhất
          .get();
      
      return readHistorySnapshot.docs
          .map((doc) => doc.data()['newsId'] as String?)
          .where((newsId) => newsId != null && newsId.isNotEmpty)
          .cast<String>()
          .toSet();
          
    } catch (e) {
      print('❌ Error getting read news IDs: $e');
      return <String>{};
    }
  }

  /// Xây dựng UserPreference từ phân tích
  Future<UserPreference> _buildUserPreferenceFromAnalysis(
    String userId,
    List<String> favoriteCategories,
  ) async {
    try {
      // Lấy keywords từ lịch sử đọc
      final readHistory = await _getReadingTitles(userId);
      final keywords = await geminiService.extractKeywordsFromReadingHistory(
        titles: readHistory,
        categories: favoriteCategories,
      );
      
      return UserPreference(
        userId: userId,
        favoriteCategories: favoriteCategories,
        keywords: keywords,
        activeHours: const {8: 5, 12: 3, 18: 4, 20: 5}, // Giờ hoạt động mặc định
        dailyNotificationLimit: 20, // Tăng cao để test dễ hơn
        enableSmartNotifications: true,
        lastAnalyzedAt: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Error building user preference: $e');
      return UserPreference(
        userId: userId,
        favoriteCategories: favoriteCategories,
        keywords: const [],
        activeHours: const {8: 5, 20: 3},
        dailyNotificationLimit: 5,
        enableSmartNotifications: true,
      );
    }
  }

  /// Lấy titles của tin đã đọc từ readingSessions để phân tích keywords
  Future<List<String>> _getReadingTitles(String userId) async {
    try {
      final readHistorySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('readingSessions')
          .limit(30)
          .get();
      
      final titles = <String>[];
      
      for (final historyDoc in readHistorySnapshot.docs) {
        final newsId = historyDoc.data()['newsId'] as String?;
        if (newsId == null) continue;
        
        final newsDoc = await firestore.collection('news').doc(newsId).get();
        if (newsDoc.exists) {
          final title = newsDoc.data()?['title'] as String?;
          if (title != null) {
            titles.add(title);
          }
        }
      }
      
      return titles;
      
    } catch (e) {
      print('❌ Error getting reading titles: $e');
      return [];
    }
  }

  /// Trigger notifications cá nhân hóa
  Future<void> _triggerPersonalizedNotifications(
    String userId,
    List<News> unreadNews,
    UserPreference userPreference,
  ) async {
    try {
      int notificationsSent = 0;
      const maxNotifications = 5; // Giới hạn 5 notification khi mở app
      
      // Lấy danh sách notification đã gửi cho user
      final sentNewsIds = await _getSentNewsIds(userId);
      
      print('📋 Processing ${unreadNews.length} unread news, already sent: ${sentNewsIds.length}');
      
      // Log newsIds để check duplicate
      final newsIdsToProcess = unreadNews.take(maxNotifications).map((n) => n.id).toList();
      print('📰 News IDs to process: $newsIdsToProcess');
      
      for (final news in unreadNews.take(maxNotifications)) {
        // Skip nếu đã gửi notification cho news này rồi
        if (sentNewsIds.contains(news.id)) {
          print('⏭️ Skip ${news.title.substring(0, 30)}... - already sent');
          continue;
        }
        
        try {
          // Calculate AI relevance score
          final relevanceScore = await geminiService.calculateRelevanceScore(
            news: news,
            userPreference: userPreference,
          );
          
          // Giảm threshold xuống 0.3 để dễ test
          if (relevanceScore < 0.3) {
            print('⏭️ Skip ${news.title.substring(0, 30)}... - Low score: $relevanceScore');
            continue;
          }
          
          // Generate personalized body
          final personalizedBody = await geminiService.generatePersonalizedNotificationBody(
            news: news,
            userPreference: userPreference,
          );
          
          // Create notification
          final notification = SmartNotificationModel(
            id: 'trigger_${DateTime.now().millisecondsSinceEpoch}_${news.id}',
            userId: userId,
            newsId: news.id,
            title: news.title,
            body: personalizedBody,
            type: NotificationType.recommended,
            priority: relevanceScore >= 0.8 ? NotificationPriority.high : NotificationPriority.normal,
            aiRelevanceScore: relevanceScore,
            scheduledAt: DateTime.now(),
            sentAt: DateTime.now(),
            isRead: false,
            metadata: {
              'category': news.category,
              'source': news.source,
              'triggeredByCategory': true,
            },
          );
          
          // Save to Firestore
          await firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc(notification.id)
              .set(notification.toJson());
          
          // Thêm vào sentNewsIds để tránh duplicate trong cùng 1 lần trigger
          sentNewsIds.add(news.id);
          
          // Show local notification popup
          print('🔔 Sending notification #${notificationsSent + 1}: ${news.title}');
          await autoNotificationService.notificationDataSource.showLocalNotification(
            title: notification.title,
            body: notification.body,
            payload: {'newsId': news.id},
          );
          
          notificationsSent++;
          print('✅ Sent notification #$notificationsSent: ${news.title.substring(0, 30)}... (newsId: ${news.id}, score: ${relevanceScore.toStringAsFixed(2)})');
          
          // Delay để tránh duplicate ID
          await Future.delayed(const Duration(milliseconds: 1100));
          
        } catch (e) {
          print('❌ Error creating notification for ${news.title}: $e');
          continue;
        }
      }
      
      print('📱 Sent $notificationsSent personalized notifications');
      
    } catch (e) {
      print('❌ Error triggering personalized notifications: $e');
    }
  }
  
  /// Lấy danh sách newsId đã gửi notification
  Future<Set<String>> _getSentNewsIds(String userId) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data()['newsId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
    } catch (e) {
      print('❌ Error getting sent news IDs: $e');
      return {};
    }
  }

  /// Trigger recommendations mặc định cho user mới
  Future<void> _triggerDefaultRecommendations(String userId) async {
    try {
      final defaultCategories = ['Thời sự', 'Thế giới', 'Công nghệ', 'Thể thao'];
      
      final defaultPreference = UserPreference(
        userId: userId,
        favoriteCategories: defaultCategories,
        keywords: const [],
        activeHours: const {8: 5, 20: 3},
        dailyNotificationLimit: 20, // Tăng limit
        enableSmartNotifications: true,
      );
      
      await autoNotificationService.checkAndCreateNotifications(
        userId,
        defaultPreference,
      );
      
      print('📱 Sent default recommendations for new user');
      
    } catch (e) {
      print('❌ Error sending default recommendations: $e');
    }
  }

  /// Log user activity để phân tích sau này
  Future<void> logUserActivity(String userId, String action, {Map<String, dynamic>? metadata}) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('activity_logs')
          .add({
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print('❌ Error logging user activity: $e');
    }
  }
}