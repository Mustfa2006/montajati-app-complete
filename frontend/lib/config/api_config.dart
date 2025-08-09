// إعدادات API المركزية لتطبيق منتجاتي - الإنتاج فقط
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ✅ إعداد الإنتاج النهائي
  static const bool isProduction = true;

  // ✅ رابط الإنتاج الرسمي - DigitalOcean
  static const String _productionBaseUrl = 'https://clownfish-app-krnk9.ondigitalocean.app';

  // ✅ الرابط الأساسي للـ API - إنتاج نهائي
  static String get baseUrl => _productionBaseUrl;
  
  // روابط API مختلفة
  static String get apiUrl => '$baseUrl/api';
  static String get authUrl => '$apiUrl/auth';
  static String get ordersUrl => '$apiUrl/orders';
  static String get productsUrl => '$apiUrl/products';
  static String get usersUrl => '$apiUrl/users';
  static String get statisticsUrl => '$apiUrl/statistics';
  static String get uploadUrl => '$apiUrl/upload';
  static String get healthUrl => '$baseUrl/health';
  
  // إعدادات المهلة الزمنية
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Headers افتراضية
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // معلومات التطبيق
  static const String appName = 'منتجاتي';
  static const String appVersion = '1.0.0';
  static const String userAgent = '$appName/$appVersion';
  
  // ✅ إعدادات التسجيل - مُفعل في وضع التطوير
  static const bool enableLogging = kDebugMode;

  // دالة للحصول على الرابط الكامل
  static String getFullUrl(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    return '$baseUrl$endpoint';
  }

  // دالة للحصول على رابط API
  static String getApiUrl(String endpoint) {
    if (endpoint.startsWith('/')) {
      return '$apiUrl$endpoint';
    }
    return '$apiUrl/$endpoint';
  }

  // تحميل صامت للإعدادات
  static void printConfig() {
    // تحميل صامت
  }
}
