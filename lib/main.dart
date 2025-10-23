// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart'
    as di;
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/appointment_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/pages/sign_in_page.dart';
import 'package:hospital_booking_app/app/presentation/features/medical_record/bloc/medical_record_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/profile/bloc/profile_cubit.dart';
import 'package:hospital_booking_app/app/presentation/main_tab_controller.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hospital_booking_app/app/presentation/doctor_main_tab_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi', null);
  await initializeDateFormatting('en', null);

  await di.init(); // Khởi tạo các dependencies
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => sl<AuthCubit>()..checkAuthStatus(),
        ),
        // ĐĂNG KÝ TẤT CẢ CÁC CUBIT CẦN DÙNG CHO CẢ ỨNG DỤNG
        BlocProvider<AppointmentCubit>(
          create: (context) => sl<AppointmentCubit>(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => sl<ProfileCubit>(),
        ),
        BlocProvider<MedicalRecordCubit>(
          create: (context) => sl<MedicalRecordCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Hospital Booking App',
        locale: const Locale('vi', 'VN'),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial || state is AuthLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is AuthAuthenticated) {
              // LOGIC QUAN TRỌNG: CHUYỂN HƯỚNG THEO VAI TRÒ
              if (state.role == 'DOCTOR' || state.role == 'ADMIN') {
                return const DoctorMainTabController(); // 3 Tab cho Bác sĩ/Admin
              }
              return const MainTabController(); // 4 Tab cho Bệnh nhân
            }
            return const SignInPage();
          },
        ),
      ),
    );
  }
}
