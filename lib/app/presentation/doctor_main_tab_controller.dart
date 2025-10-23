// lib/app/presentation/doctor_main_tab_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/data/models/working_schedule_model.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/pages/appointment_list_page.dart';
import 'package:hospital_booking_app/app/presentation/features/medical_record/bloc/medical_record_cubit.dart'; // CẦN CHO BLOC
import 'package:hospital_booking_app/app/presentation/features/profile/pages/profile_page.dart';

class DoctorMainTabController extends StatefulWidget {
  const DoctorMainTabController({super.key});

  @override
  State<DoctorMainTabController> createState() =>
      _DoctorMainTabControllerState();
}

class _DoctorMainTabControllerState extends State<DoctorMainTabController> {
  int _currentIndex = 0;

  // CHỈ 3 PAGE
  final List<Widget> _pages = [
    AppointmentListPage(), // 0: Lịch Hẹn
    const DoctorSchedulePage(), // 1: Lịch Làm Việc
    const ProfilePage(), // 2: Hồ Sơ
  ];

  // CHỈ 3 ITEM
  final List<BottomNavigationBarItem> _navBarItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today),
      label: 'Lịch Hẹn',
    ),
    // LỊCH LÀM VIỆC
    BottomNavigationBarItem(
      icon: Icon(Icons.schedule),
      label: 'Lịch Làm Việc',
    ),
    // HỒ SƠ
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
      // SỬ DỤNG IndexedStack để chuyển đổi giữa 3 Page
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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

// BỔ SUNG PAGE LỊCH LÀM VIỆC THẬT (Sử dụng DoctorScheduleCubit)
class DoctorSchedulePage extends StatelessWidget {
  const DoctorSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorScheduleCubit, DoctorScheduleState>(
      builder: (context, state) {
        if (state is DoctorScheduleLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        if (state is DoctorScheduleLoadFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Lỗi tải lịch làm việc.',
                    style: TextStyle(color: AppColors.red)),
                Text(state.message,
                    style: TextStyle(color: AppColors.hintColor)),
                ElevatedButton(
                    onPressed: () =>
                        context.read<DoctorScheduleCubit>().fetchSchedules(),
                    child: const Text('Thử lại')),
              ],
            ),
          );
        }

        final schedules = state is DoctorScheduleLoadSuccess
            ? state.schedules
            : <WorkingScheduleModel>[];

        if (schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule,
                    color: AppColors.hintColor, size: 50),
                const SizedBox(height: 10),
                const Text('Bạn chưa có lịch làm việc nào.',
                    style: TextStyle(fontSize: 16, color: AppColors.hintColor)),
                ElevatedButton(
                    onPressed: () =>
                        context.read<DoctorScheduleCubit>().fetchSchedules(),
                    child: const Text('Tải lại')),
              ],
            ),
          );
        }

        // HIỂN THỊ DANH SÁCH LỊCH LÀM VIỆC
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Lịch Làm Việc Đã Đăng Ký',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor),
            ),
            const Divider(height: 20),
            // HEADER CỘT
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8))),
              child: const Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('Thứ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white)))),
                  Expanded(
                      flex: 3,
                      child: Center(
                          child: Text('Thời Gian',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white)))),
                ],
              ),
            ),

            // DANH SÁCH SCHEDULE
            ...schedules
                .map((schedule) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.lightGray, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Center(
                                  child: Text(schedule.dayOfWeek,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)))),
                          Expanded(
                              flex: 3,
                              child: Center(child: Text(schedule.timeSlot))),
                        ],
                      ),
                    ))
                .toList(),

            const SizedBox(height: 20),
            const Text(
              'Ghi chú: Lịch được quản lý chi tiết qua Web Admin.',
              style: TextStyle(
                  color: AppColors.hintColor, fontStyle: FontStyle.italic),
            )
          ],
        );
      },
    );
  }
}
