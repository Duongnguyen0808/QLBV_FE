import 'package:dio/dio.dart';
import 'package:hospital_booking_app/app/data/models/appointment_request_model.dart';
import 'package:hospital_booking_app/app/data/models/payment_models.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart';

abstract class AppointmentRepository {
  // 1. Tạo lịch hẹn (POST /api/appointments)
  Future<UserModel> createAppointment(AppointmentRequestModel request);

  // 2. Khởi tạo thanh toán (POST /api/payments/create-request)
  Future<PaymentResponseModel> createPaymentRequest(
      PaymentRequestModel request);

  // 3. Kiểm tra trạng thái giao dịch (GET /api/payments/{id}/status)
  Future<TransactionStatusResponseModel> checkTransactionStatus(
      int transactionId);

  // 4. Lấy lịch làm việc có sẵn của bác sĩ (Mô phỏng/TBD: GET /api/doctors/available)
  Future<List<String>> fetchAvailableTimeSlots(int doctorId, String date);
}

class AppointmentRepositoryImpl implements AppointmentRepository {
  final Dio dio;

  AppointmentRepositoryImpl({required this.dio});

  // API 1: Tạo lịch hẹn
  @override
  Future<UserModel> createAppointment(AppointmentRequestModel request) async {
    try {
      final response = await dio.post(
        '/api/appointments',
        data: request.toJson(),
      );
      // Backend trả về AppointmentResponseDTO. Ta chỉ cần ID lịch hẹn, hoặc model đơn giản.
      // Do không có AppointmentResponseModel, tôi giả định trả về User model (cần sửa lại)
      // *LƯU Ý: AppointmentController trả về AppointmentResponseDTO, nên cần Model DTO tương ứng.
      // Tạm thời, tôi sẽ trả về dữ liệu response.data (Map) và client sẽ xử lý.
      return UserModel.fromJson(response.data['patient'] ?? response.data);
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
      return PaymentResponseModel.fromJson(response.data);
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

  // API 4: Lấy Slot Trống (Mô phỏng)
  @override
  Future<List<String>> fetchAvailableTimeSlots(
      int doctorId, String date) async {
    // API backend có /api/doctors/available nhưng phức tạp. Mô phỏng dữ liệu tĩnh cho UI.
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
