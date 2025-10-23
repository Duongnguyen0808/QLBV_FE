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
  final int specialtyId; 

  const DoctorSearchResultModel({
    required this.doctorId,
    required this.fullName,
    required this.specialtyName,
    required this.schedules,
    this.avatarUrl,
    this.rating = 5.0,
    required this.specialtyId, 
  });

  factory DoctorSearchResultModel.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName'] as String;
    final int hash = fullName.hashCode;
    final double rating = (4.0 + (hash % 10) / 10).clamp(4.0, 5.0);

    return DoctorSearchResultModel(
      doctorId: (json['doctorId'] as num).toInt(),
      fullName: fullName,
      specialtyName: json['specialtyName'] as String,
      specialtyId: (json['specialtyId'] as num)
          .toInt(), // <--- DÒNG SỬA: Đảm bảo đọc từ BE và loại bỏ logic gán cứng 1
      schedules: (json['schedules'] as List<dynamic>)
          .map((s) => WorkingScheduleModel.fromJson(s))
          .toList(),
      avatarUrl: 'assets/images/doctor.png',
      rating: rating,
    );
  }

  @override
  List<Object> get props =>
      [doctorId, fullName, specialtyName, schedules, rating, specialtyId];
}
