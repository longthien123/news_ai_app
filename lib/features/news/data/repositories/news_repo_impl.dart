import '../../domain/entities/news.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/remote/news_remote_source.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteSource remoteSource;

  NewsRepositoryImpl({required this.remoteSource});

  @override
  Future<List<News>> getAllNews() async {
    return await remoteSource.getAllNews();
  }

  @override
  Future<List<News>> getBreakingNews() async {
    return await remoteSource.getBreakingNews();
  }

  @override
  Future<List<News>> getNewsByCategory(String category) async {
    return await remoteSource.getNewsByCategory(category);
  }

  @override
  Future<News> getNewsById(String id) async {
    return await remoteSource.getNewsById(id);
  }

  @override
  Future<void> updateNewsInteraction(String id, {int? views, int? likes}) async {
    await remoteSource.updateNewsInteraction(id, views: views, likes: likes);
  }
}
