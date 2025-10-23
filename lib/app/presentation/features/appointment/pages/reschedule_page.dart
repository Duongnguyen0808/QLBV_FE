// lib/app/presentation/features/appointment/pages/reschedule_page.dart

// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/appointment/bloc/appointment_cubit.dart';
import 'package:intl/intl.dart';

class ReschedulePage extends StatefulWidget {
  final AppointmentListModel appointment;
  final DoctorSearchResultModel doctor;

  const ReschedulePage({
    super.key,
    required this.appointment,
    required this.doctor,
  });

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  // SỬA: Khởi tạo _selectedDate là ngày hiện tại
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  List<String> _timeSlots = [];
  bool _isLoadingSlots = false;

  final DataRepository _dataRepo = sl<DataRepository>();

  // Logic xác định liệu bệnh nhân có cần thanh toán lại sau khi đổi lịch không
  late bool _needsRepayment;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'vi_VN';

    // Logic xác định cần thanh toán lại hay không
    _needsRepayment = !(widget.appointment.status == 'CONFIRMED' ||
        widget.appointment.status == 'COMPLETED');

    // Khởi tạo ngày đã chọn là ngày hôm nay, TRỪ KHI lịch hẹn cũ là ngày sau hôm nay (và ta muốn chọn nó)
    try {
      final oldDate =
          DateTime.parse(widget.appointment.appointmentDateTime).toLocal();
      // Giữ lại ngày cũ nếu nó vẫn trong tương lai (sau ngày hiện tại)
      if (oldDate.isAfter(DateTime.now().subtract(const Duration(hours: 1)))) {
        _selectedDate = oldDate;
      }
    } catch (_) {}
    _fetchTimeSlots(_selectedDate);
  }

  Future<void> _fetchTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _timeSlots = [];
      _selectedTimeSlot = null;
      _selectedDate = date;
    });

    final List<String> availableSlots = [];
    final String requestedDayEnglish =
        DateFormat('EEEE', 'en_US').format(date).toUpperCase();

    // Lấy schedule từ model DoctorSearchResultModel (đã được truyền)
    final schedulesForDay = widget.doctor.schedules
        .where((s) => s.dayOfWeekEnglish == requestedDayEnglish)
        .toList();

    if (schedulesForDay.isEmpty) {
      setState(() {
        _isLoadingSlots = false;
      });
      return;
    }

    for (var schedule in schedulesForDay) {
      try {
        final parts = schedule.timeSlot.split(' - ');
        final startTimeStr = parts[0];
        final endTimeStr = parts[1];

        var currentSlot = DateTime.parse('2025-01-01 $startTimeStr:00');
        final endTime = DateTime.parse('2025-01-01 $endTimeStr:00');

        while (currentSlot.isBefore(endTime)) {
          final slotStartTime = DateTime(date.year, date.month, date.day,
              currentSlot.hour, currentSlot.minute);
          final slotEndTime = slotStartTime.add(const Duration(minutes: 30));

          final actualEndTimeOfDay = DateTime(
              date.year, date.month, date.day, endTime.hour, endTime.minute);

          // Kiểm tra: Slot phải trong tương lai (ít nhất 1 giờ) và nằm trong ca làm việc
          if (slotStartTime
                  .isAfter(DateTime.now().add(const Duration(hours: 1))) &&
              !slotEndTime.isAfter(actualEndTimeOfDay)) {
            final slotString = DateFormat('HH:mm').format(currentSlot);
            availableSlots.add(slotString);
          }

          currentSlot = currentSlot.add(const Duration(minutes: 30));
        }
      } catch (e) {
        // Log lỗi
      }
    }

    setState(() {
      _timeSlots = availableSlots.toSet().toList()..sort();
      _isLoadingSlots = false;
    });
  }

  void _submitReschedule() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ khám mới.')),
      );
      return;
    }

    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final newAppointmentDateTime = '${dateString}T$_selectedTimeSlot:00+07:00';

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang xử lý đổi lịch...')),
        );
      }

      await context.read<AppointmentCubit>().rescheduleAppointment(
            widget.appointment.id,
            newAppointmentDateTime,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // SỬA: Cập nhật thông báo chính xác
        String message = _needsRepayment
            ? 'Đổi lịch thành công! Lịch hẹn đã chuyển về Chờ Thanh Toán.'
            : 'Đổi lịch thành công! Lịch hẹn đã được XÁC NHẬN lại.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.green,
          ),
        );
        // Trở về trang danh sách lịch hẹn
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Lỗi đổi lịch: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Đổi Lịch Khám',
            style: TextStyle(color: AppColors.primaryColor)),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCurrentAppointmentInfo(),
            const SizedBox(height: 20),

            // CHỌN NGÀY
            _buildDateSelector(),
            const SizedBox(height: 30),

            // CHỌN GIỜ (dựa trên ca làm việc thực)
            _buildTimeSlotSelector(),
            const SizedBox(height: 50),

            // NÚT XÁC NHẬN ĐỔI LỊCH
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReschedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Xác nhận Đổi Lịch',
                    style: TextStyle(fontSize: 18, color: AppColors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAppointmentInfo() {
    final currentDateTime = DateFormat('HH:mm - EEE dd/MM/yyyy', 'vi_VN')
        .format(
            DateTime.parse(widget.appointment.appointmentDateTime).toLocal());

    // Cập nhật thông báo dựa trên _needsRepayment
    String repaymentNote = _needsRepayment
        ? 'LƯU Ý: Đổi lịch sẽ đặt lại trạng thái về "Chờ Thanh Toán" và bạn cần thanh toán lại.'
        : 'LƯU Ý: Lịch hẹn đã được thanh toán. Sau khi đổi lịch, trạng thái sẽ là "Đã Xác Nhận" (KHÔNG cần thanh toán lại).';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: AppColors.hintColor.withOpacity(0.1), blurRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lịch hẹn hiện tại',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Text('Bác sĩ: ${widget.doctor.fullName}',
              style: TextStyle(color: AppColors.textColor)),
          Text('Chuyên khoa: ${widget.doctor.specialtyName}',
              style: TextStyle(color: AppColors.hintColor)),
          const SizedBox(height: 5),
          Text('Thời gian cũ: $currentDateTime',
              style:
                  TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(repaymentNote,
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _needsRepayment ? AppColors.red : AppColors.green)),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    // SỬA: TẠO 7 NGÀY TÍNH TỪ NGÀY HIỆN TẠI (index 0 là today)
    final dates = List.generate(7, (i) => today.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn Ngày Mới',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];

              final isSelected = DateFormat('dd').format(date) ==
                  DateFormat('dd').format(_selectedDate);

              String dayNameVietnamese =
                  DateFormat('EEE', 'vi_VN').format(date);

              // SỬA: Hiển thị "H.Nay" cho ngày đầu tiên
              if (index == 0) {
                dayNameVietnamese = 'H.Nay';
              } else if (dayNameVietnamese.contains('CN')) {
                dayNameVietnamese = 'CN';
              } else if (dayNameVietnamese.contains('Th')) {
                dayNameVietnamese = dayNameVietnamese.replaceFirst('Th', 'Th ');
              }

              return GestureDetector(
                onTap: () => _fetchTimeSlots(date),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primaryColor : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNameVietnamese,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.hintColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Giờ Khám Trống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoadingSlots)
          const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor))
        else if (_timeSlots.isEmpty)
          Center(
              child: Text(
            'Không có ca làm việc hợp lệ hoặc còn trống trong ngày này.',
            style: TextStyle(color: AppColors.red),
          ))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              return ChoiceChip(
                label: Text(slot),
                selected: isSelected,
                selectedColor: AppColors.primaryColor,
                backgroundColor: AppColors.white,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textColor,
                  fontWeight: FontWeight.w500,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedTimeSlot = selected ? slot : null;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
