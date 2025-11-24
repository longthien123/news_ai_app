import '../entities/user.dart';

abstract class UserRepository {
  Future<User> register(String email, String password, {String? name});
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<User?> getCachedUser();
  Future<void> updateProfile({String? name});
}