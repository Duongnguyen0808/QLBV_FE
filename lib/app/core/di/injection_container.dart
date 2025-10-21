// Đặt file này vào thư mục: lib/app/core/di/
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:hospital_booking_app/app/domain/repositories/auth/auth_repository.dart';
import 'package:hospital_booking_app/app/domain/auth/auth_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // --- Core Dependencies ---
  sl.registerLazySingleton(() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      )));

  // Thêm logger để debug API
  sl<Dio>().interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ));

  // --- External Dependencies ---
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // --- Repositories ---
  // Sử dụng FlutterSecureStorage trong AuthRepositoryImpl
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dio: sl(), storage: sl()),
  );

  // --- Cubits/Blocs ---
  sl.registerFactory(() => AuthCubit());
}
