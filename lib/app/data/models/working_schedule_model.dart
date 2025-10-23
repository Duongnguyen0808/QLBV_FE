import 'package:equatable/equatable.dart';

class WorkingScheduleModel extends Equatable {
  final String dayOfWeek;
  final String dayOfWeekEnglish;
  final String timeSlot;

  const WorkingScheduleModel(
      {required this.dayOfWeek,
      required this.timeSlot,
      required this.dayOfWeekEnglish}); // <--- SỬA CONSTRUCTOR

  factory WorkingScheduleModel.fromJson(Map<String, dynamic> json) {
    return WorkingScheduleModel(
      dayOfWeek: json['dayOfWeek'] as String,
      timeSlot: json['timeSlot'] as String,
      dayOfWeekEnglish: json['dayOfWeekEnglish'] as String,
    );
  }

  @override
  List<Object> get props =>
      [dayOfWeek, timeSlot, dayOfWeekEnglish]; // <--- SỬA PROPS
}
