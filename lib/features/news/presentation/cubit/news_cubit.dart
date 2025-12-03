import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ⭐ AI Recommendation
import '../../domain/entities/news.dart';
import '../../domain/usecases/get_news_usecase.dart';

// States
abstract class NewsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<News> breakingNews;
  final List<News> recommendedNews;

  NewsLoaded({
    required this.breakingNews,
    required this.recommendedNews,
  });

  @override
  List<Object?> get props => [breakingNews, recommendedNews];
}

class NewsError extends NewsState {
  final String message;

  NewsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class NewsCubit extends Cubit<NewsState> {
  final GetNewsUseCase getNewsUseCase;
  String? _selectedCategory;

  NewsCubit({required this.getNewsUseCase}) : super(NewsInitial());

  Future<void> loadNews({String? category}) async {
    try {
      emit(NewsLoading());
      
      _selectedCategory = category;
      final breakingNews = await getNewsUseCase.getBreakingNews();
      
      List<News> newsList;
      
      // ⭐ AI Recommendation: Kiểm tra category "Gợi ý cho bạn"
      if (category == 'Gợi ý cho bạn') {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        newsList = await getNewsUseCase.getRecommendedNews(userId);
      } else if (category != null && category.isNotEmpty) {
        newsList = await getNewsUseCase.getNewsByCategory(category);
      } else {
        newsList = await getNewsUseCase.getAllNews();
      }
      
      emit(NewsLoaded(
        breakingNews: breakingNews,
        recommendedNews: newsList,
      ));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> refreshNews() async {
    await loadNews(category: _selectedCategory);
  }

  Future<void> filterByCategory(String category) async {
    try {
      final currentState = state;
      if (currentState is NewsLoaded) {
        _selectedCategory = category;
        
        List<News> newsList;
        
        // ⭐ AI Recommendation: Kiểm tra category "Gợi ý cho bạn"
        if (category == 'Gợi ý cho bạn') {
          emit(NewsLoading());
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          newsList = await getNewsUseCase.getRecommendedNews(userId);
        } else {
          newsList = await getNewsUseCase.getNewsByCategory(category);
        }
        
        emit(NewsLoaded(
          breakingNews: currentState.breakingNews,
          recommendedNews: newsList,
        ));
      }
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }
}
