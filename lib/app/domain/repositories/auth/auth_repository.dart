// Đặt file này vào: lib/app/domain/repositories/auth/

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospital_booking_app/app/core/config/app_config.dart';

// --- Thay thế DTOs: Các lớp dữ liệu đơn giản ---

class SignInRequest {
  final String email;
  final String password;
  SignInRequest({required this.email, required required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class SignUpRequest {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String password;
  SignUpRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
  });
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
      };
}

class JwtResponse {
  final String token;
  JwtResponse({required this.token});
  factory JwtResponse.fromJson(Map<String, dynamic> json) {
    return JwtResponse(token: json['token'] as String);
  }
}

// --- Repository Interface and Implementation ---

abstract class AuthRepository {
  Future<JwtResponse> signIn(SignInRequest request);
  Future<String> signUp(SignUpRequest request);
  Future<void> saveToken(String token);
  Future<void> deleteToken();
  Future<bool> isLoggedIn();
}

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'jwt_token';

  AuthRepositoryImpl({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  // Gọi API Đăng nhập: POST /api/auth/signin
  @override
  Future<JwtResponse> signIn(SignInRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConfig.baseUrl}/api/auth/signin',
        data: request.toJson(),
      );
      final jwtResponse = JwtResponse.fromJson(response.data);
      await saveToken(jwtResponse.token);
      return jwtResponse;
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 400) {
        final errorBody = e.response!.data;
        // Xử lý lỗi 400 (Bad Request) từ Backend
        final message =
            errorBody is String ? errorBody : (errorBody['message'] ?? 'Email hoặc mật khẩu không hợp lệ.');
        throw Exception(message);
      }
      throw Exception('Lỗi kết nối hoặc server: ${e.message}');
    }
  }

  // Gọi API Đăng ký: POST /api/auth/signup
  @override
  Future<String> signUp(SignUpRequest request) async {
    try {
      final response = await _dio.post(
        '${AppConfig.baseUrl}/api/auth/signup',
        data: request.toJson(),
      );
      // Backend trả về message là String
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 400) {
        final errorBody = e.response!.data;
        final message =
            errorBody is String ? errorBody : (errorBody['message'] ?? 'Dữ liệu không hợp lệ.');
        throw Exception(message);
      }
      throw Exception('Lỗi kết nối hoặc server.');
    }
  }

  // --- Token Management ---

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }
}