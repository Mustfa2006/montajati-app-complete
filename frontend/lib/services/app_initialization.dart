import 'package:flutter/material.dart';
import 'app_update_service.dart';

/// خدمة تهيئة التطبيق مع النظام الصامت للتحديثات
class AppInitialization {
  
  /// تهيئة التطبيق مع نظام التحديث الصامت
  static Future<void> initialize() async {
    try {
      debugPrint('🚀 بدء تهيئة التطبيق...');
      
      // تهيئة نظام التحديث الصامت
      await AppUpdateService.initialize();
      
      debugPrint('✅ تم تهيئة التطبيق بنجاح');
      
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة التطبيق: $e');
    }
  }
  
  /// تنظيف الموارد عند إغلاق التطبيق
  static void dispose() {
    AppUpdateService.dispose();
    debugPrint('🧹 تم تنظيف موارد التطبيق');
  }
}
