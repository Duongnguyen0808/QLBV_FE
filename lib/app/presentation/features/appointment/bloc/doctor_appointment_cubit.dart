// lib/app/presentation/features/appointment/bloc/doctor_appointment_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/appointment/appointment_repository.dart';

// --- State (Giống AppointmentCubit) ---
abstract class DoctorAppointmentState extends Equatable {
  const DoctorAppointmentState();
  @override
  List<Object> get props => [];
}

class DoctorAppointmentInitial extends DoctorAppointmentState {}

class DoctorAppointmentLoading extends DoctorAppointmentState {}

class DoctorAppointmentLoadSuccess extends DoctorAppointmentState {
  final List<AppointmentListModel> appointments;
  const DoctorAppointmentLoadSuccess(this.appointments);
  @override
  List<Object> get props => [appointments];
}

class DoctorAppointmentLoadFailure extends DoctorAppointmentState {
  final String message;
  const DoctorAppointmentLoadFailure(this.message);
  @override
  List<Object> get props => [message];
}

// --- Cubit ---
class DoctorAppointmentCubit extends Cubit<DoctorAppointmentState> {
  final AppointmentRepository _appointmentRepo = sl<AppointmentRepository>();

  DoctorAppointmentCubit() : super(DoctorAppointmentInitial());

  // Sắp xếp lịch hẹn
  List<AppointmentListModel> _sortAppointments(
      List<AppointmentListModel> list) {
    list.sort((a, b) {
      final isACancelled = a.status == 'CANCELLED';
      final isBCancelled = b.status == 'CANCELLED';

      if (!isACancelled && isBCancelled) {
        return -1;
      }
      if (isACancelled && !isBCancelled) {
        return 1;
      }

      final timeA = DateTime.parse(a.appointmentDateTime);
      final timeB = DateTime.parse(b.appointmentDateTime);
      return timeA.compareTo(timeB);
    });
    return list;
  }

  // GỌI API RIÊNG CHO BÁC SĨ
  Future<void> fetchDoctorAppointments() async {
    if (state is! DoctorAppointmentLoading) {
      emit(DoctorAppointmentLoading());
    }

    try {
      print('🔵 DEBUG DoctorAppointmentCubit: Calling fetchDoctorAppointments()');
      
      // Gọi repository method mới cho bác sĩ
      final appointments = await _appointmentRepo.fetchDoctorAppointments();
      
      final sortedAppointments = _sortAppointments(appointments);
      print('✅ DEBUG DoctorAppointmentCubit: Loaded ${sortedAppointments.length} appointments');
      
      emit(DoctorAppointmentLoadSuccess(sortedAppointments));
    } catch (e) {
      print('❌ DEBUG DoctorAppointmentCubit: Error = $e');
      emit(DoctorAppointmentLoadFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
