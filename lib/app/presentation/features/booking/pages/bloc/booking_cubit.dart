// lib/app/presentation/features/booking/bloc/booking_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/doctor_search_result_model.dart';
// FIX: Import models từ DATA layer
import 'package:hospital_booking_app/app/data/models/specialty_model.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';

// --- State --- (Định nghĩa các lớp State bị báo lỗi)
abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object> get props => [];
}

class BookingLoading extends BookingState {}

class BookingLoadSuccess extends BookingState {
  final UserModel userProfile;
  final List<SpecialtyModel> specialties;
  final List<DoctorSearchResultModel> recommendedDoctors;

  const BookingLoadSuccess({
    required this.userProfile,
    required this.specialties,
    required this.recommendedDoctors,
  });

  @override
  List<Object> get props => [userProfile, specialties, recommendedDoctors];
}

class BookingLoadFailure extends BookingState {
  final String message;
  const BookingLoadFailure(this.message);
  @override
  List<Object> get props => [message];
}

// --- Cubit ---
class BookingCubit extends Cubit<BookingState> {
  final DataRepository _dataRepository = sl<DataRepository>();

  BookingCubit() : super(BookingLoading());

  Future<void> fetchInitialData() async {
    emit(BookingLoading());
    try {
      final user = await _dataRepository.fetchMyProfile();
      final specialties = await _dataRepository.fetchAllSpecialties();
      final allDoctors = await _dataRepository.searchDoctors(name: '');

      emit(BookingLoadSuccess(
        userProfile: user,
        specialties: specialties,
        recommendedDoctors: allDoctors.take(3).toList(),
      ));
    } catch (e) {
      emit(BookingLoadFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<List<DoctorSearchResultModel>> fetchAllDoctors() async {
    try {
      return await _dataRepository.searchDoctors(name: '');
    } catch (e) {
      rethrow;
    }
  }
}
