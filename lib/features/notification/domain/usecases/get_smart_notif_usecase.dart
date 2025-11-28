import '../repositories/notification_repository.dart';
import '../repositories/user_behavior_repository.dart';
import '../entities/smart_notification.dart';

/// UseCase: Lấy smart notifications được AI recommend
class GetSmartNotificationsUseCase {
  final NotificationRepository notificationRepository;
  final UserBehaviorRepository behaviorRepository;

  GetSmartNotificationsUseCase({
    required this.notificationRepository,
    required this.behaviorRepository,
  });

  /// Lấy notifications pending và sort theo relevance score
  Future<List<SmartNotification>> call(String userId) async {
    final pending = await notificationRepository.getPendingNotifications(userId);
    
    // Sort theo AI score + priority
    pending.sort((a, b) {
      // Priority cao hơn lên trước
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      
      // Nếu cùng priority thì sort theo AI score
      return b.aiRelevanceScore.compareTo(a.aiRelevanceScore);
    });
    
    return pending;
  }
}
