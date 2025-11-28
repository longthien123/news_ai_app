import '../../domain/entities/user_preference.dart';

class UserPreferenceModel extends UserPreference {
  const UserPreferenceModel({
    required super.userId,
    super.favoriteCategories,
    super.keywords,
    super.activeHours,
    super.dailyNotificationLimit,
    super.enableSmartNotifications,
    super.lastAnalyzedAt,
  });

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) {
    return UserPreferenceModel(
      userId: json['userId'] as String,
      favoriteCategories: (json['favoriteCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      activeHours: (json['activeHours'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v as int),
          ) ??
          {},
      dailyNotificationLimit: json['dailyNotificationLimit'] as int? ?? 5,
      enableSmartNotifications: json['enableSmartNotifications'] as bool? ?? true,
      lastAnalyzedAt: json['lastAnalyzedAt'] != null
          ? DateTime.parse(json['lastAnalyzedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'favoriteCategories': favoriteCategories,
      'keywords': keywords,
      'activeHours': activeHours.map((k, v) => MapEntry(k.toString(), v)),
      'dailyNotificationLimit': dailyNotificationLimit,
      'enableSmartNotifications': enableSmartNotifications,
      'lastAnalyzedAt': lastAnalyzedAt?.toIso8601String(),
    };
  }

  factory UserPreferenceModel.fromEntity(UserPreference entity) {
    return UserPreferenceModel(
      userId: entity.userId,
      favoriteCategories: entity.favoriteCategories,
      keywords: entity.keywords,
      activeHours: entity.activeHours,
      dailyNotificationLimit: entity.dailyNotificationLimit,
      enableSmartNotifications: entity.enableSmartNotifications,
      lastAnalyzedAt: entity.lastAnalyzedAt,
    );
  }
}
