import '../entities/news.dart';

abstract class NewsRepository {
  Future<News> addNews({
    required String title,
    required String content,
    required List<String> imageUrls,
    required String category,
    required String source,
    String? authorId,
  });
  
  Future<News> getNewsById(String id);
  Future<List<News>> getAllNews();
  Future<List<News>> getNewsByCategory(String category);
  Future<void> updateNews(String id, Map<String, dynamic> updates);
  Future<void> deleteNews(String id);
  Future<void> incrementViews(String id);
  Future<void> toggleLike(String id, String userId);
}