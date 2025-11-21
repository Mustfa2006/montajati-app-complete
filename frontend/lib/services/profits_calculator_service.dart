import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🛡️ خدمة حساب الأرباح الآمنة 100%
///
/// ✅ النظام الجديد الآمن:
/// - لا إعادة حساب من قاعدة البيانات أبداً
/// - عمليات بسيطة فقط: إضافة/نقل/حذف
/// - استخدام دوال آمنة من قاعدة البيانات
/// - حماية من الأخطاء المالية 100%
///
/// 🎯 طريقة العمل:
/// 1. عند تثبيت طلب: safe_add_expected_profit()
/// 2. عند التوصيل: safe_move_to_achieved_profit()
/// 3. عند الحذف: safe_remove_expected_profit()
class ProfitsCalculatorService {
  static final _supabase = Supabase.instance.client;

  /// ✅ إضافة ربح إلى الأرباح المنتظرة (عند تثبيت طلب جديد)
  // ❌ لم يعد الفرونت إند مسؤولاً عن تعديل الأرباح، كل شيء عبر Profit Engine في قاعدة البيانات
  static Future<bool> addToExpectedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    debugPrint('addToExpectedProfits() معطلة – الربح يُدار من خلال ORDER_PROFIT_ENGINE.sql فقط');
    return true;
  }

  // الإبقاء على التوقيع لاستخدامه لاحقاً إن احتجنا إشعاراً فقط بدون تعديل القيم
  static Future<bool> moveToAchievedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    debugPrint('moveToAchievedProfits() معطلة – التحويل يتم تلقائياً في التريغر');
    return true;
  }

  static Future<bool> removeFromExpectedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    debugPrint('removeFromExpectedProfits() معطلة – الحذف يتم تلقائياً إذا احتجنا عبر الباك إند/SQL');
    return true;
  }

  /// 🛡️ جلب الأرباح الحالية للمستخدم (نظام آمن)
  static Future<Map<String, double>> getUserProfits(String userPhone) async {
    try {
      final userResponse = await _supabase
          .from('users')
          .select('achieved_profits, expected_profits')
          .eq('phone', userPhone)
          .maybeSingle();
      if (userResponse == null) {
        return {'achieved': 0.0, 'expected': 0.0};
      }
      final achieved = (userResponse['achieved_profits'] as num?)?.toDouble() ?? 0.0;
      final expected = (userResponse['expected_profits'] as num?)?.toDouble() ?? 0.0;
      return {'achieved': achieved, 'expected': expected};
    } catch (_) {
      return {'achieved': 0.0, 'expected': 0.0};
    }
  }
}
