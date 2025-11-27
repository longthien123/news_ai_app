import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/external_news_model.dart';

class ExternalNewsService {
  static const String _apiKey = '5b7fce098af247ea98a5e7bb25d28d13';
  static const String _base = 'https://newsapi.org/v2';

  Future<List<ExternalNewsModel>> fetchTopHeadlines({
    String country = 'us',
    String? category,
    int pageSize = 20,
  }) async {
    final params = {
      'apiKey': _apiKey,
      'pageSize': pageSize.toString(),
      'country': country,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final uri = Uri.parse(
      '$_base/top-headlines',
    ).replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('NewsAPI error ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final articles = (body['articles'] as List?) ?? [];
    return articles
        .map((a) => ExternalNewsModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExternalNewsModel>> search(
    String query, {
    int pageSize = 20,
  }) async {
    final params = {
      'apiKey': _apiKey,
      'q': query,
      'pageSize': pageSize.toString(),
      'sortBy': 'publishedAt',
    };
    final uri = Uri.parse('$_base/everything').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('NewsAPI error ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final articles = (body['articles'] as List?) ?? [];
    return articles
        .map((a) => ExternalNewsModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }
}
