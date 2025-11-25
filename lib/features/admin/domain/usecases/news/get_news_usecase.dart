import '../../entities/news.dart';
import '../../repositories/news_repository.dart';

class GetNewsUsecase {
  final NewsRepository repository;

  GetNewsUsecase(this.repository);

  Future<List<News>> call({String? category}) async {
    if (category != null && category.isNotEmpty) {
      return await repository.getNewsByCategory(category);
    }
    return await repository.getAllNews();
  }
}