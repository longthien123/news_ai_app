import 'package:image_picker/image_picker.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String userId);
  Future<void> updateProfile(UserProfile profile);
  Future<String> uploadAvatar(String userId, XFile imageFile);
}
