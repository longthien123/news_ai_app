import '../../domain/entities/reading_session.dart';

class ReadingSessionModel extends ReadingSession {
  const ReadingSessionModel({
    required super.userId,
    required super.newsId,
    required super.category,
    required super.title,
    required super.startedAt,
    super.endedAt,
    super.durationSeconds,
    super.isBookmarked,
    super.isCompleted,
  });

  factory ReadingSessionModel.fromJson(Map<String, dynamic> json) {
    return ReadingSessionModel(
      userId: json['userId'] as String,
      newsId: json['newsId'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'newsId': newsId,
      'category': category,
      'title': title,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'isBookmarked': isBookmarked,
      'isCompleted': isCompleted,
    };
  }

  factory ReadingSessionModel.fromEntity(ReadingSession entity) {
    return ReadingSessionModel(
      userId: entity.userId,
      newsId: entity.newsId,
      category: entity.category,
      title: entity.title,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      durationSeconds: entity.durationSeconds,
      isBookmarked: entity.isBookmarked,
      isCompleted: entity.isCompleted,
    );
  }
}
