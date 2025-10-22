// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart'
    as di;
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/domain/auth/auth_cubit.dart';
import 'package:hospital_booking_app/app/domain/auth/auth_state.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/pages/sign_in_page.dart';
import 'package:hospital_booking_app/app/presentation/main_tab_controller.dart';
// THÊM 2 DÒNG IMPORT INTL NÀY ĐỂ KHỞI TẠO LOCALE
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX LỖI: Gọi initializeDateFormatting() trước khi chạy ứng dụng
  // Khởi tạo locale Tiếng Việt (vi) và Tiếng Anh (en)
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
              return const MainTabController();
            }
            return const SignInPage();
          },
        ),
      ),
    );
  }
}
