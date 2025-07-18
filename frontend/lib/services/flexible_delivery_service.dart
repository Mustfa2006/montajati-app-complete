// 🚀 خدمة التوصيل المرنة المحدثة - النسخة الجديدة 2025
// تدعم النظام المرن الكامل مع جميع المزايا الجديدة

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';

class FlexibleDeliveryService {
  // رابط البروكسي المرن المحدث
  static String get _baseUrl => ApiConfig.apiUrl;

  // مهلة زمنية للطلبات
  static const Duration _timeout = Duration(seconds: 30);

  // عميل Supabase للوصول المباشر لقاعدة البيانات
  static final supabase = Supabase.instance.client;

  // معلومات النظام
  static String? _currentProvider;
  static final bool _isSystemHealthy = false;

  // ===================================
  // دوال مساعدة
  // ===================================

  // إرسال طلب GET
  static Future<Map<String, dynamic>> _sendGetRequest(String endpoint) async {
    try {
      debugPrint('🌐 إرسال طلب GET: $endpoint');

      final response = await http
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

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

  // إرسال طلب POST
  static Future<Map<String, dynamic>> _sendPostRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('🌐 إرسال طلب POST: $endpoint');
      debugPrint('📦 البيانات: $data');

      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(_timeout);

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');

      if (response.statusCode == 200) {
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
  // APIs الأساسية
  // ===================================

  // جلب المحافظات من مزود التوصيل النشط
  static Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      debugPrint('🏛️ جلب المحافظات من قاعدة البيانات...');

      // جلب المحافظات من قاعدة البيانات Supabase مباشرة
      final response = await supabase
          .from('provinces')
          .select('*')
          .order('name');

      final provinces = response
          .map(
            (province) => {
              'id': province['id']?.toString() ?? '',
              'name': province['name']?.toString() ?? '',
              'name_ar': province['name']?.toString() ?? '',
              'name_en':
                  province['name_en']?.toString() ??
                  province['name']?.toString() ??
                  '',
            },
          )
          .toList();

      debugPrint('✅ تم جلب ${provinces.length} محافظة من قاعدة البيانات');
      debugPrint(
        '🗄️ تم استخدام البيانات المحفوظة في قاعدة البيانات (سرعة فائقة)',
      );

      return provinces;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المحافظات: $e');
      throw Exception('فشل في جلب المحافظات: $e');
    }
  }

  // جلب المدن لمحافظة معينة
  static Future<List<Map<String, dynamic>>> getCitiesForProvince(
    String provinceId,
  ) async {
    try {
      debugPrint('🏙️ جلب مدن المحافظة: $provinceId من قاعدة البيانات...');

      // جلب المدن من قاعدة البيانات Supabase مباشرة
      final response = await supabase
          .from('cities')
          .select('*')
          .eq('province_id', provinceId)
          .order('name');

      final cities = response
          .map(
            (city) => {
              'id': city['id']?.toString() ?? '',
              'name': city['name']?.toString() ?? '',
              'name_ar': city['name']?.toString() ?? '',
              'name_en':
                  city['name_en']?.toString() ?? city['name']?.toString() ?? '',
              'province_id': city['province_id']?.toString() ?? '',
            },
          )
          .toList();

      debugPrint('✅ تم جلب ${cities.length} مدينة من قاعدة البيانات');
      debugPrint(
        '🗄️ تم استخدام البيانات المحفوظة في قاعدة البيانات (سرعة فائقة)',
      );

      return cities;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المدن: $e');
      throw Exception('فشل في جلب المدن: $e');
    }
  }

  // إنشاء طلب محلي في قاعدة البيانات فقط (بحالة "نشط")
  static Future<Map<String, dynamic>> createLocalOrder({
    required String localOrderId,
    required String clientName,
    required String clientMobile,
    String? clientMobile2,
    required String cityId,
    required String regionId,
    required String location,
    String? typeName,
    required int itemsNumber,
    required int price,
    String? merchantNotes,
  }) async {
    try {
      debugPrint('📦 إنشاء طلب محلي جديد بحالة "نشط"...');

      final orderData = {
        'localOrderId': localOrderId,
        'clientName': clientName,
        'clientMobile': clientMobile,
        'clientMobile2': clientMobile2,
        'cityId': cityId,
        'regionId': regionId,
        'location': location,
        'typeName': typeName ?? 'منتجات عامة',
        'itemsNumber': itemsNumber,
        'price': price,
        'merchantNotes':
            merchantNotes ?? 'طلب جديد بحالة نشط - بانتظار الموافقة',
      };

      final response = await _sendPostRequest('/create-local-order', orderData);

      debugPrint('✅ تم حفظ الطلب في قاعدة البيانات بحالة "نشط"');

      return response;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب المحلي: $e');
      throw Exception('فشل في إنشاء الطلب المحلي: $e');
    }
  }

  // إنشاء طلب جديد وإرساله للوسيط مباشرة
  static Future<Map<String, dynamic>> createOrder({
    required String localOrderId,
    required String clientName,
    required String clientMobile,
    String? clientMobile2,
    required String cityId,
    required String regionId,
    required String location,
    String? typeName,
    required int itemsNumber,
    required int price,
    String? packageSize,
    String? merchantNotes,
    int? replacement,
  }) async {
    try {
      debugPrint('📦 إنشاء طلب جديد وإرساله للوسيط...');

      final orderData = {
        'local_order_id': localOrderId,
        'client_name': clientName,
        'client_mobile': clientMobile,
        'client_mobile2': clientMobile2,
        'city_id': cityId,
        'region_id': regionId,
        'location': location,
        'type_name': typeName ?? 'منتجات عامة',
        'items_number': itemsNumber,
        'price': price,
        'package_size': packageSize ?? '1',
        'merchant_notes': merchantNotes ?? '',
        'replacement': replacement ?? 0,
      };

      final response = await _sendPostRequest('/create-order', orderData);

      final provider = response['provider'] ?? 'غير معروف';
      debugPrint('✅ تم إنشاء الطلب بنجاح في $provider');

      return response;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      throw Exception('فشل في إنشاء الطلب: $e');
    }
  }

  // فحص حالة طلب
  static Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    try {
      debugPrint('🔍 فحص حالة الطلب: $orderId');

      final response = await _sendGetRequest('/order-status/$orderId');

      final provider = response['provider'] ?? 'غير معروف';
      debugPrint('✅ تم جلب حالة الطلب من $provider');

      return response;
    } catch (e) {
      debugPrint('❌ خطأ في فحص حالة الطلب: $e');
      throw Exception('فشل في فحص حالة الطلب: $e');
    }
  }

  // تتبع طلب
  static Future<Map<String, dynamic>> trackOrder(String orderId) async {
    try {
      debugPrint('📍 تتبع الطلب: $orderId');

      final response = await _sendGetRequest('/track-order/$orderId');

      final provider = response['provider'] ?? 'غير معروف';
      debugPrint('✅ تم تتبع الطلب من $provider');

      return response;
    } catch (e) {
      debugPrint('❌ خطأ في تتبع الطلب: $e');
      throw Exception('فشل في تتبع الطلب: $e');
    }
  }

  // فحص حالة النظام
  static Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      debugPrint('🔍 فحص حالة النظام المرن...');

      final response = await _sendGetRequest('/system/status');

      debugPrint('✅ تم جلب حالة النظام بنجاح');
      return response;
    } catch (e) {
      debugPrint('❌ خطأ في فحص حالة النظام: $e');
      throw Exception('فشل في فحص حالة النظام: $e');
    }
  }

  // فحص صحة الخدمة
  static Future<bool> checkHealth() async {
    try {
      debugPrint('💚 فحص صحة خدمة التوصيل المرنة...');

      final response = await http
          .get(
            Uri.parse('http://localhost:3001/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ خدمة التوصيل المرنة تعمل بشكل طبيعي');
        debugPrint('📊 معلومات الخدمة: ${data['service']}');
        return true;
      } else {
        debugPrint('⚠️ خدمة التوصيل المرنة لا تستجيب');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص صحة الخدمة: $e');
      return false;
    }
  }

  // ===================================
  // دوال مساعدة للتطبيق
  // ===================================

  // تحويل بيانات المحافظة إلى تنسيق التطبيق
  static Map<String, dynamic> formatProvinceData(
    Map<String, dynamic> provinceData,
  ) {
    return {
      'id': provinceData['id']?.toString() ?? '',
      'name': provinceData['city_name'] ?? provinceData['name'] ?? '',
      'display_name': provinceData['city_name'] ?? provinceData['name'] ?? '',
    };
  }

  // تحويل بيانات المدينة إلى تنسيق التطبيق
  static Map<String, dynamic> formatCityData(Map<String, dynamic> cityData) {
    return {
      'id': cityData['id']?.toString() ?? '',
      'name': cityData['region_name'] ?? cityData['name'] ?? '',
      'display_name': cityData['region_name'] ?? cityData['name'] ?? '',
      'province_id': cityData['city_id']?.toString() ?? '',
    };
  }

  // تحويل حالة الطلب إلى تنسيق التطبيق
  static String mapProviderStatusToAppStatus(String? providerStatus) {
    if (providerStatus == null) return 'unknown';

    switch (providerStatus.toLowerCase()) {
      case 'created':
      case 'pending':
        return 'processing';
      case 'picked_up':
      case 'in_transit':
        return 'in_delivery';
      case 'delivered':
        return 'delivered';
      case 'cancelled':
        return 'cancelled';
      case 'returned':
        return 'returned';
      default:
        return 'unknown';
    }
  }

  // الحصول على رسالة حالة الطلب بالعربية
  static String getStatusMessage(String status) {
    switch (status) {
      case 'processing':
        return 'قيد المعالجة';
      case 'in_delivery':
        return 'قيد التوصيل';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      case 'returned':
        return 'مرتجع';
      default:
        return 'حالة غير معروفة';
    }
  }
}
