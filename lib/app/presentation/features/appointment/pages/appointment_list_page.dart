// lib/app/presentation/features/appointment/pages/appointment_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/appointment_cubit.dart';
import 'package:intl/intl.dart';

class AppointmentListPage extends StatelessWidget {
  const AppointmentListPage({super.key});

  static const String contactZalo = '0345745181';
  static const String contactPhone = '0345745181';

  @override
  Widget build(BuildContext context) {
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

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bạn chưa có lịch hẹn nào.',
                    style: TextStyle(fontSize: 16, color: AppColors.hintColor)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      context.read<AppointmentCubit>().fetchAppointments(),
                  child: const Text('Tải lại danh sách'),
                ),
              ],
            ),
          );
        }

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

  Widget _buildAppointmentCard(
      BuildContext context, AppointmentListModel appt) {
    // Kiểm tra quy tắc 6 giờ tương tự như màn hình QR
    final canCancel = _canCancel(appt.appointmentDateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch hẹn với Bác Sĩ',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryColor),
                ),
                _buildStatusBadge(appt.status),
              ],
            ),
            const Divider(height: 15),
            Text(
              'Bác sĩ: ${appt.doctorFullName}',
              style: const TextStyle(fontSize: 15, color: AppColors.textColor),
            ),
            Text(
              'Chuyên khoa: ${appt.specialtyName}',
              style: TextStyle(fontSize: 14, color: AppColors.hintColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.hintColor),
                const SizedBox(width: 5),
                Text(
                  _formatDateTime(appt.appointmentDateTime),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.textColor),
                ),
              ],
            ),

            // NÚT HÀNH ĐỘNG
            if (appt.status == 'PAID_PENDING')
              _buildActionButton(
                label: 'Tiếp tục Thanh toán',
                color: AppColors.orange,
                onPressed: () {
                  // TODO: [TBD] Điều hướng sang trang thanh toán QR nếu cần
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Chức năng tiếp tục thanh toán chưa được triển khai.')));
                },
              )
            else if (appt.status == 'CONFIRMED' && canCancel)
              _buildActionButton(
                label: 'Hủy Lịch Hẹn',
                color: AppColors.red,
                onPressed: () =>
                    _showCancelDialog(context, appt), // <-- SỬ DỤNG HÀM MỚI
              ),

            if (appt.status == 'CONFIRMED' && !canCancel)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '(Không thể hủy: < 6 giờ trước khám)',
                  style: TextStyle(
                      color: AppColors.red.withOpacity(0.7), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Helper Functions ---

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'PENDING':
        color = AppColors.orange;
        text = 'Chờ Xác Nhận (Chưa TT)';
        break;
      case 'PAID_PENDING':
        color = AppColors.orange;
        text = 'Chờ Thanh Toán';
        break;
      case 'CONFIRMED':
        color = AppColors.primaryColor;
        text = 'Đã Thanh Toán'; // <-- DÒNG SỬA
        break;
      case 'COMPLETED':
        color = AppColors.green;
        text = 'Đã Hoàn Thành';
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

  Widget _buildActionButton(
      {required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  // Kiểm tra quy tắc hủy (dưới 6 giờ)
  bool _canCancel(String dateTimeString) {
    try {
      final scheduledTime = DateTime.parse(dateTimeString).toLocal();
      final difference = scheduledTime.difference(DateTime.now());
      return difference.inHours > 6;
    } catch (e) {
      return false;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      // Đã đảm bảo locale vi_VN được khởi tạo trong main.dart
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('HH:mm - EEE dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Lỗi định dạng ngày giờ';
    }
  }

  // SỬA: Thêm logic hoàn tiền thủ công vào Dialog
  void _showCancelDialog(BuildContext context, AppointmentListModel appt) {
    // Kiểm tra xem đây là lịch hẹn đã thanh toán hay chưa
    final isPaid = appt.status == 'CONFIRMED';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            isPaid ? 'Xác nhận Hủy và Hoàn tiền' : 'Xác nhận Hủy Lịch hẹn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Bạn có chắc chắn muốn hủy lịch hẹn #${appt.id} với Bác sĩ ${appt.doctorFullName} vào ${_formatDateTime(appt.appointmentDateTime)} không?'),
            if (isPaid) ...[
              const SizedBox(height: 15),
              Text(
                'LƯU Ý HOÀN TIỀN:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.red),
              ),
              Text(
                'Vui lòng liên hệ Zalo hoặc gọi đến số ${contactZalo} kèm theo Bill chuyển khoản để được hoàn lại tiền khám.',
                style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.8), fontSize: 13),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Gọi hàm hủy lịch hẹn
              context.read<AppointmentCubit>().cancelAppointment(appt.id);
            },
            child: Text(isPaid ? 'Hủy & Yêu cầu Hoàn tiền' : 'Hủy Lịch Hẹn',
                style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
