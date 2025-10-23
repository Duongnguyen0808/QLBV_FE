// lib/app/presentation/features/appointment/pages/appointment_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/appointment_cubit.dart';
import 'package:intl/intl.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/pages/reschedule_page.dart';

class AppointmentListPage extends StatelessWidget {
  AppointmentListPage({super.key});

  final DataRepository _dataRepo = sl<DataRepository>();

  // HÀM MỚI: Fetch thông tin bác sĩ chi tiết và điều hướng đến trang đổi lịch
  void _fetchDoctorAndNavigate(
      BuildContext context, AppointmentListModel appt) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang tải thông tin bác sĩ...')),
    );

    // GIẢ ĐỊNH: Ta chỉ có thể search theo tên và lấy bác sĩ đầu tiên
    try {
      final doctors = await _dataRepo.searchDoctors(name: appt.doctorFullName);

      if (context.mounted && doctors.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (c) =>
                ReschedulePage(appointment: appt, doctor: doctors.first)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không tìm thấy thông tin bác sĩ chi tiết.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bác sĩ: ${e.toString()}')),
        );
      }
    }
  }

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
                // Nút tải lại trong trường hợp tải thất bại (hoặc không có lịch)
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
    final canRescheduleOrCancel =
        _canRescheduleOrCancel(appt.appointmentDateTime);
    final isActive = appt.status == 'CONFIRMED' ||
        appt.status == 'PAID_PENDING' ||
        appt.status == 'PENDING';

    // Kiểm tra xem đã thanh toán (CONFIRMED) hay chưa
    final isConfirmed = appt.status == 'CONFIRMED';

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
                const Text(
                  'Lịch hẹn với Bác sĩ',
                  style: TextStyle(
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
            if (isActive)
              Column(
                children: [
                  const SizedBox(height: 10),

                  // Nút Đổi lịch chỉ xuất hiện nếu có thể hủy/đổi lịch
                  if (canRescheduleOrCancel)
                    _buildActionButton(
                      label: 'Đổi Lịch Khám',
                      color: AppColors.secondaryColor,
                      onPressed: () => _fetchDoctorAndNavigate(context, appt),
                    ),

                  // Nút Thanh toán chỉ hiện khi CHƯA CONFIRMED và đang chờ thanh toán
                  // Đã thanh toán (CONFIRMED) hoặc đã khám (COMPLETED) thì không hiện.
                  if (appt.status == 'PAID_PENDING' || appt.status == 'PENDING')
                    _buildActionButton(
                      label: 'Tiếp tục Thanh toán',
                      color: AppColors.orange,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Chức năng tiếp tục thanh toán chưa được triển khai.')));
                      },
                    ),

                  // Nút Hủy
                  if (canRescheduleOrCancel)
                    _buildActionButton(
                      label: 'Hủy Lịch Hẹn',
                      color: AppColors.red,
                      onPressed: () => _showCancelDialog(context, appt),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '(Không thể hủy/đổi lịch: < 6 giờ trước khám)',
                        style: TextStyle(
                            color: AppColors.red.withOpacity(0.7),
                            fontSize: 12),
                      ),
                    ),

                  // THÊM: Nút Gửi Nhắc nhở (chỉ cho lịch hẹn hoạt động và chưa hoàn thành)
                  if (isConfirmed ||
                      appt.status == 'PENDING' ||
                      appt.status == 'PAID_PENDING')
                    _buildActionButton(
                      label: 'Gửi Nhắc nhở Lịch hẹn (Email/SMS)',
                      color: AppColors.primaryColor,
                      onPressed: () =>
                          _sendReminder(context, appt), // <-- HÀM MỚI
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // HÀM MỚI: Logic gửi nhắc nhở
  void _sendReminder(BuildContext context, AppointmentListModel appt) {
    // Đây là logic giả lập gọi EmailService/SMS Service của Backend
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Đang gửi nhắc nhở cho bệnh nhân ${appt.doctorFullName}...')));
    // TODO: [TBD] Gọi API Backend để kích hoạt EmailService/SMSService
    // Ví dụ: dio.post('/api/notifications/remind-appointment', data: {'appointmentId': appt.id})
    Future.delayed(const Duration(seconds: 1), () {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã gửi thông báo nhắc nhở thành công!'),
        backgroundColor: AppColors.green,
      ));
    });
  }

  // HÀM NÀY ĐỔI TÊN TỪ _canCancel
  bool _canRescheduleOrCancel(String dateTimeString) {
    try {
      final scheduledTime = DateTime.parse(dateTimeString).toLocal();
      final difference = scheduledTime.difference(DateTime.now());
      // Quy tắc 6 giờ
      return difference.inHours > 6;
    } catch (e) {
      return false;
    }
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
        text = 'Đã Thanh Toán';
        break;
      case 'COMPLETED':
        color = AppColors.green;
        text = 'Đã Khám'; // <-- ĐÃ SỬA
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
      padding: const EdgeInsets.only(top: 5.0),
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

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      // 'E' là viết tắt của ngày (Ví dụ: Thu, Fri)
      return DateFormat('HH:mm - E d/MM/yyyy', 'vi_VN').format(dateTime);
    } catch (e) {
      return 'Lỗi định dạng ngày giờ';
    }
  }

  void _showCancelDialog(BuildContext context, AppointmentListModel appt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Hủy'),
        content: Text(
            'Bạn có chắc chắn muốn hủy lịch hẹn với Bác sĩ ${appt.doctorFullName} vào ${_formatDateTime(appt.appointmentDateTime)} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AppointmentCubit>().cancelAppointment(appt.id);
            },
            child: const Text('Hủy Lịch Hẹn',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
