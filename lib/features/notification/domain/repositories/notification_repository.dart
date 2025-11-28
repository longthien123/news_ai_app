import '../entities/smart_notification.dart';

/// Repository quản lý smart notifications
abstract class NotificationRepository {
  /// Lấy danh sách notifications của user
  Future<List<SmartNotification>> getNotifications(String userId);
  
  /// Tạo notification mới
  Future<void> createNotification(SmartNotification notification);
  
  /// Đánh dấu đã đọc
  Future<void> markAsRead(String notificationId);
  
  /// Đánh dấu đã gửi
  Future<void> markAsSent(String notificationId);
  
  /// Xóa notification
  Future<void> deleteNotification(String notificationId);
  
  /// Đếm số notification đã gửi hôm nay
  Future<int> getDailySentCount(String userId);
  
  /// Lấy notifications chưa gửi (scheduled)
  Future<List<SmartNotification>> getPendingNotifications(String userId);
  
  /// Lưu FCM token
  Future<void> saveFCMToken(String userId, String token);
  
  /// Gửi notification qua FCM
  Future<void> sendPushNotification(SmartNotification notification);
  
  /// Stream realtime notifications
  Stream<List<SmartNotification>> notificationsStream(String userId);
}
