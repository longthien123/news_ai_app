import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/news.dart';

class NewsModel extends News {
  const NewsModel({
    required super.id,
    required super.title,
    required super.content,
    required super.imageUrls,
    required super.category,
    required super.source,
    required super.createdAt,
    super.authorId,
    super.views,
    super.likes,
  });

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'] ?? '',
      source: data['source'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorId: data['authorId'],
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'category': category,
      'source': source,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorId': authorId,
      'views': views,
      'likes': likes,
    };
  }

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      category: json['category'] ?? '',
      source: json['source'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      authorId: json['authorId'],
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'category': category,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'authorId': authorId,
      'views': views,
      'likes': likes,
    };
  }
}
