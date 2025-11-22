import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🛡️ خدمة الأرباح بعد النظام العالمي الجديد
///
/// ⚠️ ملاحظة مهمة جداً:
/// - **من الآن فصاعداً، لا يُسمح للفرونت إند أن يغيّر أي أرباح**.
/// - المرجع الوحيد للأرباح هو التريغر في قاعدة البيانات `smart_profit_manager`.
/// - هذه الخدمة أصبحت للقراءة فقط + أدوات تشخيصية بسيطة.
class ProfitsCalculatorService {
  static final _supabase = Supabase.instance.client;

  /// ❌ هذه الدالة لم تعد تستعمل لتعديل الأرباح.
  /// تترك فقط لأغراض توافقية، ولا تقوم بأي تحديث حقيقي.
  static Future<bool> addToExpectedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    debugPrint(
      '⚠️ addToExpectedProfits تم استدعاؤها من الفرونت، النظام الجديد يمنع تعديل الأرباح من التطبيق. سيتم تجاهل الطلب.'
      ' user=$userPhone, amount=$profitAmount, order=$orderId',
    );
    return true; // لا نرمي خطأ حتى لا ينكسر التطبيق، لكن لا نغيّر أي شيء
  }

  /// ❌ هذه الدالة أيضاً أصبحت للـ NO-OP (لا تفعل شيئاً).
  static Future<bool> moveToAchievedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    debugPrint(
      '⚠️ moveToAchievedProfits تم استدعاؤها من الفرونت، لكن الأرباح تُدار فقط داخل قاعدة البيانات. سيتم تجاهل الطلب.'
      ' user=$userPhone, amount=$profitAmount, order=$orderId',
    );
    return true;
  }

  /// ❌ نفس الشيء هنا: لا نحذف أي أرباح من الفرونت إند أبداً.
  static Future<bool> removeFromExpectedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    debugPrint(
      '⚠️ removeFromExpectedProfits تم استدعاؤها من الفرونت، لكن نظام الأرباح أصبح 100% داخل قاعدة البيانات. سيتم تجاهل الطلب.'
      ' user=$userPhone, amount=$profitAmount, order=$orderId',
    );
    return true;
  }

  /// ✅ الدالة الوحيدة المهمة هنا: جلب أرباح المستخدم للعرض فقط.
  static Future<Map<String, double>?> getUserProfits(String userPhone) async {
    try {
      final response = await _supabase.rpc('get_user_profits', params: {'user_phone': userPhone});

      if (response == null || response.isEmpty) return null;

      final userProfits = response[0];
      return {
        'achieved_profits': (userProfits['achieved_profits'] as num?)?.toDouble() ?? 0.0,
        'expected_profits': (userProfits['expected_profits'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب أرباح المستخدم: $e');
      return null;
    }
  }

  /// ✅ أداة تشخيصية فقط: تطبع الأرباح الحالية بدون أي تعديل.
  static Future<bool> validateProfitsCalculation(String userPhone) async {
    try {
      debugPrint('🔍 === التحقق من صحة حسابات الأرباح (قراءة فقط) ===');
      debugPrint('📱 المستخدم: $userPhone');

      final userProfits = await getUserProfits(userPhone);
      if (userProfits == null) {
        debugPrint('❌ لم يتم العثور على المستخدم');
        return false;
      }

      debugPrint('📊 الأرباح المحققة: ${userProfits['achieved_profits']} د.ع');
      debugPrint('📊 الأرباح المنتظرة: ${userProfits['expected_profits']} د.ع');
      debugPrint('✅ تم التحقق من الأرباح بنجاح (بدون أي تعديل)');

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من الأرباح: $e');
      return false;
    }
  }

  /// ❌ إعادة تعيين الأرباح من الفرونت لم تعد مسموحة أبداً.
  static Future<bool> resetUserProfitsFromOrders(String userPhone) async {
    debugPrint(
      '⚠️ resetUserProfitsFromOrders تم استدعاؤها، لكن إعادة تعيين الأرباح تتم فقط من خلال أدوات خاصة في الباك إند أو SQL يدوي. سيتم تجاهل الطلب.'
      ' user=$userPhone',
    );
    return false;
  }
}
