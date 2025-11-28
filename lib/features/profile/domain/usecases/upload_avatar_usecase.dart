import 'package:image_picker/image_picker.dart';
import '../repositories/profile_repository.dart';

class UploadAvatarUseCase {
  final ProfileRepository repository;

  UploadAvatarUseCase(this.repository);

  Future<String> call(String userId, XFile imageFile) {
    return repository.uploadAvatar(userId, imageFile);
  }
}
