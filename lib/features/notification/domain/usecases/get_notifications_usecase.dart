import '../repositories/notification_repository.dart';
import '../entities/smart_notification.dart';

/// UseCase: Lấy danh sách notifications
class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<SmartNotification>> call(String userId) async {
    return await repository.getNotifications(userId);
  }
}
