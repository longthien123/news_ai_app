import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/news.dart';
import '../../domain/repositories/news_repository.dart';
import '../../../../core/local/firebase_bookmark_manager.dart';

// States
abstract class SavedNewsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SavedNewsInitial extends SavedNewsState {}

class SavedNewsLoading extends SavedNewsState {}

class SavedNewsLoaded extends SavedNewsState {
  final List<News> savedNews;

  SavedNewsLoaded({required this.savedNews});

  @override
  List<Object?> get props => [savedNews];
}

class SavedNewsEmpty extends SavedNewsState {}

class SavedNewsError extends SavedNewsState {
  final String message;

  SavedNewsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SavedNewsCubit extends Cubit<SavedNewsState> {
  final NewsRepository newsRepository;
  final FirebaseBookmarkManager bookmarkManager;
  List<News> _allSavedNews = [];

  SavedNewsCubit({
    required this.newsRepository,
    required this.bookmarkManager,
  }) : super(SavedNewsInitial());

  Future<void> loadSavedNews() async {
    try {
      emit(SavedNewsLoading());

      // Get bookmarked news IDs
      final bookmarkedIds = await bookmarkManager.getBookmarkedNewsIds();

      if (bookmarkedIds.isEmpty) {
        emit(SavedNewsEmpty());
        return;
      }

      // Fetch news details for each bookmarked ID
      final List<News> savedNews = [];
      for (final newsId in bookmarkedIds) {
        try {
          final news = await newsRepository.getNewsById(newsId);
          savedNews.add(news);
        } catch (e) {
          // Skip news that can't be loaded
          continue;
        }
      }

      if (savedNews.isEmpty) {
        emit(SavedNewsEmpty());
      } else {
        // Sort by most recent first (assuming newer IDs or we can sort by createdAt)
        savedNews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _allSavedNews = savedNews;
        emit(SavedNewsLoaded(savedNews: savedNews));
      }
    } catch (e) {
      emit(SavedNewsError('Không thể tải tin đã lưu: $e'));
    }
  }

  Future<void> removeBookmark(String newsId) async {
    try {
      await bookmarkManager.removeBookmark(newsId);
      await loadSavedNews(); // Reload the list
    } catch (e) {
      emit(SavedNewsError('Không thể xóa tin đã lưu: $e'));
    }
  }

  void refresh() {
    loadSavedNews();
  }

  void searchSavedNews(String query) {
    if (query.trim().isEmpty) {
      emit(SavedNewsLoaded(savedNews: _allSavedNews));
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filteredNews = _allSavedNews.where((news) {
      final lowerTitle = news.title.toLowerCase();
      final lowerCategory = news.category.toLowerCase();
      return lowerTitle.contains(lowerQuery) || lowerCategory.contains(lowerQuery);
    }).toList();

    if (filteredNews.isEmpty) {
      emit(SavedNewsEmpty());
    } else {
      emit(SavedNewsLoaded(savedNews: filteredNews));
    }
  }
}
