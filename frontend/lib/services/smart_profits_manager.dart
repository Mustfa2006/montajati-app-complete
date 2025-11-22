import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 💰 مدير الأرباح الذكي - يدير الأرباح حسب حالة الطلب
class SmartProfitsManager {
  static final _supabase = Supabase.instance.client;

  /// 🎯 تحديد نوع الربح حسب حالة الطلب
  static ProfitType getProfitType(String orderStatus) {
    // 🟢 الحالات المكتملة → ربح محقق
    if (_isCompletedStatus(orderStatus)) {
      return ProfitType.achieved;
    }

    // 🔵 الحالات النشطة وقيد التوصيل → ربح منتظر
    if (_isActiveOrInDeliveryStatus(orderStatus)) {
      return ProfitType.expected;
    }

    // 🔴 الحالات الملغية → لا ربح
    if (_isCancelledStatus(orderStatus)) {
      return ProfitType.none;
    }

    // 🟡 الحالات المؤجلة → ربح منتظر
    if (_isPostponedStatus(orderStatus)) {
      return ProfitType.expected;
    }

    // افتراضي → ربح منتظر
    return ProfitType.expected;
  }

  /// 🟢 الحالات المكتملة (ربح محقق)
  static bool _isCompletedStatus(String status) {
    return status == 'تم التسليم للزبون';
  }

  /// 🔵 الحالات النشطة وقيد التوصيل (ربح منتظر)
  static bool _isActiveOrInDeliveryStatus(String status) {
    return status == 'نشط' ||
        status == 'تم تغيير محافظة الزبون' ||
        status == 'تغيير المندوب' ||
        status == 'لا يرد' ||
        status == 'لا يرد بعد الاتفاق' ||
        status == 'مغلق' ||
        status == 'مغلق بعد الاتفاق' ||
        status == 'مفصول عن الخدمة' ||
        status == 'طلب مكرر' ||
        status == 'مستلم مسبقا' ||
        status == 'الرقم غير معرف' ||
        status == 'الرقم غير داخل في الخدمة' ||
        status == 'لا يمكن الاتصال بالرقم' ||
        status == 'العنوان غير دقيق' ||
        status == 'لم يطلب' ||
        status == 'حظر المندوب' ||
        status == 'قيد التوصيل الى الزبون (في عهدة المندوب)';
  }

  /// 🔴 الحالات الملغية (لا ربح)
  static bool _isCancelledStatus(String status) {
    return status == 'الغاء الطلب' || status == 'رفض الطلب';
  }

  /// 🟡 الحالات المؤجلة (ربح منتظر)
  static bool _isPostponedStatus(String status) {
    return status == 'مؤجل' || status == 'مؤجل لحين اعادة الطلب لاحقا';
  }

  /// 🔄 إعادة حساب أرباح المستخدم بالطريقة الذكية
  static Future<Map<String, double>> recalculateUserProfits(String userPhone) async {
    try {
      debugPrint('🧠 === إعادة حساب الأرباح الذكية للمستخدم: $userPhone ===');

      // جلب جميع طلبات المستخدم
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, status, profit, order_number, customer_name')
          .eq('user_phone', userPhone);

      double achievedProfits = 0.0;
      double expectedProfits = 0.0;

      Map<String, int> statusCounts = {'achieved': 0, 'expected': 0, 'cancelled': 0, 'postponed': 0};

      debugPrint('📊 تحليل ${ordersResponse.length} طلب:');

      for (var order in ordersResponse) {
        final status = order['status'] ?? '';
        final profit = (order['profit'] ?? 0).toDouble();
        final orderNumber = order['order_number'] ?? order['id'];
        final customerName = order['customer_name'] ?? 'غير محدد';

        final profitType = getProfitType(status);

        switch (profitType) {
          case ProfitType.achieved:
            achievedProfits += profit;
            statusCounts['achieved'] = (statusCounts['achieved'] ?? 0) + 1;
            debugPrint('   ✅ $orderNumber ($customerName): $profit د.ع → محقق');
            break;
          case ProfitType.expected:
            expectedProfits += profit;
            if (_isPostponedStatus(status)) {
              statusCounts['postponed'] = (statusCounts['postponed'] ?? 0) + 1;
              debugPrint('   ⏳ $orderNumber ($customerName): $profit د.ع → منتظر (مؤجل)');
            } else {
              statusCounts['expected'] = (statusCounts['expected'] ?? 0) + 1;
              debugPrint('   📊 $orderNumber ($customerName): $profit د.ع → منتظر');
            }
            break;
          case ProfitType.none:
            statusCounts['cancelled'] = (statusCounts['cancelled'] ?? 0) + 1;
            debugPrint('   ❌ $orderNumber ($customerName): $profit د.ع → ملغي (لا ربح)');
            break;
        }
      }

      debugPrint('📈 === ملخص الأرباح الذكية ===');
      debugPrint('💰 الأرباح المحققة: $achievedProfits د.ع (${statusCounts['achieved']} طلب)');
      debugPrint('📊 الأرباح المنتظرة: $expectedProfits د.ع (${statusCounts['expected']} طلب)');
      debugPrint('⏳ الطلبات المؤجلة: ${statusCounts['postponed']} طلب');
      debugPrint('❌ الطلبات الملغية: ${statusCounts['cancelled']} طلب');

      return {'achieved_profits': achievedProfits, 'expected_profits': expectedProfits};
    } catch (e) {
      debugPrint('❌ خطأ في إعادة حساب الأرباح الذكية: $e');
      return {'achieved_profits': 0.0, 'expected_profits': 0.0};
    }
  }

  /// 🔄 تحديث أرباح المستخدم في قاعدة البيانات - ❌ معطلة: المصدر الوحيد هو التريجر في قاعدة البيانات
  static Future<bool> updateUserProfitsInDatabase(
    String userPhone,
    double achievedProfits,
    double expectedProfits,
  ) async {
    debugPrint(
      '⚠️ [SmartProfitsManager] محاولة تحديث أرباح المستخدم يدويًا سيتم تجاهلها. النظام الجديد يعتمد على التريجر فقط.',
    );
    return false;
  }

  /// 🎯 إعادة حساب وتحديث أرباح المستخدم (دالة شاملة) - الآن للعرض والتحليل فقط
  static Future<bool> smartRecalculateAndUpdate(String userPhone) async {
    try {
      // إعادة حساب الأرباح (للعرض فقط)
      final profits = await recalculateUserProfits(userPhone);
      debugPrint(
        'ℹ️ [SmartProfitsManager] smartRecalculateAndUpdate(): لن يتم حفظ النتائج في users. النظام الجديد يحسب الأرباح داخل قاعدة البيانات فقط.',
      );
      debugPrint(
        '   💰 achieved_profits=${profits['achieved_profits']} د.ع, expected_profits=${profits['expected_profits']} د.ع',
      );
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في العملية الشاملة: $e');
      return false;
    }
  }

  /// 🔄 إعادة حساب أرباح جميع المستخدمين
  static Future<void> recalculateAllUsersProfits() async {
    try {
      debugPrint('🌍 === إعادة حساب أرباح جميع المستخدمين ===');

      // جلب جميع المستخدمين
      final usersResponse = await _supabase.from('users').select('phone, name');

      debugPrint('👥 معالجة ${usersResponse.length} مستخدم...');

      for (var user in usersResponse) {
        final userPhone = user['phone'] as String;
        final userName = user['name'] as String;

        debugPrint('🔄 معالجة: $userName ($userPhone)');

        await smartRecalculateAndUpdate(userPhone);

        // تأخير قصير لتجنب الضغط على قاعدة البيانات
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ تم إعادة حساب أرباح جميع المستخدمين بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة حساب أرباح جميع المستخدمين: $e');
    }
  }

  /// 📊 جلب إحصائيات الأرباح للمستخدم
  static Future<Map<String, dynamic>> getUserProfitsStats(String userPhone) async {
    try {
      final profits = await recalculateUserProfits(userPhone);

      return {
        'achieved_profits': profits['achieved_profits'],
        'expected_profits': profits['expected_profits'],
        'total_profits': profits['achieved_profits']! + profits['expected_profits']!,
        'achievement_rate': profits['expected_profits']! > 0
            ? (profits['achieved_profits']! / (profits['achieved_profits']! + profits['expected_profits']!)) * 100
            : 100.0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات الأرباح: $e');
      return {'achieved_profits': 0.0, 'expected_profits': 0.0, 'total_profits': 0.0, 'achievement_rate': 0.0};
    }
  }
}

/// 🎯 أنواع الأرباح
enum ProfitType {
  achieved, // ربح محقق
  expected, // ربح منتظر
  none, // لا ربح
}
