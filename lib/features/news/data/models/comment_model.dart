import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.newsId,
    required super.userId,
    required super.userName,
    required super.content,
    required super.createdAt,
    super.likes,
    super.repliesCount,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      newsId: data['newsId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      repliesCount: data['repliesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'newsId': newsId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'repliesCount': repliesCount,
    };
  }
}
