import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 🔥 خدمة النمط الغامر الشاملة - تعمل على جميع الأجهزة
class ImmersiveModeService {
  static Timer? _hideTimer;
  static bool _isNavigationBarVisible = false;
  static const MethodChannel _channel = MethodChannel('immersive_mode');

  /// 🎯 إخفاء Navigation Bar فقط - Status Bar ثابت (شامل لجميع الأجهزة)
  static Future<void> enableImmersiveMode() async {
    try {
      if (Platform.isAndroid) {
        // طريقة 1: Flutter SystemChrome
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top], // Status Bar ثابت فقط
        );

        // طريقة 2: Native Android (للأجهزة العنيدة)
        try {
          await _channel.invokeMethod('hideNavigationBar');
        } catch (e) {
          debugPrint('⚠️ Native method غير متوفر: $e');
        }
      }

      _isNavigationBarVisible = false;
      debugPrint('✅ Navigation Bar مخفي - Status Bar ثابت');
    } catch (e) {
      debugPrint('❌ خطأ في إخفاء Navigation Bar: $e');
    }
  }

  /// 👆 إظهار Navigation Bar مؤقتاً - Status Bar ثابت (شامل لجميع الأجهزة)
  static Future<void> showNavigationBarTemporarily() async {
    try {
      // إلغاء أي مؤقت سابق
      _hideTimer?.cancel();

      if (Platform.isAndroid) {
        // طريقة 1: Flutter SystemChrome
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom], // كلاهما ظاهر
        );

        // طريقة 2: Native Android
        try {
          await _channel.invokeMethod('showNavigationBar');
        } catch (e) {
          debugPrint('⚠️ Native method غير متوفر: $e');
        }
      }

      _isNavigationBarVisible = true;
      debugPrint('👆 Navigation Bar ظاهر مؤقتاً - Status Bar ثابت');

      // إخفاء Navigation Bar فقط بعد 3 ثوانٍ
      _hideTimer = Timer(const Duration(seconds: 3), () {
        enableImmersiveMode();
      });
    } catch (e) {
      debugPrint('❌ خطأ في إظهار Navigation Bar: $e');
    }
  }

  /// 🔄 إعادة تعيين النمط الغامر (للاستخدام عند تغيير الصفحات)
  static Future<void> resetImmersiveMode() async {
    _hideTimer?.cancel();
    await enableImmersiveMode();
  }

  /// 🧹 تنظيف الموارد
  static void dispose() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  /// 📱 فحص حالة Navigation Bar
  static bool get isNavigationBarVisible => _isNavigationBarVisible;
}
