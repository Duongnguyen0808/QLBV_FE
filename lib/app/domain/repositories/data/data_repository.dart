// lib/app/domain/repositories/data/data_repository.dart

import 'package:dio/dio.dart';
import 'package:hospital_booking_app/app/data/models/specialty_model.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
import 'package:hospital_booking_app/app/data/models/medical_record_model.dart';
import 'package:hospital_booking_app/app/data/models/working_schedule_model.dart'; // THÊM IMPORT

// --- Data Repository Interface ---
abstract class DataRepository {
  Future<UserModel> fetchMyProfile();
  Future<List<SpecialtyModel>> fetchAllSpecialties();
  Future<List<DoctorSearchResultModel>> searchDoctors(
      {String? name, int? specialtyId});
  Future<List<MedicalRecordModel>> fetchMyMedicalRecords();
  Future<List<MedicalRecordModel>> searchMedicalRecords({String? query});

  // THÊM: Lấy lịch làm việc của Bác sĩ (API cần quyền Doctor)
  Future<List<WorkingScheduleModel>> fetchMyWorkingSchedules();
}

// --- Data Repository Implementation ---
class DataRepositoryImpl implements DataRepository {
  final Dio dio;

  DataRepositoryImpl({required this.dio});

  // ... (Các hàm fetchMyProfile, fetchAllSpecialties, searchDoctors, fetchMyMedicalRecords giữ nguyên)

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
  Future<List<DoctorSearchResultModel>> searchDoctors(
      {String? name, int? specialtyId}) async {
    try {
      final response = await dio.get(
        '/api/public/doctors/search',
        queryParameters: {
          'name': name,
          'specialtyId': specialtyId,
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

  // THÊM: API lấy lịch làm việc (SỬ DỤNG LẠI API TÌM KIẾM THEO BÁC SĨ VÀ NGÀY)
  // LƯU Ý: Backend không có API riêng cho Doctor lấy Working Schedule của chính mình
  // -> Ta sẽ dùng API Search Doctors /api/public/doctors/search và tự lọc ra lịch làm việc của mình
  @override
  Future<List<WorkingScheduleModel>> fetchMyWorkingSchedules() async {
    try {
      // BƯỚC 1: Lấy Profile để có Doctor ID
      final userProfile = await fetchMyProfile();

      // BƯỚC 2: Gọi API Public Search Doctors (Endpoint này trả về schedule trong DoctorSearchResultDTO)
      final response =
          await dio.get('/api/public/doctors/search', queryParameters: {
        // Chỉ tìm kiếm theo tên/email của chính mình để tránh lỗi
        'name': userProfile.fullName,
      });

      final List<dynamic> data = response.data;

      // BƯỚC 3: Tìm DoctorSearchResultModel có ID trùng với Profile hiện tại
      final List<DoctorSearchResultModel> doctorResults = data
          .map((json) => DoctorSearchResultModel.fromJson(json))
          .where((doc) =>
              doc.fullName == userProfile.fullName) // Giả định tên duy nhất
          .toList();

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
}
