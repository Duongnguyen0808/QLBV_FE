// lib/app/data/models/medical_record_model.dart

import 'package:equatable/equatable.dart';

class MedicalRecordModel extends Equatable {
  final int id;
  final String appointmentDate;
  final String doctorName;
  final String specialtyName;
  final String diagnosis;
  final String symptoms;
  final String vitalSigns;
  final String testResults;
  final String prescription;
  final String notes;
  final String? reexaminationDate;

  const MedicalRecordModel({
    required this.id,
    required this.appointmentDate,
    required this.doctorName,
    required this.specialtyName,
    required this.diagnosis,
    this.symptoms = '',
    this.vitalSigns = '', // <-- BỔ SUNG CONSTRUCTOR
    this.testResults = '', // <-- BỔ SUNG CONSTRUCTOR
    this.prescription = '',
    this.notes = '',
    this.reexaminationDate,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: (json['id'] as num).toInt(),
      appointmentDate: json['appointmentDate'] as String,
      doctorName: json['doctorName'] as String,
      specialtyName: json['specialtyName'] as String,
      diagnosis: json['diagnosis'] as String,
      symptoms: (json['symptoms'] ?? '') as String,
      vitalSigns: (json['vitalSigns'] ?? '') as String,
      testResults: (json['testResults'] ?? '') as String,
      prescription: (json['prescription'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
      reexaminationDate: json['reexaminationDate'] as String?,
    );
  }

  @override
  List<Object> get props => [
        id,
        appointmentDate,
        doctorName,
        specialtyName,
        diagnosis,
        symptoms,
        vitalSigns,
        testResults,
        prescription,
        notes,
        reexaminationDate ?? '',
      ];
}
