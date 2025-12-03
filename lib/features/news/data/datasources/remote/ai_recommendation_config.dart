/// ⭐ Configuration riêng CHỈ cho AI Recommendation
/// Tách biệt hoàn toàn với GeminiConfig để tránh conflict
class AIRecommendationConfig {
  // API key riêng dành cho AI Recommendation
  // static const String apiKey = 'AIzaSyBYKvMaEbPe6uc_S2VPFZou7OEJBgxcGQo';
  static const String apiKey = 'AIzaSyBhQbxCHwnt1wr2sbxzUVHDcLE7zQNyE9M';


  // Model name riêng cho AI Recommendation
  static const String modelName = 'gemini-2.0-flash';

  // Configuration cho recommendation
  static const double temperature = 0.3; // Tăng tính nhất quán
  static const double topP = 0.85; // Giảm độ ngẫu nhiên
  static const int topK = 20; // Chỉ chọn trong top 20 tokens tốt nhất
  static const int maxOutputTokens = 200; // Đủ để trả về 8 IDs
}
