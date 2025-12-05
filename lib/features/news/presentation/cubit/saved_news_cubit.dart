import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/news.dart';
import '../../domain/repositories/news_repository.dart';
import '../../../../core/local/firebase_bookmark_manager.dart';
import '../../../../core/services/offline_storage_service.dart';
import '../../../../core/services/connectivity_service.dart';

// States
abstract class SavedNewsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SavedNewsInitial extends SavedNewsState {}

class SavedNewsLoading extends SavedNewsState {}

class SavedNewsLoaded extends SavedNewsState {
  final List<News> savedNews;
  final bool isOfflineMode;

  SavedNewsLoaded({
    required this.savedNews, 
    this.isOfflineMode = false,
  });

  @override
  List<Object?> get props => [savedNews, isOfflineMode];
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
  final OfflineStorageService offlineStorage = OfflineStorageService();
  final ConnectivityService connectivityService = ConnectivityService();
  List<News> _allSavedNews = [];

  SavedNewsCubit({
    required this.newsRepository,
    required this.bookmarkManager,
  }) : super(SavedNewsInitial());

  Future<void> loadSavedNews() async {
    try {
      emit(SavedNewsLoading());

      // Kiểm tra kết nối mạng
      final hasConnection = await connectivityService.checkConnection();

      if (hasConnection) {
        // Có mạng: Load từ Firebase
        await _loadFromFirebase();
      } else {
        // Không có mạng: Load từ offline storage
        await _loadFromOffline();
      }
    } catch (e) {
      emit(SavedNewsError('Không thể tải tin đã lưu: $e'));
    }
  }

  Future<void> _loadFromFirebase() async {
    try {
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
        // Sort by most recent first
        savedNews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _allSavedNews = savedNews;
        emit(SavedNewsLoaded(savedNews: savedNews, isOfflineMode: false));
      }
    } catch (e) {
      print('❌ Error loading from Firebase: $e');
      // Nếu lỗi khi load từ Firebase, thử load từ offline
      await _loadFromOffline();
    }
  }

  Future<void> _loadFromOffline() async {
    try {
      final savedNews = await offlineStorage.getSavedNews();

      if (savedNews.isEmpty) {
        emit(SavedNewsEmpty());
      } else {
        // Sort by most recent first
        savedNews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _allSavedNews = savedNews;
        emit(SavedNewsLoaded(savedNews: savedNews, isOfflineMode: true));
      }
    } catch (e) {
      emit(SavedNewsError('Không thể tải tin đã lưu offline: $e'));
    }
  }

  /// Lưu tin vào offline storage
  Future<bool> saveNewsOffline(News news) async {
    try {
      return await offlineStorage.saveNews(news);
    } catch (e) {
      print('❌ Error saving news offline: $e');
      return false;
    }
  }

  Future<void> removeBookmark(String newsId) async {
    try {
      // Xóa từ Firebase bookmark
      await bookmarkManager.removeBookmark(newsId);
      
      // Xóa từ offline storage
      await offlineStorage.removeNews(newsId);
      
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
      final currentState = state;
      if (currentState is SavedNewsLoaded) {
        emit(SavedNewsLoaded(
          savedNews: _allSavedNews, 
          isOfflineMode: currentState.isOfflineMode,
        ));
      }
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filteredNews = _allSavedNews.where((news) {
      final lowerTitle = news.title.toLowerCase();
      final lowerCategory = news.category.toLowerCase();
      return lowerTitle.contains(lowerQuery) || lowerCategory.contains(lowerQuery);
    }).toList();

    final currentState = state;
    final isOffline = currentState is SavedNewsLoaded ? currentState.isOfflineMode : false;

    if (filteredNews.isEmpty) {
      emit(SavedNewsEmpty());
    } else {
      emit(SavedNewsLoaded(savedNews: filteredNews, isOfflineMode: isOffline));
    }
  }
}
