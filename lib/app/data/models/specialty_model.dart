import 'package:equatable/equatable.dart';

class SpecialtyModel extends Equatable {
  final int id;
  final String name;

  const SpecialtyModel({required this.id, required this.name});

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }

  @override
  List<Object> get props => [id, name];
}
