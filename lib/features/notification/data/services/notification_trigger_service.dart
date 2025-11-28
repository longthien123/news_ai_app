import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fcm_service.dart';
import '../services/auto_notification_service.dart';
import '../services/gemini_recommendation_service.dart';
import '../datasources/notification_datasource.dart';
import '../models/smart_notification_model.dart';
import '../../domain/entities/smart_notification.dart';
import '../../domain/entities/user_preference.dart';
import '../../../admin/domain/entities/news.dart';

/// Service to automatically trigger notifications when new news is added
class NotificationTriggerService {
  final FirebaseFirestore firestore;
  final FCMService fcmService;
  final AutoNotificationService autoNotificationService;
  
  StreamSubscription? _newsStreamSubscription;
  
  NotificationTriggerService({
    required this.firestore,
    required this.fcmService,
    required this.autoNotificationService,
  });
  
  /// Start listening for new news and trigger notifications
  void startListening() {
    print('🎯 Starting notification trigger service...');
    
    // Listen to new news being added
    _newsStreamSubscription = firestore
        .collection('news')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(_onNewNewsAdded, onError: (error) {
          print('❌ News stream error: $error');
        });
        
    print('✅ Notification trigger service started');
  }
  
  /// Stop listening
  void stopListening() {
    _newsStreamSubscription?.cancel();
    print('🛑 Notification trigger service stopped');
  }
  
  /// Handle new news being added
  Future<void> _onNewNewsAdded(QuerySnapshot snapshot) async {
    if (snapshot.docs.isEmpty) return;
    
    final latestDoc = snapshot.docs.first;
    final newsData = latestDoc.data() as Map<String, dynamic>;
    
    // Check if this is actually a new news (created in last 5 minutes)
    final createdAt = (newsData['createdAt'] as Timestamp).toDate();
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    
    if (createdAt.isBefore(fiveMinutesAgo)) {
      return; // Not a new news, ignore
    }
    
    print('📰 New news detected: ${newsData['title']}');
    
    // Convert to News entity
    final news = News(
      id: latestDoc.id,
      title: newsData['title'] ?? '',
      content: newsData['content'] ?? '',
      imageUrls: newsData['imageUrls'] != null 
          ? List<String>.from(newsData['imageUrls'])
          : (newsData['imageUrl'] != null ? [newsData['imageUrl']] : []),
      source: newsData['source'] ?? 'Unknown',
      category: newsData['category'] ?? 'Khác',
      createdAt: createdAt,
    );
    
    // Handle different notification strategies based on category
    await _handleNewsByCategory(news);
  }
  
  /// Handle notifications based on news category
  Future<void> _handleNewsByCategory(News news) async {
    try {
      switch (news.category.toLowerCase()) {
        case 'khẩn cấp':
        case 'breaking':
          await _sendBreakingNewsToAll(news);
          break;
          
        case 'thể thao':
        case 'giải trí':
          await _sendToInterestedUsers(news);
          break;
          
        default:
          await _sendSmartRecommendations(news);
          break;
      }
    } catch (e) {
      print('❌ Error handling news by category: $e');
    }
  }
  
  /// Send breaking news to all active users
  Future<void> _sendBreakingNewsToAll(News news) async {
    print('⚡ Sending breaking news to all users...');
    
    final notification = SmartNotificationModel(
      id: 'breaking_${DateTime.now().millisecondsSinceEpoch}_${news.id}',
      userId: '', // Will be set per user
      newsId: news.id,
      title: '⚡ ${news.title}',
      body: news.content.length > 100 
          ? '${news.content.substring(0, 100)}...' 
          : news.content,
      type: NotificationType.breaking,
      priority: NotificationPriority.high,
      aiRelevanceScore: 1.0,
      scheduledAt: DateTime.now(),
      sentAt: DateTime.now(),
      isRead: false,
      metadata: {
        'category': news.category,
        'source': news.source,
        'breaking': true,
      },
    );
    
    final sentCount = await fcmService.sendBreakingNewsToAll(notification);
    print('⚡ Breaking news sent to $sentCount users');
  }
  
  /// Send to users interested in specific category
  Future<void> _sendToInterestedUsers(News news) async {
    print('🎯 Sending to users interested in: ${news.category}');
    
    try {
      // Get users who have this category in their preferences
      final usersSnapshot = await firestore
          .collection('users')
          .where('preferences.categories', arrayContains: news.category)
          .limit(500)
          .get();
          
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      
      if (userIds.isEmpty) {
        print('⚠️ No users interested in: ${news.category}');
        return;
      }
      
      // Create targeted notification
      final notification = SmartNotificationModel(
        id: 'category_${DateTime.now().millisecondsSinceEpoch}_${news.id}',
        userId: '', // Will be set per user
        newsId: news.id,
        title: '📢 ${news.category}: ${news.title}',
        body: news.content.length > 120 
            ? '${news.content.substring(0, 120)}...' 
            : news.content,
        type: NotificationType.contextual,
        priority: NotificationPriority.normal,
        aiRelevanceScore: 0.8,
        scheduledAt: DateTime.now(),
        sentAt: DateTime.now(),
        isRead: false,
        metadata: {
          'category': news.category,
          'source': news.source,
          'targeted': true,
        },
      );
      
      final sentCount = await fcmService.sendNotificationToMultipleUsers(userIds, notification);
      print('🎯 Category notification sent to $sentCount/${userIds.length} users');
      
    } catch (e) {
      print('❌ Error sending to interested users: $e');
    }
  }
  
  /// Send AI-powered smart recommendations to relevant users
  Future<void> _sendSmartRecommendations(News news) async {
    print('🤖 Generating smart recommendations for: ${news.title}');
    
    try {
      // Get active users (updated token in last 3 days)
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      
      final usersSnapshot = await firestore
          .collection('users')
          .where('fcmTokenUpdatedAt', isGreaterThan: threeDaysAgo)
          .limit(200) // Limit for performance
          .get();
          
      int sentCount = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          // Get user preferences
          final userData = userDoc.data();
          final preferences = userData['preferences'] as Map<String, dynamic>?;
          
          if (preferences?['enableSmartNotifications'] == false) {
            continue; // User disabled smart notifications
          }
          
          // Check daily limit
          final dailyLimit = preferences?['dailyLimit'] as int? ?? 5;
          final todaySent = await _getTodayNotificationCount(userDoc.id);
          
          if (todaySent >= dailyLimit) {
            continue; // Daily limit reached
          }
          
          // Use auto notification service for AI scoring
          await autoNotificationService.checkAndCreateNotifications(
            userDoc.id,
            _parseUserPreferences(preferences),
          );
          
          sentCount++;
          
          // Small delay to avoid overwhelming
          await Future.delayed(const Duration(milliseconds: 200));
          
        } catch (e) {
          print('❌ Error processing user ${userDoc.id}: $e');
        }
      }
      
      print('🤖 Smart recommendations sent to $sentCount users');
      
    } catch (e) {
      print('❌ Error sending smart recommendations: $e');
    }
  }
  
  /// Get today's notification count for user
  Future<int> _getTodayNotificationCount(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('sentAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .get();
        
    return snapshot.size;
  }
  
  /// Parse user preferences from Firestore data
  UserPreference _parseUserPreferences(Map<String, dynamic>? prefsData) {
    if (prefsData == null) {
      return UserPreference(
        userId: 'temp_user',
        favoriteCategories: const ['Thời sự', 'Thế giới', 'Thể thao', 'Công nghệ'],
        keywords: const [],
        activeHours: const {8: 5, 20: 3},
        dailyNotificationLimit: 5,
        enableSmartNotifications: true,
      );
    }
    
    return UserPreference(
      userId: 'temp_user',
      favoriteCategories: List<String>.from(prefsData['categories'] ?? [
        'Thời sự', 'Thế giới', 'Thể thao', 'Công nghệ', 'Kinh tế'
      ]),
      keywords: List<String>.from(prefsData['keywords'] ?? []),
      activeHours: Map<int, int>.from(prefsData['activeHours'] ?? {8: 5, 20: 3}),
      dailyNotificationLimit: prefsData['dailyLimit'] ?? 5,
      enableSmartNotifications: prefsData['enableSmartNotifications'] ?? true,
      lastAnalyzedAt: prefsData['lastAnalyzedAt'] != null 
          ? (prefsData['lastAnalyzedAt'] as Timestamp).toDate()
          : null,
    );
  }
}