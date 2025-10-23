// lib/app/core/di/injection_container.dart (CẬP NHẬT)

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/appointment_cubit.dart';
// import 'package:hospital_booking_app/app/presentation/features/medical_record/bloc/medical_record_cubit.dart'; // Giữ nguyên, đã sửa ở file trên
import 'package:hospital_booking_app/app/presentation/features/profile/bloc/profile_cubit.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:hospital_booking_app/app/domain/repositories/auth/auth_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';
import 'package:hospital_booking_app/app/core/config/app_config.dart';
import 'package:hospital_booking_app/app/core/utils/dio_interceptors.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';
import 'package:hospital_booking_app/app/domain/repositories/appointment/appointment_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/booking/bloc/booking_cubit.dart';

// THÊM IMPORT VÀO ĐÂY
import 'package:hospital_booking_app/app/presentation/features/medical_record/bloc/medical_record_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // --- Core Dependencies ---
  sl.registerLazySingleton(() => AuthInterceptor(storage: sl()));

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(sl<AuthInterceptor>());

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

  sl.registerLazySingleton(() => const FlutterSecureStorage());

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dio: sl(), storage: sl()),
  );
  sl.registerLazySingleton<DataRepository>(
    () => DataRepositoryImpl(dio: sl()),
  );
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(dio: sl()),
  );

  sl.registerFactory(() => AuthCubit());
  sl.registerFactory(() => BookingCubit());
  sl.registerFactory(() => AppointmentCubit());
  sl.registerFactory(() => ProfileCubit());
  sl.registerFactory(() => MedicalRecordCubit());
  sl.registerFactory(() => DoctorScheduleCubit()); // <--- ĐĂNG KÝ CUBIT MỚI
}
