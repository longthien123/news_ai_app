import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/news.dart';
import '../../domain/usecases/news/add_news_usecase.dart';
import '../../domain/usecases/news/get_news_detail_usecase.dart';
import '../../domain/usecases/news/get_news_usecase.dart';
import '../../data/datasources/remote/external_news_service.dart';
import '../../data/models/external_news_model.dart';

part 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final AddNewsUsecase addNewsUsecase;
  final GetNewsDetailUsecase getNewsDetailUsecase;
  final GetNewsUsecase getNewsUsecase;
  final ExternalNewsService externalNewsService;

  NewsCubit({
    required this.addNewsUsecase,
    required this.getNewsDetailUsecase,
    required this.getNewsUsecase,
    ExternalNewsService? externalNewsService,
  }) : externalNewsService = externalNewsService ?? ExternalNewsService(),
       super(NewsInitial());

  Future<void> loadNews({String? category}) async {
    emit(NewsLoading());
    try {
      final newsList = await getNewsUsecase(category: category);
      emit(NewsListLoaded(newsList));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> loadNewsDetail(String id) async {
    emit(NewsLoading());
    try {
      final news = await getNewsDetailUsecase(id);
      emit(NewsDetailLoaded(news));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> addNews({
    required String title,
    required String content,
    required List<String> imageUrls,
    required String category,
    required String source,
    String? authorId,
  }) async {
    emit(NewsLoading());
    try {
      final news = await addNewsUsecase(
        title: title,
        content: content,
        imageUrls: imageUrls,
        category: category,
        source: source,
        authorId: authorId,
      );
      emit(NewsAdded(news));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> fetchExternalTop({
    String country = 'us',
    String? category,
  }) async {
    emit(ExternalNewsLoading());
    try {
      final list = await externalNewsService.fetchTopHeadlines(
        country: country,
        category: category,
        pageSize: 30,
      );
      emit(ExternalNewsLoaded(list));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> searchExternal(String query) async {
    if (query.trim().isEmpty) {
      fetchExternalTop();
      return;
    }
    emit(ExternalNewsLoading());
    try {
      final list = await externalNewsService.search(query, pageSize: 30);
      emit(ExternalNewsLoaded(list));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  void selectExternal(ExternalNewsModel item) {
    emit(ExternalNewsSelected(item));
  }

  Future<void> addExternalAsNews(
    ExternalNewsModel item, {
    String? authorId,
  }) async {
    emit(NewsLoading());
    try {
      final data = item.toNewsData(overrideSource: 'newsorg');
      final news = await addNewsUsecase(
        title: data['title'] as String,
        content: data['content'] as String,
        imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>),
        category: data['category'] as String,
        source: data['source'] as String,
        authorId: authorId,
      );
      emit(NewsAdded(news));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  // Reset state về ban đầu
  void resetToInitial() {
    emit(NewsInitial());
  }

  // Clear any selected external news (nếu cần)
  void clearSelection() {
    emit(NewsInitial());
  }
}
