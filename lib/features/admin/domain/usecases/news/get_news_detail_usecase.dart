import '../../entities/news.dart';
import '../../repositories/news_repository.dart';

class GetNewsDetailUsecase {
  final NewsRepository repository;

  GetNewsDetailUsecase(this.repository);

  Future<News> call(String id) async {
    // Tăng lượt view khi xem chi tiết
    await repository.incrementViews(id);
    return await repository.getNewsById(id);
  }
}