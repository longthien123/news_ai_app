import '../repositories/user_behavior_repository.dart';
import '../entities/reading_session.dart';

/// UseCase: Track khi user đọc tin
class TrackReadingSessionUseCase {
  final UserBehaviorRepository repository;

  TrackReadingSessionUseCase(this.repository);

  Future<void> call(ReadingSession session) async {
    await repository.trackReadingSession(session);
  }
}
