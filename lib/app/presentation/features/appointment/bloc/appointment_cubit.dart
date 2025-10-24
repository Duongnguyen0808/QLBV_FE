// lib/app/presentation/features/appointment/bloc/appointment_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/appointment_list_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/appointment/appointment_repository.dart';
import 'package:hospital_booking_app/app/data/models/appointment_response_model.dart';

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
    // SỬA Ở ĐÂY: Gọi fetchAppointments() ngay khi Cubit được tạo.
    // Repository sẽ tự động gọi đúng API dựa trên vai trò (Patient/Doctor).
    fetchAppointments();
  }

  // HÀM SẮP XẾP LỊCH HẸN THEO THỨ TỰ ƯU TIÊN (Giữ nguyên)
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
    // Chỉ emit Loading nếu trạng thái hiện tại không phải Loading
    if (state is! AppointmentLoading) {
      emit(AppointmentLoading());
    }

    try {
      // GỌI API BỆNH NHÂN (không cần kiểm tra role nữa)
      print('🟢 DEBUG AppointmentCubit: Calling fetchPatientAppointments()');
      final appointments = await _appointmentRepo.fetchPatientAppointments();

      // ÁP DỤNG SẮP XẾP MỚI
      final sortedAppointments = _sortAppointments(appointments);
      print(
          '✅ DEBUG AppointmentCubit: Loaded ${sortedAppointments.length} appointments');

      emit(AppointmentLoadSuccess(sortedAppointments));
    } catch (e) {
      emit(
          AppointmentLoadFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // Giữ nguyên các hàm khác (rescheduleAppointment, cancelAppointment, ...)
  Future<AppointmentResponseModel> rescheduleAppointment(
      int appointmentId, String newDateTime) async {
    try {
      final response = await _appointmentRepo.rescheduleAppointment(
          appointmentId, newDateTime);
      await fetchAppointments(); // Tải lại danh sách sau khi đổi lịch
      return response;
    } catch (e) {
      // Ném lại lỗi để UI có thể xử lý
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> cancelAppointment(int appointmentId) async {
    final currentState = state; // Lưu trạng thái hiện tại phòng trường hợp lỗi
    try {
      // Không cần emit loading ở đây nếu bạn muốn UI phản hồi nhanh hơn
      // hoặc bạn có thể emit loading nếu muốn hiển thị chỉ báo
      // emit(AppointmentLoading());
      await _appointmentRepo.cancelAppointment(appointmentId);
      await fetchAppointments(); // Tải lại danh sách sau khi hủy
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      // Nếu có lỗi, quay lại trạng thái trước đó (nếu là Success)
      if (currentState is AppointmentLoadSuccess) {
        emit(AppointmentLoadSuccess(currentState.appointments));
      } else {
        // Nếu trạng thái trước đó không phải Success, emit lỗi
        emit(AppointmentLoadFailure(errorMessage));
      }
      // Ném lại lỗi để UI có thể hiển thị thông báo
      throw Exception(errorMessage);
    }
  }
}
