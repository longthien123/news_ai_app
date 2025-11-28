import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_preference_model.dart';
import '../models/reading_session_model.dart';

class UserBehaviorDataSource {
  final FirebaseFirestore firestore;

  UserBehaviorDataSource({required this.firestore});

  Future<void> saveReadingSession(ReadingSessionModel session) async {
    await firestore
        .collection('users')
        .doc(session.userId)
        .collection('readingSessions')
        .add(session.toJson());
  }

  Future<List<ReadingSessionModel>> getReadingSessions(
    String userId, {
    int limit = 100,
  }) async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('readingSessions')
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ReadingSessionModel.fromJson(doc.data()))
        .toList();
  }

  Future<UserPreferenceModel?> getUserPreference(String userId) async {
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('userPreference')
        .get();

    if (!doc.exists) return null;
    return UserPreferenceModel.fromJson(doc.data()!);
  }

  Future<void> saveUserPreference(UserPreferenceModel preference) async {
    await firestore
        .collection('users')
        .doc(preference.userId)
        .collection('preferences')
        .doc('userPreference')
        .set(preference.toJson());
  }
}
