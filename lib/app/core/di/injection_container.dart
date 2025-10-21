// lib/app/core/di/injection_container.dart (CẬP NHẬT)

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hospital_booking_app/app/presentation/features/booking/pages/bloc/booking_cubit.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:hospital_booking_app/app/domain/repositories/auth/auth_repository.dart';
import 'package:hospital_booking_app/app/domain/auth/auth_cubit.dart';
import 'package:hospital_booking_app/app/core/config/app_config.dart';
import 'package:hospital_booking_app/app/core/utils/dio_interceptors.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';
// THÊM DÒNG NÀY ĐỂ SỬA LỖI LỚN NHẤT
import 'package:hospital_booking_app/app/domain/repositories/appointment/appointment_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // --- Core Dependencies ---
  // (Đảm bảo Dio và AuthInterceptor đã được đăng ký)

  sl.registerLazySingleton(() => AuthInterceptor(storage: sl()));

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl, // Đảm bảo baseUrl tồn tại
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(sl<AuthInterceptor>());

    // Thêm PrettyDioLogger (giả định đã được khai báo trong pubspec.yaml)
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    ));
    return dio;
  });

  // --- External Dependencies ---
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // --- Repositories ---
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dio: sl(), storage: sl()),
  );
  sl.registerLazySingleton<DataRepository>(
    () => DataRepositoryImpl(dio: sl()),
  );
  // ĐĂNG KÝ AppointmentRepository ĐỂ KHẮC PHỤC LỖI STATE ERROR
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(dio: sl()),
  );

  // --- Cubits/Blocs ---
  sl.registerFactory(() => AuthCubit());
  sl.registerFactory(() => BookingCubit());
}
