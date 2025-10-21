import 'package:flutter/material.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';

class MedicalHistoryPage extends StatelessWidget {
  const MedicalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '3. LỊCH SỬ KHÁM - Bệnh án và Đơn thuốc',
        style: TextStyle(
            fontSize: 20,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
