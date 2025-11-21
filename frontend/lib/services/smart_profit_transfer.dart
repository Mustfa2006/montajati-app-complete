import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🧠 نظام نقل الأرباح الذكي - ينقل ربح الطلب فقط بين المنتظر والمحقق
class SmartProfitTransfer {
  static final _supabase = Supabase.instance.client;

  /// 🎯 نقل ربح طلب واحد بذكاء (معطل حاليًا – إدارة الأرباح تتم في قاعدة البيانات)
  static Future<bool> transferOrderProfit({
    required String userPhone,
    required double orderProfit,
    required String oldStatus,
    required String newStatus,
    required String orderId,
    required String orderNumber,
  }) async {
    // ⚠️ ملاحظة مهمة:
    // هذا الكود لم يعد يغير أرباح المستخدم نهائيًا.
    // نظام الأرباح الآن يُدار بالكامل داخل PostgreSQL عبر ORDER_PROFIT_ENGINE.sql
    // + التريغرات على جدول orders.

    try {
      debugPrint('🧠 transferOrderProfit() معطلة – الربح يُدار في قاعدة البيانات فقط');

      // نستمر في تسجيل لوج للتتبع (بدون أي تعديل على جدول users)
      await _addProfitTransferLog(
        userPhone: userPhone,
        orderId: orderId,
        orderNumber: orderNumber,
        orderProfit: orderProfit,
        oldStatus: oldStatus,
        newStatus: newStatus,
        oldAchieved: 0,
        newAchieved: 0,
        oldExpected: 0,
        newExpected: 0,
      );

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في transferOrderProfit (نسخة معطلة): $e');
      return false;
    }
  }

  /// 🎯 تحديد نوع الربح حسب الحالة
  static ProfitType getProfitType(String status) {
    // الحالات المكتملة → ربح محقق
    if (status == 'تم التسليم للزبون') {
      return ProfitType.achieved;
    }

    // الحالات النشطة وقيد التوصيل → ربح منتظر
    if (status == 'نشط' ||
        status == 'تم تغيير محافظة الزبون' ||
        status == 'تغيير المندوب' ||
        status == 'قيد التوصيل الى الزبون (في عهدة المندوب)' ||
        status == 'مؤجل' ||
        status == 'مؤجل لحين اعادة الطلب لاحقا') {
      return ProfitType.expected;
    }

    // الحالات الملغية → لا ربح
    return ProfitType.none;
  }

  /// 📊 الحصول على اسم نوع الربح
  static String _getProfitTypeName(ProfitType type) {
    switch (type) {
      case ProfitType.achieved:
        return 'محقق';
      case ProfitType.expected:
        return 'منتظر';
      case ProfitType.none:
        return 'لا ربح';
    }
  }

  /// 📝 إضافة سجل نقل الأرباح للتتبع
  static Future<void> _addProfitTransferLog({
    required String userPhone,
    required String orderId,
    required String orderNumber,
    required double orderProfit,
    required String oldStatus,
    required String newStatus,
    required double oldAchieved,
    required double newAchieved,
    required double oldExpected,
    required double newExpected,
  }) async {
    try {
      await _supabase.from('profit_transfer_logs').insert({
        'user_phone': userPhone,
        'order_id': orderId,
        'order_number': orderNumber,
        'order_profit': orderProfit,
        'old_status': oldStatus,
        'new_status': newStatus,
        'old_achieved_profits': oldAchieved,
        'new_achieved_profits': newAchieved,
        'old_expected_profits': oldExpected,
        'new_expected_profits': newExpected,
        'transfer_date': DateTime.now().toIso8601String(),
      });
      debugPrint('📝 تم إضافة سجل نقل الأرباح');
    } catch (e) {
      debugPrint('⚠️ خطأ في إضافة سجل نقل الأرباح: $e');
    }
  }

  /// 🔄 إصلاح الأرباح في حالة وجود خطأ
  static Future<bool> fixUserProfits(String userPhone) async {
    try {
      debugPrint('🔧 === إصلاح أرباح المستخدم ===');
      debugPrint('📱 المستخدم: $userPhone');

      // جلب جميع طلبات المستخدم
      final ordersResponse = await _supabase.from('orders').select('profit, status').eq('user_phone', userPhone);

      double totalAchieved = 0.0;
      double totalExpected = 0.0;

      for (var order in ordersResponse) {
        final profit = (order['profit'] ?? 0).toDouble();
        final status = order['status'] ?? '';
        final profitType = getProfitType(status);

        if (profitType == ProfitType.achieved) {
          totalAchieved += profit;
        } else if (profitType == ProfitType.expected) {
          totalExpected += profit;
        }
      }

      debugPrint('🔧 الأرباح المحسوبة:');
      debugPrint('   📈 محقق: $totalAchieved د.ع');
      debugPrint('   📊 منتظر: $totalExpected د.ع');

      // تحديث قاعدة البيانات
      await _supabase
          .from('users')
          .update({
            'achieved_profits': totalAchieved,
            'expected_profits': totalExpected,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('phone', userPhone);

      debugPrint('✅ تم إصلاح الأرباح بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إصلاح الأرباح: $e');
      return false;
    }
  }

  /// 🧪 اختبار سريع للنظام
  static Future<void> testTransfer() async {
    debugPrint('🧪 === اختبار النظام الذكي ===');

    // اختبار تصنيف الحالات
    final testCases = ['نشط', 'تم التسليم للزبون', 'قيد التوصيل الى الزبون (في عهدة المندوب)', 'حظر المندوب', 'مؤجل'];

    for (String status in testCases) {
      final profitType = getProfitType(status);
      debugPrint('   📋 "$status" → ${_getProfitTypeName(profitType)}');
    }

    debugPrint('✅ اختبار التصنيف مكتمل');
  }

  /// 🔧 إصلاح سريع لمستخدم محدد
  static Future<bool> quickFixUser(String userPhone) async {
    try {
      debugPrint('🔧 === إصلاح سريع للمستخدم: $userPhone ===');

      // جلب الأرباح الحالية
      final userResponse = await _supabase
          .from('users')
          .select('achieved_profits, expected_profits, name')
          .eq('phone', userPhone)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ لم يتم العثور على المستخدم');
        return false;
      }

      final currentAchieved = (userResponse['achieved_profits'] ?? 0).toDouble();
      final currentExpected = (userResponse['expected_profits'] ?? 0).toDouble();
      final userName = userResponse['name'] ?? 'غير محدد';

      debugPrint('👤 المستخدم: $userName');
      debugPrint('💰 الأرباح الحالية:');
      debugPrint('   📈 محقق: $currentAchieved د.ع');
      debugPrint('   📊 منتظر: $currentExpected د.ع');

      // إعادة حساب الأرباح الصحيحة
      final result = await fixUserProfits(userPhone);

      if (result) {
        debugPrint('✅ تم إصلاح الأرباح بنجاح');
      } else {
        debugPrint('❌ فشل في إصلاح الأرباح');
      }

      return result;
    } catch (e) {
      debugPrint('❌ خطأ في الإصلاح السريع: $e');
      return false;
    }
  }
}

/// 🎯 أنواع الأرباح
enum ProfitType {
  achieved, // ربح محقق
  expected, // ربح منتظر
  none, // لا ربح
}
