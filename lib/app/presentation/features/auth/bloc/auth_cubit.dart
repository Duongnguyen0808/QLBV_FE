// lib/app/domain/auth/auth_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/domain/repositories/auth/auth_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';

// Giả định các Request Models được định nghĩa trong auth_repository.dart
// class SignInRequest, SignUpRequest { ... }

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository = sl<AuthRepository>();

  AuthCubit() : super(AuthInitial());

  // SỬA LỖI: Lấy Storage an toàn từ Service Locator
  Future<String?> _getRoleFromToken() async {
    // Lấy storage instance từ GetIt
    final storage = sl<FlutterSecureStorage>();

    // Đọc token
    final token = await storage.read(key: 'jwt_token');
    if (token == null) return null;

    // RẤT MẠO HIỂM - CHỈ LÀM ĐỂ MÔ PHỎNG PHÂN BIỆT VAI TRÒ DỰA TRÊN CHUỖI TOKEN/EMAIL
    // Nếu email đăng nhập là bacsibin@gmail.com, token sẽ chứa 'bacsi'
    if (token.contains('DOCTOR') || token.contains('bacsi')) {
      return 'DOCTOR';
    } else if (token.contains('ADMIN')) {
      return 'ADMIN';
    } else {
      return 'PATIENT';
    }
  }

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      final role = await _getRoleFromToken() ?? 'PATIENT'; // Lấy vai trò
      emit(AuthAuthenticated(role));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final request = SignInRequest(email: email, password: password);
      await _authRepository.signIn(request);

      final role = await _getRoleFromToken() ??
          'PATIENT'; // Lấy vai trò sau khi đăng nhập
      emit(AuthAuthenticated(role));
    } catch (e) {
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
      final request = SignUpRequest(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
      );
      final message = await _authRepository.signUp(request);
      emit(AuthSignUpSuccess(message));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> signOut() async {
    await _authRepository.deleteToken();
    emit(AuthUnauthenticated());
  }
}
