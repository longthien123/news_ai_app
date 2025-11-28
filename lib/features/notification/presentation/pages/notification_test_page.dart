import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/notification_datasource.dart';
import '../../data/models/smart_notification_model.dart';
import '../../domain/entities/smart_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Quick test page to trigger immediate notifications
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  late NotificationDataSource _notificationSource;
  String _status = 'Ready to test notifications';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() async {
    _notificationSource = NotificationDataSource(
      firestore: FirebaseFirestore.instance,
      messaging: FirebaseMessaging.instance,
      localNotifications: FlutterLocalNotificationsPlugin(),
    );
    
    await _notificationSource.initializeLocalNotifications();
    setState(() => _status = 'Notification service initialized ✅');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendSimpleNotification,
              icon: const Icon(Icons.notifications),
              label: Text(_isLoading ? 'Đang gửi...' : 'Gửi thông báo đơn giản'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendImportantNotification,
              icon: const Icon(Icons.priority_high),
              label: Text(_isLoading ? 'Đang gửi...' : 'Gửi thông báo quan trọng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendBreakingNews,
              icon: const Icon(Icons.flash_on),
              label: Text(_isLoading ? 'Đang gửi...' : 'Gửi tin khẩn cấp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Lưu ý: Thông báo sẽ hiển thị trong notification tray của Android. Hãy kéo xuống từ trên cùng để xem.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSimpleNotification() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _status = 'Đang gửi thông báo đơn giản...';
    });

    try {
      await _notificationSource.showLocalNotification(
        title: '🎉 Thông báo test',
        body: 'Đây là thông báo test từ ứng dụng!',
      );
      
      await _saveToFirestore('simple_test', '🎉 Thông báo test', 'Đây là thông báo test từ ứng dụng!');
      
      setState(() => _status = '✅ Đã gửi thông báo đơn giản!\n🔔 Kiểm tra notification tray của Android');
    } catch (e) {
      setState(() => _status = '❌ Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendImportantNotification() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _status = 'Đang gửi thông báo quan trọng...';
    });

    try {
      await _notificationSource.showLocalNotification(
        title: '⭐ Tin tức quan trọng',
        body: 'Bạn có tin tức mới phù hợp với sở thích của mình!',
      );
      
      await _saveToFirestore('important', '⭐ Tin tức quan trọng', 'Bạn có tin tức mới phù hợp với sở thích của mình!');
      
      setState(() => _status = '✅ Đã gửi thông báo quan trọng!\n🔔 Priority: Normal');
    } catch (e) {
      setState(() => _status = '❌ Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendBreakingNews() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _status = 'Đang gửi tin khẩn cấp...';
    });

    try {
      await _notificationSource.showLocalNotification(
        title: '⚡ TIN KHẨN CẤP',
        body: 'Việt Nam vừa có tin tức đột phá trong lĩnh vực công nghệ!',
      );
      
      await _saveToFirestore('breaking', '⚡ TIN KHẨN CẤP', 'Việt Nam vừa có tin tức đột phá trong lĩnh vực công nghệ!');
      
      setState(() => _status = '✅ Đã gửi tin khẩn cấp!\n🔔 Priority: HIGH\n🚨 Kiểm tra notification tray!');
    } catch (e) {
      setState(() => _status = '❌ Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToFirestore(String type, String title, String body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notification = SmartNotificationModel(
      id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      newsId: 'test_news_$type',
      title: title,
      body: body,
      type: type == 'breaking' ? NotificationType.breaking : NotificationType.recommended,
      priority: type == 'breaking' ? NotificationPriority.high : NotificationPriority.normal,
      aiRelevanceScore: type == 'breaking' ? 1.0 : 0.7,
      scheduledAt: DateTime.now(),
      sentAt: DateTime.now(),
      isRead: false,
      metadata: {'test': true, 'type': type},
    );

    await _notificationSource.saveNotification(notification);
  }
}