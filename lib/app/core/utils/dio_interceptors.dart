import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';

final sl = GetIt.instance;

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  AuthInterceptor({required this.storage});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'jwt_token');

    // DEBUG: Log để kiểm tra token
    print('🔍 DEBUG AuthInterceptor: Reading token from storage...');
    print('🔍 DEBUG AuthInterceptor: Token exists = ${token != null}');
    if (token != null && token.length > 20) {
      print(
          '🔍 DEBUG AuthInterceptor: Token preview = ${token.substring(0, 20)}...');
    }

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print('✅ DEBUG AuthInterceptor: Added Authorization header');
    } else {
      print(
          '❌ DEBUG AuthInterceptor: No token found, skipping Authorization header');
    }

    if (options.path.contains('/api/auth/') ||
        options.path.contains('/api/public/')) {}

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await storage.delete(key: 'jwt_token');

      try {
        if (sl.isRegistered<AuthCubit>()) {
          sl<AuthCubit>().signOut();
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}
