import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

abstract class NewsLocalSource {
  Future<void> cacheNews(List<Map<String, dynamic>> newsList);
  Future<List<Map<String, dynamic>>?> getCachedNews();
  Future<void> cacheNewsDetail(String id, Map<String, dynamic> news);
  Future<Map<String, dynamic>?> getCachedNewsDetail(String id);
  Future<void> clearCache();
}

class NewsLocalSourceImpl implements NewsLocalSource {
  static const String _newsListKey = 'cached_news_list';
  static const String _newsDetailPrefix = 'cached_news_detail_';
  final SharedPreferences prefs;

  NewsLocalSourceImpl({required this.prefs});

  @override
  Future<void> cacheNews(List<Map<String, dynamic>> newsList) async {
    await prefs.setString(_newsListKey, jsonEncode(newsList));
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedNews() async {
    final json = prefs.getString(_newsListKey);
    if (json == null) return null;
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<void> cacheNewsDetail(String id, Map<String, dynamic> news) async {
    await prefs.setString('$_newsDetailPrefix$id', jsonEncode(news));
  }

  @override
  Future<Map<String, dynamic>?> getCachedNewsDetail(String id) async {
    final json = prefs.getString('$_newsDetailPrefix$id');
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  @override
  Future<void> clearCache() async {
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_newsDetailPrefix) || key == _newsListKey) {
        await prefs.remove(key);
      }
    }
  }
}