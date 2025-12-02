import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/news.dart';
import '../../data/datasources/user_interaction_datasource.dart';
import '../../data/models/user_interaction_model.dart';

class ReadingTrackerService {
  static final ReadingTrackerService _instance = ReadingTrackerService._internal();

  factory ReadingTrackerService() {
    return _instance;
  }

  ReadingTrackerService._internal();

  final _interactionDataSource = UserInteractionDataSourceImpl();

  Future<void> trackNewsReading({
    required News news,
    required int readDurationSeconds,
    List<String>? keywords,
  }) async {
    try {
      print('📱 [ReadingTracker] trackNewsReading called! duration=$readDurationSeconds');
      final user = FirebaseAuth.instance.currentUser;
      print('📱 [ReadingTracker] User: ${user?.uid}');
      
      if (user == null) {
        print('❌ [ReadingTracker] User is null!');
        return;
      }

      // Chỉ lưu nếu đọc trên 5 giây
      if (readDurationSeconds < 5) {
        print('⚠️ [ReadingTracker] Duration too short (<5s), ignoring.');
        return;
      }

      print('📱 [ReadingTracker] Saving interaction to Firestore...');
      
      final interaction = UserInteractionModel(
        userId: user.uid,
        newsId: news.id,
        eventType: 'view',
        durationSeconds: readDurationSeconds,
        timestamp: DateTime.now(),
      );

      await _interactionDataSource.saveInteraction(interaction);
      print('✅ [ReadingTracker] Tracking completed!');
    } catch (e) {
      print('❌ [ReadingTracker] Error: $e');
    }
  }
}
