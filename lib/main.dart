// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart'
    as di;
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/appointment_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/doctor_appointment_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/pages/sign_in_page.dart';
import 'package:hospital_booking_app/app/presentation/features/medical_record/bloc/medical_record_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/profile/bloc/profile_cubit.dart';
import 'package:hospital_booking_app/app/presentation/main_tab_controller.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hospital_booking_app/app/presentation/doctor_main_tab_controller.dart';

// THÊM navigatorKey TOÀN CỤC ĐỂ ĐIỀU HƯỚNG THEO AUTH STATE
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
        BlocProvider<DoctorAppointmentCubit>(
          create: (context) => sl<DoctorAppointmentCubit>(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => sl<ProfileCubit>(),
        ),
        BlocProvider<MedicalRecordCubit>(
          create: (context) => sl<MedicalRecordCubit>(),
        ),
        BlocProvider<DoctorScheduleCubit>(
          // <--- THÊM PROVIDER NÀY
          create: (context) => sl<DoctorScheduleCubit>(),
        ),
      ],
      // THAY MaterialApp TRỰC TIẾP BẰNG BlocListener ĐỂ ĐIỀU HƯỚNG THEO AUTH STATE
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          final nav = rootNavigatorKey.currentState;
          if (nav == null) return;

          if (state is AuthAuthenticated) {
            if (state.role == 'DOCTOR' || state.role == 'ADMIN') {
              nav.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const DoctorMainTabController(),
                ),
                (route) => false,
              );
            } else {
              nav.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainTabController(),
                ),
                (route) => false,
              );
            }
          } else if (state is AuthUnauthenticated) {
            nav.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const SignInPage(),
              ),
              (route) => false,
            );
          }
          // AuthInitial/AuthLoading -> giữ SplashPage
        },
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
          // DÙNG navigatorKey TOÀN CỤC
          navigatorKey: rootNavigatorKey,
          // DÙNG SPLASH TỐI GIẢN LÀM HOME, ĐIỀU HƯỚNG SẼ DO BlocListener XỬ LÝ
          home: const _SplashPage(),
        ),
      ),
    );
  }
}

// THÊM SPLASH PAGE TỐI GIẢN
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
