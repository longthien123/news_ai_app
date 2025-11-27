import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkManager {
  static const String _bookmarkKeyPrefix = 'bookmarked_news_ids_';
  
  static BookmarkManager? _instance;
  late SharedPreferences _prefs;
  final FirebaseAuth _auth;
  
  BookmarkManager._({FirebaseAuth? auth}) 
      : _auth = auth ?? FirebaseAuth.instance;
  
  static Future<BookmarkManager> getInstance({FirebaseAuth? auth}) async {
    if (_instance == null) {
      _instance = BookmarkManager._(auth: auth);
      await _instance!._init();
    }
    return _instance!;
  }
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Get current user's bookmark key
  String? _getUserBookmarkKey() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return '$_bookmarkKeyPrefix$userId';
  }
  
  // Get all bookmarked news IDs for current user
  List<String> getBookmarkedNewsIds() {
    final key = _getUserBookmarkKey();
    if (key == null) return [];
    return _prefs.getStringList(key) ?? [];
  }
  
  // Check if a news is bookmarked by current user
  bool isBookmarked(String newsId) {
    final bookmarks = getBookmarkedNewsIds();
    return bookmarks.contains(newsId);
  }
  
  // Toggle bookmark status for current user
  Future<bool> toggleBookmark(String newsId) async {
    final key = _getUserBookmarkKey();
    if (key == null) return false; // User not logged in
    
    final bookmarks = getBookmarkedNewsIds();
    
    if (bookmarks.contains(newsId)) {
      bookmarks.remove(newsId);
      await _prefs.setStringList(key, bookmarks);
      return false; // Not bookmarked anymore
    } else {
      bookmarks.add(newsId);
      await _prefs.setStringList(key, bookmarks);
      return true; // Now bookmarked
    }
  }
  
  // Add bookmark for current user
  Future<void> addBookmark(String newsId) async {
    final key = _getUserBookmarkKey();
    if (key == null) return; // User not logged in
    
    final bookmarks = getBookmarkedNewsIds();
    if (!bookmarks.contains(newsId)) {
      bookmarks.add(newsId);
      await _prefs.setStringList(key, bookmarks);
    }
  }
  
  // Remove bookmark for current user
  Future<void> removeBookmark(String newsId) async {
    final key = _getUserBookmarkKey();
    if (key == null) return; // User not logged in
    
    final bookmarks = getBookmarkedNewsIds();
    if (bookmarks.contains(newsId)) {
      bookmarks.remove(newsId);
      await _prefs.setStringList(key, bookmarks);
    }
  }
  
  // Clear all bookmarks for current user
  Future<void> clearAllBookmarks() async {
    final key = _getUserBookmarkKey();
    if (key == null) return;
    await _prefs.remove(key);
  }
  
  // Clear all bookmarks for a specific user (useful when user logs out)
  Future<void> clearBookmarksForUser(String userId) async {
    final key = '$_bookmarkKeyPrefix$userId';
    await _prefs.remove(key);
  }
  
  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  
  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}
