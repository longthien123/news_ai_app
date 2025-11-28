import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';

// States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;

  ProfileCubit({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadAvatarUseCase,
  }) : super(ProfileInitial());

  Future<void> loadProfile(String userId) async {
    emit(ProfileLoading());
    try {
      final profile = await getProfileUseCase(userId);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    emit(ProfileLoading());
    try {
      await updateProfileUseCase(profile);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> uploadAvatar(String userId, XFile imageFile) async {
    if (state is! ProfileLoaded) return;
    final currentProfile = (state as ProfileLoaded).profile;

    emit(ProfileLoading());
    try {
      final photoUrl = await uploadAvatarUseCase(userId, imageFile);
      
      // Update profile with new photoUrl
      final updatedProfile = UserProfile(
        id: currentProfile.id,
        email: currentProfile.email,
        username: currentProfile.username,
        fullName: currentProfile.fullName,
        dateOfBirth: currentProfile.dateOfBirth,
        photoUrl: photoUrl,
      );

      // Save to Firestore
      await updateProfileUseCase(updatedProfile);
      
      emit(ProfileLoaded(updatedProfile));
    } catch (e) {
      // If upload fails, just revert to the current profile (or keep showing it)
      // We don't want to block the user from using the app just because of storage issues.
      emit(ProfileLoaded(currentProfile));
      // In a real app, we would emit a side-effect (e.g. via a separate stream) to show a SnackBar.
      print('Error uploading avatar: $e'); 
    }
  }
}
