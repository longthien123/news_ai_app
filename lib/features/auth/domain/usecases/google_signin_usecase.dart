import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GoogleSignInUsecase {
  final UserRepository repository;

  GoogleSignInUsecase(this.repository);

  Future<User> call() async {
    return await repository.signInWithGoogle();
  }
}
