import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../models/user_model.dart';

abstract class UserRemoteSource {
  Future<UserModel> registerWithEmail(String email, String password, {String? displayName});
  Future<UserModel> loginWithEmail(String email, String password);
  Future<void> signOut();
  UserModel? getCurrentUser();
  Future<void> updateDisplayName(String name);
}

class UserRemoteSourceImpl implements UserRemoteSource {
  final fb.FirebaseAuth _auth;

  UserRemoteSourceImpl({fb.FirebaseAuth? firebaseAuth}) 
      : _auth = firebaseAuth ?? fb.FirebaseAuth.instance;

  @override
  Future<UserModel> registerWithEmail(String email, String password, {String? displayName}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      final user = cred.user;
      if (user == null) throw Exception('Đăng ký thất bại: user null');
      
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }
      
      return UserModel.fromFirebaseUser(_auth.currentUser!);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      final user = cred.user;
      if (user == null) throw Exception('Đăng nhập thất bại: user null');
      
      return UserModel.fromFirebaseUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  UserModel? getCurrentUser() {
    final u = _auth.currentUser;
    if (u == null) return null;
    return UserModel.fromFirebaseUser(u);
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Không có user đăng nhập');
    await user.updateDisplayName(name);
    await user.reload();
  }

  Exception _handleAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('Email đã được sử dụng');
      case 'invalid-email':
        return Exception('Email không hợp lệ');
      case 'weak-password':
        return Exception('Mật khẩu quá yếu');
      case 'user-not-found':
        return Exception('Không tìm thấy người dùng');
      case 'wrong-password':
        return Exception('Mật khẩu sai');
      default:
        return Exception(e.message ?? 'Lỗi xác thực');
    }
  }
}