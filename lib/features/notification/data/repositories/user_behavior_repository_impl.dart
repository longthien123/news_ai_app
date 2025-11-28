import '../../domain/entities/user_preference.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/repositories/user_behavior_repository.dart';
import '../datasources/user_behavior_datasource.dart';
import '../models/user_preference_model.dart';
import '../models/reading_session_model.dart';
import '../services/gemini_recommendation_service.dart';

class UserBehaviorRepositoryImpl implements UserBehaviorRepository {
  final UserBehaviorDataSource dataSource;
  final GeminiRecommendationService aiService;

  UserBehaviorRepositoryImpl({
    required this.dataSource,
    required this.aiService,
  });

  @override
  Future<void> trackReadingSession(ReadingSession session) async {
    final model = ReadingSessionModel.fromEntity(session);
    await dataSource.saveReadingSession(model);
  }

  @override
  Future<List<ReadingSession>> getReadingHistory(String userId, {int limit = 100}) async {
    return await dataSource.getReadingSessions(userId, limit: limit);
  }

  @override
  Future<UserPreference?> getUserPreference(String userId) async {
    return await dataSource.getUserPreference(userId);
  }

  @override
  Future<void> updateUserPreference(UserPreference preference) async {
    final model = UserPreferenceModel.fromEntity(preference);
    await dataSource.saveUserPreference(model);
  }

  @override
  Future<UserPreference> analyzeAndUpdatePreferences(String userId) async {
    // Lấy lịch sử đọc tin gần đây
    final sessions = await getReadingHistory(userId, limit: 100);

    if (sessions.isEmpty) {
      // Chưa có data → tạo preference mặc định
      final defaultPreference = UserPreference(
        userId: userId,
        lastAnalyzedAt: DateTime.now(),
      );
      await updateUserPreference(defaultPreference);
      return defaultPreference;
    }

    // Phân tích categories yêu thích (top 5)
    final categoryCount = <String, int>{};
    for (final session in sessions) {
      categoryCount[session.category] = (categoryCount[session.category] ?? 0) + 1;
    }
    final favoriteCategories = (categoryCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => e.key)
        .toList();

    // Phân tích giờ vàng
    final hourCount = <int, int>{};
    for (final session in sessions) {
      final hour = session.startedAt.hour;
      hourCount[hour] = (hourCount[hour] ?? 0) + 1;
    }

    // Trích xuất keywords bằng AI
    final titles = sessions.map((s) => s.title).toList();
    final categories = sessions.map((s) => s.category).toList();
    final keywords = await aiService.extractKeywordsFromReadingHistory(
      titles: titles,
      categories: categories,
    );

    // Lấy preference cũ (nếu có) để giữ settings
    final oldPreference = await getUserPreference(userId);

    final newPreference = UserPreference(
      userId: userId,
      favoriteCategories: favoriteCategories,
      keywords: keywords,
      activeHours: hourCount,
      dailyNotificationLimit: oldPreference?.dailyNotificationLimit ?? 5,
      enableSmartNotifications: oldPreference?.enableSmartNotifications ?? true,
      lastAnalyzedAt: DateTime.now(),
    );

    await updateUserPreference(newPreference);
    return newPreference;
  }

  @override
  Future<List<String>> getFavoriteCategories(String userId) async {
    final preference = await getUserPreference(userId);
    return preference?.favoriteCategories ?? [];
  }

  @override
  Future<List<String>> extractKeywords(String userId) async {
    final preference = await getUserPreference(userId);
    return preference?.keywords ?? [];
  }

  @override
  Future<List<int>> getActiveHours(String userId) async {
    final preference = await getUserPreference(userId);
    return preference?.getGoldenHours() ?? [8, 12, 20];
  }
}
