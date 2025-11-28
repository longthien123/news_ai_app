import '../repositories/news_repository.dart';

class IncrementViewUseCase {
  final NewsRepository repository;

  IncrementViewUseCase({required this.repository});

  Future<void> call(String newsId) async {
    try {
      await repository.updateNewsInteraction(newsId, views: 1);
    } catch (e) {
      throw Exception('Failed to increment view count: $e');
    }
  }
}
