// lib/app/data/models/doctor_review_model.dart

import 'package:equatable/equatable.dart';

class DoctorReviewModel extends Equatable {
  final int rating; // 1-5
  final String comment;
  final String? createdAt; // optional, if backend returns it

  const DoctorReviewModel({
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory DoctorReviewModel.fromJson(Map<String, dynamic> json) {
    return DoctorReviewModel(
      rating: (json['rating'] as num).toInt(),
      comment: (json['comment'] ?? '') as String,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'comment': comment,
      };

  @override
  List<Object> get props => [rating, comment, createdAt ?? ''];
}