import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/smart_notification.dart';
import '../../domain/entities/user_preference.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_smart_notif_usecase.dart';
import '../../domain/usecases/analyze_user_behavior_usecase.dart';
import '../../domain/usecases/create_smart_notification_usecase.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetSmartNotificationsUseCase getSmartNotificationsUseCase;
  final AnalyzeUserBehaviorUseCase analyzeUserBehaviorUseCase;
  final CreateSmartNotificationUseCase createSmartNotificationUseCase;

  NotificationCubit({
    required this.getNotificationsUseCase,
    required this.getSmartNotificationsUseCase,
    required this.analyzeUserBehaviorUseCase,
    required this.createSmartNotificationUseCase,
  }) : super(NotificationInitial());

  Future<void> loadNotifications(String userId) async {
    emit(NotificationLoading());
    try {
      final notifications = await getNotificationsUseCase(userId);
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> loadSmartNotifications(String userId) async {
    emit(NotificationLoading());
    try {
      final notifications = await getSmartNotificationsUseCase(userId);
      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: notifications.where((n) => !n.isRead).length,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> analyzeUserBehavior(String userId) async {
    try {
      final preference = await analyzeUserBehaviorUseCase(userId);
      emit(UserBehaviorAnalyzed(preference: preference));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> createSmartNotification({
    required String userId,
    required String newsId,
    required String title,
    required String body,
    required String category,
    String? imageUrl,
    required double aiRelevanceScore,
    NotificationType type = NotificationType.recommended,
  }) async {
    try {
      await createSmartNotificationUseCase(
        userId: userId,
        newsId: newsId,
        title: title,
        body: body,
        category: category,
        imageUrl: imageUrl,
        aiRelevanceScore: aiRelevanceScore,
        type: type,
      );
      await loadNotifications(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
