// ignore_for_file: empty_catches, unused_catch_clause

import 'package:dio/dio.dart';
import 'package:hospital_booking_app/app/data/models/appointment_request_model.dart';
import 'package:hospital_booking_app/app/data/models/payment_models.dart';
import 'package:hospital_booking_app/app/data/models/appointment_response_model.dart';

abstract class AppointmentRepository {
  // 1. Tạo lịch hẹn (POST /api/appointments)
  Future<AppointmentResponseModel> createAppointment(
      AppointmentRequestModel request);

  // 2. Khởi tạo thanh toán (POST /api/payments/create-request)
  Future<PaymentResponseModel> createPaymentRequest(
      PaymentRequestModel request);

  // 3. Kiểm tra trạng thái giao dịch (GET /api/payments/{id}/status)
  Future<TransactionStatusResponseModel> checkTransactionStatus(
      int transactionId);

  // 4. MÔ PHỎNG CALLBACK
  Future<void> simulateSuccessfulPayment(int transactionId);

  // 5. Lấy lịch làm việc có sẵn của bác sĩ (Mô phỏng/TBD: GET /api/doctors/available)
  Future<List<String>> fetchAvailableTimeSlots(int doctorId, String date);

  // THÊM KHAI BÁO NÀY (Đã thiếu)
  Future<void> cancelAppointment(int appointmentId);
}

class AppointmentRepositoryImpl implements AppointmentRepository {
  final Dio dio;

  AppointmentRepositoryImpl({required this.dio});

  // API 1: Tạo lịch hẹn
  @override
  Future<AppointmentResponseModel> createAppointment(
      AppointmentRequestModel request) async {
    try {
      final response = await dio.post(
        '/api/appointments',
        data: request.toJson(),
      );
      return AppointmentResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data['message'] ?? 'Lỗi tạo lịch hẹn không xác định.';
      throw Exception(errorMessage);
    }
  }

  // API 2: Khởi tạo thanh toán QR
  @override
  Future<PaymentResponseModel> createPaymentRequest(
      PaymentRequestModel request) async {
    try {
      final response = await dio.post(
        '/api/payments/create-request',
        data: request.toJson(),
      );
      final paymentResponse = PaymentResponseModel.fromJson(response.data);
      return paymentResponse;
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data['message'] ?? 'Lỗi khởi tạo thanh toán.';
      throw Exception(errorMessage);
    }
  }

  // API 3: Kiểm tra trạng thái giao dịch
  @override
  Future<TransactionStatusResponseModel> checkTransactionStatus(
      int transactionId) async {
    try {
      final response = await dio.get('/api/payments/$transactionId/status');
      return TransactionStatusResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Lỗi kiểm tra trạng thái giao dịch: ${e.message}');
    }
  }

  // API MÔ PHỎNG: Giữ lại
  @override
  Future<void> simulateSuccessfulPayment(int transactionId) async {
    try {
      await dio.get(
        '/api/payments/callback',
        queryParameters: {
          'txnId': transactionId,
          'status': 'SUCCESS',
          'transactionCode':
              'SIMULATED_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    } on DioException catch (e) {}
  }

  @override
  Future<void> cancelAppointment(int appointmentId) async {
    try {
      // Gọi API hủy lịch hẹn (PUT /api/appointments/{id}/cancel)
      await dio.put('/api/appointments/$appointmentId/cancel');
      // Backend sẽ tự động xử lý việc hủy giao dịch PENDING liên quan
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data['message'] ?? 'Lỗi hủy lịch hẹn không xác định.';
      throw Exception(errorMessage);
    }
  }

  // API 5: Lấy Slot Trống (Mô phỏng)
  @override
  Future<List<String>> fetchAvailableTimeSlots(
      int doctorId, String date) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30'
    ];
  }
}
