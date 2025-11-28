import 'package:equatable/equatable.dart';

/// Entity lưu sở thích người dùng để AI phân tích
class UserPreference extends Equatable {
  final String userId;
  final List<String> favoriteCategories; // Categories đọc nhiều nhất
  final List<String> keywords; // Keywords quan tâm (từ tin đã đọc/bookmark)
  final Map<int, int> activeHours; // {hour: readCount} - giờ thường mở app
  final int dailyNotificationLimit; // Giới hạn số thông báo/ngày (default: 5)
  final bool enableSmartNotifications; // Bật/tắt AI notifications
  final DateTime? lastAnalyzedAt; // Lần cuối phân tích behavior
  
  const UserPreference({
    required this.userId,
    this.favoriteCategories = const [],
    this.keywords = const [],
    this.activeHours = const {},
    this.dailyNotificationLimit = 5,
    this.enableSmartNotifications = true,
    this.lastAnalyzedAt,
  });
  
  @override
  List<Object?> get props => [
    userId,
    favoriteCategories,
    keywords,
    activeHours,
    dailyNotificationLimit,
    enableSmartNotifications,
    lastAnalyzedAt,
  ];
  
  /// Lấy giờ vàng (top 3 giờ user hay mở app)
  List<int> getGoldenHours() {
    if (activeHours.isEmpty) return [8, 12, 20]; // Default golden hours
    
    final sortedHours = activeHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHours.take(3).map((e) => e.key).toList();
  }
  
  UserPreference copyWith({
    String? userId,
    List<String>? favoriteCategories,
    List<String>? keywords,
    Map<int, int>? activeHours,
    int? dailyNotificationLimit,
    bool? enableSmartNotifications,
    DateTime? lastAnalyzedAt,
  }) {
    return UserPreference(
      userId: userId ?? this.userId,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      keywords: keywords ?? this.keywords,
      activeHours: activeHours ?? this.activeHours,
      dailyNotificationLimit: dailyNotificationLimit ?? this.dailyNotificationLimit,
      enableSmartNotifications: enableSmartNotifications ?? this.enableSmartNotifications,
      lastAnalyzedAt: lastAnalyzedAt ?? this.lastAnalyzedAt,
    );
  }
}
