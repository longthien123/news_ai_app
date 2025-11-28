import '../repositories/user_behavior_repository.dart';
import '../entities/user_preference.dart';

/// UseCase: Phân tích behavior user và cập nhật preferences
class AnalyzeUserBehaviorUseCase {
  final UserBehaviorRepository repository;

  AnalyzeUserBehaviorUseCase(this.repository);

  Future<UserPreference> call(String userId) async {
    return await repository.analyzeAndUpdatePreferences(userId);
  }
}
