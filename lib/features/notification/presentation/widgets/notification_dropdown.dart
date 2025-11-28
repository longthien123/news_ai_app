import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/config/app_colors.dart';
import '../cubit/notification_cubit.dart';
import '../../domain/entities/smart_notification.dart';

class NotificationDropdown extends StatefulWidget {
  const NotificationDropdown({super.key});

  @override
  State<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<NotificationDropdown> {
  final _overlayController = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationLoaded) {
          unreadCount = state.unreadCount;
        }

        return OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) {
            return Positioned(
              top: 70,
              right: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 360,
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Thông báo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.settings, size: 20),
                              onPressed: () {
                                _overlayController.hide();
                                Navigator.pushNamed(context, '/notification-settings');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _overlayController.hide(),
                            ),
                          ],
                        ),
                      ),
                      // Tabs
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            _buildTab('Tất cả', true),
                            const SizedBox(width: 8),
                            _buildTab('Chưa đọc', false),
                          ],
                        ),
                      ),
                      // Notifications list
                      Expanded(
                        child: _buildNotificationsList(state),
                      ),
                      // Footer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            _overlayController.hide();
                            Navigator.pushNamed(context, '/notifications');
                          },
                          child: const Center(
                            child: Text(
                              'Xem tất cả thông báo',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Ionicons.notifications_outline, color: Colors.black, size: 20),
                  onPressed: () => _overlayController.toggle(),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.blue : Colors.grey[600],
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationState state) {
    if (state is NotificationLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is NotificationError) {
      return Center(
        child: Text('Lỗi: ${state.message}'),
      );
    }

    if (state is NotificationLoaded) {
      if (state.notifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Không có thông báo',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: state.notifications.length > 5 ? 5 : state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return _buildNotificationItem(notification);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNotificationItem(SmartNotification notification) {
    return InkWell(
      onTap: () {
        _overlayController.hide();
        Navigator.pushNamed(context, '/notifications');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.scheduledAt, locale: 'vi'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.breaking:
        return Colors.red;
      case NotificationType.recommended:
        return Colors.blue;
      case NotificationType.contextual:
        return Colors.orange;
      case NotificationType.digest:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.breaking:
        return Icons.flash_on;
      case NotificationType.recommended:
        return Icons.star;
      case NotificationType.contextual:
        return Icons.lightbulb;
      case NotificationType.digest:
        return Icons.library_books;
    }
  }
}
