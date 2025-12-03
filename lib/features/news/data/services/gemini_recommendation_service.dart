import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../datasources/remote/ai_recommendation_config.dart'; // ⭐ Import config RIÊNG
import '../datasources/remote/news_remote_source.dart';
import '../datasources/user_interaction_datasource.dart';
import '../models/news_model.dart';

class GeminiRecommendationService {
  final NewsRemoteSource _newsSource;
  final UserInteractionDataSource _interactionSource;

  GeminiRecommendationService({
    required NewsRemoteSource newsSource,
    required UserInteractionDataSource interactionSource,
  })  : _newsSource = newsSource,
        _interactionSource = interactionSource;

  GenerativeModel _getModel() {
    // ⭐ Sử dụng AIRecommendationConfig RIÊNG - không động vào GeminiConfig cũ
    return GenerativeModel(
      model: AIRecommendationConfig.modelName,
      apiKey: AIRecommendationConfig.apiKey,
      generationConfig: GenerationConfig(
        temperature: AIRecommendationConfig.temperature,
        topP: AIRecommendationConfig.topP,
        topK: AIRecommendationConfig.topK,
        maxOutputTokens: AIRecommendationConfig.maxOutputTokens,
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<List<NewsModel>> getRecommendations(String userId) async {
    List<dynamic> interactions = []; // Khai báo ở ngoài try để dùng trong catch
    
    try {
      print('🤖 Gemini Rec: Bắt đầu lấy gợi ý cho User $userId');

      // 1. Lấy lịch sử tương tác của User
      interactions = await _interactionSource.getUserInteractions(userId);
      
      // Nếu user mới chưa có lịch sử, trả về tin mới nhất (Breaking News)
      if (interactions.isEmpty) {
        print('⚠️ User mới (Cold Start) -> Trả về Breaking News');
        return await _newsSource.getBreakingNews();
      }

      // 2. Phân tích sở thích (User Profile)
      final categoryCounts = <String, int>{};
      final viewedNewsIds = <String>{};
      final readArticles = <Map<String, String>>[]; // ⭐ MỚI: Lưu nội dung bài đã đọc

      for (var interaction in interactions) {
        viewedNewsIds.add(interaction.newsId);
        
        try {
          final news = await _newsSource.getNewsById(interaction.newsId);
          categoryCounts[news.category] = (categoryCounts[news.category] ?? 0) + 1;
          
          // ⭐ Chỉ lưu 3 bài gần nhất (giảm từ 5 → 3 để tiết kiệm tokens)
          if (readArticles.length < 3) {
            readArticles.add({
              'title': news.title,
              'category': news.category,
              'summary': news.content.length > 150 ? news.content.substring(0, 150) : news.content,
            });
          }
        } catch (e) {
          continue;
        }
      }

      // Sắp xếp category theo số lần xem giảm dần
      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topCategories = sortedCategories.take(3).map((e) => e.key).toList();
      print('👤 User Profile: Thích $topCategories');
      print('📖 Đã đọc ${readArticles.length} bài gần nhất');

      // 3. Lấy danh sách tin ứng viên (Candidate Pool)
      final allNews = await _newsSource.getAllNews();
      
      // Lọc THÔNG MINH: Chỉ lấy tin thuộc TOP 3 chủ đề yêu thích
      final candidates = allNews
          .where((news) => 
              !viewedNewsIds.contains(news.id) &&
              topCategories.contains(news.category) // Chỉ lấy tin đúng sở thích
          )
          .take(12) // Giảm từ 20 → 12 tin để tiết kiệm tokens (vẫn đủ AI chọn 8)
          .toList();
      
      // Fallback: Nếu không đủ tin theo sở thích, lấy thêm tin khác
      if (candidates.length < 15) {
        final extraCandidates = allNews
            .where((news) => 
                !viewedNewsIds.contains(news.id) &&
                !topCategories.contains(news.category)
            )
            .take(15 - candidates.length)
            .toList();
        candidates.addAll(extraCandidates);
      }

      if (candidates.isEmpty) {
        return [];
      }

      // 4. Tạo Prompt gửi Gemini (kèm nội dung bài đã đọc)
      final prompt = _buildPrompt(topCategories, candidates, readArticles);

      // 5. Gọi Gemini API
      final model = _getModel();
      final response = await model.generateContent([Content.text(prompt)]);
      
      print('📦 Gemini Response: ${response.text}');

      // 6. Parse kết quả
      if (response.text == null) return [];

      final List<dynamic> recommendedIds = jsonDecode(response.text!);
      
      // Map ID sang NewsModel
      final recommendations = candidates
          .where((news) => recommendedIds.contains(news.id))
          .toList();

      return recommendations;

    } catch (e) {
      print('❌ Lỗi Gemini Recommendation: $e');
      print('🔄 Fallback: Trả về tin Breaking News + theo sở thích');
      
      try {
        // Fallback thông minh: Kết hợp Breaking News + tin theo sở thích
        final breakingNews = await _newsSource.getBreakingNews();
        
        // Nếu có lịch sử, thêm tin theo category yêu thích
        if (interactions.isNotEmpty) {
          final categoryCounts = <String, int>{};
          for (var interaction in interactions) {
            try {
              final news = await _newsSource.getNewsById(interaction.newsId);
              categoryCounts[news.category] = (categoryCounts[news.category] ?? 0) + 1;
            } catch (_) {}
          }
          
          if (categoryCounts.isNotEmpty) {
            final topCategory = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
            final categoryNews = await _newsSource.getNewsByCategory(topCategory);
            
            // Kết hợp: 50% Breaking + 50% Category
            final combined = [...breakingNews.take(4), ...categoryNews.take(4)];
            return combined;
          }
        }
        
        return breakingNews;
      } catch (fallbackError) {
        print('❌ Fallback cũng lỗi: $fallbackError');
        return []; // Trả về empty list nếu mọi thứ đều lỗi
      }
    }
  }

  String _buildPrompt(List<String> interests, List<NewsModel> candidates, List<Map<String, String>> readArticles) {
    // Rút gọn thông tin tin tức - lấy 150 từ đầu tiên
    final candidatesJson = candidates.map((n) => {
      'id': n.id,
      'title': n.title,
      'category': n.category,
      'content': _extractWords(n.content, 150), // Lấy 150 từ đầu
    }).toList();

    // ⭐ Thêm context về các bài đã đọc - lấy 150 từ đầu
    String readContext = '';
    if (readArticles.isNotEmpty) {
      readContext = '\nRECENTLY READ ARTICLES:\n';
      for (var i = 0; i < readArticles.length; i++) {
        final content = readArticles[i]['summary'] ?? '';
        readContext += '${i + 1}. "${readArticles[i]['title']}" (${readArticles[i]['category']})\n   ${_extractWords(content, 150)}\n';
      }
    }

    return '''
You are a smart news recommender. Analyze user's reading history deeply.

USER PREFERENCES:
- Favorite categories: ${interests.join(', ')}$readContext
NEWS POOL:
${jsonEncode(candidatesJson)}

TASK:
Select 8 news IDs that match user's SPECIFIC interests (not just categories).

RULES:
1. DEEP MATCHING (70%): Analyze content similarity with read articles. 
   Example: If user read "Ronaldo scores", recommend other Ronaldo/Messi news, NOT random sports like "Vietnam vs Thailand".
2. CATEGORY FILTER (20%): Prioritize favorite categories.
3. DIVERSITY (10%): Include 1-2 trending articles from different topics.

STRICT:
- DO NOT recommend articles with completely different topics even if same category.
- Example: User likes "Kpop" → DO NOT suggest "Korean Drama" (both Entertainment but different).

Return ONLY JSON array: ["id1","id2","id3","id4","id5","id6","id7","id8"]
''';
  }

  // ⭐ Helper: Lấy N từ đầu tiên từ văn bản
  String _extractWords(String text, int wordCount) {
    if (text.isEmpty) return '';
    
    final words = text.split(' ');
    if (words.length <= wordCount) return text;
    
    return words.take(wordCount).join(' ') + '...';
  }
}
