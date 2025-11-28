import '../../domain/entities/smart_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';
import '../models/smart_notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource dataSource;

  NotificationRepositoryImpl({required this.dataSource});

  @override
  Future<List<SmartNotification>> getNotifications(String userId) async {
    return await dataSource.getNotifications(userId);
  }

  @override
  Future<void> createNotification(SmartNotification notification) async {
    final model = SmartNotificationModel.fromEntity(notification);
    await dataSource.saveNotification(model);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // Cần userId - sẽ fix sau khi integrate
    throw UnimplementedError('Cần truyền userId');
  }

  @override
  Future<void> markAsSent(String notificationId) async {
    // Cần userId
    throw UnimplementedError('Cần truyền userId');
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    // Cần userId
    throw UnimplementedError('Cần truyền userId');
  }

  @override
  Future<int> getDailySentCount(String userId) async {
    return await dataSource.getTodaySentCount(userId);
  }

  @override
  Future<List<SmartNotification>> getPendingNotifications(String userId) async {
    final all = await getNotifications(userId);
    return all.where((n) => n.sentAt == null).toList();
  }

  @override
  Future<void> saveFCMToken(String userId, String token) async {
    await dataSource.saveFCMToken(userId, token);
  }

  @override
  Future<void> sendPushNotification(SmartNotification notification) async {
    await dataSource.showLocalNotification(
      title: notification.title,
      body: notification.body,
      imageUrl: notification.imageUrl,
    );
  }

  @override
  Stream<List<SmartNotification>> notificationsStream(String userId) {
    return dataSource.notificationsStream(userId);
  }
}
