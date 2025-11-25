import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/remote/user_remote_source.dart';
import '../datasources/local/user_local_source.dart';
import '../models/user_model.dart';

class UserRepoImpl implements UserRepository {
  final UserRemoteSource remote;
  final UserLocalSource local;

  UserRepoImpl({required this.remote, required this.local});

  @override
  Future<User> register(String email, String password, {String? name}) async {
    final model = await remote.registerWithEmail(
      email, 
      password, 
      displayName: name,
    );
    await local.cacheUser(model.toMap());
    return model;
  }

  @override
  Future<User> login(String email, String password) async {
    final model = await remote.loginWithEmail(email, password);
    await local.cacheUser(model.toMap());
    return model;
  }

  @override
  Future<User> signInWithGoogle() async {
    final model = await remote.signInWithGoogle();
    await local.cacheUser(model.toMap());
    return model;
  }

  @override
  Future<void> logout() async {
    await remote.signOut();
    await local.clearUser();
  }

  @override
  Future<User?> getCachedUser() async {
    final map = await local.getCachedUser();
    if (map == null) return null;
    return UserModel.fromMap(map);
  }

  @override
  Future<void> updateProfile({String? name}) async {
    if (name != null) {
      await remote.updateDisplayName(name);
      final user = remote.getCurrentUser();
      if (user != null) {
        await local.cacheUser(user.toMap());
      }
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    await remote.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    return await remote.isEmailVerified();
  }

  @override
  Future<void> reloadUser() async {
    await remote.reloadUser();
  }

  @override
  Future<void> resetPassword(String email) async {
    await remote.resetPassword(email);
  }
}