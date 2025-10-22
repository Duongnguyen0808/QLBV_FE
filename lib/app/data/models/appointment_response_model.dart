// lib/app/data/models/appointment_response_model.dart

import 'package:equatable/equatable.dart';

class AppointmentResponseModel extends Equatable {
  final int id;

  const AppointmentResponseModel({
    required this.id,
  });

  factory AppointmentResponseModel.fromJson(Map<String, dynamic> json) {
    return AppointmentResponseModel(
      id: (json['id'] as num).toInt(),
    );
  }

  @override
  List<Object> get props => [id];
}
