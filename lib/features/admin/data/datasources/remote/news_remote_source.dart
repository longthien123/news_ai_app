import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/news_model.dart';

abstract class NewsRemoteSource {
  Future<NewsModel> addNews(NewsModel news);
  Future<NewsModel> getNewsById(String id);
  Future<List<NewsModel>> getAllNews();
  Future<List<NewsModel>> getNewsByCategory(String category);
  Future<void> updateNews(String id, Map<String, dynamic> updates);
  Future<void> deleteNews(String id);
  Future<void> incrementViews(String id);
}

class NewsRemoteSourceImpl implements NewsRemoteSource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'news';

  NewsRemoteSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<NewsModel> addNews(NewsModel news) async {
    try {
      final docRef = await _firestore.collection(_collection).add(news.toMap());
      final doc = await docRef.get();
      return NewsModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Thêm tin tức thất bại: $e');
    }
  }

  @override
  Future<NewsModel> getNewsById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('Không tìm thấy tin tức');
      }
      return NewsModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Lấy tin tức thất bại: $e');
    }
  }

  @override
  Future<List<NewsModel>> getAllNews() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lấy danh sách tin tức thất bại: $e');
    }
  }

  @override
  Future<List<NewsModel>> getNewsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lấy tin tức theo danh mục thất bại: $e');
    }
  }

  @override
  Future<void> updateNews(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(id).update(updates);
    } catch (e) {
      throw Exception('Cập nhật tin tức thất bại: $e');
    }
  }

  @override
  Future<void> deleteNews(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Xóa tin tức thất bại: $e');
    }
  }

  @override
  Future<void> incrementViews(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      // Không throw exception để không ảnh hưởng UX
      print('Tăng lượt xem thất bại: $e');
    }
  }
}
