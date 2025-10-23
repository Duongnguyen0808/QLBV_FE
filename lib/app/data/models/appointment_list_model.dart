// lib/app/data/models/appointment_list_model.dart

import 'package:equatable/equatable.dart';

class AppointmentListModel extends Equatable {
  final int id;
  // SỬA: Thêm thông tin bệnh nhân (cần cho vai trò DOCTOR)
  final String patientFullName;

  final String doctorFullName;
  final String specialtyName;
  final String appointmentDateTime;
  final String status;

  const AppointmentListModel({
    required this.id,
    required this.doctorFullName,
    required this.specialtyName,
    required this.appointmentDateTime,
    required this.status,
    required this.patientFullName, // <--- THÊM TRƯỜNG NÀY
  });

  factory AppointmentListModel.fromJson(Map<String, dynamic> json) {
    return AppointmentListModel(
      id: (json['id'] as num).toInt(),
      // API Bệnh nhân trả về Doctor, API Bác sĩ trả về Patient
      // Ta phải giả định cả hai đều có trường `patient` và `doctor`
      patientFullName:
          json['patient']?['fullName'] as String? ?? 'N/A', // Lấy tên bệnh nhân
      doctorFullName: json['doctor']?['fullName'] as String? ?? 'N/A',
      specialtyName: json['doctor']?['specialtyName'] as String? ?? 'N/A',
      appointmentDateTime: json['appointmentDateTime'] as String,
      status: json['status'] as String,
    );
  }

  @override
  List<Object> get props => [
        id,
        doctorFullName,
        specialtyName,
        appointmentDateTime,
        status,
        patientFullName
      ];
}
