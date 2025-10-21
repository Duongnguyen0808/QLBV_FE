// lib/app/domain/repositories/auth/auth_repository.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:equatable/equatable.dart';

// --- REQUEST MODELS (Lớp bị thiếu: SignInRequest, SignUpRequest) ---
class SignInRequest extends Equatable {
  final String email;
  final String password;

  const SignInRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };

  @override
  List<Object> get props => [email, password];
}

class SignUpRequest extends Equatable {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String password;

  const SignUpRequest({
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

  @override
  List<Object> get props => [fullName, phoneNumber, email, password];
}

// --- RESPONSE MODEL (Phản hồi API) ---
class JwtResponse {
  final String token;

  JwtResponse({required this.token});

  factory JwtResponse.fromJson(Map<String, dynamic> json) {
    return JwtResponse(
      token: json['token'] as String,
    );
  }
}

// --- ABSTRACT REPOSITORY (Lớp bị thiếu: AuthRepository) ---
abstract class AuthRepository {
  Future<void> signIn(SignInRequest request);
  Future<String> signUp(SignUpRequest request);
  Future<bool> isLoggedIn();
  Future<void> deleteToken();
}

// --- REPOSITORY IMPLEMENTATION (Lớp bị thiếu: AuthRepositoryImpl) ---
class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;
  final FlutterSecureStorage storage;

  AuthRepositoryImpl({required this.dio, required this.storage});

  @override
  Future<void> signIn(SignInRequest request) async {
    try {
      final response = await dio.post(
        '/api/auth/signin',
        data: request.toJson(),
      );

      final jwtResponse = JwtResponse.fromJson(response.data);
      await storage.write(key: 'jwt_token', value: jwtResponse.token);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        // Xử lý lỗi từ Backend (ví dụ: Sai mật khẩu)
        String errorMessage = e.response!.data is String
            ? e.response!.data
            : e.response!.data['message'] ?? 'Lỗi đăng nhập không xác định.';
        throw Exception(errorMessage);
      }
      throw Exception(
          'Kết nối thất bại. Vui lòng kiểm tra lại mạng hoặc server.');
    }
  }

  @override
  Future<String> signUp(SignUpRequest request) async {
    try {
      final response = await dio.post(
        '/api/auth/signup',
        data: request.toJson(),
      );

      // Backend trả về String message (ví dụ: "Đăng ký thành công...")
      return response.data is String
          ? response.data
          : 'Đăng ký thành công! Vui lòng kiểm tra email.';
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        // Xử lý lỗi từ Backend (ví dụ: Email đã tồn tại)
        String errorMessage = e.response!.data is String
            ? e.response!.data
            : e.response!.data['message'] ?? 'Lỗi đăng ký không xác định.';
        throw Exception(errorMessage);
      }
      throw Exception(
          'Kết nối thất bại. Vui lòng kiểm tra lại mạng hoặc server.');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'jwt_token');
    // Logic đơn giản: chỉ cần có token là coi như đã đăng nhập
    return token != null;
  }

  @override
  Future<void> deleteToken() async {
    await storage.delete(key: 'jwt_token');
  }
}
