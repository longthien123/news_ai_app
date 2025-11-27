import '../entities/news.dart';
import '../repositories/news_repository.dart';

class GetNewsUseCase {
  final NewsRepository repository;

  GetNewsUseCase(this.repository);

  Future<List<News>> getAllNews() async {
    return await repository.getAllNews();
  }

  Future<List<News>> getBreakingNews() async {
    return await repository.getBreakingNews();
  }

  Future<List<News>> getNewsByCategory(String category) async {
    return await repository.getNewsByCategory(category);
  }
}
