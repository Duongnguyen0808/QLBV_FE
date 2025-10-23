// lib/app/data/models/user_model.dart

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role; // <--- THÊM VAI TRÒ

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role, // <--- THÊM VAI TRÒ
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: json['role'] as String, // <--- MAP VAI TRÒ TỪ RESPONSE BE
    );
  }

  @override
  List<Object> get props => [id, fullName, email, phoneNumber, role];

  void operator [](String other) {}
}
