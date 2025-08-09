import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// مساعد التشخيص لمراقبة تحديث حالات الطلبات
class DebugHelper {
  static const String _tag = 'ORDER_STATUS_DEBUG';
  
  /// طباعة رسالة تشخيص مع timestamp
  static void log(String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final finalTag = tag ?? _tag;
    
    if (kDebugMode) {
      print('[$timestamp] [$finalTag] $message');
      developer.log(message, name: finalTag, time: DateTime.now());
    }
  }
  
  /// طباعة خطأ مع تفاصيل
  static void logError(String message, dynamic error, {StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    
    if (kDebugMode) {
      print('[$timestamp] [ERROR] $message');
      print('[$timestamp] [ERROR] Error: $error');
      if (stackTrace != null) {
        print('[$timestamp] [ERROR] StackTrace: $stackTrace');
      }
      
      developer.log(
        message,
        name: 'ERROR',
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }
  }
  
  /// طباعة معلومات تحديث حالة الطلب
  static void logOrderStatusUpdate({
    required String orderId,
    required String oldStatus,
    required String newStatus,
    String? additionalInfo,
  }) {
    log('🔄 تحديث حالة الطلب:');
    log('   📝 معرف الطلب: $orderId');
    log('   📋 الحالة القديمة: $oldStatus');
    log('   📋 الحالة الجديدة: $newStatus');
    if (additionalInfo != null) {
      log('   ℹ️ معلومات إضافية: $additionalInfo');
    }
  }
  
  /// طباعة نتيجة عملية التحديث
  static void logUpdateResult({
    required String orderId,
    required bool success,
    String? errorMessage,
  }) {
    if (success) {
      log('✅ نجح تحديث حالة الطلب: $orderId');
    } else {
      log('❌ فشل تحديث حالة الطلب: $orderId');
      if (errorMessage != null) {
        log('❌ سبب الفشل: $errorMessage');
      }
    }
  }
  
  /// طباعة معلومات الاتصال بقاعدة البيانات
  static void logDatabaseConnection({
    required bool connected,
    String? errorMessage,
  }) {
    if (connected) {
      log('🔗 الاتصال بقاعدة البيانات: متصل');
    } else {
      log('❌ الاتصال بقاعدة البيانات: منقطع');
      if (errorMessage != null) {
        log('❌ خطأ الاتصال: $errorMessage');
      }
    }
  }
}
