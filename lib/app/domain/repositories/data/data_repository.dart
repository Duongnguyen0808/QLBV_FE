// lib/app/domain/repositories/data/data_repository.dart

import 'package:dio/dio.dart';
import 'package:hospital_booking_app/app/data/models/specialty_model.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
import 'package:hospital_booking_app/app/data/models/medical_record_model.dart';

// --- Data Repository Interface ---
abstract class DataRepository {
  Future<UserModel> fetchMyProfile();
  Future<List<SpecialtyModel>> fetchAllSpecialties();
  Future<List<DoctorSearchResultModel>> searchDoctors(
      {String? name, int? specialtyId});
  Future<List<MedicalRecordModel>> fetchMyMedicalRecords();
}

// --- Data Repository Implementation ---
class DataRepositoryImpl implements DataRepository {
  final Dio dio;

  DataRepositoryImpl({required this.dio});

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

  // API MỚI: Lấy danh sách bệnh án
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
}
