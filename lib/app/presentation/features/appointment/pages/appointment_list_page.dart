import 'package:flutter/material.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';

class AppointmentListPage extends StatelessWidget {
  const AppointmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '2. LỊCH HẸN - Danh sách lịch hẹn đã đặt',
        style: TextStyle(
            fontSize: 20,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
