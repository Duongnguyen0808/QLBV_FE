// lib/app/presentation/features/profile/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/domain/auth/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '4. CÁ NHÂN - Hồ sơ của tôi',
            style: TextStyle(
                fontSize: 20,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.read<AuthCubit>().signOut(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red, // Nút Đăng xuất màu đỏ
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontSize: 18, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
