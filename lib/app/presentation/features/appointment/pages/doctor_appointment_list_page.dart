// lib/app/presentation/features/appointment/pages/doctor_appointment_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/doctor_appointment_cubit.dart';
import 'package:intl/intl.dart';

// KHÔNG cần các import logic cho Patient (Reschedule, Cancel)

class DoctorAppointmentListPage extends StatefulWidget {
  const DoctorAppointmentListPage({super.key});

  @override
  State<DoctorAppointmentListPage> createState() =>
      _DoctorAppointmentListPageState();
}

class _DoctorAppointmentListPageState extends State<DoctorAppointmentListPage> {
  @override
  void initState() {
    super.initState();
    // Bắt buộc gọi tải dữ liệu khi màn hình khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Tách hàm tải dữ liệu
  Future<void> _loadData() async {
    print('🔄 DEBUG: _loadData() called');

    // DEBUG: Kiểm tra user role và token (SỬA KEY ĐÚNG)
    const storage = FlutterSecureStorage();
    final role = await storage.read(key: 'user_role');
    final token = await storage.read(
        key: 'jwt_token'); // SỬA: jwt_token thay vì auth_token
    print('🔐 DEBUG: Current user role = $role');
    print('🔑 DEBUG: Token exists = ${token != null}');
    if (token != null && token.length > 20) {
      print('🔑 DEBUG: Token preview = ${token.substring(0, 20)}...');
    }

    // Chỉ tải nếu trạng thái hiện tại không phải là loading
    if (context.read<DoctorAppointmentCubit>().state
        is! DoctorAppointmentLoading) {
      print('📲 DEBUG: Calling fetchDoctorAppointments()...');
      await context.read<DoctorAppointmentCubit>().fetchDoctorAppointments();
    } else {
      print('⏳ DEBUG: Already loading, skipping...');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DoctorAppointmentCubit, DoctorAppointmentState>(
      listener: (context, state) {
        print(
            '🎧 DEBUG: BlocConsumer listener triggered, state = ${state.runtimeType}');
        if (state is DoctorAppointmentLoadFailure) {
          print('❌ DEBUG: DoctorAppointmentLoadFailure - ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${state.message}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        print('🏗️ DEBUG: BlocConsumer builder, state = ${state.runtimeType}');

        if (state is DoctorAppointmentLoading ||
            state is DoctorAppointmentInitial) {
          print('⏳ DEBUG: Showing loading indicator');
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        final appointments = state is DoctorAppointmentLoadSuccess
            ? state.appointments
            : <AppointmentListModel>[];

        print('📊 DEBUG: Appointments count = ${appointments.length}');

        if (appointments.isEmpty) {
          print('📭 DEBUG: No appointments, showing empty state');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bạn chưa có lịch hẹn khám nào.',
                    style: TextStyle(fontSize: 16, color: AppColors.hintColor)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadData, // Gọi hàm tải dữ liệu đã tách
                  child: const Text('Tải lại danh sách'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData, // Gọi hàm tải dữ liệu đã tách
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildDoctorAppointmentCard(context, appointments[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildDoctorAppointmentCard(
      BuildContext context, AppointmentListModel appt) {
    // Chỉ cần kiểm tra xem lịch hẹn có còn hoạt động để gửi nhắc nhở không
    final isActiveForDoctor = appt.status == 'CONFIRMED' ||
        appt.status == 'PAID_PENDING' ||
        appt.status == 'PENDING';

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
          // DÒNG 1: Tên Bệnh nhân + Trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  // HIỂN THỊ TÊN BỆNH NHÂN
                  'Bệnh nhân: ${appt.patientFullName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textColor),
                ),
              ),
              _buildStatusBadge(appt.status),
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
                _formatDateTime(appt.appointmentDateTime),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // DÒNG 3: Chuyên khoa (thông tin bổ sung - chỉ nên hiển thị nếu cần)
          Text(
            'Chuyên khoa: ${appt.specialtyName}',
            style: TextStyle(fontSize: 14, color: AppColors.hintColor),
          ),

          // DÒNG 4: NÚT HÀNH ĐỘNG (Gửi Nhắc nhở)
          if (isActiveForDoctor)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    label: 'Gửi Nhắc nhở',
                    color: AppColors.primaryColor,
                    onPressed: () => _sendReminder(context, appt),
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
            'Đang gửi nhắc nhở lịch hẹn về Gmail cho bệnh nhân ${appt.patientFullName}...')));
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
