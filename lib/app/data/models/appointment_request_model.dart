import 'package:equatable/equatable.dart';

class AppointmentRequestModel extends Equatable {
  final int specialtyId;
  final int doctorId;
  final String appointmentDateTime;
  final int duration;
  final String notes;

  const AppointmentRequestModel({
    required this.specialtyId,
    required this.doctorId,
    required this.appointmentDateTime,
    this.duration = 30, // Mặc định 30 phút
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'specialtyId': specialtyId,
        'doctorId': doctorId,
        'appointmentDateTime': appointmentDateTime,
        'duration': duration,
        'notes': notes,
      };

  @override
  List<Object> get props =>
      [specialtyId, doctorId, appointmentDateTime, duration, notes];
}
