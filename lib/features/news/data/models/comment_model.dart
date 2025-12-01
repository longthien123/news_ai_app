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
    super.userAvatar,
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
      userAvatar: data['userAvatar'],
    );
  }

  /// Factory method to create CommentModel with updated username from users collection
  static Future<CommentModel> fromFirestoreWithUserData(
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userId'] ?? '';
    
    // Get updated username from users collection
    String userName = data['userName'] ?? 'Anonymous';
    String? userAvatar;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        // Priority: username > fullName > stored userName
        userName = userData?['username'] ?? 
                   userData?['fullName'] ?? 
                   userName;
        userAvatar = userData?['photoUrl'];
      }
    } catch (e) {
      // If error, use the stored userName
    }
    
    return CommentModel(
      id: doc.id,
      newsId: data['newsId'] ?? '',
      userId: userId,
      userName: userName,
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      repliesCount: data['repliesCount'] ?? 0,
      userAvatar: userAvatar ?? data['userAvatar'],
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
      'userAvatar': userAvatar,
    };
  }
}
