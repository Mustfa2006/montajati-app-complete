// ===================================
// خدمة إدارة الطلبات الإنتاجية والمعتمدة
// النظام الكامل والمتكامل - الإصدار الإنتاجي
// ===================================

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';

class OfficialOrderService {
  static String get _baseUrl => ApiConfig.apiUrl;
  static const Duration _timeout = Duration(seconds: 30);

  // ===================================
  // إنشاء طلب جديد (رسمي)
  // ===================================
  static Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String primaryPhone,
    String? secondaryPhone,
    String? email,
    required String cityId,
    required String regionId,
    required String deliveryAddress,
    String? deliveryNotes,
    String? customerNotes, // ✅ إضافة ملاحظات العميل
    required List<Map<String, dynamic>> items,
    required double subtotal,
    double deliveryFee = 0,
  }) async {
    try {
      debugPrint('📦 إنشاء طلب جديد في النظام الرسمي...');

      // إنشاء معرف فريد للطلب
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      // الحصول على معرف المستخدم الحالي
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id ?? 'bba1fc61-3db9-4c5f-8b19-d8689251990d';
      final userPhone = currentUser?.phone ?? '07503597589';

      // حساب الربح (افتراضي 20% من المجموع الفرعي)
      final profit = subtotal * 0.2;

      final total = subtotal + deliveryFee;

      final requestBody = {
        'id': orderId,
        'customer_name': customerName,
        'primary_phone': primaryPhone,
        'secondary_phone': secondaryPhone,
        'email': email,
        'customer_address': deliveryAddress,
        'delivery_address': deliveryAddress,
        'delivery_notes': deliveryNotes,
        'notes': customerNotes,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total': total,
        'profit': profit,
        'profit_amount': profit,
        'status': 'active',
        'user_id': userId,
        'user_phone': userPhone,
        'order_number': orderNumber,
        'items': jsonEncode(items),
      };

      debugPrint('📋 بيانات الطلب: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/orders'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');
      debugPrint('📄 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          // التحقق من أن الاستجابة ليست فارغة
          if (response.body.isEmpty) {
            throw Exception('استجابة فارغة من الخادم');
          }

          // تنظيف الاستجابة من أي رموز غير مرغوب فيها
          String cleanBody = response.body.trim();

          // التحقق من أن الاستجابة تبدأ بـ {
          if (!cleanBody.startsWith('{')) {
            debugPrint('⚠️ الاستجابة لا تبدأ بـ JSON صحيح');
            debugPrint(
              '📄 أول 100 حرف: ${cleanBody.substring(0, cleanBody.length > 100 ? 100 : cleanBody.length)}',
            );
            throw Exception('تنسيق استجابة غير صحيح من الخادم');
          }

          final result = jsonDecode(cleanBody);
          debugPrint('✅ تم إنشاء الطلب بنجاح');
          debugPrint('📋 تفاصيل الاستجابة: ${jsonEncode(result)}');
          return result;
        } catch (e) {
          debugPrint('❌ خطأ في تحليل JSON: $e');
          debugPrint('📄 محتوى الاستجابة الخام: ${response.body}');
          debugPrint('📏 طول الاستجابة: ${response.body.length}');
          throw Exception('خطأ في تحليل استجابة الخادم: $e');
        }
      } else {
        debugPrint('❌ خطأ HTTP ${response.statusCode}');
        debugPrint('📄 محتوى الخطأ: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      throw Exception('فشل في إنشاء الطلب: $e');
    }
  }

  // ===================================
  // جلب جميع الطلبات
  // ===================================
  static Future<Map<String, dynamic>> getOrders({
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      debugPrint('📋 جلب الطلبات...');

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(
        '$_baseUrl/orders',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ تم جلب ${result['data']?.length ?? 0} طلب');
        return result;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات: $e');
      throw Exception('فشل في جلب الطلبات: $e');
    }
  }

  // ===================================
  // جلب طلب محدد
  // ===================================
  static Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      debugPrint('🔍 جلب الطلب: $orderId');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/orders/$orderId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ تم جلب الطلب بنجاح');
        return result;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلب: $e');
      throw Exception('فشل في جلب الطلب: $e');
    }
  }

  // ===================================
  // تحديث حالة الطلب
  // ===================================
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? reason,
    String changedBy = 'admin',
  }) async {
    try {
      debugPrint('\n🚀 ===== بداية تحديث حالة الطلب =====');
      debugPrint('⏰ الوقت: ${DateTime.now().toIso8601String()}');
      debugPrint('🆔 معرف الطلب: $orderId');
      debugPrint('📊 الحالة الجديدة: "$status"');
      debugPrint('📝 السبب: ${reason ?? "غير محدد"}');
      debugPrint('👤 تم التغيير بواسطة: $changedBy');
      debugPrint('🔄 تحديث حالة الطلب $orderId إلى $status');

      final requestBody = {
        'status': status,
        'reason': reason,
        'changedBy': changedBy,
      };

      debugPrint('📦 البيانات المرسلة: ${jsonEncode(requestBody)}');
      debugPrint('🌐 URL: $_baseUrl/orders/$orderId/status');
      debugPrint('📤 إرسال الطلب...');

      final response = await http
          .put(
            Uri.parse('$_baseUrl/orders/$orderId/status'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      debugPrint('📥 استجابة الخادم:');
      debugPrint('   📊 Status Code: ${response.statusCode}');
      debugPrint('   📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ تم تحديث حالة الطلب بنجاح');
        debugPrint('📋 النتيجة: ${jsonEncode(result)}');
        debugPrint('✅ تم تحديث حالة الطلب بنجاح');
        return result;
      } else if (response.statusCode == 429) {
        // معالجة خاصة لخطأ تجاوز الحد المسموح
        debugPrint('⚠️ تجاوز الحد المسموح من الطلبات - Status: ${response.statusCode}');
        debugPrint('⚠️ Response: ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          final retryAfterMinutes = errorData['retryAfterMinutes'] ?? 1;
          throw Exception('تجاوزت العدد المسموح من الطلبات. حاول مرة أخرى بعد $retryAfterMinutes دقيقة.');
        } catch (e) {
          if (e.toString().contains('تجاوزت العدد المسموح')) {
            rethrow;
          }
          throw Exception('تجاوزت العدد المسموح من الطلبات. حاول مرة أخرى بعد 1 دقيقة.');
        }
      } else {
        debugPrint('❌ فشل في تحديث الحالة - Status: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الطلب: $e');
      debugPrint('❌ خطأ في تحديث حالة الطلب: $e');
      throw Exception('فشل في تحديث حالة الطلب: $e');
    }
  }

  // ===================================
  // فحص صحة النظام
  // ===================================
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      debugPrint('🏥 فحص صحة النظام...');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ النظام يعمل بشكل طبيعي');
        return result;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص النظام: $e');
      throw Exception('فشل في فحص النظام: $e');
    }
  }

  // ===================================
  // دالة للتوافق مع النظام القديم
  // ===================================
  @Deprecated('Use createOfficialOrder instead. This method will be removed in future versions.')
  static Future<Map<String, dynamic>> createLocalOrder({
    required String localOrderId,
    required String clientName,
    required String clientMobile,
    required String cityId,
    required String regionId,
    required String location,
    required int itemsNumber,
    required double price,
  }) async {
    debugPrint('⚠️ استخدام دالة قديمة - سيتم التحويل للنظام الجديد');

    // تحويل إلى النظام الجديد
    return createOrder(
      customerName: clientName,
      primaryPhone: clientMobile,
      cityId: cityId,
      regionId: regionId,
      deliveryAddress: location,
      items: [
        {
          'name': 'منتج عام',
          'quantity': itemsNumber,
          'price': price / itemsNumber,
          'sku': 'GENERAL_PRODUCT',
        },
      ],
      subtotal: price,
    );
  }

  // ===================================
  // دوال مساعدة
  // ===================================

  // تحويل حالة الطلب إلى نص عربي
  static String getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'confirmed':
        return 'مؤكد';
      case 'in_delivery':
        return 'قيد التوصيل';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  // تحويل حالة الطلب إلى لون
  static String getStatusColor(String status) {
    switch (status) {
      case 'active':
        return '#FFD700'; // أصفر ذهبي
      case 'confirmed':
        return '#FFD700'; // أصفر ذهبي
      case 'in_delivery':
        return '#17a2b8'; // سماوي
      case 'shipped':
        return '#17a2b8'; // سماوي
      case 'delivered':
        return '#28a745'; // أخضر
      case 'cancelled':
        return '#dc3545'; // أحمر
      default:
        return '#6c757d'; // رمادي
    }
  }
}
