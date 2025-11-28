import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/news.dart';
import '../../domain/usecases/news/add_news_usecase.dart';
import '../../domain/usecases/news/get_news_detail_usecase.dart';
import '../../domain/usecases/news/get_news_usecase.dart';
import '../../data/datasources/remote/rss_news_service.dart';
import '../../data/models/external_news_model.dart';
import '../../data/models/rss_source_model.dart';

part 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final AddNewsUsecase addNewsUsecase;
  final GetNewsDetailUsecase getNewsDetailUsecase;
  final GetNewsUsecase getNewsUsecase;
  final RssNewsService rssNewsService;

  NewsCubit({
    required this.addNewsUsecase,
    required this.getNewsDetailUsecase,
    required this.getNewsUsecase,
    RssNewsService? rssNewsService,
  }) : rssNewsService = rssNewsService ?? RssNewsService(),
       super(NewsInitial());

  // Load danh sách nguồn RSS
  Future<void> loadRssSources() async {
    emit(RssSourcesLoading());
    try {
      final sources = await rssNewsService.loadSources();
      emit(RssSourcesLoaded(sources));
    } catch (e) {
      emit(NewsError('Không thể tải danh sách nguồn: $e'));
    }
  }

  // Fetch tin từ RSS
  Future<void> fetchFromRss({
    required String rssUrl,
    required String sourceName,
    required String category,
  }) async {
    emit(ExternalNewsLoading());
    try {
      final newsList = await rssNewsService.fetchFromRss(
        rssUrl: rssUrl,
        sourceName: sourceName,
        category: category,
      );

      if (newsList.isEmpty) {
        emit(const NewsError('Không có tin tức nào'));
        return;
      }

      emit(ExternalNewsLoaded(newsList));
    } catch (e) {
      emit(NewsError('Không thể tải tin: $e'));
    }
  }

  // Tìm kiếm trong danh sách hiện tại
  void searchInCurrentList(List<ExternalNewsModel> currentList, String query) {
    emit(ExternalNewsLoading());
    try {
      final filtered = rssNewsService.searchInList(currentList, query);
      emit(ExternalNewsLoaded(filtered));
    } catch (e) {
      emit(NewsError('Lỗi tìm kiếm: $e'));
    }
  }

  void selectExternal(ExternalNewsModel item) {
    emit(ExternalNewsSelected(item));
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

  void resetToInitial() {
    emit(NewsInitial());
  }

  void clearSelection() {
    emit(NewsInitial());
  }
}
