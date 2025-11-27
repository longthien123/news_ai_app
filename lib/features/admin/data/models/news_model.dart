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

  factory NewsModel.fromMap(Map<String, dynamic> map) {
    return NewsModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      category: map['category'] ?? '',
      source: map['source'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      authorId: map['authorId'],
      views: map['views'] ?? 0,
      likes: map['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
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

  NewsModel copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? imageUrls,
    String? category,
    String? source,
    DateTime? createdAt,
    String? authorId,
    int? views,
    int? likes,
  }) {
    return NewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      views: views ?? this.views,
      likes: likes ?? this.likes,
    );
  }
}