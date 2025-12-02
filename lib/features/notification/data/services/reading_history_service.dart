import 'package:cloud_firestore/cloud_firestore.dart';

/// Service để track reading history của user
class ReadingHistoryService {
  final FirebaseFirestore firestore;
  
  ReadingHistoryService({required this.firestore});
  
  /// Track khi user đọc một tin - sử dụng readingSessions có sẵn
  Future<void> trackNewsRead(String userId, String newsId) async {
    try {
      // Dùng readingSessions thay vì reading_history
      await firestore
          .collection('users')
          .doc(userId)
          .collection('readingSessions')
          .add({
        'newsId': newsId,
        'startTime': Timestamp.now(),
        'endTime': Timestamp.now(),
        'duration': 0, // Sẽ update sau
      });
      
      print('📖 Tracked reading: User $userId read news $newsId');
    } catch (e) {
      print('❌ Error tracking reading history: $e');
    }
  }
  
  /// Track thời gian đọc tin
  Future<void> trackReadingDuration(String userId, String newsId, Duration duration) async {
    try {
      final historySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('reading_history')
          .where('newsId', isEqualTo: newsId)
          .orderBy('readAt', descending: true)
          .limit(1)
          .get();
      
      if (historySnapshot.docs.isNotEmpty) {
        final docId = historySnapshot.docs.first.id;
        await firestore
            .collection('users')
            .doc(userId)
            .collection('reading_history')
            .doc(docId)
            .update({
          'readDuration': duration.inSeconds,
        });
        
        print('⏱️ Updated reading duration: ${duration.inSeconds}s');
      }
    } catch (e) {
      print('❌ Error updating reading duration: $e');
    }
  }
  
  /// Lấy reading history gần đây
  Future<List<Map<String, dynamic>>> getRecentReadingHistory(String userId, {int limit = 50}) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('reading_history')
          .orderBy('readAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Error getting reading history: $e');
      return [];
    }
  }
}

/// Global instance để sử dụng trong app
late ReadingHistoryService _globalReadingHistoryService;

/// Initialize reading history service
void initializeReadingHistoryService() {
  _globalReadingHistoryService = ReadingHistoryService(
    firestore: FirebaseFirestore.instance,
  );
}

/// Track khi user đọc tin - gọi từ news detail page
Future<void> trackUserReadNews(String userId, String newsId) async {
  try {
    await _globalReadingHistoryService.trackNewsRead(userId, newsId);
  } catch (e) {
    print('❌ Error in global track news read: $e');
  }
}

/// Track reading duration - gọi khi user thoát khỏi news detail
Future<void> trackUserReadingDuration(String userId, String newsId, Duration duration) async {
  try {
    await _globalReadingHistoryService.trackReadingDuration(userId, newsId, duration);
  } catch (e) {
    print('❌ Error in global track reading duration: $e');
  }
}