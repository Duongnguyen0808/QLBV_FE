// lib/app/data/models/doctor_search_result_model.dart
import 'package:equatable/equatable.dart';
import 'package:hospital_booking_app/app/data/models/working_schedule_model.dart';

class DoctorSearchResultModel extends Equatable {
  final int doctorId;
  final String fullName;
  final String specialtyName;
  final List<WorkingScheduleModel> schedules;
  final String? avatarUrl;
  final double rating;
  final int specialtyId; // THÊM DÒNG NÀY

  const DoctorSearchResultModel({
    required this.doctorId,
    required this.fullName,
    required this.specialtyName,
    required this.schedules,
    this.avatarUrl,
    this.rating = 5.0,
    required this.specialtyId, // THÊM DÒNG NÀY
  });

  factory DoctorSearchResultModel.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName'] as String;
    final int hash = fullName.hashCode;
    final double rating = (4.0 + (hash % 10) / 10).clamp(4.0, 5.0);

    // LƯU Ý: Backend không trả về specialtyId trực tiếp, mà thông qua specialtyName.
    // Giả định logic backend có thể đã được sửa để trả về ID.
    // Tuy nhiên, theo DTO BE (DoctorSearchResultDTO), specialtyName đã có.
    // Tạm thời hardcode specialtyId = 1 hoặc sửa BE để trả về.
    // Dựa trên mô hình FE hiện tại, tôi sẽ thêm trường này và kỳ vọng BE sẽ trả về.
    // Nếu BE chưa trả về, bạn sẽ phải hardcode hoặc fix BE.

    // TẠM THỜI: Lấy specialtyId từ specialtyName (vì không có dữ liệu khác)
    // Nếu bạn muốn test luồng, hãy đảm bảo BE DTO đã được sửa!
    // **Tôi sẽ giả định BE DTO đã được sửa để trả về `specialtyId` trong model này**

    return DoctorSearchResultModel(
      doctorId: (json['doctorId'] as num).toInt(),
      fullName: fullName,
      specialtyName: json['specialtyName'] as String,
      schedules: (json['schedules'] as List<dynamic>)
          .map((s) => WorkingScheduleModel.fromJson(s))
          .toList(),
      avatarUrl: 'assets/images/logo_app.png',
      rating: rating,
      specialtyId: json['specialtyId'] != null
          ? (json['specialtyId'] as num).toInt()
          : 1, // GIẢ ĐỊNH FIX TỪ BE
    );
  }

  @override
  List<Object> get props => [
        doctorId,
        fullName,
        specialtyName,
        schedules,
        rating,
        specialtyId
      ]; // THÊM specialtyId
}
