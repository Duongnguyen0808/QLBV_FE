// lib/app/presentation/main_tab_controller.dart

import 'package:flutter/material.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/pages/appointment_list_page.dart';
import 'package:hospital_booking_app/app/presentation/features/booking/pages/booking_page.dart';
import 'package:hospital_booking_app/app/presentation/features/medical_record/pages/medical_history_page.dart';
import 'package:hospital_booking_app/app/presentation/features/profile/pages/profile_page.dart';

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BookingPage(), // Tab 1: Đặt Lịch (Trang Chủ)
    AppointmentListPage(),
    MedicalHistoryPage(),
    ProfilePage(),
  ];

  final List<BottomNavigationBarItem> _navBarItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home), // Thay đổi icon cho Trang Chủ
      label: 'Trang Chủ', // ĐỔI TÊN
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today),
      label: 'Lịch Hẹn',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'Lịch Sử Khám',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Cá Nhân',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _navBarItems[_currentIndex].label!,
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
