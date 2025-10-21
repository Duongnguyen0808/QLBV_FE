// lib/app/domain/auth/auth_cubit.dart (FIXED)

import 'package:bloc/bloc.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/domain/auth/auth_state.dart';
// THÊM IMPORT NÀY ĐỂ ĐỊNH NGHĨA AuthRepository, SignInRequest, SignUpRequest
import 'package:hospital_booking_app/app/domain/repositories/auth/auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  // Lỗi đã sửa nhờ import ở trên
  final AuthRepository _authRepository = sl<AuthRepository>();

  AuthCubit() : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    emit(isLoggedIn ? AuthAuthenticated() : AuthUnauthenticated());
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      // Lỗi đã sửa nhờ import ở trên
      final request = SignInRequest(email: email, password: password);
      await _authRepository.signIn(request);
      emit(AuthAuthenticated());
    } catch (e) {
      // Lỗi cSpell ở đây không ảnh hưởng đến code, tôi xóa comment tiếng Việt để tránh
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> signUp({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      // Lỗi đã sửa nhờ import ở trên
      final request = SignUpRequest(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
      );
      final message = await _authRepository.signUp(request);
      emit(AuthSignUpSuccess(message));
    } catch (e) {
      // Lỗi cSpell ở đây không ảnh hưởng đến code, tôi xóa comment tiếng Việt để tránh
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> signOut() async {
    await _authRepository.deleteToken();
    emit(AuthUnauthenticated());
  }
}
