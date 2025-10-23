// lib/app/presentation/doctor_main_tab_controller.dart

import 'package:flutter/material.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/pages/appointment_list_page.dart';
import 'package:hospital_booking_app/app/presentation/features/medical_record/pages/medical_history_page.dart';
import 'package:hospital_booking_app/app/presentation/features/profile/pages/profile_page.dart';

class DoctorMainTabController extends StatefulWidget {
  const DoctorMainTabController({super.key});

  @override
  State<DoctorMainTabController> createState() =>
      _DoctorMainTabControllerState();
}

class _DoctorMainTabControllerState extends State<DoctorMainTabController> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    AppointmentListPage(), // Tab 1: Danh sách Lịch hẹn (Sẽ bao gồm chức năng nhắc nhở)
    const MedicalHistoryPage(), // Tab 2: Lịch Sử Bệnh án
    const ProfilePage(), // Tab 3: Hồ Sơ Cá Nhân
  ];

  final List<BottomNavigationBarItem> _navBarItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today),
      label: 'Lịch Hẹn',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_edu), // Lịch sử Bệnh án
      label: 'Bệnh Án',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Hồ Sơ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentTitle = _navBarItems[_currentIndex].label!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentTitle,
          style: const TextStyle(
              color: AppColors.primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.hintColor,
        items: _navBarItems,
      ),
    );
  }
}
