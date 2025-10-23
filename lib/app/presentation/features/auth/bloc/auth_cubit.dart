// lib/app/domain/auth/auth_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart'; // Import cho UserModel đã cập nhật
import 'package:hospital_booking_app/app/domain/repositories/auth/auth_repository.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart'; // Cần DataRepo để fetch Role
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';

// Giả định các Request Models được định nghĩa trong auth_repository.dart
// class SignInRequest, SignUpRequest { ... }

class AuthCubit extends Bloc<dynamic, AuthState> {
  final AuthRepository _authRepository = sl<AuthRepository>();
  // Thêm DataRepository và Storage để quản lý vai trò thủ công
  final DataRepository _dataRepository = sl<DataRepository>();
  final FlutterSecureStorage _storage = sl<FlutterSecureStorage>();

  AuthCubit() : super(AuthInitial());

  // HÀM MỚI: Lấy vai trò từ Secure Storage (key mới)
  Future<String?> _getRoleFromStorage() async {
    // Đọc vai trò đã lưu sau khi đăng nhập thành công
    return await _storage.read(key: 'user_role');
  }

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      // Lấy vai trò từ storage (đã được lưu sau khi đăng nhập thành công)
      final role = await _getRoleFromStorage() ?? 'PATIENT';
      emit(AuthAuthenticated(role));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final request = SignInRequest(email: email, password: password);
      // 1. Đăng nhập (Lưu JWT)
      await _authRepository.signIn(request);

      // 2. Lấy thông tin Profile (Bao gồm Role)
      // Chức năng này chỉ hoạt động nếu UserModel đã có trường role
      final UserModel userProfile = await _dataRepository.fetchMyProfile();
      final String role = userProfile.role; // Lấy role chính xác từ Backend

      // 3. Lưu vai trò chính xác vào storage để sử dụng cho lần sau
      await _storage.write(key: 'user_role', value: role);

      emit(AuthAuthenticated(role));
    } catch (e) {
      // Đảm bảo xóa token và role nếu đăng nhập thất bại
      await _authRepository.deleteToken();
      await _storage.delete(key: 'user_role');
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
    await _storage.delete(key: 'user_role'); // Xóa cả role khi đăng xuất
    emit(AuthUnauthenticated());
  }
}
