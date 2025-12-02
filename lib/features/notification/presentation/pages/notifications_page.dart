import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/config/app_colors.dart';
import '../cubit/notification_cubit.dart';
import '../../domain/entities/smart_notification.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.settings_outline, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/notification-settings');
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Ionicons.alert_circle_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${state.message}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.notifications_off_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có thông báo nào',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return NotificationCard(notification: notification);
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final SmartNotification notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityBadge(),
                const SizedBox(width: 8),
                Text(
                  _formatTime(notification.scheduledAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          print('📱 Notification tapped: newsId=${notification.newsId}');
          
          // Navigate to news detail if newsId exists
          if (notification.newsId != null && notification.newsId!.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/news-detail',
              arguments: notification.newsId,
            );
          } else {
            print('⚠️ No newsId found in notification');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy bài báo')),
            );
          }
        },
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.breaking:
        icon = Ionicons.flash;
        color = Colors.red;
        break;
      case NotificationType.recommended:
        icon = Ionicons.star;
        color = AppColors.primary;
        break;
      case NotificationType.contextual:
        icon = Ionicons.bulb;
        color = Colors.orange;
        break;
      case NotificationType.digest:
        icon = Ionicons.newspaper;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildPriorityBadge() {
    String label;
    Color color;

    switch (notification.priority) {
      case NotificationPriority.high:
        label = 'Quan trọng';
        color = Colors.red;
        break;
      case NotificationPriority.normal:
        label = 'Thường';
        color = Colors.blue;
        break;
      case NotificationPriority.low:
        label = 'Thấp';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}
