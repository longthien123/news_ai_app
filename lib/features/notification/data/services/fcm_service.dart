import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/smart_notification_model.dart';

/// Service to send FCM push notifications via HTTP API
class FCMService {
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY'; // Add your FCM server key
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  
  final FirebaseFirestore firestore;
  
  FCMService({required this.firestore});
  
  /// Send push notification to specific user
  Future<bool> sendNotificationToUser(
    String userId, 
    SmartNotificationModel notification
  ) async {
    try {
      // Get user's FCM token
      final userDoc = await firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken == null) {
        print('⚠️ No FCM token found for user: $userId');
        return false;
      }
      
      return await sendNotificationToToken(fcmToken, notification);
    } catch (e) {
      print('❌ Error sending notification to user: $e');
      return false;
    }
  }
  
  /// Send push notification to specific FCM token
  Future<bool> sendNotificationToToken(
    String fcmToken,
    SmartNotificationModel notification
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': fcmToken,
          'notification': {
            'title': notification.title,
            'body': notification.body,
            'icon': 'ic_launcher',
            'sound': 'default',
            'badge': '1',
          },
          'data': {
            'notificationId': notification.id,
            'newsId': notification.newsId,
            'type': notification.type.name,
            'priority': notification.priority.name,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'priority': 'high',
          'android': {
            'notification': {
              'channel_id': 'smart_notifications',
              'icon': 'ic_launcher',
              'color': '#2196F3',
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': notification.title,
                  'body': notification.body,
                },
                'badge': 1,
                'sound': 'default',
              }
            }
          }
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ FCM sent successfully: ${notification.title}');
        return true;
      } else {
        print('❌ FCM failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending FCM: $e');
      return false;
    }
  }
  
  /// Send notification to multiple users
  Future<int> sendNotificationToMultipleUsers(
    List<String> userIds,
    SmartNotificationModel notification
  ) async {
    int successCount = 0;
    
    for (final userId in userIds) {
      final success = await sendNotificationToUser(userId, notification);
      if (success) successCount++;
      
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('📊 Sent to $successCount/${userIds.length} users');
    return successCount;
  }
  
  /// Send breaking news to all active users
  Future<int> sendBreakingNewsToAll(SmartNotificationModel notification) async {
    try {
      // Get all users with FCM tokens (active in last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final usersSnapshot = await firestore
          .collection('users')
          .where('fcmTokenUpdatedAt', isGreaterThan: sevenDaysAgo)
          .limit(1000) // Limit for safety
          .get();
          
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      
      if (userIds.isEmpty) {
        print('⚠️ No active users found for breaking news');
        return 0;
      }
      
      return await sendNotificationToMultipleUsers(userIds, notification);
    } catch (e) {
      print('❌ Error sending breaking news to all: $e');
      return 0;
    }
  }
}