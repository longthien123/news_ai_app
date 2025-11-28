import '../repositories/notification_repository.dart';
import '../repositories/user_behavior_repository.dart';
import '../entities/smart_notification.dart';
import '../entities/user_preference.dart';

/// UseCase: Tạo smart notification với AI scoring
class CreateSmartNotificationUseCase {
  final NotificationRepository notificationRepository;
  final UserBehaviorRepository behaviorRepository;

  CreateSmartNotificationUseCase({
    required this.notificationRepository,
    required this.behaviorRepository,
  });

  Future<SmartNotification> call({
    required String userId,
    required String newsId,
    required String title,
    required String body,
    required String category,
    String? imageUrl,
    required double aiRelevanceScore,
    NotificationType type = NotificationType.recommended,
  }) async {
    // Lấy preferences để xác định thời điểm gửi
    final preference = await behaviorRepository.getUserPreference(userId);
    
    // Xác định priority dựa trên AI score
    NotificationPriority priority;
    if (aiRelevanceScore >= 0.8) {
      priority = NotificationPriority.high;
    } else if (aiRelevanceScore >= 0.5) {
      priority = NotificationPriority.normal;
    } else {
      priority = NotificationPriority.low;
    }
    
    // Xác định thời điểm gửi
    DateTime scheduledAt;
    if (type == NotificationType.breaking) {
      // Breaking news → gửi ngay
      scheduledAt = DateTime.now();
    } else {
      // Gửi vào giờ vàng tiếp theo
      scheduledAt = _getNextGoldenHour(preference);
    }
    
    // Kiểm tra giới hạn thông báo hàng ngày
    final todayCount = await notificationRepository.getDailySentCount(userId);
    final limit = preference?.dailyNotificationLimit ?? 5;
    
    if (todayCount >= limit && type != NotificationType.breaking) {
      // Đã đạt giới hạn → lên lịch cho ngày mai
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }
    
    final notification = SmartNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      newsId: newsId,
      title: title,
      body: body,
      imageUrl: imageUrl,
      type: type,
      priority: priority,
      aiRelevanceScore: aiRelevanceScore,
      scheduledAt: scheduledAt,
      metadata: {
        'category': category,
      },
    );
    
    await notificationRepository.createNotification(notification);
    
    // Nếu cần gửi ngay → gửi luôn
    if (notification.shouldSendImmediately) {
      await notificationRepository.sendPushNotification(notification);
      await notificationRepository.markAsSent(notification.id);
    }
    
    return notification;
  }
  
  DateTime _getNextGoldenHour(UserPreference? preference) {
    final now = DateTime.now();
    final goldenHours = preference?.getGoldenHours() ?? [8, 12, 20];
    
    // Tìm giờ vàng tiếp theo
    for (final hour in goldenHours) {
      if (now.hour < hour) {
        return DateTime(now.year, now.month, now.day, hour);
      }
    }
    
    // Nếu đã qua tất cả giờ vàng hôm nay → lấy giờ đầu tiên ngày mai
    return DateTime(now.year, now.month, now.day + 1, goldenHours.first);
  }
}
