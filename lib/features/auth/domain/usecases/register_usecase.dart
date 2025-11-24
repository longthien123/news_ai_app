import '../entities/user.dart';
import '../repositories/user_repository.dart';

class RegisterUsecase {
  final UserRepository repository;

  RegisterUsecase(this.repository);

  Future<User> call(String email, String password, {String? name}) async {
    return await repository.register(email, password, name: name);
  }
}