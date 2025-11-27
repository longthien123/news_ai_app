import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/news_model.dart';

abstract class NewsRemoteSource {
  Future<List<NewsModel>> getAllNews();
  Future<List<NewsModel>> getBreakingNews();
  Future<List<NewsModel>> getNewsByCategory(String category);
  Future<NewsModel> getNewsById(String id);
  Future<void> updateNewsInteraction(String id, {int? views, int? likes});
}

class NewsRemoteSourceImpl implements NewsRemoteSource {
  final FirebaseFirestore firestore;

  NewsRemoteSourceImpl({required this.firestore});

  @override
  Future<List<NewsModel>> getAllNews() async {
    try {
      final querySnapshot = await firestore
          .collection('news')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  @override
  Future<List<NewsModel>> getBreakingNews() async {
    try {
      final querySnapshot = await firestore
          .collection('news')
          .orderBy('createdAt', descending: true)
          .limit(4)
          .get();

      return querySnapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch breaking news: $e');
    }
  }

  @override
  Future<List<NewsModel>> getNewsByCategory(String category) async {
    try {
      // Get all news first, then filter by category in memory
      final querySnapshot = await firestore
          .collection('news')
          .get();

      final filteredNews = querySnapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .where((news) => news.category == category)
          .toList();

      // Sort by createdAt descending
      filteredNews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filteredNews;
    } catch (e) {
      throw Exception('Failed to fetch news by category: $e');
    }
  }

  @override
  Future<NewsModel> getNewsById(String id) async {
    try {
      final docSnapshot = await firestore.collection('news').doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('News not found');
      }

      return NewsModel.fromFirestore(docSnapshot);
    } catch (e) {
      throw Exception('Failed to fetch news by id: $e');
    }
  }

  @override
  Future<void> updateNewsInteraction(String id, {int? views, int? likes}) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (views != null) {
        updates['views'] = FieldValue.increment(views);
      }
      
      if (likes != null) {
        updates['likes'] = FieldValue.increment(likes);
      }

      await firestore.collection('news').doc(id).update(updates);
    } catch (e) {
      throw Exception('Failed to update news interaction: $e');
    }
  }
}
