import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../features/news/domain/entities/news.dart';

/// Service lưu trữ tin tức offline với SharedPreferences
class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static const String _savedNewsKey = 'offline_saved_news';

  /// Lưu tin tức vào offline storage
  Future<bool> saveNews(News news) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNewsList = await getSavedNews();
      
      // Kiểm tra xem tin đã được lưu chưa
      final exists = savedNewsList.any((n) => n.id == news.id);
      if (exists) {
        print('⚠️ News already saved: ${news.id}');
        return true;
      }
      
      // Thêm tin mới vào danh sách
      savedNewsList.add(news);
      
      // Chuyển đổi danh sách sang JSON
      final jsonList = savedNewsList.map((n) => _newsToJson(n)).toList();
      final jsonString = jsonEncode(jsonList);
      
      // Lưu vào SharedPreferences
      final success = await prefs.setString(_savedNewsKey, jsonString);
      
      if (success) {
        print('✅ News saved offline: ${news.title}');
      }
      
      return success;
    } catch (e) {
      print('❌ Error saving news offline: $e');
      return false;
    }
  }

  /// Lấy danh sách tin tức đã lưu
  Future<List<News>> getSavedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_savedNewsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      final newsList = jsonList.map((json) => _newsFromJson(json)).toList();
      
      return newsList;
    } catch (e) {
      print('❌ Error loading saved news: $e');
      return [];
    }
  }

  /// Xóa tin tức khỏi offline storage
  Future<bool> removeNews(String newsId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNewsList = await getSavedNews();
      
      // Xóa tin khỏi danh sách
      savedNewsList.removeWhere((n) => n.id == newsId);
      
      // Lưu lại danh sách mới
      final jsonList = savedNewsList.map((n) => _newsToJson(n)).toList();
      final jsonString = jsonEncode(jsonList);
      
      final success = await prefs.setString(_savedNewsKey, jsonString);
      
      if (success) {
        print('✅ News removed from offline: $newsId');
      }
      
      return success;
    } catch (e) {
      print('❌ Error removing news from offline: $e');
      return false;
    }
  }

  /// Kiểm tra xem tin có được lưu offline không
  Future<bool> isNewsSaved(String newsId) async {
    try {
      final savedNewsList = await getSavedNews();
      return savedNewsList.any((n) => n.id == newsId);
    } catch (e) {
      print('❌ Error checking if news is saved: $e');
      return false;
    }
  }

  /// Xóa tất cả tin đã lưu
  Future<bool> clearAllSavedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_savedNewsKey);
    } catch (e) {
      print('❌ Error clearing saved news: $e');
      return false;
    }
  }

  /// Chuyển đổi News sang JSON
  Map<String, dynamic> _newsToJson(News news) {
    return {
      'id': news.id,
      'title': news.title,
      'content': news.content,
      'imageUrls': news.imageUrls,
      'category': news.category,
      'source': news.source,
      'createdAt': news.createdAt.toIso8601String(),
      'authorId': news.authorId,
      'views': news.views,
      'likes': news.likes,
    };
  }

  /// Chuyển đổi JSON sang News
  News _newsFromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrls: (json['imageUrls'] as List).cast<String>(),
      category: json['category'] as String,
      source: json['source'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorId: json['authorId'] as String?,
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
    );
  }
}
