import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile(String userId);
  Future<void> updateProfile(UserProfileModel profile);
  Future<String> uploadAvatar(String userId, XFile imageFile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ProfileRemoteDataSourceImpl({
    required this.firestore,
    FirebaseStorage? storage,
  }) : storage = storage ?? FirebaseStorage.instance;

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
      final ref = storage.ref().child('avatars/$userId.jpg');
      // Use putData for cross-platform support (works on Web)
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final data = await imageFile.readAsBytes();
      await ref.putData(data, metadata);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Error uploading avatar: $e');
    }
  }
}
