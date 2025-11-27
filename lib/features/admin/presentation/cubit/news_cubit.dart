import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/news.dart';
import '../../domain/usecases/news/add_news_usecase.dart';
import '../../domain/usecases/news/get_news_detail_usecase.dart';
import '../../domain/usecases/news/get_news_usecase.dart';

part 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final AddNewsUsecase addNewsUsecase;
  final GetNewsDetailUsecase getNewsDetailUsecase;
  final GetNewsUsecase getNewsUsecase;

  NewsCubit({
    required this.addNewsUsecase,
    required this.getNewsDetailUsecase,
    required this.getNewsUsecase,
  }) : super(NewsInitial());

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
}