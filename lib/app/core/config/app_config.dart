import 'package:flutter/foundation.dart';

class AppConfig {
// Android emulator không dùng được http://localhost:8080 của máy bạn.
// Dùng 10.0.2.2 để trỏ về localhost trên PC.
  static const String baseUrl = kDebugMode
      ? 'http://10.0.2.2:8080'
      : 'https://api.example.com'; // đổi khi có domain thật
}
