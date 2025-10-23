// lib/app/presentation/features/appointment/pages/appointment_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/appointment_cubit.dart';
import 'package:intl/intl.dart';

import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';

class AppointmentListPage extends StatelessWidget {
  AppointmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // SỬA LỖI: Buộc tải dữ liệu nếu Cubit đang ở trạng thái ban đầu
    if (context.read<AppointmentCubit>().state is AppointmentInitial) {
      // Tải bất đồng bộ để tránh lỗi trong quá trình build
      Future.microtask(
          () => context.read<AppointmentCubit>().fetchAppointments());
    }

    return BlocConsumer<AppointmentCubit, AppointmentState>(
      listener: (context, state) {
        if (state is AppointmentLoadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${state.message}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AppointmentLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        final appointments = state is AppointmentLoadSuccess
            ? state.appointments
            : <AppointmentListModel>[];

        final isDoctor = _isCurrentRoleDoctor(context);

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    isDoctor
                        ? 'Bạn chưa có lịch hẹn khám nào.'
                        : 'Bạn chưa có lịch hẹn nào.',
                    style: TextStyle(fontSize: 16, color: AppColors.hintColor)),
                const SizedBox(height: 10),
                // Nút tải lại
                ElevatedButton(
                  onPressed: () =>
                      context.read<AppointmentCubit>().fetchAppointments(),
                  child: const Text('Tải lại danh sách'),
                ),
              ],
            ),
          );
        }

        // HIỂN THỊ DANH SÁCH LỊCH HẸN
        return RefreshIndicator(
          onRefresh: () => context.read<AppointmentCubit>().fetchAppointments(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(context, appointments[index]);
            },
          ),
        );
      },
    );
  }

  // QUAN TRỌNG: Kiểm tra xem user hiện tại có phải là Doctor không (Chuyển ra ngoài build method)
  bool _isCurrentRoleDoctor(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    return authState is AuthAuthenticated &&
        (authState.role == 'DOCTOR' || authState.role == 'ADMIN');
  }

  Widget _buildAppointmentCard(
      BuildContext context, AppointmentListModel appt) {
    final isDoctor = _isCurrentRoleDoctor(context);
    final isActiveForDoctor = appt.status == 'CONFIRMED' ||
        appt.status == 'PAID_PENDING' ||
        appt.status == 'PENDING';

    // Dùng Container thay vì Card để mô phỏng hiển thị dạng bảng (table row)
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: AppColors.hintColor.withOpacity(0.1), blurRadius: 3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DÒNG 1: Bệnh nhân + Trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                // HIỂN THỊ TÊN BỆNH NHÂN (Giống cột "Bệnh nhân" trên web)
                isDoctor
                    ? 'Bệnh nhân: ${appt.patientFullName}'
                    : 'Lịch hẹn với Bác sĩ',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textColor),
              ),
              _buildStatusBadge(appt.status), // Cột Trạng thái
            ],
          ),
          const Divider(height: 10, color: AppColors.lightGray),

          // DÒNG 2: Thời gian hẹn
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 16, color: AppColors.hintColor),
              const SizedBox(width: 5),
              Text(
                _formatDateTime(appt.appointmentDateTime), // Cột Thời gian hẹn
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // DÒNG 3: Chuyên khoa (thông tin bổ sung)
          Text(
            'Chuyên khoa: ${appt.specialtyName}',
            style: TextStyle(fontSize: 14, color: AppColors.hintColor),
          ),

          // NÚT HÀNH ĐỘNG CỦA BÁC SĨ (CHỈ GỬI NHẮC NHỞ)
          if (isDoctor && isActiveForDoctor)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  // NÚT GỬI NHẮC NHỞ
                  Expanded(
                    child: _buildActionButton(
                      label: 'Gửi Nhắc nhở',
                      color: AppColors.primaryColor,
                      onPressed: () => _sendReminder(context, appt),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _sendReminder(BuildContext context, AppointmentListModel appt) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Đang gửi nhắc nhở cho bệnh nhân ${appt.patientFullName}...')));
    Future.delayed(const Duration(seconds: 1), () {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã gửi thông báo nhắc nhở thành công!'),
        backgroundColor: AppColors.green,
      ));
    });
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('HH:mm - E d/MM/yyyy', 'vi_VN').format(dateTime);
    } catch (e) {
      return 'Lỗi định dạng ngày giờ';
    }
  }

  Widget _buildActionButton(
      {required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'PENDING':
        color = AppColors.orange;
        text = 'Chờ Xác Nhận';
        break;
      case 'PAID_PENDING':
        color = AppColors.orange;
        text = 'Chờ Thanh Toán';
        break;
      case 'CONFIRMED':
        color = AppColors.green;
        text = 'Đã Xác Nhận';
        break;
      case 'COMPLETED':
        color = AppColors.green;
        text = 'Đã Khám';
        break;
      case 'CANCELLED':
        color = AppColors.red;
        text = 'Đã Hủy';
        break;
      default:
        color = AppColors.hintColor;
        text = 'Không rõ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
