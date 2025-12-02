import 'package:cloud_firestore/cloud_firestore.dart';

/// Model để lưu thống kê views theo ngày
class DailyViewStats {
  final String id; // Format: yyyyMMdd_newsId hoặc yyyyMMdd_category
  final DateTime date;
  final String? newsId; // null nếu là tổng hợp theo ngày
  final String? category;
  final int viewCount;
  final DateTime updatedAt;

  DailyViewStats({
    required this.id,
    required this.date,
    this.newsId,
    this.category,
    required this.viewCount,
    required this.updatedAt,
  });

  factory DailyViewStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyViewStats(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      newsId: data['newsId'],
      category: data['category'],
      viewCount: data['viewCount'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'newsId': newsId,
      'category': category,
      'viewCount': viewCount,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
