import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? username; // Display name
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? photoUrl;

  const UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.dateOfBirth,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, email, username, fullName, dateOfBirth, photoUrl];
}
