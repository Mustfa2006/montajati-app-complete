// خدمة API للاتصال مع Backend
import 'dart:async';
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
      final response = await http.get(Uri.parse('$baseUrl/'), headers: {'Content-Type': 'application/json'});

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
      final response = await http.get(Uri.parse('$baseUrl/api/test'), headers: {'Content-Type': 'application/json'});

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
  static Future<Map<String, dynamic>?> login(String email, String password) async {
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
        body: json.encode({'name': name, 'email': email, 'password': password, 'confirmPassword': confirmPassword}),
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

  // ===================================
  // 📦 دوال إدارة الطلبات
  // ===================================

  /// 📤 إنشاء طلب جديد عبر الباك إند (آمن وسريع)
  static Future<String> createOrder({
    required Map<String, dynamic> orderData,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      debugPrint('🚀 إرسال الطلب إلى الباك إند...');
      debugPrint('🔗 URL: $baseUrl/api/orders');

      // تحضير البيانات
      final requestBody = {...orderData, 'items': items};

      debugPrint('📦 بيانات الطلب: ${jsonEncode(requestBody)}');

      // إرسال الطلب
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/orders'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏰ انتهت مهلة الاتصال بالباك إند');
              throw TimeoutException('انتهت مهلة الاتصال بالخادم', const Duration(seconds: 10));
            },
          );

      debugPrint('📡 استجابة الباك إند: ${response.statusCode}');
      debugPrint('📄 محتوى الاستجابة: ${response.body}');

      // التحقق من نجاح الطلب
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final orderId = responseData['data']?['id'] ?? responseData['orderId'];

          if (orderId != null) {
            debugPrint('✅ تم إنشاء الطلب بنجاح - ID: $orderId');
            return orderId.toString();
          } else {
            debugPrint('❌ الاستجابة لا تحتوي على orderId');
            throw Exception('الاستجابة لا تحتوي على معرف الطلب');
          }
        } else {
          final errorMessage = responseData['error'] ?? 'فشل في إنشاء الطلب';
          debugPrint('❌ فشل إنشاء الطلب: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        debugPrint('❌ خطأ في الاستجابة: ${response.statusCode}');
        throw Exception('فشل في الاتصال بالخادم (${response.statusCode})');
      }
    } on TimeoutException catch (e) {
      debugPrint('⏰ انتهت مهلة الاتصال: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الطلب: $e');
      rethrow;
    }
  }

  /// 📤 إنشاء طلب مجدول عبر الباك إند
  static Future<String> createScheduledOrder({
    required Map<String, dynamic> orderData,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      debugPrint('🚀 إرسال الطلب المجدول إلى الباك إند...');
      debugPrint('🔗 URL: $baseUrl/api/scheduled-orders');

      // تحضير البيانات
      final requestBody = {...orderData, 'items': items};

      debugPrint('📦 بيانات الطلب المجدول: ${jsonEncode(requestBody)}');

      // إرسال الطلب
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/scheduled-orders'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏰ انتهت مهلة الاتصال بالباك إند');
              throw TimeoutException('انتهت مهلة الاتصال بالخادم', const Duration(seconds: 10));
            },
          );

      debugPrint('📡 استجابة الباك إند: ${response.statusCode}');
      debugPrint('📄 محتوى الاستجابة: ${response.body}');

      // التحقق من نجاح الطلب
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final orderId = responseData['data']?['id'] ?? responseData['orderId'];

          if (orderId != null) {
            debugPrint('✅ تم إنشاء الطلب المجدول بنجاح - ID: $orderId');
            return orderId.toString();
          } else {
            debugPrint('❌ الاستجابة لا تحتوي على orderId');
            throw Exception('الاستجابة لا تحتوي على معرف الطلب');
          }
        } else {
          final errorMessage = responseData['error'] ?? 'فشل في إنشاء الطلب المجدول';
          debugPrint('❌ فشل إنشاء الطلب المجدول: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        debugPrint('❌ خطأ في الاستجابة: ${response.statusCode}');
        throw Exception('فشل في الاتصال بالخادم (${response.statusCode})');
      }
    } on TimeoutException catch (e) {
      debugPrint('⏰ انتهت مهلة الاتصال: $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الطلب المجدول: $e');
      rethrow;
    }
  }
}
