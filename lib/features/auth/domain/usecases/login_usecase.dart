import '../entities/user.dart';
import '../repositories/user_repository.dart';

class LoginUsecase {
  final UserRepository repository;

  LoginUsecase(this.repository);

  Future<User> call(String email, String password) async {
    return await repository.login(email, password);
  }
}