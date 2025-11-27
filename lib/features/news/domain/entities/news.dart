import 'package:equatable/equatable.dart';

class News extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<String> imageUrls;
  final String category;
  final String source;
  final DateTime createdAt;
  final String? authorId;
  final int views;
  final int likes;

  const News({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.category,
    required this.source,
    required this.createdAt,
    this.authorId,
    this.views = 0,
    this.likes = 0,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        imageUrls,
        category,
        source,
        createdAt,
        authorId,
        views,
        likes,
      ];
}
