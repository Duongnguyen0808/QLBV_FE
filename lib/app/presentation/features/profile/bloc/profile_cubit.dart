// lib/app/domain/profile/profile_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hospital_booking_app/app/core/di/injection_container.dart';
import 'package:hospital_booking_app/app/data/models/user_model.dart';
import 'package:hospital_booking_app/app/domain/repositories/data/data_repository.dart';

// --- State ---
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoadSuccess extends ProfileState {
  final UserModel user;
  const ProfileLoadSuccess(this.user);
  @override
  List<Object> get props => [user];
}

class ProfileLoadFailure extends ProfileState {
  final String message;
  const ProfileLoadFailure(this.message);
  @override
  List<Object> get props => [message];
}

// --- Cubit ---
class ProfileCubit extends Cubit<ProfileState> {
  final DataRepository _dataRepo = sl<DataRepository>();

  ProfileCubit() : super(ProfileInitial());

  Future<void> fetchMyProfile() async {
    emit(ProfileLoading());
    try {
      final user = await _dataRepo.fetchMyProfile();
      emit(ProfileLoadSuccess(user));
    } catch (e) {
      emit(ProfileLoadFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
