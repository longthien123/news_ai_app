import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/news.dart';
import '../../domain/usecases/get_news_usecase.dart';

// States
abstract class SearchNewsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchNewsInitial extends SearchNewsState {}

class SearchNewsLoading extends SearchNewsState {}

class SearchNewsLoaded extends SearchNewsState {
  final List<News> results;
  final String query;

  SearchNewsLoaded({
    required this.results,
    required this.query,
  });

  @override
  List<Object?> get props => [results, query];
}

class SearchNewsError extends SearchNewsState {
  final String message;

  SearchNewsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SearchNewsCubit extends Cubit<SearchNewsState> {
  final GetNewsUseCase getNewsUseCase;

  SearchNewsCubit({required this.getNewsUseCase}) : super(SearchNewsInitial());

  Future<void> searchNews(String query) async {
    try {
      emit(SearchNewsLoading());

      // Lấy tất cả tin tức
      final allNews = await getNewsUseCase.getAllNews();

      // Tìm kiếm trong title và category
      final results = allNews.where((news) {
        final lowerQuery = query.toLowerCase();
        final lowerTitle = news.title.toLowerCase();
        final lowerCategory = news.category.toLowerCase();

        return lowerTitle.contains(lowerQuery) ||
            lowerCategory.contains(lowerQuery);
      }).toList();

      // Sắp xếp theo thời gian (mới nhất trước)
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(SearchNewsLoaded(results: results, query: query));
    } catch (e) {
      emit(SearchNewsError('Lỗi khi tìm kiếm: ${e.toString()}'));
    }
  }

  void clearSearch() {
    emit(SearchNewsInitial());
  }
}
