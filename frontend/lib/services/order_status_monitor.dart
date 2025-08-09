import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'smart_profit_transfer.dart';

/// 👁️ مراقب حالة الطلبات - يراقب تغيير الحالات ويحدث الأرباح تلقائياً
class OrderStatusMonitor {
  static final _supabase = Supabase.instance.client;
  static bool _isMonitoring = false;

  /// 🚀 بدء مراقبة تغيير حالات الطلبات
  static void startMonitoring() {
    if (_isMonitoring) return;
    
    debugPrint('👁️ بدء مراقبة تغيير حالات الطلبات...');
    
    _supabase
        .channel('order_status_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: _handleOrderStatusChange,
        )
        .subscribe();
    
    _isMonitoring = true;
    debugPrint('✅ تم تفعيل مراقبة حالات الطلبات');
  }

  /// 🛑 إيقاف مراقبة تغيير حالات الطلبات
  static void stopMonitoring() {
    if (!_isMonitoring) return;
    
    debugPrint('🛑 إيقاف مراقبة حالات الطلبات...');
    
    _supabase.removeAllChannels();
    _isMonitoring = false;
    
    debugPrint('✅ تم إيقاف مراقبة حالات الطلبات');
  }

  /// 🔄 معالجة تغيير حالة الطلب
  static void _handleOrderStatusChange(PostgresChangePayload payload) async {
    try {
      debugPrint('🔔 === تم رصد تغيير في حالة طلب ===');
      
      final oldRecord = payload.oldRecord;
      final newRecord = payload.newRecord;

      if (oldRecord.isEmpty || newRecord.isEmpty) return;
      
      final orderId = newRecord['id'];
      final orderNumber = newRecord['order_number'] ?? orderId;
      final customerName = newRecord['customer_name'] ?? 'غير محدد';
      final userPhone = newRecord['user_phone'];
      final profit = (newRecord['profit'] ?? 0).toDouble();
      
      final oldStatus = oldRecord['status'] ?? '';
      final newStatus = newRecord['status'] ?? '';
      
      // تجاهل إذا لم تتغير الحالة
      if (oldStatus == newStatus) return;
      
      debugPrint('📋 تفاصيل التغيير:');
      debugPrint('   🆔 رقم الطلب: $orderNumber');
      debugPrint('   👤 العميل: $customerName');
      debugPrint('   📱 المستخدم: $userPhone');
      debugPrint('   💰 الربح: $profit د.ع');
      debugPrint('   🔄 الحالة: "$oldStatus" → "$newStatus"');
      
      // نقل ربح الطلب بذكاء
      if (userPhone != null && profit > 0) {
        debugPrint('🧠 نقل ربح الطلب بذكاء...');

        final success = await SmartProfitTransfer.transferOrderProfit(
          userPhone: userPhone,
          orderProfit: profit,
          oldStatus: oldStatus,
          newStatus: newStatus,
          orderId: orderId,
          orderNumber: orderNumber,
        );

        if (success) {
          debugPrint('✅ تم نقل ربح الطلب تلقائياً');

          // إرسال إشعار للمستخدم إذا تحول الربح إلى محقق
          if (newStatus == 'تم التسليم للزبون' && oldStatus != 'تم التسليم للزبون') {
            await _notifyProfitAchieved(userPhone, orderNumber, customerName, profit);
          }
        } else {
          debugPrint('❌ فشل في نقل ربح الطلب');
        }
      } else {
        debugPrint('ℹ️ لا يوجد رقم هاتف أو ربح للطلب');
      }
      
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تغيير حالة الطلب: $e');
    }
  }

  /// 📱 إرسال إشعار عند تحقق الربح
  static Future<void> _notifyProfitAchieved(
    String userPhone,
    String orderNumber,
    String customerName,
    double profit,
  ) async {
    try {
      debugPrint('📱 إرسال إشعار تحقق الربح...');
      
      // يمكن إضافة إرسال إشعار push notification هنا
      // أو إضافة سجل في جدول الإشعارات
      
      debugPrint('🎉 تم تحقق ربح $profit د.ع من طلب $orderNumber للعميل $customerName');
      
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار تحقق الربح: $e');
    }
  }

  // تم حذف دالة _getProfitTypeName غير المستخدمة

  /// 🔄 إعادة حساب أرباح طلب محدد
  static Future<bool> recalculateOrderProfit(String orderId) async {
    try {
      debugPrint('🔄 إعادة حساب ربح الطلب: $orderId');
      
      // جلب بيانات الطلب
      final orderResponse = await _supabase
          .from('orders')
          .select('user_phone, status, profit, order_number, customer_name')
          .eq('id', orderId)
          .maybeSingle();
      
      if (orderResponse == null) {
        debugPrint('❌ لم يتم العثور على الطلب');
        return false;
      }
      
      final userPhone = orderResponse['user_phone'];
      if (userPhone == null) {
        debugPrint('❌ لا يوجد رقم هاتف للمستخدم');
        return false;
      }
      
      // إصلاح أرباح المستخدم
      return await SmartProfitTransfer.fixUserProfits(userPhone);
      
    } catch (e) {
      debugPrint('❌ خطأ في إعادة حساب ربح الطلب: $e');
      return false;
    }
  }

  /// 📊 إحصائيات المراقبة
  static Map<String, dynamic> getMonitoringStats() {
    return {
      'is_monitoring': _isMonitoring,
      'monitor_start_time': _isMonitoring ? DateTime.now().toIso8601String() : null,
    };
  }

  /// اختبار النظام بصمت
  static Future<void> testSystem() async {
    try {
      // اختبار تصنيف الحالات
      final testStatuses = [
        'نشط',
        'تم التسليم للزبون',
        'قيد التوصيل الى الزبون (في عهدة المندوب)',
        'حظر المندوب',
        'مؤجل',
        'لا يرد',
      ];

      for (String status in testStatuses) {
        SmartProfitTransfer.getProfitType(status);
      }

    } catch (e) {
      // اختبار صامت
    }
  }
}
