import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/smart_notification_model.dart';

class NotificationDataSource {
  final FirebaseFirestore firestore;
  final FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin localNotifications;

  NotificationDataSource({
    required this.firestore,
    required this.messaging,
    required this.localNotifications,
  });

  Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await localNotifications.initialize(settings);
  }

  Future<String?> getFCMToken() async {
    return await messaging.getToken();
  }

  Future<void> saveFCMToken(String userId, String token) async {
    await firestore
        .collection('users')
        .doc(userId)
        .update({'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> saveNotification(SmartNotificationModel notification) async {
    await firestore
        .collection('users')
        .doc(notification.userId)
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toJson());
  }

  Future<List<SmartNotificationModel>> getNotifications(String userId) async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('scheduledAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => SmartNotificationModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> updateNotification(String userId, String notificationId, Map<String, dynamic> updates) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update(updates);
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<int> getTodaySentCount(String userId) async {
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

  Stream<List<SmartNotificationModel>> notificationsStream(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('scheduledAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SmartNotificationModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_notifications',
      'Smart Notifications',
      channelDescription: 'AI-powered personalized notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }
}
