import 'package:equatable/equatable.dart';

enum NotificationType {
  breaking, // Breaking news - gửi ngay
  recommended, // AI gợi ý
  contextual, // Theo ngữ cảnh (đang đọc tin liên quan)
  digest, // Tổng hợp tin hot
}

enum NotificationPriority {
  low, // Tin thường
  normal, // Tin quan tâm vừa phải
  high, // Tin rất phù hợp hoặc breaking
}

/// Entity cho thông báo thông minh với AI scoring
class SmartNotification extends Equatable {
  final String id;
  final String userId;
  final String newsId;
  final String title;
  final String body;
  final String? imageUrl;
  final NotificationType type;
  final NotificationPriority priority;
  final double aiRelevanceScore; // Điểm AI (0.0 - 1.0) đánh giá mức độ phù hợp
  final DateTime scheduledAt; // Thời điểm dự kiến gửi
  final DateTime? sentAt; // Thời điểm gửi thực tế
  final bool isRead;
  final Map<String, dynamic>? metadata; // Data thêm (category, keywords...)
  
  const SmartNotification({
    required this.id,
    required this.userId,
    required this.newsId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.type = NotificationType.recommended,
    this.priority = NotificationPriority.normal,
    this.aiRelevanceScore = 0.5,
    required this.scheduledAt,
    this.sentAt,
    this.isRead = false,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [
    id,
    userId,
    newsId,
    title,
    body,
    imageUrl,
    type,
    priority,
    aiRelevanceScore,
    scheduledAt,
    sentAt,
    isRead,
    metadata,
  ];
  
  /// Kiểm tra có nên gửi ngay không (breaking news hoặc score cao)
  bool get shouldSendImmediately {
    return type == NotificationType.breaking || 
           (priority == NotificationPriority.high && aiRelevanceScore >= 0.8);
  }
  
  SmartNotification copyWith({
    String? id,
    String? userId,
    String? newsId,
    String? title,
    String? body,
    String? imageUrl,
    NotificationType? type,
    NotificationPriority? priority,
    double? aiRelevanceScore,
    DateTime? scheduledAt,
    DateTime? sentAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return SmartNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      newsId: newsId ?? this.newsId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      aiRelevanceScore: aiRelevanceScore ?? this.aiRelevanceScore,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
