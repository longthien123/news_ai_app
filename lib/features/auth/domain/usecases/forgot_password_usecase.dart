import '../repositories/user_repository.dart';

class ForgotPasswordUsecase {
  final UserRepository repository;

  ForgotPasswordUsecase(this.repository);

  Future<void> call(String email) async {
    if (email.isEmpty) {
      throw Exception('Vui lòng nhập email');
    }
    if (!email.contains('@')) {
      throw Exception('Email không hợp lệ');
    }
    await repository.resetPassword(email);
  }
}
