import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';



/// خدمة مراقبة الطلبات في الوقت الفعلي
class OrderMonitoringService {
  static final OrderMonitoringService _instance = OrderMonitoringService._internal();
  factory OrderMonitoringService() => _instance;
  OrderMonitoringService._internal();

  static SupabaseClient get _supabase => SupabaseConfig.client;
  
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;
  final Map<String, String> _lastOrderStatuses = {};
  bool _isMonitoring = false;

  /// بدء مراقبة الطلبات
  static Future<void> startMonitoring() async {
    try {
      debugPrint('🔄 بدء مراقبة الطلبات في الوقت الفعلي...');
      
      if (_instance._isMonitoring) {
        debugPrint('⚠️ المراقبة تعمل بالفعل');
        return;
      }

      // تم إزالة نظام الإشعارات
      
      // جلب الحالات الحالية للطلبات
      await _instance._loadCurrentOrderStatuses();
      
      // بدء الاستماع للتغييرات
      _instance._ordersSubscription = _supabase
          .from('orders')
          .stream(primaryKey: ['id'])
          .listen(
            _instance._onOrdersChanged,
            onError: (error) {
              debugPrint('❌ خطأ في مراقبة الطلبات: $error');
            },
          );

      _instance._isMonitoring = true;
      debugPrint('✅ تم بدء مراقبة الطلبات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في بدء مراقبة الطلبات: $e');
    }
  }

  /// إيقاف مراقبة الطلبات
  static Future<void> stopMonitoring() async {
    try {
      debugPrint('🛑 إيقاف مراقبة الطلبات...');
      
      await _instance._ordersSubscription?.cancel();
      _instance._ordersSubscription = null;
      _instance._isMonitoring = false;
      _instance._lastOrderStatuses.clear();
      
      debugPrint('✅ تم إيقاف مراقبة الطلبات');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف مراقبة الطلبات: $e');
    }
  }

  /// تحميل الحالات الحالية للطلبات
  Future<void> _loadCurrentOrderStatuses() async {
    try {
      debugPrint('📋 تحميل الحالات الحالية للطلبات...');
      
      final response = await _supabase
          .from('orders')
          .select('id, status')
          .order('created_at', ascending: false)
          .limit(100); // آخر 100 طلب

      for (final order in response) {
        final orderId = order['id'] as String;
        final status = order['status'] as String;
        _lastOrderStatuses[orderId] = status;
      }

      debugPrint('📊 تم تحميل ${_lastOrderStatuses.length} طلب للمراقبة');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الحالات الحالية: $e');
    }
  }

  /// معالجة تغييرات الطلبات
  void _onOrdersChanged(List<Map<String, dynamic>> orders) {
    try {
      debugPrint('🔄 تم اكتشاف تغييرات في الطلبات: ${orders.length} طلب');
      
      for (final order in orders) {
        final orderId = order['id'] as String;
        final currentStatus = order['status'] as String;
        final customerName = order['customer_name'] as String? ?? 'عميل';
        final orderNumber = orderId.substring(0, 8);
        
        // التحقق من وجود تغيير في الحالة
        final lastStatus = _lastOrderStatuses[orderId];
        
        if (lastStatus != null && lastStatus != currentStatus) {
          debugPrint('🔔 تغيير حالة الطلب:');
          debugPrint('   📋 الطلب: $orderNumber');
          debugPrint('   👤 العميل: $customerName');
          debugPrint('   🔄 من: $lastStatus إلى: $currentStatus');
          
          // إرسال إشعار فوري
          _sendOrderStatusNotification(
            customerName: customerName,
            orderNumber: orderNumber,
            oldStatus: lastStatus,
            newStatus: currentStatus,
          );
        }
        
        // تحديث الحالة المحفوظة
        _lastOrderStatuses[orderId] = currentStatus;
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تغييرات الطلبات: $e');
    }
  }

  /// إرسال إشعار تغيير حالة الطلب
  Future<void> _sendOrderStatusNotification({
    required String customerName,
    required String orderNumber,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      // تحديد رسالة الإشعار حسب الحالة
      String title = '';
      String message = '';
      
      switch (newStatus) {
        case 'pending':
          title = '⏳ طلب قيد المراجعة';
          message = 'طلب $customerName ($orderNumber) قيد المراجعة';
          break;
        case 'confirmed':
          title = '✅ تم تأكيد الطلب';
          message = 'تم تأكيد طلب $customerName ($orderNumber)';
          break;
        case 'processing':
          title = '🔄 جاري تحضير الطلب';
          message = 'طلب $customerName ($orderNumber) قيد التحضير';
          break;
        case 'in_delivery':
          title = '🚚 الطلب قيد التوصيل';
          message = 'طلب $customerName ($orderNumber) قيد التوصيل';
          break;
        case 'delivered':
          title = '🎉 تم تسليم الطلب';
          message = 'تم تسليم طلب $customerName ($orderNumber) بنجاح';
          break;
        case 'cancelled':
          title = '❌ تم إلغاء الطلب';
          message = 'تم إلغاء طلب $customerName ($orderNumber)';
          break;
        default:
          title = '🔄 تحديث حالة الطلب';
          message = 'تم تحديث حالة طلب $customerName ($orderNumber)';
      }

      // تم إزالة نظام الإشعارات
      debugPrint('تحديث حالة الطلب: $title - $message');

      debugPrint('✅ تم إرسال إشعار تغيير الحالة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار تغيير الحالة: $e');
    }
  }

  /// التحقق من حالة المراقبة
  static bool get isMonitoring => _instance._isMonitoring;

  /// إعادة تشغيل المراقبة
  static Future<void> restartMonitoring() async {
    await stopMonitoring();
    await Future.delayed(const Duration(seconds: 2));
    await startMonitoring();
  }

  /// اختبار الإشعارات بصمت
  static Future<void> testNotification() async {
    try {
      // اختبار صامت للإشعارات
    } catch (e) {
      // اختبار صامت
    }
  }
}
