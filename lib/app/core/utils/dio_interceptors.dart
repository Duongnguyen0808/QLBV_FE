// lib/app/core/utils/dio_interceptors.dart (TẠO MỚI)

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

// Đây là nơi chứa GetIt instance
final sl = GetIt.instance;

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  AuthInterceptor({required this.storage});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Lấy token
    final token = await storage.read(key: 'jwt_token');

    // 2. Thêm Bearer token vào header nếu có
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Cho phép các request công khai đi qua mà không cần token
    // (VD: /api/auth/signin, /api/auth/signup, /api/public/**)
    if (options.path.contains('/api/auth/') ||
        options.path.contains('/api/public/')) {
      // Không cần thêm token, nhưng nếu có thì vẫn thêm
    }

    handler.next(options);
  }

  // Xử lý khi nhận response lỗi 401 (Unauthorized)
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Logic: Nếu bị 401, xóa token cũ và chuyển về trạng thái chưa đăng nhập
      await storage.delete(key: 'jwt_token');
      // Thường sẽ emit AuthUnauthenticated() ở đây, nhưng vì Cubit không thể
      // gọi từ Interceptor nên ta chỉ cần đảm bảo token bị xóa.
      // Khi app tiếp tục chạy, checkAuthStatus() sẽ tự động chuyển trạng thái.
    }
    handler.next(err);
  }
}
