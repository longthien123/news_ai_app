import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.username,
    super.fullName,
    super.dateOfBirth,
    super.photoUrl,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      // Return a basic profile if document doesn't exist yet but ID is known
      // Or throw exception depending on logic. Here we assume basic profile.
      return UserProfileModel(
        id: doc.id,
        email: '', // Email might not be in Firestore if only in Auth
      );
    }

    return UserProfileModel(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'],
      fullName: data['fullName'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'photoUrl': photoUrl,
    };
  }

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      username: entity.username,
      fullName: entity.fullName,
      dateOfBirth: entity.dateOfBirth,
      photoUrl: entity.photoUrl,
    );
  }
}
