import '../entities/user_preference.dart';
import '../entities/reading_session.dart';

/// Repository quản lý hành vi đọc tin của user
abstract class UserBehaviorRepository {
  /// Lưu phiên đọc tin
  Future<void> trackReadingSession(ReadingSession session);
  
  /// Lấy lịch sử đọc tin của user
  Future<List<ReadingSession>> getReadingHistory(String userId, {int limit = 100});
  
  /// Lấy preferences của user
  Future<UserPreference?> getUserPreference(String userId);
  
  /// Cập nhật preferences
  Future<void> updateUserPreference(UserPreference preference);
  
  /// Phân tích behavior và cập nhật preferences tự động
  Future<UserPreference> analyzeAndUpdatePreferences(String userId);
  
  /// Lấy categories user quan tâm nhất
  Future<List<String>> getFavoriteCategories(String userId);
  
  /// Lấy keywords từ tin đã đọc
  Future<List<String>> extractKeywords(String userId);
  
  /// Lấy giờ vàng (user thường mở app)
  Future<List<int>> getActiveHours(String userId);
}
