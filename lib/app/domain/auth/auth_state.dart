// lib/app/domain/auth/auth_state.dart (TẠO MỚI)

import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {} // Đăng nhập thành công

class AuthUnauthenticated extends AuthState {} // Chưa đăng nhập

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}

class AuthSignUpSuccess extends AuthState {
  final String message;
  const AuthSignUpSuccess(this.message);
  @override
  List<Object> get props => [message];
}
