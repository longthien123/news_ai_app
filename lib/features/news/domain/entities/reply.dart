import 'package:equatable/equatable.dart';

class Reply extends Equatable {
  final String id;
  final String commentId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  const Reply({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        commentId,
        userId,
        userName,
        content,
        createdAt,
      ];
}
