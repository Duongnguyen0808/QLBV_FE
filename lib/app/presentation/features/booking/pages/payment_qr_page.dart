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

  const PaymentQRPage({
    super.key,
    required this.doctorName,
    required this.amount,
    required this.qrUrl,
    required this.transactionId,
  });

  @override
  State<PaymentQRPage> createState() => _PaymentQRPageState();
}

class _PaymentQRPageState extends State<PaymentQRPage> {
  String _statusMessage = 'Đang chờ xác nhận thanh toán...';
  Color _statusColor = AppColors.orange;
  Timer? _pollingTimer;

  final AppointmentRepository _appointmentRepo = sl<AppointmentRepository>();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Chạy lần đầu tiên
    _checkStatus();

    // Polling mỗi 3 giây
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
        setState(() {
          _statusMessage = 'Thanh toán THÀNH CÔNG! Đang chuyển hướng...';
          _statusColor = AppColors.green;
        });
        // Chờ 2 giây rồi chuyển về trang chủ (hoặc trang lịch hẹn)
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainTabController()),
            (Route<dynamic> route) => false,
          );
        });
      } else if (status == 'FAILED') {
        _pollingTimer?.cancel();
        setState(() {
          _statusMessage = 'Thanh toán THẤT BẠI. Vui lòng thử lại.';
          _statusColor = AppColors.red;
        });
      }
      // Nếu là PENDING, giữ nguyên trạng thái
    } catch (e) {
      _pollingTimer?.cancel();
      setState(() {
        _statusMessage = 'Lỗi kết nối kiểm tra trạng thái.';
        _statusColor = AppColors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Ngăn chặn người dùng quay lại khi đang thanh toán
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          title: const Text('Thanh Toán',
              style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          automaticallyImplyLeading:
              false, // Bỏ nút back khi ở màn hình thanh toán
        ),
        body: Column(
          children: [
            // Phần Header hiển thị số tiền
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                _currencyFormat.format(widget.amount) + ' VND',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

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
                      // Tiêu đề thanh toán
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

                      // QR Code (Sử dụng Image.network)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.hintColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.network(
                          widget.qrUrl,
                          height: 250,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                            height: 250,
                            child: Center(child: Text('Lỗi tải QR Code')),
                          ),
                        ),
                      ),
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

                      // Nút Hủy giao dịch (Cho phép quay về màn hình trước khi thanh toán thành công)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _pollingTimer?.cancel();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Hủy Giao Dịch',
                              style: TextStyle(fontSize: 18)),
                        ),
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
