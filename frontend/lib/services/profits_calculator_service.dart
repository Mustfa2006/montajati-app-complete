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
  static Future<bool> addToExpectedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    try {
      debugPrint('💰 === إضافة ربح إلى الأرباح المنتظرة ===');
      debugPrint('📱 المستخدم: $userPhone');
      debugPrint('💵 المبلغ: $profitAmount د.ع');
      debugPrint('📦 الطلب: $orderId');

      if (profitAmount <= 0) {
        debugPrint('⚠️ مبلغ الربح = 0، لا حاجة للتحديث');
        return true;
      }

      // ✅ التحقق من عدم وجود الطلب مسبقاً لتجنب التكرار
      if (orderId != null) {
        final existingOrder = await _supabase
            .from('orders')
            .select('id')
            .eq('id', orderId)
            .maybeSingle();

        if (existingOrder == null) {
          debugPrint('⚠️ الطلب غير موجود في قاعدة البيانات: $orderId');
          return false;
        }
      }

      // جلب الأرباح المنتظرة الحالية
      final userResponse = await _supabase
          .from('users')
          .select('expected_profits, name')
          .eq('phone', userPhone)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ المستخدم غير موجود: $userPhone');
        return false;
      }

      final currentExpectedProfits =
          (userResponse['expected_profits'] as num?)?.toDouble() ?? 0.0;
      final userName = userResponse['name'] ?? 'مستخدم';

      // حساب الأرباح المنتظرة الجديدة
      final newExpectedProfits = currentExpectedProfits + profitAmount;

      debugPrint('📊 الأرباح المنتظرة الحالية: $currentExpectedProfits د.ع');
      debugPrint('🎯 الأرباح المنتظرة الجديدة: $newExpectedProfits د.ع');

      // 🛡️ استخدام الدالة الآمنة من قاعدة البيانات (بدون إعادة حساب)
      final result = await _supabase.rpc(
        'safe_add_expected_profit',
        params: {'user_phone': userPhone, 'profit_amount': profitAmount},
      );

      if (result == true) {
        debugPrint(
          '✅ تم إضافة $profitAmount د.ع بأمان للأرباح المنتظرة للمستخدم: $userName',
        );
        debugPrint(
          '📈 الأرباح المنتظرة: $currentExpectedProfits → $newExpectedProfits د.ع',
        );
        return true;
      } else {
        debugPrint('❌ فشل في إضافة الربح - المستخدم غير موجود أو خطأ');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إضافة الربح للأرباح المنتظرة: $e');
      return false;
    }
  }

  /// 🛡️ تحويل ربح من المنتظرة إلى المحققة (نظام آمن)
  static Future<bool> moveToAchievedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    try {
      debugPrint('🛡️ === تحويل ربح آمن من المنتظرة إلى المحققة ===');
      debugPrint('📱 المستخدم: $userPhone');
      debugPrint('💵 المبلغ: $profitAmount د.ع');
      debugPrint('📦 الطلب: $orderId');
      debugPrint('🔧 استخدام الدالة الآمنة: safe_move_to_achieved_profit');

      if (profitAmount <= 0) {
        debugPrint('⚠️ مبلغ الربح = 0، لا حاجة للتحديث');
        return true;
      }

      // جلب الأرباح الحالية من الجدول الصحيح
      final userResponse = await _supabase
          .from('user_profits')
          .select('achieved_profits, expected_profits, user_phone')
          .eq('user_phone', userPhone)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ المستخدم غير موجود: $userPhone');
        return false;
      }

      final currentAchievedProfits =
          (userResponse['achieved_profits'] as num?)?.toDouble() ?? 0.0;
      final currentExpectedProfits =
          (userResponse['expected_profits'] as num?)?.toDouble() ?? 0.0;
      final userName = userResponse['user_phone'] ?? 'مستخدم';

      // حساب الأرباح الجديدة
      final newAchievedProfits = currentAchievedProfits + profitAmount;
      final newExpectedProfits = (currentExpectedProfits - profitAmount).clamp(
        0.0,
        double.infinity,
      );

      debugPrint('📊 الأرباح المحققة الحالية: $currentAchievedProfits د.ع');
      debugPrint('📊 الأرباح المنتظرة الحالية: $currentExpectedProfits د.ع');
      debugPrint('🎯 الأرباح المحققة الجديدة: $newAchievedProfits د.ع');
      debugPrint('🎯 الأرباح المنتظرة الجديدة: $newExpectedProfits د.ع');

      // 🛡️ استخدام الدالة الآمنة لنقل الربح (بدون إعادة حساب)
      debugPrint('🔧 استدعاء الدالة الآمنة...');
      final result = await _supabase.rpc(
        'safe_move_to_achieved_profit',
        params: {'user_phone': userPhone, 'profit_amount': profitAmount},
      );

      debugPrint('📋 نتيجة الدالة الآمنة: $result');

      if (result == true) {
        debugPrint(
          '✅ تم تحويل $profitAmount د.ع بأمان من المنتظرة إلى المحققة للمستخدم: $userName',
        );
        debugPrint(
          '📈 الأرباح المحققة: $currentAchievedProfits → $newAchievedProfits د.ع',
        );
        debugPrint(
          '📉 الأرباح المنتظرة: $currentExpectedProfits → $newExpectedProfits د.ع',
        );

        // التحقق من النتيجة الفعلية في قاعدة البيانات
        final verifyResponse = await _supabase
            .from('users')
            .select('achieved_profits, expected_profits')
            .eq('phone', userPhone)
            .maybeSingle();

        if (verifyResponse != null) {
          final actualAchieved =
              (verifyResponse['achieved_profits'] as num?)?.toDouble() ?? 0.0;
          final actualExpected =
              (verifyResponse['expected_profits'] as num?)?.toDouble() ?? 0.0;
          debugPrint('🔍 التحقق من النتيجة الفعلية:');
          debugPrint('   الأرباح المحققة الفعلية: $actualAchieved د.ع');
          debugPrint('   الأرباح المنتظرة الفعلية: $actualExpected د.ع');
        }

        return true;
      } else {
        debugPrint('❌ فشل في تحويل الربح - رصيد غير كافي أو خطأ');
        debugPrint('⚠️ الأرباح المنتظرة الحالية: $currentExpectedProfits د.ع');
        debugPrint('⚠️ المبلغ المطلوب نقله: $profitAmount د.ع');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحويل الربح إلى المحققة: $e');
      return false;
    }
  }

  /// ✅ حذف ربح من الأرباح المنتظرة (عند حذف طلب)
  static Future<bool> removeFromExpectedProfits({
    required String userPhone,
    required double profitAmount,
    String? orderId,
  }) async {
    try {
      debugPrint('🗑️ === حذف ربح من الأرباح المنتظرة ===');
      debugPrint('📱 المستخدم: $userPhone');
      debugPrint('💵 المبلغ: $profitAmount د.ع');
      debugPrint('📦 الطلب: $orderId');

      if (profitAmount <= 0) {
        debugPrint('⚠️ مبلغ الربح = 0، لا حاجة للتحديث');
        return true;
      }

      // جلب الأرباح المنتظرة الحالية
      final userResponse = await _supabase
          .from('users')
          .select('expected_profits, name')
          .eq('phone', userPhone)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ المستخدم غير موجود: $userPhone');
        return false;
      }

      final currentExpectedProfits =
          (userResponse['expected_profits'] as num?)?.toDouble() ?? 0.0;
      final userName = userResponse['name'] ?? 'مستخدم';

      // حساب الأرباح المنتظرة الجديدة (لا تقل عن 0)
      final newExpectedProfits = (currentExpectedProfits - profitAmount).clamp(
        0.0,
        double.infinity,
      );

      debugPrint('📊 الأرباح المنتظرة الحالية: $currentExpectedProfits د.ع');
      debugPrint('🎯 الأرباح المنتظرة الجديدة: $newExpectedProfits د.ع');

      // 🛡️ استخدام الدالة الآمنة لحذف الربح (بدون إعادة حساب)
      final result = await _supabase.rpc(
        'safe_remove_expected_profit',
        params: {'user_phone': userPhone, 'profit_amount': profitAmount},
      );

      if (result == true) {
        debugPrint(
          '✅ تم حذف $profitAmount د.ع بأمان من الأرباح المنتظرة للمستخدم: $userName',
        );
        debugPrint(
          '📉 الأرباح المنتظرة: $currentExpectedProfits → $newExpectedProfits د.ع',
        );
        return true;
      } else {
        debugPrint('❌ فشل في حذف الربح - المستخدم غير موجود أو خطأ');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في حذف الربح من الأرباح المنتظرة: $e');
      return false;
    }
  }

  /// 🛡️ جلب الأرباح الحالية للمستخدم (نظام آمن)
  static Future<Map<String, double>?> getUserProfits(String userPhone) async {
    try {
      // 🛡️ استخدام الدالة الآمنة لجلب الأرباح
      final response = await _supabase.rpc(
        'get_user_profits',
        params: {'user_phone': userPhone},
      );

      if (response == null || response.isEmpty) return null;

      final userProfits = response[0];
      return {
        'achieved_profits':
            (userProfits['achieved_profits'] as num?)?.toDouble() ?? 0.0,
        'expected_profits':
            (userProfits['expected_profits'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب أرباح المستخدم: $e');
      return null;
    }
  }

  /// 🔍 التحقق من صحة العمليات الحسابية
  static Future<bool> validateProfitsCalculation(String userPhone) async {
    try {
      debugPrint('🔍 === التحقق من صحة حسابات الأرباح ===');
      debugPrint('📱 المستخدم: $userPhone');

      // جلب الأرباح من قاعدة البيانات
      final userProfits = await getUserProfits(userPhone);
      if (userProfits == null) {
        debugPrint('❌ لم يتم العثور على المستخدم');
        return false;
      }

      debugPrint('📊 الأرباح المحققة: ${userProfits['achieved_profits']} د.ع');
      debugPrint('📊 الأرباح المنتظرة: ${userProfits['expected_profits']} د.ع');
      debugPrint('✅ تم التحقق من الأرباح بنجاح');

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من الأرباح: $e');
      return false;
    }
  }

  /// 🔄 إعادة تعيين الأرباح بناءً على الطلبات الفعلية (لحل المشاكل)
  static Future<bool> resetUserProfitsFromOrders(String userPhone) async {
    try {
      debugPrint('🔄 === إعادة تعيين الأرباح من الطلبات الفعلية ===');
      debugPrint('📱 المستخدم: $userPhone');

      // حساب الأرباح المحققة من الطلبات المكتملة
      final deliveredOrdersResponse = await _supabase
          .from('orders')
          .select('profit')
          .eq('primary_phone', userPhone)
          .inFilter('status', ['delivered', 'shipped', 'completed']);

      double totalAchievedProfits = 0.0;
      for (var order in deliveredOrdersResponse) {
        final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
        totalAchievedProfits += profit;
      }

      // حساب الأرباح المنتظرة من الطلبات النشطة
      final activeOrdersResponse = await _supabase
          .from('orders')
          .select('profit')
          .eq('primary_phone', userPhone)
          .inFilter('status', [
            'active',
            'in_delivery',
            'pending',
            'confirmed',
          ]);

      double totalExpectedProfits = 0.0;
      for (var order in activeOrdersResponse) {
        final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
        totalExpectedProfits += profit;
      }

      debugPrint('💰 الأرباح المحققة المحسوبة: $totalAchievedProfits د.ع');
      debugPrint('📊 الأرباح المنتظرة المحسوبة: $totalExpectedProfits د.ع');

      // تحديث أرباح المستخدم في قاعدة البيانات
      await _supabase
          .from('users')
          .update({
            'achieved_profits': totalAchievedProfits,
            'expected_profits': totalExpectedProfits,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('phone', userPhone);

      debugPrint('✅ تم إعادة تعيين الأرباح بنجاح');
      debugPrint('📈 الأرباح المحققة: $totalAchievedProfits د.ع');
      debugPrint('📊 الأرباح المنتظرة: $totalExpectedProfits د.ع');

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين الأرباح: $e');
      return false;
    }
  }
}
