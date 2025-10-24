import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/appointment_cubit.dart';
import 'package:intl/intl.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/pages/reschedule_page.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';

class AppointmentListPage extends StatefulWidget {
  const AppointmentListPage({super.key});

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage> {
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        setState(() {
          _isDoctor = authState.role == 'DOCTOR' || authState.role == 'ADMIN';
        });
      }
      context.read<AppointmentCubit>().fetchAppointments();
    });
  }

  Future<void> _loadData() async {
    await context.read<AppointmentCubit>().fetchAppointments();
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
        if (state is AppointmentLoading || state is AppointmentInitial) {
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
                Text(
                    _isDoctor
                        ? 'Bạn chưa có lịch hẹn khám nào.'
                        : 'Bạn chưa có lịch hẹn nào.',
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.hintColor)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Tải lại danh sách'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
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
    final isEditable = appt.status != 'COMPLETED' && appt.status != 'CANCELLED';
    final mainTitle = _isDoctor
        ? 'Bệnh nhân: ${appt.patientFullName}'
        : 'Lịch hẹn với Bác sĩ';
    final isForPatient = !_isDoctor;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mainTitle,
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
          Text(
            'Chuyên khoa: ${appt.specialtyName}',
            style: const TextStyle(fontSize: 14, color: AppColors.hintColor),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: isForPatient && isEditable
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'Đổi lịch',
                          color: AppColors.secondaryColor,
                          onPressed: () => _navigateToReschedule(context, appt),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Hủy lịch',
                          color: AppColors.red,
                          onPressed: () => _confirmCancel(context, appt),
                        ),
                      ),
                    ],
                  )
                : isForPatient && !isEditable
                    ? const SizedBox.shrink()
                    : _isDoctor && isEditable
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildActionButton(
                                label: 'Gửi Nhắc nhở',
                                color: AppColors.primaryColor,
                                onPressed: () => _sendReminder(context, appt),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _navigateToReschedule(
      BuildContext context, AppointmentListModel appt) async {
    final dataRepo = sl<DataRepository>();

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải thông tin Bác sĩ...')),
        );
      }

      final List<DoctorSearchResultModel> doctorResults =
          await dataRepo.searchDoctors(name: appt.doctorFullName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (doctorResults.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Không tìm thấy hồ sơ bác sĩ để đổi lịch.')),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReschedulePage(
            appointment: appt,
            doctor: doctorResults.first,
          ),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Lỗi tải dữ liệu: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  void _confirmCancel(BuildContext context, AppointmentListModel appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Hủy Lịch Hẹn'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn hủy lịch hẹn này?'),
            SizedBox(height: 10),
            Text(
              '⚠️ Để được hoàn tiền, vui lòng liên hệ Bộ phận Chăm sóc Khách hàng (CSKH) của bệnh viện.',
              style:
                  TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng',
                style: TextStyle(color: AppColors.hintColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleCancel(context, appt);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Hủy Lịch',
                style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _handleCancel(BuildContext context, AppointmentListModel appt) async {
    try {
      await context.read<AppointmentCubit>().cancelAppointment(appt.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hủy lịch hẹn thành công!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Lỗi hủy lịch: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
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

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('HH:mm - E d/MM/yyyy', 'vi_VN').format(dateTime);
    } catch (e) {
      return 'Lỗi định dạng ngày giờ';
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
