import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_interaction_model.dart';

abstract class UserInteractionDataSource {
  Future<void> saveInteraction(UserInteractionModel interaction);
  Future<List<UserInteractionModel>> getUserInteractions(String userId);
  Future<void> syncToVertex(String userId); // Gửi dữ liệu lên Vertex
}

class UserInteractionDataSourceImpl implements UserInteractionDataSource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'user_interactions';

  UserInteractionDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveInteraction(UserInteractionModel interaction) async {
    try {
      print('💾 [DataSource] Saving interaction: userId=${interaction.userId}, newsId=${interaction.newsId}');
      final data = interaction.toFirestore();
      print('💾 [DataSource] Data to save: $data');
      
      final result = await _firestore.collection(_collection).add(data);
      print('✅ [DataSource] Saved successfully! Doc ID: ${result.id}');
    } catch (e) {
      print('❌ [DataSource] Error saving: $e');
      throw Exception('Lưu interaction thất bại: $e');
    }
  }

  @override
  Future<List<UserInteractionModel>> getUserInteractions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => UserInteractionModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lấy interactions thất bại: $e');
    }
  }

  @override
  Future<void> syncToVertex(String userId) async {
    try {
      // TODO: Gọi Vertex API để gửi dữ liệu
      // Sẽ implement trong vertex_recommendation_service.dart
      await getUserInteractions(userId);
    } catch (e) {
      throw Exception('Sync to Vertex thất bại: $e');
    }
  }
}
