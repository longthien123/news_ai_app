import '../../domain/entities/smart_notification.dart';

class SmartNotificationModel extends SmartNotification {
  const SmartNotificationModel({
    required super.id,
    required super.userId,
    required super.newsId,
    required super.title,
    required super.body,
    super.imageUrl,
    required super.type,
    required super.priority,
    super.aiRelevanceScore,
    required super.scheduledAt,
    super.sentAt,
    super.isRead,
    super.metadata,
  });

  factory SmartNotificationModel.fromJson(Map<String, dynamic> json) {
    return SmartNotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      newsId: json['newsId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.recommended,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      aiRelevanceScore: (json['aiRelevanceScore'] as num?)?.toDouble() ?? 0.5,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'newsId': newsId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'type': type.name,
      'priority': priority.name,
      'aiRelevanceScore': aiRelevanceScore,
      'scheduledAt': scheduledAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory SmartNotificationModel.fromEntity(SmartNotification entity) {
    return SmartNotificationModel(
      id: entity.id,
      userId: entity.userId,
      newsId: entity.newsId,
      title: entity.title,
      body: entity.body,
      imageUrl: entity.imageUrl,
      type: entity.type,
      priority: entity.priority,
      aiRelevanceScore: entity.aiRelevanceScore,
      scheduledAt: entity.scheduledAt,
      sentAt: entity.sentAt,
      isRead: entity.isRead,
      metadata: entity.metadata,
    );
  }
}
