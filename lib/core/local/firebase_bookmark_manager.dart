import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseBookmarkManager {
  static FirebaseBookmarkManager? _instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  FirebaseBookmarkManager._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  
  static FirebaseBookmarkManager getInstance({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    _instance ??= FirebaseBookmarkManager._(
      firestore: firestore,
      auth: auth,
    );
    return _instance!;
  }
  
  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  
  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
  
  // Get user's bookmarks collection reference
  CollectionReference? _getUserBookmarksCollection() {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('bookmarks');
  }
  
  // Check if a news is bookmarked
  Future<bool> isBookmarked(String newsId) async {
    try {
      final collection = _getUserBookmarksCollection();
      if (collection == null) return false;
      
      final doc = await collection.doc(newsId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
  
  // Toggle bookmark status
  Future<bool> toggleBookmark(String newsId) async {
    try {
      final collection = _getUserBookmarksCollection();
      if (collection == null) return false;
      
      final doc = await collection.doc(newsId).get();
      
      if (doc.exists) {
        // Remove bookmark
        await collection.doc(newsId).delete();
        return false;
      } else {
        // Add bookmark
        await collection.doc(newsId).set({
          'newsId': newsId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      throw Exception('Lỗi khi toggle bookmark: $e');
    }
  }
  
  // Add bookmark
  Future<void> addBookmark(String newsId) async {
    try {
      final collection = _getUserBookmarksCollection();
      if (collection == null) return;
      
      await collection.doc(newsId).set({
        'newsId': newsId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Lỗi khi thêm bookmark: $e');
    }
  }
  
  // Remove bookmark
  Future<void> removeBookmark(String newsId) async {
    try {
      final collection = _getUserBookmarksCollection();
      if (collection == null) return;
      
      await collection.doc(newsId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa bookmark: $e');
    }
  }
  
  // Get all bookmarked news IDs
  Future<List<String>> getBookmarkedNewsIds() async {
    try {
      final collection = _getUserBookmarksCollection();
      if (collection == null) return [];
      
      final snapshot = await collection.get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get bookmarks as stream (real-time updates)
  Stream<List<String>>? getBookmarksStream() {
    final collection = _getUserBookmarksCollection();
    if (collection == null) return null;
    
    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }
  
  // Clear all bookmarks for current user
  Future<void> clearAllBookmarks() async {
    try {
      final collection = _getUserBookmarksCollection();
      if (collection == null) return;
      
      final snapshot = await collection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Lỗi khi xóa tất cả bookmark: $e');
    }
  }
}
