// خدمة API للاتصال مع Backend - نظام ذكي ومتطور
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// 🎯 إعدادات النظام الذكي لإنشاء الطلبات
class SmartOrderConfig {
  /// الحد الأقصى لعدد محاولات إعادة المحاولة
  static const int maxRetries = 5;

  /// الوقت الأساسي للانتظار بين المحاولات (ثواني)
  static const int baseDelaySeconds = 2;

  /// الحد الأقصى للانتظار بين المحاولات (ثواني)
  static const int maxDelaySeconds = 30;

  /// مهلة الاتصال للإنترنت الضعيف (ثواني)
  static const int weakNetworkTimeout = 60;

  /// مهلة الاتصال العادية (ثواني)
  static const int normalTimeout = 30;

  /// عدد محاولات التحقق من نجاح الطلب
  static const int verificationRetries = 3;
}

/// 📊 حالة إنشاء الطلب
enum OrderCreationStatus { pending, sending, retrying, verifying, success, failed }

/// 📦 نتيجة إنشاء الطلب
class OrderCreationResult {
  final bool success;
  final String? orderId;
  final String? message;
  final int attempts;
  final Duration totalDuration;
  final OrderCreationStatus status;

  OrderCreationResult({
    required this.success,
    this.orderId,
    this.message,
    required this.attempts,
    required this.totalDuration,
    required this.status,
  });
}

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

  // ===================================
  // 🚀 نظام إنشاء الطلبات الذكي والمتطور
  // ===================================

  /// 📤 إنشاء طلب جديد عبر الباك إند (نظام ذكي مع إعادة المحاولة)
  /// - يدعم الإنترنت الضعيف
  /// - إعادة محاولة ذكية مع exponential backoff
  /// - التحقق من نجاح الطلب في قاعدة البيانات
  /// - لا يخرج حتى يتأكد من نجاح الطلب
  /// 🔐 إنشاء طلب جديد (نظام آمن - الحسابات في السيرفر)
  /// ✅ Flutter يرسل البيانات الأساسية فقط
  /// ✅ Backend يحسب الأسعار، الربح، التوصيل، المجموع
  static Future<String> createOrder({
    required Map<String, dynamic> orderData,
    required List<Map<String, dynamic>> items,
    Function(String status, int attempt)? onStatusChange,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;
    String? lastError;
    String? createdOrderId; // سيتم تعيينه من Backend

    // معرف مؤقت للتحقق (يستخدم رقم الهاتف والوقت)
    final tempId = 'temp_${orderData['primary_phone']}_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('🔐 ══════════════════════════════════════════');
    debugPrint('🔐 بدء نظام إنشاء الطلب الآمن');
    debugPrint('📤 البيانات الأساسية فقط (لا حسابات!)');
    debugPrint('🔗 URL: $baseUrl/api/orders');
    debugPrint('🔐 ══════════════════════════════════════════');

    // تحضير البيانات (الأساسية فقط - لا حسابات!)
    final requestBody = {...orderData, 'items': items};
    final bodyJson = jsonEncode(requestBody);

    debugPrint('📦 عدد المنتجات: ${items.length}');
    debugPrint('👤 العميل: ${orderData['customer_name']}');
    debugPrint('📱 الهاتف: ${orderData['primary_phone']}');

    // محاولات إنشاء الطلب مع إعادة المحاولة الذكية
    while (attempts < SmartOrderConfig.maxRetries) {
      attempts++;
      onStatusChange?.call(
        attempts == 1 ? 'جاري إرسال الطلب...' : 'إعادة المحاولة ($attempts/${SmartOrderConfig.maxRetries})...',
        attempts,
      );

      debugPrint('📤 ─────────────────────────────────────');
      debugPrint('📤 المحاولة $attempts من ${SmartOrderConfig.maxRetries}');

      try {
        // حساب timeout ديناميكي (يزداد مع كل محاولة)
        final timeout = Duration(seconds: SmartOrderConfig.normalTimeout + (attempts * 10));
        debugPrint('⏱️ مهلة الاتصال: ${timeout.inSeconds} ثانية');

        final response = await http
            .post(
              Uri.parse('$baseUrl/api/orders'),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: bodyJson,
            )
            .timeout(
              timeout,
              onTimeout: () {
                debugPrint('⏰ انتهت مهلة الاتصال (${timeout.inSeconds} ثانية)');
                throw TimeoutException('انتهت مهلة الاتصال', timeout);
              },
            );

        debugPrint('📡 استجابة الباك إند: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;

          if (responseData['success'] == true) {
            createdOrderId = responseData['orderId']?.toString() ?? responseData['data']?['id']?.toString();
            stopwatch.stop();

            // عرض القيم المحسوبة من Backend
            final calculatedValues = responseData['calculatedValues'];
            if (calculatedValues != null) {
              debugPrint('💰 ═══ القيم المحسوبة من Backend ═══');
              debugPrint('   المجموع الفرعي: ${calculatedValues['subtotal']} د.ع');
              debugPrint('   رسوم التوصيل: ${calculatedValues['deliveryFee']} د.ع');
              debugPrint('   المجموع النهائي: ${calculatedValues['total']} د.ع');
              debugPrint('   الربح: ${calculatedValues['finalProfit']} د.ع');
              debugPrint('💰 ═══════════════════════════════════');
            }

            debugPrint('✅ ══════════════════════════════════════════');
            debugPrint('✅ تم إنشاء الطلب بنجاح!');
            debugPrint('🆔 معرف الطلب: $createdOrderId');
            debugPrint('📊 عدد المحاولات: $attempts');
            debugPrint('⏱️ الوقت: ${responseData['duration'] ?? stopwatch.elapsedMilliseconds}ms');
            debugPrint('✅ ══════════════════════════════════════════');

            onStatusChange?.call('تم إنشاء الطلب بنجاح!', attempts);
            return createdOrderId ?? tempId;
          } else {
            lastError = responseData['error']?.toString() ?? 'فشل في إنشاء الطلب';
            debugPrint('⚠️ الاستجابة غير ناجحة: $lastError');
          }
        } else if (response.statusCode >= 500) {
          // خطأ في الخادم - يمكن إعادة المحاولة
          lastError = 'خطأ في الخادم (${response.statusCode})';
          debugPrint('⚠️ خطأ في الخادم: ${response.statusCode}');
        } else {
          // خطأ في البيانات - لا فائدة من إعادة المحاولة
          lastError = 'خطأ في البيانات (${response.statusCode})';
          debugPrint('❌ خطأ في البيانات: ${response.statusCode} - ${response.body}');
          break;
        }
      } on TimeoutException {
        lastError = 'انتهت مهلة الاتصال - الإنترنت بطيء';
        debugPrint('⏰ انتهت مهلة الاتصال - سيتم إعادة المحاولة');

        // التحقق من أن الطلب ربما تم إنشاؤه رغم انتهاء المهلة
        // نستخدم رقم الهاتف للتحقق لأن Backend يولد الـ ID
        final phone = orderData['primary_phone']?.toString() ?? '';
        final verified = await _verifyOrderByPhone(phone);
        if (verified != null) {
          stopwatch.stop();
          debugPrint('✅ تم التحقق - الطلب موجود في قاعدة البيانات!');
          onStatusChange?.call('تم التحقق من إنشاء الطلب!', attempts);
          return verified;
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('❌ خطأ: $e');

        // إذا كان خطأ شبكة، نحاول التحقق من الطلب
        if (_isNetworkError(e)) {
          debugPrint('🔍 خطأ شبكة - التحقق من إنشاء الطلب...');
          final phone = orderData['primary_phone']?.toString() ?? '';
          final verified = await _verifyOrderByPhone(phone);
          if (verified != null) {
            stopwatch.stop();
            debugPrint('✅ تم التحقق - الطلب موجود في قاعدة البيانات!');
            onStatusChange?.call('تم التحقق من إنشاء الطلب!', attempts);
            return verified;
          }
        }
      }

      // الانتظار قبل إعادة المحاولة (exponential backoff مع jitter)
      if (attempts < SmartOrderConfig.maxRetries) {
        final delay = _calculateRetryDelay(attempts);
        debugPrint('⏳ الانتظار ${delay.inSeconds} ثانية قبل إعادة المحاولة...');
        onStatusChange?.call('الانتظار ${delay.inSeconds} ثانية...', attempts);
        await Future.delayed(delay);
      }
    }

    // محاولة أخيرة للتحقق من الطلب
    debugPrint('🔍 المحاولة الأخيرة للتحقق من الطلب...');
    onStatusChange?.call('التحقق النهائي...', attempts);
    final phone = orderData['primary_phone']?.toString() ?? '';
    final finalCheck = await _verifyOrderByPhone(phone);
    if (finalCheck != null) {
      stopwatch.stop();
      debugPrint('✅ تم العثور على الطلب في التحقق النهائي!');
      return finalCheck;
    }

    stopwatch.stop();
    debugPrint('❌ ══════════════════════════════════════════');
    debugPrint('❌ فشل إنشاء الطلب بعد $attempts محاولات');
    debugPrint('❌ السبب: $lastError');
    debugPrint('⏱️ الوقت المستغرق: ${stopwatch.elapsed.inSeconds} ثانية');
    debugPrint('❌ ══════════════════════════════════════════');

    throw Exception(lastError ?? 'فشل في إنشاء الطلب');
  }

  /// 🔍 التحقق من أن الطلب تم إنشاؤه باستخدام رقم هاتف العميل
  /// نبحث عن آخر طلب تم إنشاؤه لهذا الرقم في آخر دقيقة
  static Future<String?> _verifyOrderByPhone(String phone) async {
    if (phone.isEmpty) return null;

    for (int i = 0; i < SmartOrderConfig.verificationRetries; i++) {
      try {
        debugPrint('🔍 التحقق من الطلب برقم الهاتف (${i + 1}/${SmartOrderConfig.verificationRetries})...');

        // البحث عن آخر طلب لهذا الرقم
        final response = await http
            .get(
              Uri.parse('$baseUrl/api/orders/verify-recent?phone=$phone'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['orderId'] != null) {
            final foundId = data['orderId']?.toString();
            debugPrint('✅ تم العثور على الطلب: $foundId');
            return foundId;
          }
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في التحقق: $e');
      }

      if (i < SmartOrderConfig.verificationRetries - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  /// 📊 حساب وقت الانتظار بين المحاولات (exponential backoff مع jitter)
  static Duration _calculateRetryDelay(int attempt) {
    // Exponential backoff: 2^attempt * base delay
    final exponentialDelay = (1 << attempt) * SmartOrderConfig.baseDelaySeconds;
    // الحد الأقصى
    final cappedDelay = exponentialDelay.clamp(SmartOrderConfig.baseDelaySeconds, SmartOrderConfig.maxDelaySeconds);
    // إضافة jitter عشوائي (0-20%)
    final jitter = (cappedDelay * 0.2 * (DateTime.now().millisecondsSinceEpoch % 100) / 100).round();
    return Duration(seconds: cappedDelay + jitter);
  }

  /// 🌐 التحقق من نوع الخطأ (هل هو خطأ شبكة؟)
  static bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('failed to fetch') ||
        errorString.contains('socketexception') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('clientexception');
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
