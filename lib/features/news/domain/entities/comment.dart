import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String newsId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int repliesCount;
  final String? userAvatar;

  const Comment({
    required this.id,
    required this.newsId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.repliesCount = 0,
    this.userAvatar,
  });

  @override
  List<Object?> get props => [
        id,
        newsId,
        userId,
        userName,
        content,
        createdAt,
        likes,
        repliesCount,
        userAvatar,
      ];
}
