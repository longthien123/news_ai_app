import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile(String userId);
  Future<void> updateProfile(UserProfileModel profile);
  Future<String> uploadAvatar(String userId, XFile imageFile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final CloudinaryService cloudinaryService;

  ProfileRemoteDataSourceImpl({
    required this.firestore,
    CloudinaryService? cloudinaryService,
  }) : cloudinaryService = cloudinaryService ??
            CloudinaryService(
              cloudName: 'dcr56rtwl',
              uploadPreset: 'news_upload',
            );

  @override
  Future<UserProfileModel> getProfile(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfileModel.fromFirestore(doc);
      } else {
        // If profile doesn't exist in Firestore, return a basic one with ID
        // The repository or UI can handle merging with Auth info
        return UserProfileModel(id: userId, email: '');
      }
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
  }

  @override
  Future<void> updateProfile(UserProfileModel profile) async {
    try {
      await firestore.collection('users').doc(profile.id).set(
            profile.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  @override
  Future<String> uploadAvatar(String userId, XFile imageFile) async {
    try {
      return await cloudinaryService.uploadImage(imageFile);
    } catch (e) {
      throw Exception('Error uploading avatar: $e');
    }
  }
}
