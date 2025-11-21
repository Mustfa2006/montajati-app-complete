import 'package:flutter/foundation.dart';

/// Logger مركزي للتحكم في جميع سجلات التطبيق.
///
/// - على الويب: يتم تعطيل جميع السجلات نهائياً لتجنب تهنيج المتصفح.
/// - في الإصدارات النهائية (release): يتم تعطيل السجلات أيضاً.
/// - في وضع التطوير على الموبايل: تعمل السجلات بشكل طبيعي.
class AppLogger {
  AppLogger._();

  /// سجلات معلومات / ديبغ خفيفة.
  static void debug(String message) {
    if (kIsWeb) return; // لا نطبع أي شيء على الويب
    if (!kDebugMode) return; // لا نطبع في الإصدارات النهائية
    _safePrint(message);
  }

  /// سجلات للأخطاء المهمة.
  static void error(String message) {
    if (kIsWeb) return; // حتى الأخطاء لا نطبعها على الويب لتقليل الضغط
    _safePrint(message);
  }

  /// تنفيذ آمن لـ debugPrint مع التفاف بسيط على الأخطاء.
  static void _safePrint(String message) {
    try {
      debugPrint(message);
    } catch (_) {
      // تجاهل أي خطأ في الطباعة حتى لا يؤثر على التطبيق.
    }
  }
}

