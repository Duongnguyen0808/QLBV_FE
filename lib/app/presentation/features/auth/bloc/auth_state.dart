// lib/app/domain/auth/auth_state.dart

import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

// SỬA: Phải có trường role để main.dart đọc được
class AuthAuthenticated extends AuthState {
  final String role; // Role: 'DOCTOR', 'PATIENT', 'ADMIN'
  const AuthAuthenticated(this.role);
  @override
  List<Object> get props => [role];
}

class AuthUnauthenticated extends AuthState {}

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
