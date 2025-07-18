// 🚀 خدمة التوصيل المرنة الجديدة - النسخة المحدثة 2025
// تدعم النظام المرن الكامل مع جميع المزايا الجديدة

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NewFlexibleDeliveryService {
  // رابط البروكسي المرن المحدث
  static String get _baseUrl => ApiConfig.apiUrl;
  
  // مهلة زمنية للطلبات
  static const Duration _timeout = Duration(seconds: 30);
  
  // معلومات النظام
  static String? _currentProvider;
  static bool _isSystemHealthy = false;
  static Map<String, dynamic>? _cachedProvinces;
  static Map<String, dynamic>? _cachedCities;

  // ===================================
  // دوال النظام الجديدة
  // ===================================

  // فحص صحة النظام
  static Future<bool> checkSystemHealth() async {
    try {
      final response = await _sendGetRequest('/health');
      _isSystemHealthy = response['healthy'] ?? false;
      _currentProvider = response['currentProvider'];
      debugPrint('🏥 صحة النظام: $_isSystemHealthy، المزود: $_currentProvider');
      return _isSystemHealthy;
    } catch (e) {
      debugPrint('❌ خطأ في فحص صحة النظام: $e');
      _isSystemHealthy = false;
      return false;
    }
  }

  // الحصول على معلومات النظام
  static Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final response = await _sendGetRequest('/system-info');
      return response['data'] ?? {};
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على معلومات النظام: $e');
      return {};
    }
  }

  // ===================================
  // دوال المحافظات والمدن المحدثة
  // ===================================

  // جلب المحافظات مع التخزين المؤقت
  static Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      // استخدام البيانات المخزنة مؤقتاً إذا كانت متوفرة
      if (_cachedProvinces != null) {
        debugPrint('📦 استخدام المحافظات المخزنة مؤقتاً');
        return List<Map<String, dynamic>>.from(_cachedProvinces!['provinces'] ?? []);
      }

      debugPrint('🌍 جلب المحافظات من الخادم...');
      final response = await _sendGetRequest('/provinces');
      
      if (response['success'] == true && response['data'] != null) {
        _cachedProvinces = response['data'];
        final provinces = List<Map<String, dynamic>>.from(response['data']['provinces'] ?? []);
        debugPrint('✅ تم جلب ${provinces.length} محافظة');
        return provinces;
      } else {
        throw Exception('فشل في جلب المحافظات');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب المحافظات: $e');
      return [];
    }
  }

  // جلب المدن حسب المحافظة مع التخزين المؤقت
  static Future<List<Map<String, dynamic>>> getCities(String provinceId) async {
    try {
      // التحقق من البيانات المخزنة مؤقتاً
      if (_cachedCities != null && _cachedCities!['provinceId'] == provinceId) {
        debugPrint('📦 استخدام المدن المخزنة مؤقتاً للمحافظة: $provinceId');
        return List<Map<String, dynamic>>.from(_cachedCities!['cities'] ?? []);
      }

      debugPrint('🏙️ جلب المدن للمحافظة: $provinceId');
      final response = await _sendGetRequest('/cities/$provinceId');
      
      if (response['success'] == true && response['data'] != null) {
        _cachedCities = {
          'provinceId': provinceId,
          'cities': response['data']['cities'] ?? []
        };
        final cities = List<Map<String, dynamic>>.from(response['data']['cities'] ?? []);
        debugPrint('✅ تم جلب ${cities.length} مدينة للمحافظة: $provinceId');
        return cities;
      } else {
        throw Exception('فشل في جلب المدن');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب المدن: $e');
      return [];
    }
  }

  // ===================================
  // دوال إنشاء الطلبات المحدثة
  // ===================================

  // إنشاء طلب جديد مع النظام المرن
  static Future<Map<String, dynamic>> createOrder({
    required int userId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String provinceId,
    required String cityId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      debugPrint('📦 إنشاء طلب جديد للمستخدم: $userId');
      
      final orderData = {
        'userId': userId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'provinceId': provinceId,
        'cityId': cityId,
        'items': items,
        'notes': notes ?? '',
      };

      final response = await _sendPostRequest('/create-order', orderData);
      
      if (response['success'] == true) {
        debugPrint('✅ تم إنشاء الطلب بنجاح: ${response['orderId']}');
        return {
          'success': true,
          'orderId': response['orderId'],
          'trackingNumber': response['trackingNumber'],
          'message': 'تم إنشاء الطلب بنجاح'
        };
      } else {
        throw Exception(response['error'] ?? 'فشل في إنشاء الطلب');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // تتبع الطلب
  static Future<Map<String, dynamic>> trackOrder(String orderId) async {
    try {
      debugPrint('🔍 تتبع الطلب: $orderId');
      final response = await _sendGetRequest('/track-order/$orderId');
      
      if (response['success'] == true) {
        return {
          'success': true,
          'status': response['status'],
          'statusArabic': response['statusArabic'],
          'history': response['history'] ?? [],
          'lastUpdate': response['lastUpdate'],
        };
      } else {
        throw Exception(response['error'] ?? 'فشل في تتبع الطلب');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تتبع الطلب: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // ===================================
  // دوال مساعدة محدثة
  // ===================================

  // إرسال طلب GET محدث
  static Future<Map<String, dynamic>> _sendGetRequest(String endpoint) async {
    try {
      debugPrint('🌐 إرسال طلب GET: $endpoint');
      
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Montajati-Flutter-App/2.0',
        },
      ).timeout(_timeout);

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'خطأ غير معروف');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'خطأ في الخادم');
      }
    } catch (e) {
      debugPrint('❌ خطأ في الطلب: $e');
      rethrow;
    }
  }

  // إرسال طلب POST محدث
  static Future<Map<String, dynamic>> _sendPostRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      debugPrint('🌐 إرسال طلب POST: $endpoint');
      debugPrint('📤 البيانات: ${json.encode(data)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Montajati-Flutter-App/2.0',
        },
        body: json.encode(data),
      ).timeout(_timeout);

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'خطأ غير معروف');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'خطأ في الخادم');
      }
    } catch (e) {
      debugPrint('❌ خطأ في الطلب: $e');
      rethrow;
    }
  }

  // ===================================
  // دوال إضافية
  // ===================================

  // مسح البيانات المخزنة مؤقتاً
  static void clearCache() {
    _cachedProvinces = null;
    _cachedCities = null;
    debugPrint('🗑️ تم مسح البيانات المخزنة مؤقتاً');
  }

  // الحصول على حالة النظام
  static Map<String, dynamic> getSystemStatus() {
    return {
      'isHealthy': _isSystemHealthy,
      'currentProvider': _currentProvider,
      'hasCachedProvinces': _cachedProvinces != null,
      'hasCachedCities': _cachedCities != null,
    };
  }

  // تحديث مزود التوصيل
  static Future<bool> switchDeliveryProvider(String providerId) async {
    try {
      debugPrint('🔄 تبديل مزود التوصيل إلى: $providerId');
      final response = await _sendPostRequest('/switch-provider', {'providerId': providerId});
      
      if (response['success'] == true) {
        _currentProvider = providerId;
        clearCache(); // مسح البيانات المخزنة مؤقتاً
        debugPrint('✅ تم تبديل مزود التوصيل بنجاح');
        return true;
      } else {
        throw Exception(response['error'] ?? 'فشل في تبديل المزود');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تبديل مزود التوصيل: $e');
      return false;
    }
  }
}
