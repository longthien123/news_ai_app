import '../repositories/user_repository.dart';

class UpdateProfileUsecase {
  final UserRepository repository;

  UpdateProfileUsecase(this.repository);

  Future<void> call({String? name}) async {
    return await repository.updateProfile(name: name);
  }
}