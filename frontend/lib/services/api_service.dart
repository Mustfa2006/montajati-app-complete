// خدمة API للاتصال مع Backend
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // رابط Backend من الإعدادات المركزية
  static String get baseUrl => ApiConfig.baseUrl;

  // دالة للحصول على معلومات الخادم
  static Future<Map<String, dynamic>?> getServerInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('خطأ في الخادم: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('خطأ في الاتصال: $e');
      return null;
    }
  }

  // دالة لاختبار API
  static Future<Map<String, dynamic>?> testApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/test'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('خطأ في اختبار API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('خطأ في اختبار API: $e');
      return null;
    }
  }

  // دالة تسجيل الدخول
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('خطأ في تسجيل الدخول: ${response.statusCode}');
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول: $e');
      return null;
    }
  }

  // دالة إنشاء حساب
  static Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('خطأ في إنشاء الحساب: ${response.statusCode}');
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('خطأ في إنشاء الحساب: $e');
      return null;
    }
  }
}
