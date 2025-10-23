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

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
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
