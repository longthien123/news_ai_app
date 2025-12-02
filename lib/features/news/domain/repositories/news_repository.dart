import '../entities/news.dart';

abstract class NewsRepository {
  Future<List<News>> getAllNews();
  Future<List<News>> getBreakingNews();
  Future<List<News>> getNewsByCategory(String category);
  Future<News> getNewsById(String id);
  Future<void> updateNewsInteraction(String id, {int? views, int? likes});
  
  // ⭐ AI Recommendation
  Future<List<News>> getRecommendedNews(String userId);
}
