/// Model ghi lại user interaction với tin tức
/// Dùng để gửi cho Vertex AI Recommendations
class UserInteractionModel {
  final String userId;
  final String newsId;
  final String eventType; // 'view', 'like', 'comment'
  final int durationSeconds; // Thời gian xem (nếu view)
  final DateTime timestamp;

  const UserInteractionModel({
    required this.userId,
    required this.newsId,
    required this.eventType,
    this.durationSeconds = 0,
    required this.timestamp,
  });

  factory UserInteractionModel.fromFirestore(Map<String, dynamic> doc) {
    return UserInteractionModel(
      userId: doc['userId'] as String? ?? '',
      newsId: doc['newsId'] as String? ?? '',
      eventType: doc['eventType'] as String? ?? 'view',
      durationSeconds: doc['durationSeconds'] as int? ?? 0,
      timestamp: (doc['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'newsId': newsId,
        'eventType': eventType,
        'durationSeconds': durationSeconds,
        'timestamp': timestamp,
      };

  /// Vertex AI format
  Map<String, dynamic> toVertexFormat() => {
        'userId': userId,
        'itemId': newsId,
        'eventType': eventType,
        'eventValue': durationSeconds > 0 ? (durationSeconds / 60).toStringAsFixed(2) : '1',
        'eventTimestamp': '${timestamp.millisecondsSinceEpoch}',
      };
}
