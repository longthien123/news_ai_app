import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/repositories/user_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUsecase loginUsecase;
  final RegisterUsecase registerUsecase;
  final UpdateProfileUsecase updateProfileUsecase;
  final UserRepository repository;

  AuthCubit({
    required this.loginUsecase,
    required this.registerUsecase,
    required this.updateProfileUsecase,
    required this.repository,
  }) : super(AuthInitial());

  Future<void> checkAuth() async {
    emit(AuthLoading());
    try {
      final user = await repository.getCachedUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await loginUsecase(email, password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register(String email, String password, {String? name}) async {
    emit(AuthLoading());
    try {
      final user = await registerUsecase(email, password, name: name);
      print('✅ Register success: ${user.email}, id: ${user.id}'); // Debug log
      emit(Authenticated(user));
      print('✅ Emitted Authenticated state'); // Debug log
    } catch (e) {
      print('❌ Register error: $e'); // Debug log
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await repository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateProfile({String? name}) async {
    if (state is! Authenticated) return;
    
    try {
      await updateProfileUsecase(name: name);
      final user = await repository.getCachedUser();
      if (user != null) {
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}