// lib/app/domain/appointment/appointment_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/appointment/appointment_repository.dart';

// --- State ---
abstract class AppointmentState extends Equatable {
  const AppointmentState();
  @override
  List<Object> get props => [];
}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentLoadSuccess extends AppointmentState {
  final List<AppointmentListModel> appointments;
  const AppointmentLoadSuccess(this.appointments);
  @override
  List<Object> get props => [appointments];
}

class AppointmentLoadFailure extends AppointmentState {
  final String message;
  const AppointmentLoadFailure(this.message);
  @override
  List<Object> get props => [message];
}

// --- Cubit ---
class AppointmentCubit extends Cubit<AppointmentState> {
  final AppointmentRepository _appointmentRepo = sl<AppointmentRepository>();

  AppointmentCubit() : super(AppointmentInitial()) {
    fetchAppointments();
  }

  // HÀM SẮP XẾP LỊCH HẸN THEO THỨ TỰ ƯU TIÊN
  List<AppointmentListModel> _sortAppointments(
      List<AppointmentListModel> list) {
    list.sort((a, b) {
      final isACancelled = a.status == 'CANCELLED';
      final isBCancelled = b.status == 'CANCELLED';

      // 1. Phân loại Hoạt động và Đã Hủy
      if (!isACancelled && isBCancelled) {
        return -1; // A (Hoạt động) lên trước B (Đã hủy)
      }
      if (isACancelled && !isBCancelled) {
        return 1; // A (Đã hủy) xuống sau B (Hoạt động)
      }

      // 2. Nếu cùng trạng thái (cùng Hoạt động HOẶC cùng Đã Hủy), sắp xếp theo thời gian
      final timeA = DateTime.parse(a.appointmentDateTime);
      final timeB = DateTime.parse(b.appointmentDateTime);

      // Hoạt động: Sắp xếp thời gian TĂNG dần (gần nhất lên trên)
      // Đã Hủy: Giữ nguyên thứ tự thời gian tăng dần
      return timeA.compareTo(timeB);
    });
    return list;
  }

  Future<void> fetchAppointments() async {
    if (state is! AppointmentLoading) {
      emit(AppointmentLoading());
    }

    try {
      final appointments = await _appointmentRepo.fetchMyAppointments();
      // ÁP DỤNG SẮP XẾP MỚI
      final sortedAppointments = _sortAppointments(appointments);

      emit(AppointmentLoadSuccess(sortedAppointments));
    } catch (e) {
      emit(
          AppointmentLoadFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> cancelAppointment(int appointmentId) async {
    final currentState = state;
    try {
      // Bắt đầu Loading để chặn hành động
      emit(AppointmentLoading());

      await _appointmentRepo.cancelAppointment(appointmentId);

      // Sau khi hủy thành công, reload lại danh sách (và nó sẽ được sắp xếp lại)
      await fetchAppointments();
    } catch (e) {
      // Khi hủy lỗi, emit lỗi qua listener và giữ lại danh sách cũ nếu có
      String errorMessage = e.toString().replaceFirst('Exception: ', '');

      if (currentState is AppointmentLoadSuccess) {
        // Vẫn hiển thị danh sách cũ, nhưng emit lỗi để Snackbar thông báo
        emit(AppointmentLoadSuccess(currentState.appointments));
      }

      // Dùng throw để listener trong BlocConsumer bắt lỗi và hiển thị Snackbar
      throw Exception(errorMessage);
    }
  }
}
