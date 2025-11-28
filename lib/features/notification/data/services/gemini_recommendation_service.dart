import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../news/data/datasources/remote/gemini_config.dart';
import '../../domain/entities/user_preference.dart';
import '../../../../features/admin/domain/entities/news.dart';

/// Service dùng Gemini AI để phân tích và gợi ý tin tức phù hợp với user
class GeminiRecommendationService {
  GenerativeModel _getModel() {
    return GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.apiKey,
    );
  }

  /// Tính điểm relevance của tin tức so với user preferences (0.0 - 1.0)
  Future<double> calculateRelevanceScore({
    required News news,
    required UserPreference userPreference,
  }) async {
    if (GeminiConfig.apiKey == 'YOUR_GEMINI_API_KEY') {
      // Fallback: tính score theo rule-based
      return _fallbackRelevanceScore(news, userPreference);
    }

    try {
      final model = _getModel();
      final prompt = '''
Bạn là AI phân tích sở thích người dùng đọc tin tức.

THÔNG TIN USER:
- Categories yêu thích: ${userPreference.favoriteCategories.join(', ')}
- Keywords quan tâm: ${userPreference.keywords.join(', ')}

TIN TỨC CẦN ĐÁNH GIÁ:
- Tiêu đề: ${news.title}
- Category: ${news.category}
- Nội dung (50 từ đầu): ${_truncateContent(news.content, 50)}

YÊU CẦU:
Đánh giá mức độ phù hợp của tin tức này với sở thích user, trả về 1 số duy nhất từ 0.0 đến 1.0:
- 0.0-0.3: Không phù hợp
- 0.4-0.6: Phù hợp vừa phải
- 0.7-0.9: Rất phù hợp
- 0.9-1.0: Cực kỳ phù hợp (chắc chắn user sẽ thích)

CHỈ TRẢ VỀ 1 SỐ, KHÔNG GHI GÌ THÊM.
''';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 10));

      if (response.text != null && response.text!.isNotEmpty) {
        final scoreText = response.text!.trim();
        final score = double.tryParse(scoreText);
        if (score != null && score >= 0.0 && score <= 1.0) {
          print('✅ AI Relevance Score: $score');
          return score;
        }
      }

      print('⚠️ AI trả về không hợp lệ, dùng fallback');
    } catch (e) {
      print('❌ Lỗi Gemini: $e');
    }

    return _fallbackRelevanceScore(news, userPreference);
  }

  /// Tạo nội dung thông báo được cá nhân hóa bằng AI
  Future<String> generatePersonalizedNotificationBody({
    required News news,
    required UserPreference userPreference,
  }) async {
    if (GeminiConfig.apiKey == 'YOUR_GEMINI_API_KEY') {
      return _fallbackNotificationBody(news);
    }

    try {
      final model = _getModel();
      final prompt = '''
Tạo nội dung thông báo ngắn gọn, hấp dẫn để user click vào đọc tin.

THÔNG TIN USER:
- Quan tâm đến: ${userPreference.favoriteCategories.join(', ')}
- Keywords: ${userPreference.keywords.join(', ')}

TIN TỨC:
- Tiêu đề: ${news.title}
- Nội dung: ${_truncateContent(news.content, 100)}

YÊU CẦU:
- Viết 1 câu duy nhất (tối đa 60 ký tự)
- Ngắn gọn, súc tích, hấp dẫn
- Nhấn mạnh điểm liên quan đến sở thích user
- Không dùng emoji
- Tiếng Việt

CHỈ TRẢ VỀ NỘI DUNG THÔNG BÁO, KHÔNG GHI GÌ THÊM.
''';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 10));

      if (response.text != null && response.text!.isNotEmpty) {
        final body = response.text!.trim();
        if (body.length <= 80) {
          print('✅ AI Generated Body: $body');
          return body;
        }
      }
    } catch (e) {
      print('❌ Lỗi Gemini generate body: $e');
    }

    return _fallbackNotificationBody(news);
  }

  /// Phân tích keywords từ danh sách tin đã đọc
  Future<List<String>> extractKeywordsFromReadingHistory({
    required List<String> titles,
    required List<String> categories,
  }) async {
    if (GeminiConfig.apiKey == 'YOUR_GEMINI_API_KEY' || titles.isEmpty) {
      return _fallbackExtractKeywords(titles, categories);
    }

    try {
      final model = _getModel();
      final prompt = '''
Phân tích danh sách tin tức user đã đọc, tìm ra các keywords chính user quan tâm.

TIN ĐÃ ĐỌC:
${titles.take(20).map((t) => '- $t').join('\n')}

CATEGORIES ĐÃ ĐỌC:
${categories.toSet().join(', ')}

YÊU CẦU:
- Trích xuất 5-10 keywords chính
- Keywords phải là danh từ hoặc cụm danh từ (tiếng Việt không dấu cũng được)
- Loại bỏ stopwords, chỉ giữ từ có nghĩa
- Mỗi keyword trên 1 dòng
- Không đánh số, không gạch đầu dòng

VÍ DỤ OUTPUT:
bong da
champions league
kinh te
dau tu
''';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));

      if (response.text != null && response.text!.isNotEmpty) {
        final keywords = response.text!
            .trim()
            .split('\n')
            .map((k) => k.trim().toLowerCase())
            .where((k) => k.isNotEmpty && k.length > 2)
            .take(10)
            .toList();

        if (keywords.isNotEmpty) {
          print('✅ AI Extracted Keywords: ${keywords.join(', ')}');
          return keywords;
        }
      }
    } catch (e) {
      print('❌ Lỗi Gemini extract keywords: $e');
    }

    return _fallbackExtractKeywords(titles, categories);
  }

  // ===== FALLBACK METHODS (rule-based) =====

  double _fallbackRelevanceScore(News news, UserPreference userPreference) {
    double score = 0.0;

    // Kiểm tra category (50%)
    if (userPreference.favoriteCategories.contains(news.category)) {
      score += 0.5;
    }

    // Kiểm tra keywords trong title hoặc content (50%)
    final titleLower = news.title.toLowerCase();
    final contentLower = news.content.toLowerCase();
    int keywordMatches = 0;

    for (final keyword in userPreference.keywords) {
      if (titleLower.contains(keyword.toLowerCase()) ||
          contentLower.contains(keyword.toLowerCase())) {
        keywordMatches++;
      }
    }

    if (userPreference.keywords.isNotEmpty) {
      score += 0.5 * (keywordMatches / userPreference.keywords.length);
    }

    return score.clamp(0.0, 1.0);
  }

  String _fallbackNotificationBody(News news) {
    final content = news.content;
    if (content.length <= 60) return content;

    // Lấy 60 ký tự đầu
    return '${content.substring(0, 57)}...';
  }

  List<String> _fallbackExtractKeywords(
      List<String> titles, List<String> categories) {
    // Rule-based: lấy từ xuất hiện nhiều trong titles
    final wordCount = <String, int>{};

    for (final title in titles) {
      final words = title.toLowerCase().split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length > 3) {
          // Bỏ stopwords
          wordCount[word] = (wordCount[word] ?? 0) + 1;
        }
      }
    }

    final sorted = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => e.key).toList();
  }

  String _truncateContent(String content, int wordLimit) {
    final words = content.split(RegExp(r'\s+'));
    if (words.length <= wordLimit) return content;
    return '${words.take(wordLimit).join(' ')}...';
  }
}
