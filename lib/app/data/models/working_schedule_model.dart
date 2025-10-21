import 'package:equatable/equatable.dart';

class WorkingScheduleModel extends Equatable {
  final String dayOfWeek;
  final String timeSlot;

  const WorkingScheduleModel({required this.dayOfWeek, required this.timeSlot});

  factory WorkingScheduleModel.fromJson(Map<String, dynamic> json) {
    return WorkingScheduleModel(
      dayOfWeek: json['dayOfWeek'] as String,
      timeSlot: json['timeSlot'] as String,
    );
  }

  @override
  List<Object> get props => [dayOfWeek, timeSlot];
}
