// lib/app/domain/medical_record/medical_record_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/medical_record_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';

// --- State ---
abstract class MedicalRecordState extends Equatable {
  const MedicalRecordState();
  @override
  List<Object> get props => [];
}

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

// --- Cubit ---
class MedicalRecordCubit extends Cubit<MedicalRecordState> {
  final DataRepository _dataRepo = sl<DataRepository>();

  MedicalRecordCubit() : super(MedicalRecordInitial()) {
    fetchMedicalRecords();
  }

  Future<void> fetchMedicalRecords() async {
    if (state is! MedicalRecordLoading) {
      emit(MedicalRecordLoading());
    }

    try {
      final records = await _dataRepo.fetchMyMedicalRecords();
      emit(MedicalRecordLoadSuccess(records));
    } catch (e) {
      emit(MedicalRecordLoadFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
