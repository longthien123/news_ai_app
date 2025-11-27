import 'package:google_generative_ai/google_generative_ai.dart';
import 'gemini_config.dart';

abstract class AISummaryService {
  Future<String> summarizeNews(String title, String content);
}

class AISummaryServiceImpl implements AISummaryService {
  GenerativeModel _getModel() {
    return GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.apiKey,
    );
  }

  @override
  Future<String> summarizeNews(String title, String content) async {
    if (GeminiConfig.apiKey == 'YOUR_GEMINI_API_KEY') {
      print('⚠️ AI Summary: Dùng fallback (chưa có API key)');
      return _fallbackSummary(title, content);
    }

    // Thử gọi Gemini với retry mechanism
    return await _callGeminiWithRetry(title, content);
  }

  Future<String> _callGeminiWithRetry(
    String title,
    String content, {
    int maxRetries = 2,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print(
          '🤖 AI Summary: Đang gọi Gemini API (lần $attempt/$maxRetries)...',
        );

        final model = _getModel();
        final prompt =
            '''
Hãy tóm tắt bài viết tin tức sau đây một cách ngắn gọn, súc tích và chuyên nghiệp:

Tiêu đề: $title

Nội dung: $content

Yêu cầu tóm tắt:
- Tóm tắt trong 3-5 câu
- Nêu những điểm chính, quan trọng nhất
- Sử dụng tiếng Việt
- Văn phong rõ ràng, dễ hiểu
- Không thêm thông tin không có trong bài gốc
''';

        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 15));

        if (response.text != null && response.text!.isNotEmpty) {
          print('✅ AI Summary: Gemini thành công!');
          return response.text!.trim();
        }

        print('⚠️ AI Summary: Gemini trả về rỗng');
      } catch (e) {
        final errorMsg = e.toString();
        print('❌ AI Summary: Lỗi lần $attempt: $errorMsg');

        // Nếu là lỗi 503 (overload) và còn lượt retry, đợi rồi thử lại
        if (errorMsg.contains('503') && attempt < maxRetries) {
          print('⏳ Đợi 2 giây trước khi thử lại...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        // Nếu hết lượt retry hoặc lỗi khác, break
        if (attempt == maxRetries) {
          print('💡 Dùng phương pháp tóm tắt dự phòng');
          break;
        }
      }
    }

    // Fallback nếu tất cả các lần thử đều thất bại
    return _fallbackSummary(title, content);
  }

  String _fallbackSummary(String title, String content) {
    final sentences = content.split(RegExp(r'[.!?]\s+'));
    final summary = sentences
        .where((s) => s.trim().isNotEmpty)
        .take(3)
        .join('. ');

    if (summary.isEmpty) {
      return 'Nội dung bài viết: $title. Đây là một bản tin quan trọng cần được theo dõi.';
    }

    return '$summary.';
  }
}
