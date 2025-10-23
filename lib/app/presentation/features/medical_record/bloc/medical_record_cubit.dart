// lib/app/presentation/features/medical_record/bloc/medical_record_cubit.dart

// LỚP CŨ: MedicalRecordCubit (Duy trì)
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/medical_record_model.dart';
import 'package:hospital_booking_app/app/data/models/working_schedule_model.dart'; // THÊM IMPORT
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';

// --- State ---
abstract class MedicalRecordState extends Equatable {
  const MedicalRecordState();
  @override
  List<Object> get props => [];
}

// ... (MedicalRecordInitial, MedicalRecordLoading, MedicalRecordLoadSuccess, MedicalRecordLoadFailure giữ nguyên)
class MedicalRecordInitial extends MedicalRecordState {}

class MedicalRecordLoading extends MedicalRecordState {}

class MedicalRecordLoadSuccess extends MedicalRecordState {
  final List<MedicalRecordModel> records;
  const MedicalRecordLoadSuccess(this.records);
  @override
  List<Object> get props => [records];
}

class MedicalRecordLoadFailure extends MedicalRecordState {
  final String message;
  const MedicalRecordLoadFailure(this.message);
  @override
  List<Object> get props => [message];
}

// --- Cubit cho Medical Record ---
class MedicalRecordCubit extends Cubit<MedicalRecordState> {
  final DataRepository _dataRepo = sl<DataRepository>();

  MedicalRecordCubit() : super(MedicalRecordInitial()) {
    // Không tự gọi fetch ở đây nữa để tránh lỗi Forbidden cho Doctor
    // Sẽ gọi từ widget nếu là PATIENT
  }

  Future<void> fetchMedicalRecords({String? query}) async {
    if (state is! MedicalRecordLoading) {
      emit(MedicalRecordLoading());
    }

    try {
      final records = await _dataRepo.searchMedicalRecords(query: query);
      emit(MedicalRecordLoadSuccess(records));
    } catch (e) {
      emit(MedicalRecordLoadFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}

// --- LỚP MỚI: DoctorScheduleCubit ---
abstract class DoctorScheduleState extends Equatable {
  const DoctorScheduleState();
  @override
  List<Object> get props => [];
}

class DoctorScheduleInitial extends DoctorScheduleState {}

class DoctorScheduleLoading extends DoctorScheduleState {}

class DoctorScheduleLoadSuccess extends DoctorScheduleState {
  final List<WorkingScheduleModel> schedules;
  const DoctorScheduleLoadSuccess(this.schedules);
  @override
  List<Object> get props => [schedules];
}

class DoctorScheduleLoadFailure extends DoctorScheduleState {
  final String message;
  const DoctorScheduleLoadFailure(this.message);
  @override
  List<Object> get props => [message];
}

class DoctorScheduleCubit extends Cubit<DoctorScheduleState> {
  final DataRepository _dataRepo = sl<DataRepository>();

  DoctorScheduleCubit() : super(DoctorScheduleInitial()) {
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    emit(DoctorScheduleLoading());
    try {
      final schedules = await _dataRepo.fetchMyWorkingSchedules();
      emit(DoctorScheduleLoadSuccess(schedules));
    } catch (e) {
      emit(DoctorScheduleLoadFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
