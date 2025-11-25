import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';

abstract class UserRemoteSource {
  Future<UserModel> registerWithEmail(String email, String password, {String? displayName});
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  UserModel? getCurrentUser();
  Future<void> updateDisplayName(String name);
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Future<void> reloadUser();
  Future<void> resetPassword(String email);
}

class UserRemoteSourceImpl implements UserRemoteSource {
  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  UserRemoteSourceImpl({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

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
      }
      
      // Gửi email xác thực ngay sau khi đăng ký
      await user.sendEmailVerification();
      await user.reload();
      
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
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Đăng nhập Google bị hủy');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      
      if (user == null) throw Exception('Đăng nhập thất bại: user null');
      
      return UserModel.fromFirebaseUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Lỗi đăng nhập Google: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
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

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Không có user đăng nhập');
    if (user.emailVerified) throw Exception('Email đã được xác thực');
    
    try {
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception('Quá nhiều yêu cầu. Vui lòng thử lại sau');
      }
      throw _handleAuthException(e);
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload(); // Lấy trạng thái mới nhất từ Firebase
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Không có user đăng nhập');
    await user.reload();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
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