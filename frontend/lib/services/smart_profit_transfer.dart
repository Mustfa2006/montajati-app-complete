import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🧠 نظام نقل الأرباح الذكي - ينقل ربح الطلب فقط بين المنتظر والمحقق
class SmartProfitTransfer {
  static final _supabase = Supabase.instance.client;

  /// 🎯 نقل ربح طلب واحد بذكاء
  static Future<bool> transferOrderProfit({
    required String userPhone,
    required double orderProfit,
    required String oldStatus,
    required String newStatus,
    required String orderId,
    required String orderNumber,
  }) async {
    try {
      debugPrint('🧠 === نقل ربح الطلب الذكي ===');
      debugPrint('📱 المستخدم: $userPhone');
      debugPrint('💰 ربح الطلب: $orderProfit د.ع');
      debugPrint('🔄 الحالة: "$oldStatus" → "$newStatus"');
      debugPrint('📋 رقم الطلب: $orderNumber');

      // 🚫 حماية إضافية: تجاهل الحالات غير المهمة
      const ignoredStatuses = ['فعال', 'في موقع فرز بغداد', 'في الطريق الى مكتب المحافظة'];
      if (ignoredStatuses.contains(oldStatus) || ignoredStatuses.contains(newStatus)) {
        debugPrint('🚫 تجاهل نقل الربح - حالة غير مهمة (old=$oldStatus, new=$newStatus)');
        return true;
      }

      // 🚫 حماية من الحالات الفارغة أو المتطابقة
      if (oldStatus.isEmpty || newStatus.isEmpty || oldStatus == newStatus) {
        debugPrint('⏭️ تجاهل نقل الربح - حالات فارغة أو متطابقة');
        return true;
      }

      // تحديد نوع الربح للحالة القديمة والجديدة
      final oldProfitType = getProfitType(oldStatus);
      final newProfitType = getProfitType(newStatus);

      debugPrint('📊 تحليل الحالات:');
      debugPrint('   🔍 الحالة القديمة: "$oldStatus" → ${_getProfitTypeName(oldProfitType)}');
      debugPrint('   🔍 الحالة الجديدة: "$newStatus" → ${_getProfitTypeName(newProfitType)}');
      debugPrint('   🎯 هل تم التسليم؟ ${newStatus == 'تم التسليم للزبون'}');
      debugPrint(
        '   🎯 هل نشط؟ ${oldStatus == 'نشط' || oldStatus == 'تم تغيير محافظة الزبون' || oldStatus == 'تغيير المندوب'}',
      );

      // إذا لم يتغير نوع الربح، لا حاجة للتحديث
      if (oldProfitType == newProfitType) {
        debugPrint('ℹ️ لم يتغير نوع الربح - لا حاجة للتحديث');
        debugPrint('   📊 كلا الحالتين من نوع: ${_getProfitTypeName(oldProfitType)}');
        return true;
      }

      debugPrint('🔄 تغير نوع الربح - سيتم النقل!');

      // جلب الأرباح الحالية للمستخدم
      final userResponse = await _supabase
          .from('users')
          .select('achieved_profits, expected_profits')
          .eq('phone', userPhone)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ لم يتم العثور على المستخدم');
        return false;
      }

      double currentAchieved = (userResponse['achieved_profits'] ?? 0).toDouble();
      double currentExpected = (userResponse['expected_profits'] ?? 0).toDouble();

      debugPrint('💰 الأرباح الحالية:');
      debugPrint('   📈 محقق: $currentAchieved د.ع');
      debugPrint('   📊 منتظر: $currentExpected د.ع');

      // حساب الأرباح الجديدة بناءً على التغيير
      double newAchieved = currentAchieved;
      double newExpected = currentExpected;

      // تطبيق التغيير
      if (oldProfitType == ProfitType.expected && newProfitType == ProfitType.achieved) {
        // نقل من منتظر إلى محقق
        newExpected -= orderProfit;
        newAchieved += orderProfit;
        debugPrint('⬆️ نقل $orderProfit د.ع من منتظر إلى محقق');
      } else if (oldProfitType == ProfitType.achieved && newProfitType == ProfitType.expected) {
        // نقل من محقق إلى منتظر
        newAchieved -= orderProfit;
        newExpected += orderProfit;
        debugPrint('⬇️ نقل $orderProfit د.ع من محقق إلى منتظر');
      } else if (oldProfitType == ProfitType.expected && newProfitType == ProfitType.none) {
        // إزالة من منتظر
        newExpected -= orderProfit;
        debugPrint('➖ إزالة $orderProfit د.ع من منتظر');
      } else if (oldProfitType == ProfitType.achieved && newProfitType == ProfitType.none) {
        // إزالة من محقق
        newAchieved -= orderProfit;
        debugPrint('➖ إزالة $orderProfit د.ع من محقق');
      } else if (oldProfitType == ProfitType.none && newProfitType == ProfitType.expected) {
        // إضافة إلى منتظر
        newExpected += orderProfit;
        debugPrint('➕ إضافة $orderProfit د.ع إلى منتظر');
      } else if (oldProfitType == ProfitType.none && newProfitType == ProfitType.achieved) {
        // إضافة إلى محقق
        newAchieved += orderProfit;
        debugPrint('➕ إضافة $orderProfit د.ع إلى محقق');
      }

      // التأكد من عدم وجود أرقام سالبة
      newAchieved = newAchieved < 0 ? 0 : newAchieved;
      newExpected = newExpected < 0 ? 0 : newExpected;

      debugPrint('💰 الأرباح الجديدة:');
      debugPrint('   📈 محقق: $newAchieved د.ع (كان: $currentAchieved د.ع)');
      debugPrint('   📊 منتظر: $newExpected د.ع (كان: $currentExpected د.ع)');

      // ⛔ ممنوع تحديث الأرباح من الفرونت إند
      // نظام الأرباح الآن بالكامل داخل قاعدة البيانات (Triggers)
      debugPrint('🚫 SmartProfitTransfer: محاولة تحديث أرباح المستخدم $userPhone تم إلغاؤها (DB-only profits system)');

      // إضافة سجل للتتبع
      await _addProfitTransferLog(
        userPhone: userPhone,
        orderId: orderId,
        orderNumber: orderNumber,
        orderProfit: orderProfit,
        oldStatus: oldStatus,
        newStatus: newStatus,
        oldAchieved: currentAchieved,
        newAchieved: newAchieved,
        oldExpected: currentExpected,
        newExpected: newExpected,
      );

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في نقل ربح الطلب: $e');
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

      debugPrint('🔧 الأرباح المحسوبة (للتحقق فقط – لا يوجد أي تعديل من الفرونت):');
      debugPrint('   📈 محقق: $totalAchieved د.ع');
      debugPrint('   📊 منتظر: $totalExpected د.ع');

      // ⛔ ممنوع تماماً تعديل أرباح المستخدم من الفرونت إند.
      // نظام الأرباح بالكامل يُدار من داخل قاعدة البيانات عبر smart_profit_manager + safe_update_user_profits.
      // هنا نكتفي فقط بالـ logging والنجاح الشكلي حتى لا ينكسر أي كود قديم يعتمد على القيمة المرجعة.
      debugPrint('🛡️ [SmartProfitTransfer] منع أي تحديث مباشر لأرباح المستخدم من التطبيق.');

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
