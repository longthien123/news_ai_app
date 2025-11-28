import 'package:equatable/equatable.dart';

/// Entity lưu phiên đọc tin của user để phân tích behavior
class ReadingSession extends Equatable {
  final String userId;
  final String newsId;
  final String category;
  final String title;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds; // Thời gian đọc (giây)
  final bool isBookmarked; // Có bookmark không
  final bool isCompleted; // Đọc hết bài không (scroll đến cuối)
  
  const ReadingSession({
    required this.userId,
    required this.newsId,
    required this.category,
    required this.title,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.isBookmarked = false,
    this.isCompleted = false,
  });
  
  @override
  List<Object?> get props => [
    userId,
    newsId,
    category,
    title,
    startedAt,
    endedAt,
    durationSeconds,
    isBookmarked,
    isCompleted,
  ];
  
  /// Tính engagement score (0-100)
  /// Dựa trên: thời gian đọc, bookmark, hoàn thành
  int get engagementScore {
    int score = 0;
    
    // Thời gian đọc (max 40 điểm)
    if (durationSeconds >= 120) score += 40; // >= 2 phút
    else if (durationSeconds >= 60) score += 30; // >= 1 phút
    else if (durationSeconds >= 30) score += 20; // >= 30s
    else score += 10;
    
    // Bookmark (30 điểm)
    if (isBookmarked) score += 30;
    
    // Hoàn thành bài (30 điểm)
    if (isCompleted) score += 30;
    
    return score;
  }
  
  ReadingSession copyWith({
    String? userId,
    String? newsId,
    String? category,
    String? title,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    bool? isBookmarked,
    bool? isCompleted,
  }) {
    return ReadingSession(
      userId: userId ?? this.userId,
      newsId: newsId ?? this.newsId,
      category: category ?? this.category,
      title: title ?? this.title,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
