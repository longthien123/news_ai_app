import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reply.dart';

class ReplyModel extends Reply {
  const ReplyModel({
    required super.id,
    required super.commentId,
    required super.userId,
    required super.userName,
    required super.content,
    required super.createdAt,
  });

  factory ReplyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReplyModel(
      id: doc.id,
      commentId: data['commentId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Factory method to create ReplyModel with updated username from users collection
  static Future<ReplyModel> fromFirestoreWithUserData(
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userId'] ?? '';
    
    // Get updated username from users collection
    String userName = data['userName'] ?? 'Anonymous';
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
      }
    } catch (e) {
      // If error, use the stored userName
    }
    
    return ReplyModel(
      id: doc.id,
      commentId: data['commentId'] ?? '',
      userId: userId,
      userName: userName,
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'commentId': commentId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
