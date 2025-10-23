import 'package:equatable/equatable.dart';

class AppointmentListModel extends Equatable {
  final int id;
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
  });

  factory AppointmentListModel.fromJson(Map<String, dynamic> json) {
    return AppointmentListModel(
      id: (json['id'] as num).toInt(),
      doctorFullName: json['doctor']['fullName'] as String,
      specialtyName: json['doctor']['specialtyName'] as String,
      appointmentDateTime: json['appointmentDateTime'] as String,
      status: json['status'] as String,
    );
  }

  @override
  List<Object> get props =>
      [id, doctorFullName, specialtyName, appointmentDateTime, status];
}
