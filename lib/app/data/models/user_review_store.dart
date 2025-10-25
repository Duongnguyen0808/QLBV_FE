import 'package:flutter/foundation.dart';

/// Lưu lại số sao mà bệnh nhân vừa đánh giá theo tên bác sĩ
class UserReviewStore {
  UserReviewStore._();
  static final UserReviewStore instance = UserReviewStore._();

  /// Map<normalizedDoctorFullName, rating>
  final ValueNotifier<Map<String, int>> lastRatingsByDoctorName =
      ValueNotifier<Map<String, int>>({});

  static String normalizeName(String name) {
    // Chuẩn hoá tên: bỏ tiền tố chức danh, bỏ dấu tiếng Việt, gộp khoảng trắng, lowercase
    var s = name.trim().toLowerCase();

    // Bỏ các tiền tố thường gặp ở đầu tên
    s = s.replaceAll(RegExp(r'^(bs\.?\s*|bác sĩ\s*|bac si\s*|dr\.?\s*|doctor\s*)', caseSensitive: false), '');

    // Bỏ dấu tiếng Việt để khớp giữa "bac si" và "bác sĩ"
    s = _removeDiacritics(s);

    // Gộp nhiều khoảng trắng và bỏ ký tự chấm/đặc biệt thừa
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  static String _removeDiacritics(String s) {
    final patterns = {
      r'[àáạảãâầấậẩẫăằắặẳẵ]': 'a',
      r'[èéẹẻẽêềếệểễ]': 'e',
      r'[ìíịỉĩ]': 'i',
      r'[òóọỏõôồốộổỗơờớợởỡ]': 'o',
      r'[ùúụủũưừứựửữ]': 'u',
      r'[ỳýỵỷỹ]': 'y',
      r'[đ]': 'd',
      r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]': 'a',
      r'[ÈÉẸẺẼÊỀẾỆỂỄ]': 'e',
      r'[ÌÍỊỈĨ]': 'i',
      r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]': 'o',
      r'[ÙÚỤỦŨƯỪỨỰỬỮ]': 'u',
      r'[ỲÝỴỶỸ]': 'y',
      r'[Đ]': 'd',
    };
    patterns.forEach((regex, repl) {
      s = s.replaceAll(RegExp(regex), repl);
    });
    return s;
  }

  void update(String doctorFullName, int rating) {
    final key = normalizeName(doctorFullName);
    final next = Map<String, int>.from(lastRatingsByDoctorName.value);
    next[key] = rating;
    lastRatingsByDoctorName.value = next;
  }

  int? getForDoctor(String doctorFullName) {
    return lastRatingsByDoctorName.value[normalizeName(doctorFullName)];
  }
}