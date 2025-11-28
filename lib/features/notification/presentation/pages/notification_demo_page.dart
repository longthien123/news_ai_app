import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:js' as js;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../admin/domain/entities/news.dart';
import '../../domain/entities/user_preference.dart';
import '../../data/datasources/notification_datasource.dart';
import '../../data/services/gemini_recommendation_service.dart';
import '../../data/models/smart_notification_model.dart';
import '../../domain/entities/smart_notification.dart';

/// Demo page để test notification thật trên máy
class NotificationDemoPage extends StatefulWidget {
  const NotificationDemoPage({super.key});

  @override
  State<NotificationDemoPage> createState() => _NotificationDemoPageState();
}

class _NotificationDemoPageState extends State<NotificationDemoPage> {
  late NotificationDataSource _notificationDataSource;
  late GeminiRecommendationService _geminiService;
  bool _isLoading = false;
  String _status = 'Sẵn sàng gửi thông báo test';
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() async {
    final localNotifications = FlutterLocalNotificationsPlugin();
    _notificationDataSource = NotificationDataSource(
      firestore: FirebaseFirestore.instance,
      messaging: FirebaseMessaging.instance,
      localNotifications: localNotifications,
    );
    _geminiService = GeminiRecommendationService();
    
    // Initialize local notifications
    await _notificationDataSource.initializeLocalNotifications();
    
    // Request web notification permission
    if (kIsWeb) {
      await _requestWebNotificationPermission();
    }
    
    setState(() => _status = 'Đã khởi tạo notification service');
  }

  Future<void> _requestWebNotificationPermission() async {
    try {
      if (kIsWeb) {
        // Check if browser supports notifications
        final permission = js.context.callMethod('eval', ['typeof Notification !== "undefined" ? Notification.permission : "denied"']);
        
        if (permission == 'default') {
          // Request permission
          js.context['Notification'].callMethod('requestPermission').then((result) {
            setState(() => _status = result == 'granted' 
              ? '✅ Đã cấp quyền thông báo web' 
              : '⚠️ Bạn cần cấp quyền thông báo trong browser');
          });
        } else if (permission == 'granted') {
          setState(() => _status = '✅ Browser đã có quyền thông báo');
        } else {
          setState(() => _status = '⚠️ Vui lòng cấp quyền thông báo trong Settings browser');
        }
      }
    } catch (e) {
      print('Error requesting web notification permission: $e');
    }
  }

  Future<void> _showWebNotification(String title, String body) async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['''
          if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
            new Notification('$title', {
              body: '$body',
              icon: '/icons/Icon-192.png',
              badge: '/icons/Icon-192.png',
              vibrate: [200, 100, 200],
              requireInteraction: false,
              tag: 'news-notification',
            });
          }
        ''']);
      } catch (e) {
        print('Error showing web notification: $e');
      }
    }
  }

  Future<void> _sendSimpleNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = '❌ Vui lòng đăng nhập trước');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Đang gửi thông báo đơn giản...';
    });

    try {
      // Create notification model
      final notification = SmartNotificationModel(
        id: 'simple_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        newsId: 'test_news_1',
        title: '🎉 Test Notification',
        body: 'Đây là tin tức mới dành cho bạn!',
        type: NotificationType.recommended,
        priority: NotificationPriority.normal,
        aiRelevanceScore: 0.7,
        scheduledAt: DateTime.now(),
        sentAt: DateTime.now(),
        isRead: false,
        metadata: {'test': true},
      );

      // Save to Firestore
      await _notificationDataSource.saveNotification(notification);
      
      // Show web notification (popup ra ngoài browser)
      await _showWebNotification(
        '🎉 Test Notification',
        'Đây là tin tức mới dành cho bạn!',
      );
      
      // Also show in-app notification
      await _notificationDataSource.showLocalNotification(
        title: '🎉 Test Notification',
        body: 'Đây là tin tức mới dành cho bạn!',
      );
      
      setState(() => _status = '✅ Đã gửi thông báo!\n💾 Đã lưu vào Firestore\n🔔 Check popup và danh sách thông báo');
    } catch (e) {
      setState(() => _status = '❌ Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSmartNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = '❌ Vui lòng đăng nhập trước');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Đang tạo Smart Notification với AI...';
    });

    try {
      // Lấy reading sessions để phân tích categories user thực sự đã đọc
      final readingSessions = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('readingSessions')
          .orderBy('startedAt', descending: true)
          .limit(10)
          .get();

      if (readingSessions.docs.isEmpty) {
        setState(() => _status = '⚠️ Bạn chưa đọc bài nào! Đọc ít nhất 5 bài trước khi dùng AI notification.');
        setState(() => _isLoading = false);
        return;
      }

      // Phân tích categories từ reading history
      final readCategories = <String>{};
      for (var doc in readingSessions.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null) readCategories.add(category);
      }

      if (readCategories.isEmpty) {
        setState(() => _status = '⚠️ Không tìm thấy category trong lịch sử đọc!');
        setState(() => _isLoading = false);
        return;
      }

      print('📚 User đã đọc các categories: ${readCategories.join(", ")}');

      // Lấy tin tức MỚI từ categories user đã đọc (không phải tin đã đọc)
      final readNewsIds = readingSessions.docs
          .map((doc) => doc.data()['newsId'] as String?)
          .where((id) => id != null)
          .toSet();

      final newsQuery = await FirebaseFirestore.instance
          .collection('news')
          .where('category', whereIn: readCategories.toList())
          .limit(20)
          .get();

      if (newsQuery.docs.isEmpty) {
        setState(() => _status = '⚠️ Không có tin nào trong categories: ${readCategories.join(", ")}');
        setState(() => _isLoading = false);
        return;
      }

      // Ưu tiên tin chưa đọc, nếu không có thì lấy tin đã đọc
      final unreadNews = newsQuery.docs
          .where((doc) => !readNewsIds.contains(doc.id))
          .toList();
      
      final newsDoc = unreadNews.isNotEmpty ? unreadNews.first : newsQuery.docs.first;
      print('📰 ${unreadNews.isNotEmpty ? "Tin chưa đọc" : "Tin đã đọc (demo)"}: ${newsDoc.id}');
      final newsData = newsDoc.data();
      final mockNews = News(
        id: newsDoc.id,
        title: newsData['title'] ?? 'Tin tức',
        content: newsData['content'] ?? '',
        imageUrls: List<String>.from(newsData['imageUrls'] ?? []),
        category: newsData['category'] ?? 'Thời sự',
        source: newsData['source'] ?? 'Unknown',
        createdAt: (newsData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      // Dùng user preference thật từ Firestore
      final prefDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('userPreference')
          .get();

      final UserPreference mockPreference;
      if (prefDoc.exists) {
        final prefData = prefDoc.data()!;
        mockPreference = UserPreference(
          userId: user.uid,
          favoriteCategories: List<String>.from(prefData['favoriteCategories'] ?? readCategories.toList()),
          keywords: List<String>.from(prefData['keywords'] ?? []),
          activeHours: Map<int, int>.from(prefData['activeHours'] ?? {}),
          dailyNotificationLimit: prefData['dailyNotificationLimit'] ?? 5,
        );
      } else {
        // Dùng categories từ reading history
        mockPreference = UserPreference(
          userId: user.uid,
          favoriteCategories: readCategories.toList(),
          keywords: [],
          activeHours: {},
          dailyNotificationLimit: 5,
        );
      }

      print('🎯 Sẽ phân tích tin: ${mockNews.title} (${mockNews.category})');

      setState(() => _status = 'AI đang phân tích tin tức...');
      
      // Calculate AI relevance score
      double relevanceScore;
      try {
        relevanceScore = await _geminiService.calculateRelevanceScore(
          news: mockNews,
          userPreference: mockPreference,
        );
        print('✅ AI Relevance Score: $relevanceScore');
      } catch (e) {
        print('❌ Lỗi calculate score: $e');
        setState(() => _status = '❌ Lỗi AI phân tích: $e');
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _status = 'AI đang tạo nội dung cá nhân hóa... (score: ${relevanceScore.toStringAsFixed(2)})');
      
      // Generate personalized body
      String personalizedBody;
      try {
        personalizedBody = await _geminiService.generatePersonalizedNotificationBody(
          news: mockNews,
          userPreference: mockPreference,
        );
        print('✅ Personalized body: $personalizedBody');
      } catch (e) {
        print('❌ Lỗi generate body: $e');
        setState(() => _status = '❌ Lỗi AI tạo nội dung: $e');
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _status = 'Đang gửi thông báo...');

      // Create and save notification
      final notification = SmartNotificationModel(
        id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        newsId: mockNews.id,
        title: mockNews.title,
        body: personalizedBody,
        aiRelevanceScore: relevanceScore,
        type: NotificationType.recommended,
        priority: relevanceScore >= 0.8 ? NotificationPriority.high : NotificationPriority.normal,
        scheduledAt: DateTime.now(),
        sentAt: DateTime.now(),
        isRead: false,
        metadata: {
          'category': mockNews.category,
          'source': mockNews.source,
        },
      );

      // Save to Firestore
      await _notificationDataSource.saveNotification(notification);

      // Show web notification (popup ra ngoài)
      await _showWebNotification('⭐ Tin tức đề xuất', personalizedBody);
      
      // Show local notification
      await _notificationDataSource.showLocalNotification(
        title: '⭐ Tin tức đề xuất',
        body: personalizedBody,
      );

      setState(() => _status = '✅ Smart Notification đã gửi!\n'
          '📊 AI Relevance Score: ${relevanceScore.toStringAsFixed(2)}\n'
          '💬 Body: "$personalizedBody"\n'
          '🔔 Check popup ngoài browser!');
    } catch (e) {
      setState(() => _status = '❌ Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendBreakingNews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = '❌ Vui lòng đăng nhập trước');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Đang gửi tin khẩn cấp...';
    });

    try {
      // Create breaking news notification
      final notification = SmartNotificationModel(
        id: 'breaking_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        newsId: 'breaking_news_1',
        title: '⚡ TIN KHẨN CẤP',
        body: 'Việt Nam vừa ghi bàn thắng quyết định ở phút 90+3!',
        type: NotificationType.breaking,
        priority: NotificationPriority.high,
        aiRelevanceScore: 1.0,
        scheduledAt: DateTime.now(),
        sentAt: DateTime.now(),
        isRead: false,
        metadata: {'category': 'Thể thao', 'urgent': true},
      );

      // Save to Firestore
      await _notificationDataSource.saveNotification(notification);
      
      await _showWebNotification(
        '⚡ TIN KHẨN CẤP',
        'Việt Nam vừa ghi bàn thắng quyết định ở phút 90+3!',
      );
      
      await _notificationDataSource.showLocalNotification(
        title: '⚡ TIN KHẨN CẤP',
        body: 'Việt Nam vừa ghi bàn thắng quyết định ở phút 90+3!',
      );
      
      setState(() => _status = '✅ Đã gửi tin khẩn cấp!\n💾 Đã lưu vào Firestore\n🔔 Priority: HIGH');
    } catch (e) {
      setState(() => _status = '❌ Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMultipleNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = '❌ Vui lòng đăng nhập trước');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Đang gửi 3 thông báo liên tiếp...';
    });

    try {
      final notifications = [
        {'title': '📰 Tin tức 1', 'body': 'ChatGPT ra mắt tính năng mới', 'category': 'Công nghệ'},
        {'title': '📰 Tin tức 2', 'body': 'Bitcoin tăng giá 10%', 'category': 'Kinh tế'},
        {'title': '📰 Tin tức 3', 'body': 'Apple ra mắt iPhone 16', 'category': 'Công nghệ'},
      ];

      for (var i = 0; i < notifications.length; i++) {
        // Create and save notification
        final notification = SmartNotificationModel(
          id: 'multi_${DateTime.now().millisecondsSinceEpoch}_$i',
          userId: user.uid,
          newsId: 'news_${i + 1}',
          title: notifications[i]['title']!,
          body: notifications[i]['body']!,
          type: NotificationType.recommended,
          priority: NotificationPriority.normal,
          aiRelevanceScore: 0.6 + (i * 0.1),
          scheduledAt: DateTime.now(),
          sentAt: DateTime.now(),
          isRead: false,
          metadata: {'category': notifications[i]['category']},
        );
        
        await _notificationDataSource.saveNotification(notification);
        
        await _showWebNotification(
          notifications[i]['title']!,
          notifications[i]['body']!,
        );
        
        await _notificationDataSource.showLocalNotification(
          title: notifications[i]['title']!,
          body: notifications[i]['body']!,
        );
        setState(() => _status = 'Đã gửi ${i + 1}/3 thông báo 💾🔔');
        await Future.delayed(const Duration(seconds: 2));
      }
      
      setState(() => _status = '✅ Đã gửi 3 thông báo!\n💾 Đã lưu vào Firestore\n🔔 Vào danh sách thông báo để xem');
    } catch (e) {
      setState(() => _status = '❌ Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Demo Thông báo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Trạng thái',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Instruction
            const Text(
              '💡 Hướng dẫn:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Browser sẽ hỏi cấp quyền → Click "Allow"\n'
              '2. Bấm nút test → Thông báo POPUP ra ngoài browser\n'
              '3. Thông báo hiện ở góc màn hình desktop (như app thật)\n'
              '4. Smart Notification dùng AI Gemini cá nhân hóa',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Simple notification
            _buildNotificationButton(
              icon: Icons.notifications_outlined,
              title: '📢 Thông báo đơn giản',
              description: 'Gửi 1 thông báo test cơ bản',
              color: Colors.blue,
              onPressed: _isLoading ? null : _sendSimpleNotification,
            ),
            const SizedBox(height: 12),

            // Smart notification with AI
            _buildNotificationButton(
              icon: Icons.auto_awesome,
              title: '🤖 Smart Notification (AI)',
              description: 'Sử dụng Gemini để cá nhân hóa nội dung',
              color: Colors.purple,
              onPressed: _isLoading ? null : _sendSmartNotification,
            ),
            const SizedBox(height: 12),

            // Breaking news
            _buildNotificationButton(
              icon: Icons.flash_on,
              title: '⚡ Tin khẩn cấp',
              description: 'Priority HIGH, gửi ngay lập tức',
              color: Colors.red,
              onPressed: _isLoading ? null : _sendBreakingNews,
            ),
            const SizedBox(height: 12),

            // Multiple notifications
            _buildNotificationButton(
              icon: Icons.burst_mode,
              title: '📚 Gửi nhiều thông báo',
              description: 'Gửi 3 thông báo liên tiếp (cách nhau 2s)',
              color: Colors.orange,
              onPressed: _isLoading ? null : _sendMultipleNotifications,
            ),
            
            const SizedBox(height: 32),
            
            // View notifications button
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              icon: const Icon(Icons.list),
              label: const Text('Xem danh sách thông báo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}
