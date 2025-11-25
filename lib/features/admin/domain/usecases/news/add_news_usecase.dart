import '../../entities/news.dart';
import '../../repositories/news_repository.dart';

class AddNewsUsecase {
  final NewsRepository repository;

  AddNewsUsecase(this.repository);

  Future<News> call({
    required String title,
    required String content,
    required List<String> imageUrls,
    required String category,
    required String source,
    String? authorId,
  }) async {
    return await repository.addNews(
      title: title,
      content: content,
      imageUrls: imageUrls,
      category: category,
      source: source,
      authorId: authorId,
    );
  }
}