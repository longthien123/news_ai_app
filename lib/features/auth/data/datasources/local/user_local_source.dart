import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

abstract class UserLocalSource {
  Future<void> cacheUser(Map<String, dynamic> userMap);
  Future<Map<String, dynamic>?> getCachedUser();
  Future<void> clearUser();
}

class UserLocalSourceImpl implements UserLocalSource {
  static const String _userKey = 'cached_user';
  final SharedPreferences prefs;

  UserLocalSourceImpl({required this.prefs});

  @override
  Future<void> cacheUser(Map<String, dynamic> userMap) async {
    await prefs.setString(_userKey, jsonEncode(userMap));
  }

  @override
  Future<Map<String, dynamic>?> getCachedUser() async {
    final json = prefs.getString(_userKey);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  @override
  Future<void> clearUser() async {
    await prefs.remove(_userKey);
  }
}