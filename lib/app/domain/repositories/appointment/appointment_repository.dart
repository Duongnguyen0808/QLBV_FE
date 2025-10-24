// lib/app/domain/repositories/appointment/appointment_repository.dart

// ignore_for_file: empty_catches, unused_catch_clause

import 'package:dio/dio.dart';
import 'package:hospital_booking_app/app/data/models/appointment_request_model.dart';
import 'package:hospital_booking_app/app/data/models/payment_models.dart';
import 'package:hospital_booking_app/app/data/models/appointment_response_model.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_cubit.dart';
import 'package:hospital_booking_app/app/presentation/features/auth/bloc/auth_state.dart';

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

  // 4. LẤY DANH SÁCH LỊCH HẸN CỦA TÔI (Cho cả Bệnh nhân và Bác sĩ)
  Future<List<AppointmentListModel>> fetchMyAppointments();

  // 4B. LẤY DANH SÁCH LỊCH HẸN CHO BÁC SĨ (Gọi trực tiếp API bác sĩ)
  Future<List<AppointmentListModel>> fetchDoctorAppointments();

  // 4C. LẤY DANH SÁCH LỊCH HẸN CHO BỆNH NHÂN (Gọi trực tiếp API bệnh nhân)
  Future<List<AppointmentListModel>> fetchPatientAppointments();

  // 5. ĐỔI LỊCH (RESCHEDULE)
  Future<AppointmentResponseModel> rescheduleAppointment(
      int appointmentId, String newDateTime);

  // 6. MÔ PHỎNG CALLBACK
  Future<void> simulateSuccessfulPayment(int transactionId);

  // 7. Lấy lịch làm việc có sẵn của bác sĩ (Mô phỏng/TBD: GET /api/doctors/available)
  Future<List<String>> fetchAvailableTimeSlots(int doctorId, String date);

  // 8. Hủy lịch hẹn
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

  // API 4: Lấy danh sách lịch hẹn (QUAN TRỌNG: Đã sửa logic phân biệt vai trò)
  @override
  Future<List<AppointmentListModel>> fetchMyAppointments() async {
    // Sửa lỗi: Lấy vai trò ngay lập tức từ AuthCubit (Giả định nó luôn có dữ liệu sau đăng nhập)
    final authCubit = sl<AuthCubit>();
    String endpoint;

    // Phải kiểm tra trạng thái đã xác thực và lấy vai trò
    final authState = authCubit.state;
    bool isDoctor = false;
    if (authState is AuthAuthenticated) {
      // SỬA: Hỗ trợ cả DOCTOR và ROLE_DOCTOR
      final role = authState.role.toUpperCase();
      isDoctor = role == 'DOCTOR' ||
          role == 'ROLE_DOCTOR' ||
          role == 'ADMIN' ||
          role == 'ROLE_ADMIN';
      print('🔍 DEBUG: User role = ${authState.role}, isDoctor = $isDoctor');
    } else {
      print('❌ DEBUG: User is NOT authenticated! State = $authState');
    }

    // PHÂN BIỆT API DỰA TRÊN VAI TRÒ
    if (isDoctor) {
      endpoint = '/api/doctors/me/appointments'; // API Bác sĩ
    } else {
      endpoint = '/api/appointments/me'; // API Bệnh nhân
    }

    print('📡 DEBUG: Calling API endpoint: $endpoint');

    try {
      final response = await dio.get(endpoint);
      print('✅ DEBUG: API Response status = ${response.statusCode}');
      print('📦 DEBUG: API Response data type = ${response.data.runtimeType}');
      print('📦 DEBUG: API Response data = ${response.data}');

      final List<dynamic> data = response.data;
      print('📊 DEBUG: Total appointments received = ${data.length}');

      final appointments =
          data.map((json) => AppointmentListModel.fromJson(json)).toList();
      print('✅ DEBUG: Successfully parsed ${appointments.length} appointments');

      return appointments;
    } on DioException catch (e) {
      print('❌ DEBUG: DioException occurred!');
      print('❌ DEBUG: Status code = ${e.response?.statusCode}');
      print('❌ DEBUG: Error message = ${e.response?.data}');

      String errorMessage =
          e.response?.data['message'] ?? 'Lỗi lấy danh sách lịch hẹn.';
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ DEBUG: Unexpected error = $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // API 4B: Lấy danh sách lịch hẹn cho BÁC SĨ (Gọi trực tiếp /api/doctors/me/appointments)
  @override
  Future<List<AppointmentListModel>> fetchDoctorAppointments() async {
    const endpoint = '/api/doctors/me/appointments';
    print('🔵 DEBUG fetchDoctorAppointments: Calling $endpoint');

    try {
      final response = await dio.get(endpoint);
      print('✅ DEBUG fetchDoctorAppointments: Status = ${response.statusCode}');
      print(
          '📦 DEBUG fetchDoctorAppointments: Data length = ${(response.data as List).length}');

      final List<dynamic> data = response.data;
      final appointments =
          data.map((json) => AppointmentListModel.fromJson(json)).toList();

      return appointments;
    } on DioException catch (e) {
      print('❌ DEBUG fetchDoctorAppointments: Error = ${e.response?.data}');
      String errorMessage =
          e.response?.data['message'] ?? 'Lỗi lấy danh sách lịch hẹn bác sĩ.';
      throw Exception(errorMessage);
    }
  }

  // API 4C: Lấy danh sách lịch hẹn cho BỆNH NHÂN (Gọi trực tiếp /api/appointments/me)
  @override
  Future<List<AppointmentListModel>> fetchPatientAppointments() async {
    const endpoint = '/api/appointments/me';
    print('🟢 DEBUG fetchPatientAppointments: Calling $endpoint');

    try {
      final response = await dio.get(endpoint);
      print(
          '✅ DEBUG fetchPatientAppointments: Status = ${response.statusCode}');
      print(
          '📦 DEBUG fetchPatientAppointments: Data length = ${(response.data as List).length}');

      final List<dynamic> data = response.data;
      final appointments =
          data.map((json) => AppointmentListModel.fromJson(json)).toList();

      return appointments;
    } on DioException catch (e) {
      print('❌ DEBUG fetchPatientAppointments: Error = ${e.response?.data}');
      String errorMessage = e.response?.data['message'] ??
          'Lỗi lấy danh sách lịch hẹn bệnh nhân.';
      throw Exception(errorMessage);
    }
  }

  // API MỚI: Đổi lịch (Reschedule)
  @override
  Future<AppointmentResponseModel> rescheduleAppointment(
      int appointmentId, String newDateTime) async {
    try {
      final response = await dio.put(
        '/api/appointments/$appointmentId/reschedule',
        data: {'newAppointmentDateTime': newDateTime},
      );
      return AppointmentResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data['message'] ?? 'Lỗi đổi lịch không xác định.';
      throw Exception(errorMessage);
    }
  }

  // ... (các hàm khác giữ nguyên)

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
