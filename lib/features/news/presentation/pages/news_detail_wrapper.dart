import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/news.dart';
import 'news_home_details.dart';

/// Wrapper để load News từ newsId và hiển thị NewsDetailPage
class NewsDetailWrapper extends StatelessWidget {
  final String newsId;
  
  const NewsDetailWrapper({
    super.key,
    required this.newsId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('news').doc(newsId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lỗi')),
            body: const Center(
              child: Text('Không tìm thấy bài báo'),
            ),
          );
        }
        
        // Convert to News entity
        final data = snapshot.data!.data() as Map<String, dynamic>;
        
        // Handle createdAt - convert to DateTime
        DateTime createdAtDateTime;
        if (data['createdAt'] is Timestamp) {
          createdAtDateTime = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          createdAtDateTime = DateTime.parse(data['createdAt']);
        } else {
          createdAtDateTime = DateTime.now();
        }
        
        final news = News(
          id: snapshot.data!.id,
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          imageUrls: data['imageUrls'] != null 
              ? List<String>.from(data['imageUrls'])
              : (data['imageUrl'] != null ? [data['imageUrl']] : []),
          source: data['source'] ?? 'Unknown',
          category: data['category'] ?? 'Khác',
          createdAt: createdAtDateTime,
        );
        
        return NewsDetailPage(news: news);
      },
    );
  }
}
