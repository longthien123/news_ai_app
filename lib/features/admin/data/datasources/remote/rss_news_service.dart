import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import '../../models/external_news_model.dart';
import '../../models/rss_source_model.dart';

class RssNewsService {
  List<RssSourceModel>? _sources;

  // Cache
  final Map<String, _CachedNews> _cache = {};

  // ✅ Giới hạn 15 bài mỗi danh mục
  static const int maxNewsItems = 15;

  static const List<String> proxies = [
    'https://corsproxy.io/?',
    'https://api.allorigins.win/raw?url=',
    'https://api.codetabs.com/v1/proxy?quest=',
  ];

  Future<List<RssSourceModel>> loadSources() async {
    if (_sources != null) return _sources!;

    try {
      final jsonString = await rootBundle.loadString('assets/rss_sources.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final sourcesList = jsonData['sources'] as List;

      _sources = sourcesList
          .map((s) => RssSourceModel.fromJson(s as Map<String, dynamic>))
          .toList();

      return _sources!;
    } catch (e) {
      print('❌ Error loading RSS sources: $e');
      return [];
    }
  }

  Future<List<ExternalNewsModel>> fetchFromRss({
    required String rssUrl,
    required String sourceName,
    required String category,
  }) async {
    // Check cache
    final cacheKey = '$rssUrl|$sourceName|$category';
    final cached = _cache[cacheKey];

    if (cached != null &&
        DateTime.now().difference(cached.timestamp).inMinutes < 5) {
      print('📦 Cache hit: ${cached.newsList.length} items');
      return cached.newsList;
    }

    print('📡 Fetching: $rssUrl');

    for (int proxyIndex = 0; proxyIndex < proxies.length; proxyIndex++) {
      final proxy = proxies[proxyIndex];
      print('🔄 Proxy ${proxyIndex + 1}/${proxies.length}');

      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final encodedUrl = Uri.encodeComponent(rssUrl);
          final finalUrl = '$proxy$encodedUrl';

          final response = await http
              .get(
                Uri.parse(finalUrl),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  'Accept':
                      'application/rss+xml, application/xml, text/xml, */*',
                },
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            print('✅ HTTP 200 - Parsing...');

            final feed = RssFeed.parse(response.body);

            if (feed.items.isEmpty) {
              print('⚠️ Empty feed');
              break;
            }

            print('📄 Total in feed: ${feed.items.length}');

            // ✅ CHỈ LẤY 15 BÀI ĐẦU TIÊN
            final itemsToProcess = feed.items.take(maxNewsItems).toList();
            print('⚡ Processing ${itemsToProcess.length} items...');

            final newsList = itemsToProcess
                .map((item) {
                  try {
                    return ExternalNewsModel.fromRssItem(
                      item: item,
                      sourceName: sourceName,
                      category: category,
                    );
                  } catch (e) {
                    return null;
                  }
                })
                .where(
                  (news) =>
                      news != null &&
                      news.title.isNotEmpty &&
                      news.description.isNotEmpty,
                )
                .cast<ExternalNewsModel>()
                .toList();

            if (newsList.isEmpty) {
              print('⚠️ No valid items');
              break;
            }

            // Lưu cache
            _cache[cacheKey] = _CachedNews(
              newsList: newsList,
              timestamp: DateTime.now(),
            );

            print('🎉 Loaded ${newsList.length}/15 articles');
            return newsList;
          }

          print('⚠️ HTTP ${response.statusCode}');
          if (attempt < 2) {
            await Future.delayed(const Duration(seconds: 1));
          }
        } on http.ClientException catch (e) {
          print('❌ Network error');
          if (attempt < 2) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          print('❌ Error: ${e.toString().substring(0, 50)}...');
          if (attempt < 2) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
    }

    throw Exception(
      'Không thể tải tin.\n\n'
      'Vui lòng:\n'
      '• Thử danh mục khác\n'
      '• Thử nguồn tin khác\n'
      '• Đợi 1-2 phút rồi thử lại',
    );
  }

  void clearCache() {
    _cache.clear();
    print('🗑️ Cache cleared');
  }

  List<ExternalNewsModel> searchInList(
    List<ExternalNewsModel> newsList,
    String query,
  ) {
    if (query.trim().isEmpty) return newsList;

    final lowerQuery = query.toLowerCase();
    return newsList.where((news) {
      return news.title.toLowerCase().contains(lowerQuery) ||
          news.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

class _CachedNews {
  final List<ExternalNewsModel> newsList;
  final DateTime timestamp;

  _CachedNews({required this.newsList, required this.timestamp});
}
