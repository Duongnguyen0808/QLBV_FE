// lib/app/presentation/features/booking/pages/appointment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/appointment_request_model.dart';
import 'package:hospital_booking_app/app/data/models/appointment_response_model.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
import 'package:hospital_booking_app/app/data/models/payment_models.dart';
import 'package:hospital_booking_app/app/domain/repositories/appointment/appointment_repository.dart';
import 'package:hospital_booking_app/app/presentation/features/booking/pages/payment_qr_page.dart';
import 'package:intl/intl.dart';

class AppointmentDetailPage extends StatefulWidget {
  final DoctorSearchResultModel doctor;
  const AppointmentDetailPage({super.key, required this.doctor});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  // Khởi tạo _selectedDate là ngày hiện tại (index 0)
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  List<String> _timeSlots = [];
  bool _isLoadingSlots = false;

  final AppointmentRepository _appointmentRepo = sl<AppointmentRepository>();

  @override
  void initState() {
    super.initState();
    // Khởi tạo locale Tiếng Việt để hiển thị ngày
    Intl.defaultLocale = 'vi_VN';
    // Load slot cho ngày hiện tại (Today)
    _fetchTimeSlots(_selectedDate);
  }

  // --- LOGIC TÍNH TOÁN SLOT DỰA TRÊN SCHEDULE TỪ API ---
  Future<void> _fetchTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _timeSlots = [];
      _selectedTimeSlot = null;
      _selectedDate = date;
    });

    final List<String> availableSlots = [];

    // Lấy tên ngày trong tuần theo chuẩn Enum (ví dụ: MONDAY)
    final String requestedDayEnglish =
        DateFormat('EEEE', 'en_US').format(date).toUpperCase();

    // Lọc lịch làm việc dựa trên tên Enum Tiếng Anh (dayOfWeekEnglish)
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
        if (parts.length < 2) continue;

        final startTimeStr = parts[0];
        final endTimeStr = parts[1];

        // Tạo DateTime giả định (vì LocalTime không có ngày)
        var currentSlot = DateTime.parse('2025-01-01 $startTimeStr:00');
        final endTime = DateTime.parse('2025-01-01 $endTimeStr:00');

        // Lặp qua các slot 30 phút
        while (currentSlot.isBefore(endTime)) {
          final slotStartTime = DateTime(date.year, date.month, date.day,
              currentSlot.hour, currentSlot.minute);
          final slotEndTime = slotStartTime.add(const Duration(minutes: 30));

          // Lấy giờ kết thúc ca làm việc thực tế trong ngày hiện tại
          final actualEndTimeOfDay = DateTime(
              date.year, date.month, date.day, endTime.hour, endTime.minute);

          // Kiểm tra 1: Slot phải trong tương lai (ít nhất 1 giờ)
          // Kiểm tra 2: Slot phải kết thúc trước hoặc đúng giờ kết thúc ca làm việc
          if (slotStartTime
                  .isAfter(DateTime.now().add(const Duration(hours: 1))) &&
              !slotEndTime.isAfter(actualEndTimeOfDay)) {
            final slotString = DateFormat('HH:mm').format(currentSlot);
            availableSlots.add(slotString);
          }

          currentSlot = currentSlot.add(const Duration(minutes: 30));
        }
      } catch (e) {
        // Log lỗi nếu định dạng giờ sai (không ảnh hưởng luồng)
      }
    }

    setState(() {
      _timeSlots = availableSlots.toSet().toList()..sort();
      _isLoadingSlots = false;
    });
  }

  // Hàm xử lý Đặt lịch và Thanh toán
  void _bookAppointment() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày và giờ khám.')),
      );
      return;
    }

    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final appointmentDateTime = '${dateString}T$_selectedTimeSlot:00+07:00';

    final request = AppointmentRequestModel(
      specialtyId: widget.doctor.specialtyId,
      doctorId: widget.doctor.doctorId,
      appointmentDateTime: appointmentDateTime,
      notes: 'Đặt lịch từ Mobile App',
    );

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tạo lịch hẹn...')),
        );
      }

      final AppointmentResponseModel newAppointment =
          await _appointmentRepo.createAppointment(request);
      final int newAppointmentId = newAppointment.id;

      final paymentRequest =
          PaymentRequestModel(appointmentId: newAppointmentId);
      final paymentResponse =
          await _appointmentRepo.createPaymentRequest(paymentRequest);

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => PaymentQRPage(
            doctorName: widget.doctor.fullName,
            amount: paymentResponse.amount,
            qrUrl: paymentResponse.paymentUrl,
            transactionId: paymentResponse.transactionId,
            appointmentId: newAppointmentId,
            appointmentDateTime: appointmentDateTime,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Lỗi đặt lịch: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Đặt Lịch Khám'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorHeader(widget.doctor),
            const SizedBox(height: 20),

            const Text(
              'Thông tin chi tiết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bác sĩ ${widget.doctor.fullName} chuyên ${widget.doctor.specialtyName} đã được đào tạo chuyên sâu và có kinh nghiệm nhiều năm trong lĩnh vực của mình.',
              style: TextStyle(color: AppColors.textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 30),

            // CHỌN NGÀY
            _buildDateSelector(),
            const SizedBox(height: 30),

            // CHỌN GIỜ (dựa trên ca làm việc thực)
            _buildTimeSlotSelector(),
            const SizedBox(height: 50),

            // NÚT ĐẶT LỊCH
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Xác nhận và Thanh toán',
                    style: TextStyle(fontSize: 18, color: AppColors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorHeader(DoctorSearchResultModel doc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: AppColors.hintColor.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              doc.avatarUrl ?? 'assets/images/profile_placeholder.png',
              height: 100,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fullName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  // Hiển thị Chuyên khoa của Bác sĩ
                  doc.specialtyName,
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phí khám',
                      style: TextStyle(color: AppColors.hintColor),
                    ),
                    Flexible(
                      child: Text(
                        '5.000 VND',
                        style: TextStyle(
                            color: AppColors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 20, color: AppColors.hintColor),
              const SizedBox(height: 10),
              Icon(Icons.phone_outlined, size: 20, color: AppColors.hintColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    // SỬA: Bắt đầu từ ngày hôm nay (index 0 là today)
    final dates = List.generate(7, (i) => today.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn Ngày',
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
