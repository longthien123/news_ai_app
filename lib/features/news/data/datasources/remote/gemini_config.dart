import 'package:flutter_dotenv/flutter_dotenv.dart';
class GeminiConfig {
  static final String apiKey = dotenv.env['GEMINI_API_KEY_LT'] ?? '';

  static const String modelName = 'gemini-2.5-flash';

  static const double temperature = 0.7;
  static const int maxOutputTokens = 500;
}
