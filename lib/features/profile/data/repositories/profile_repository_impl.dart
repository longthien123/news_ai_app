import 'package:image_picker/image_picker.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfile> getProfile(String userId) async {
    return await remoteDataSource.getProfile(userId);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final model = UserProfileModel.fromEntity(profile);
    await remoteDataSource.updateProfile(model);
  }

  @override
  Future<String> uploadAvatar(String userId, XFile imageFile) async {
    return await remoteDataSource.uploadAvatar(userId, imageFile);
  }
}
