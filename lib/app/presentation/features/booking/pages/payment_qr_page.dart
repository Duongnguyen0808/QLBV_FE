// lib/app/presentation/features/booking/pages/payment_qr_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hospital_booking_app/app/core/constants/app_colors.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/domain/repositories/appointment/appointment_repository.dart';
import 'package:hospital_booking_app/app/presentation/main_tab_controller.dart';
import 'package:intl/intl.dart';

class PaymentQRPage extends StatefulWidget {
  final String doctorName;
  final int amount;
  final String qrUrl;
  final int transactionId;
  final int appointmentId;
  // THÊM: Thời gian hẹn để kiểm tra quy tắc hủy 6 giờ
  final String appointmentDateTime;

  const PaymentQRPage({
    super.key,
    required this.doctorName,
    required this.amount,
    required this.qrUrl,
    required this.transactionId,
    required this.appointmentId,
    required this.appointmentDateTime,
  });

  @override
  State<PaymentQRPage> createState() => _PaymentQRPageState();
}

class _PaymentQRPageState extends State<PaymentQRPage> {
  String _statusMessage = 'Đang chờ xác nhận thanh toán...';
  Color _statusColor = AppColors.orange;
  Timer? _pollingTimer;
  Timer? _countdownTimer; // <-- THÊM: Timer đếm ngược
  int _countdownSeconds = 60; // <-- THÊM: Biến đếm ngược

  static const int minimumCancellationHours = 6;

  final AppointmentRepository _appointmentRepo = sl<AppointmentRepository>();

  @override
  void initState() {
    super.initState();
    _startPolling();
    _startCountdown(); // <-- BẮT ĐẦU ĐẾM NGƯỢC
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel(); // <-- HỦY TIMER ĐẾM NGƯỢC
    super.dispose();
  }

  // --- LOGIC ĐẾM NGƯỢC ---
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          timer.cancel();
          // Kích hoạt hủy tự động khi hết giờ
          _autoCancelDueToTimeout();
        }
      });
    });
  }

  // --- LOGIC HỦY TỰ ĐỘNG KHI HẾT GIỜ (1 PHÚT) ---
  void _autoCancelDueToTimeout() async {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();

    // Đặt trạng thái thông báo
    setState(() {
      _statusMessage =
          'Hết thời gian thanh toán (1 phút). Đang hủy lịch hẹn...';
      _statusColor = AppColors.red;
    });

    try {
      // Gọi API HỦY LỊCH HẸN. Backend sẽ hủy cả Appointment và Transaction
      await _appointmentRepo.cancelAppointment(widget.appointmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lịch hẹn đã bị hủy tự động.')),
        );
      }
    } catch (e) {
      // Nếu có lỗi hủy (ví dụ: đã bị hủy bởi tác vụ Scheduled của BE), ta vẫn tiếp tục
      // hoặc hiển thị thông báo lỗi hủy nếu cần thiết.
      if (mounted) {
        // Có thể hiển thị lỗi nếu muốn
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Lỗi hủy tự động: ${e.toString().replaceFirst('Exception: ', '')}')),
        // );
      }
    }

    // Chuyển hướng về trang chủ
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainTabController()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  // LOGIC CŨ: Kiểm tra có thể hủy thủ công không (cần > 6 giờ)
  bool get _canCancelAppointment {
    try {
      final scheduledTime =
          DateTime.parse(widget.appointmentDateTime).toLocal();
      final difference = scheduledTime.difference(DateTime.now());
      return difference.inHours > minimumCancellationHours;
    } catch (e) {
      return false;
    }
  }

  void _startPolling() {
    _checkStatus();

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkStatus();
    });
  }

  void _checkStatus() async {
    try {
      final result =
          await _appointmentRepo.checkTransactionStatus(widget.transactionId);
      final status = result.status;

      if (status == 'SUCCESS') {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel(); // <-- HỦY ĐẾM NGƯỢC KHI THÀNH CÔNG
        setState(() {
          _statusMessage = 'Thanh toán THÀNH CÔNG! Đang chuyển hướng...';
          _statusColor = AppColors.green;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const MainTabController()),
              (Route<dynamic> route) => false,
            );
          }
        });
      } else if (status == 'FAILED' || status == 'CANCELLED') {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel(); // <-- HỦY ĐẾM NGƯỢC KHI BỊ HỦY BỞI BE
        setState(() {
          _statusMessage =
              'Giao dịch đã bị hủy bởi hệ thống hoặc thất bại. Vui lòng đặt lại lịch hẹn.';
          _statusColor = AppColors.red;
        });
        Future.delayed(const Duration(seconds: 3), () {
          // Trả về trang đặt lịch để người dùng chọn lại
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        // Nếu vẫn PENDING, kiểm tra lại trạng thái đếm ngược
        if (_countdownSeconds <= 0 && _statusColor != AppColors.red) {
          _autoCancelDueToTimeout();
        }
      }
    } catch (e) {
      // Lỗi Polling
      _pollingTimer?.cancel();
      _countdownTimer?.cancel();
      setState(() {
        _statusMessage = 'Lỗi kết nối kiểm tra trạng thái.';
        _statusColor = AppColors.red;
      });
    }
  }

  void _cancelAppointment() async {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang hủy giao dịch...')),
        );
      }
      await _appointmentRepo.cancelAppointment(widget.appointmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hủy giao dịch thành công.')),
        );
      }
      // Về trang đặt lịch
      Navigator.of(context).pop();
    } catch (e) {
      // HIỂN THỊ THÔNG BÁO LỖI TỪ BE
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Lỗi hủy giao dịch: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
      // Về trang đặt lịch
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final encodedQrUrl = Uri.encodeFull(widget.qrUrl);
    final bool showCancelButton = _canCancelAppointment;

    // Nút Hủy
    final cancelButton = SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _cancelAppointment,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: const BorderSide(color: AppColors.red),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Hủy Giao Dịch', style: TextStyle(fontSize: 18)),
      ),
    );

    // Thông báo không thể hủy
    final cannotCancelMessage = Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Text(
        'Không thể hủy vì lịch hẹn đã gần kề (dưới $minimumCancellationHours giờ). Vui lòng liên hệ bệnh viện.',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: AppColors.red, fontSize: 14, fontStyle: FontStyle.italic),
      ),
    );

    // THẺ HIỂN THỊ ĐẾM NGƯỢC
    final countdownWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(top: 15),
      child: Text(
        'Giao dịch sẽ hết hạn sau: ${DateFormat('mm:ss').format(DateTime.fromMillisecondsSinceEpoch(_countdownSeconds * 1000, isUtc: true))}',
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          title: const Text('Thanh Toán',
              style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Thanh toán cho Lịch hẹn Bác sĩ ${widget.doctorName}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.hintColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.network(
                          encodedQrUrl,
                          height: 300,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                            height: 300,
                            child: Center(child: Text('Lỗi tải QR Code')),
                          ),
                        ),
                      ),

                      // THẺ ĐẾM NGƯỢC
                      if (_countdownSeconds > 0) countdownWidget,

                      const SizedBox(height: 20),

                      // Thông báo trạng thái (Polling)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _statusColor),
                        ),
                        width: double.infinity,
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Mã giao dịch nội bộ: ${widget.transactionId}',
                        style:
                            TextStyle(color: AppColors.hintColor, fontSize: 12),
                      ),
                      const SizedBox(height: 30),

                      // Nút Hủy giao dịch (GỌI HÀM HỦY)
                      if (showCancelButton && _countdownSeconds > 0)
                        cancelButton
                      else if (_countdownSeconds <= 0 &&
                          _statusColor != AppColors.green)
                        cannotCancelMessage // Thay bằng thông báo khi hết giờ/hủy tự động
                      else
                        cannotCancelMessage, // Hiển thị quy tắc 6 giờ

                      // Nút Quay lại (Chỉ là nút quay lại màn hình trước, không phải nút hủy chính)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Quay lại",
                            style: TextStyle(color: AppColors.hintColor)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
