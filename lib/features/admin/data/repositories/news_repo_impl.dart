import '../../domain/entities/news.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/remote/news_remote_source.dart';
import '../datasources/local/news_local_source.dart';
import '../models/news_model.dart';

class NewsRepoImpl implements NewsRepository {
  final NewsRemoteSource remote;
  final NewsLocalSource local;

  NewsRepoImpl({required this.remote, required this.local});

  @override
  Future<News> addNews({
    required String title,
    required String content,
    required List<String> imageUrls,
    required String category,
    required String source,
    String? authorId,
  }) async {
    final newsModel = NewsModel(
      id: '', // Firestore sẽ tự tạo ID
      title: title,
      content: content,
      imageUrls: imageUrls,
      category: category,
      source: source,
      createdAt: DateTime.now(),
      authorId: authorId,
    );

    final result = await remote.addNews(newsModel);
    // Clear cache để force refresh danh sách
    await local.clearCache();
    return result;
  }

  @override
  Future<News> getNewsById(String id) async {
    try {
      final news = await remote.getNewsById(id);
      await local.cacheNewsDetail(id, news.toMap());
      return news;
    } catch (e) {
      // Fallback to cache nếu offline
      final cached = await local.getCachedNewsDetail(id);
      if (cached != null) {
        return NewsModel.fromMap(cached);
      }
      rethrow;
    }
  }

  @override
  Future<List<News>> getAllNews() async {
    try {
      final newsList = await remote.getAllNews();
      await local.cacheNews(newsList.map((n) => n.toMap()).toList());
      return newsList;
    } catch (e) {
      // Fallback to cache nếu offline
      final cached = await local.getCachedNews();
      if (cached != null) {
        return cached.map((map) => NewsModel.fromMap(map)).toList();
      }
      rethrow;
    }
  }

  @override
  Future<List<News>> getNewsByCategory(String category) async {
    try {
      return await remote.getNewsByCategory(category);
    } catch (e) {
      // Fallback: filter từ cache
      final cached = await local.getCachedNews();
      if (cached != null) {
        return cached
            .where((map) => map['category'] == category)
            .map((map) => NewsModel.fromMap(map))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<void> updateNews(String id, Map<String, dynamic> updates) async {
    await remote.updateNews(id, updates);
    await local.clearCache();
  }

  @override
  Future<void> deleteNews(String id) async {
    await remote.deleteNews(id);
    await local.clearCache();
  }

  @override
  Future<void> incrementViews(String id) async {
    await remote.incrementViews(id);
  }

  @override
  Future<void> toggleLike(String id, String userId) async {
    // TODO: Implement like functionality với collection riêng
    throw UnimplementedError();
  }
}