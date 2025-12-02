import 'package:flutter/material.dart';

/// Service để handle navigation khi click vào notification
class NotificationNavigationService {
  static final NotificationNavigationService _instance = NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  
  /// Set navigator key từ MaterialApp
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    print('✅ NotificationNavigationService: Navigator key set');
  }
  
  /// Navigate đến news detail khi click notification
  Future<void> navigateToNewsDetail(String newsId) async {
    if (_navigatorKey?.currentContext == null) {
      print('⚠️ NotificationNavigationService: Navigator key not available');
      return;
    }
    
    print('📱 Navigating to news detail: $newsId');
    
    try {
      // Navigate using named route instead of direct import
      await _navigatorKey!.currentState?.pushNamed(
        '/news-detail',
        arguments: newsId,
      );
    } catch (e) {
      print('❌ Error navigating to news detail: $e');
    }
  }
  
  /// Handle notification payload
  void handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      print('⚠️ Empty notification payload');
      return;
    }
    
    print('📱 Handling notification payload: $payload');
    
    // Payload format: "newsId:abc123"
    if (payload.startsWith('newsId:')) {
      final newsId = payload.replaceFirst('newsId:', '');
      navigateToNewsDetail(newsId);
    } else {
      print('⚠️ Unknown payload format: $payload');
    }
  }
}

/// Global instance
final notificationNavigationService = NotificationNavigationService();
