// lib/app/domain/repositories/data/data_repository.dart

import 'package:dio/dio.dart';
import 'package:hospital_booking_app/app/data/models/specialty_model.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
import 'package:hospital_booking_app/app/data/models/medical_record_model.dart';
import 'package:hospital_booking_app/app/data/models/working_schedule_model.dart'; // THÊM IMPORT
import 'package:hospital_booking_app/app/data/models/doctor_review_model.dart';

// --- Data Repository Interface ---
abstract class DataRepository {
  Future<UserModel> fetchMyProfile();
  Future<List<SpecialtyModel>> fetchAllSpecialties();
  // SỬA: Thêm email vào searchDoctors để tăng tính duy nhất khi tìm kiếm
  Future<List<DoctorSearchResultModel>> searchDoctors(
      {String? name, int? specialtyId, String? email});
  Future<List<MedicalRecordModel>> fetchMyMedicalRecords();
  Future<List<MedicalRecordModel>> searchMedicalRecords({String? query});

  // THÊM: Lấy lịch làm việc của Bác sĩ (API cần quyền Doctor)
  Future<List<WorkingScheduleModel>> fetchMyWorkingSchedules();

  // THÊM: API Review cho bệnh án
  Future<DoctorReviewModel?> fetchReviewForRecord(int recordId);
  Future<DoctorReviewModel> submitReviewForRecord(
      int recordId, int rating, String comment);
}

// --- Data Repository Implementation ---
class DataRepositoryImpl implements DataRepository {
  final Dio dio;

  DataRepositoryImpl({required this.dio});

  // ... (Các hàm fetchMyProfile, fetchAllSpecialties giữ nguyên)

  @override
  Future<UserModel> fetchMyProfile() async {
    try {
      final response = await dio.get('/api/users/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Lỗi lấy thông tin hồ sơ: ${e.message}');
    }
  }

  @override
  Future<List<SpecialtyModel>> fetchAllSpecialties() async {
    try {
      final response = await dio.get('/api/specialties');
      final List<dynamic> data = response.data;
      return data.map((json) => SpecialtyModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Lỗi lấy danh sách chuyên khoa: ${e.message}');
    }
  }

  @override
  // SỬA: Thêm email vào queryParameters
  Future<List<DoctorSearchResultModel>> searchDoctors(
      {String? name, int? specialtyId, String? email}) async {
    try {
      final response = await dio.get(
        '/api/public/doctors/search',
        queryParameters: {
          'name': name,
          'specialtyId': specialtyId,
          // SỬA: Thêm email vào Query Parameter
          'email': email,
        },
      );
      final List<dynamic> data = response.data;
      return data
          .map((json) => DoctorSearchResultModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Lỗi tìm kiếm bác sĩ: ${e.message}');
    }
  }

  @override
  Future<List<MedicalRecordModel>> fetchMyMedicalRecords() async {
    try {
      final response = await dio.get('/api/medical-records/me'); // <-- API BE
      final List<dynamic> data = response.data;
      return data.map((json) => MedicalRecordModel.fromJson(json)).toList();
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data['message'] ?? 'Lỗi lấy lịch sử khám bệnh.';
      throw Exception(errorMessage);
    }
  }

  @override
  Future<List<MedicalRecordModel>> searchMedicalRecords({String? query}) async {
    final allRecords = await fetchMyMedicalRecords();
    if (query == null || query.isEmpty) {
      return allRecords;
    }
    final lowerQuery = query.toLowerCase();
    // Filter dựa trên: Tên bác sĩ, Chuyên khoa, Chẩn đoán, Triệu chứng
    return allRecords.where((record) {
      return record.doctorName.toLowerCase().contains(lowerQuery) ||
          record.specialtyName.toLowerCase().contains(lowerQuery) ||
          record.diagnosis.toLowerCase().contains(lowerQuery) ||
          record.symptoms.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // THÊM: API lấy lịch làm việc (SỬ DỤNG EMAIL DUY NHẤT)
  @override
  Future<List<WorkingScheduleModel>> fetchMyWorkingSchedules() async {
    try {
      // BƯỚC 1: Lấy Profile để có Email (unique identifier)
      final userProfile = await fetchMyProfile();

      // BƯỚC 2: Gọi API Public Search Doctors với email (ổn định hơn tên)
      final List<DoctorSearchResultModel> doctorResults = await searchDoctors(
        email: userProfile.email,
        name: userProfile
            .fullName, // Giữ lại name để backend tìm kiếm thêm nếu cần
      );

      // BƯỚC 3: Trả về schedules
      if (doctorResults.isNotEmpty) {
        return doctorResults.first.schedules;
      }
      return [];
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data['message'] ?? 'Lỗi tải lịch làm việc.';
      throw Exception(errorMessage);
    }
  }

  // THÊM: API lấy review theo medical_record_id
  @override
  Future<DoctorReviewModel?> fetchReviewForRecord(int recordId) async {
    try {
      final response = await dio.get('/api/reviews/medical-records/$recordId');
      if (response.statusCode == 204 || response.data == null) {
        return null; // Không có review
      }
      return DoctorReviewModel.fromJson(response.data);
    } on DioException catch (e) {
      // Nếu 404 hoặc 204 => coi như chưa có review
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) {
        return null;
      }
      throw Exception(e.response?.data['message'] ?? 'Lỗi tải đánh giá.');
    }
  }

  // THÊM: API gửi/ cập nhật review theo medical_record_id
  @override
  Future<DoctorReviewModel> submitReviewForRecord(
      int recordId, int rating, String comment) async {
    try {
      final response = await dio.post(
        '/api/reviews/medical-records/$recordId',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
      return DoctorReviewModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi gửi đánh giá.');
    }
  }
}
