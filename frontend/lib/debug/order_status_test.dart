// اختبار تحديث حالة الطلبات
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../utils/order_status_helper.dart';

class OrderStatusTest {
  static Future<void> testConnection() async {
    try {
      debugPrint('🔍 اختبار الاتصال بـ Supabase...');

      final client = SupabaseConfig.client;
      debugPrint('✅ تم الحصول على عميل Supabase');
      debugPrint('🔗 URL: ${SupabaseConfig.supabaseUrl}');

      // اختبار جلب الطلبات
      debugPrint('🔍 اختبار جلب الطلبات...');
      final orders = await client
          .from('orders')
          .select('id, status, customer_name')
          .limit(5);

      debugPrint('✅ تم جلب ${orders.length} طلب');

      if (orders.isNotEmpty) {
        final firstOrder = orders.first;
        debugPrint('📋 أول طلب: ${firstOrder['id']}');
        debugPrint('📋 الحالة: ${firstOrder['status']}');
        debugPrint('📋 العميل: ${firstOrder['customer_name']}');

        // اختبار تحديث الحالة
        await testStatusUpdate(firstOrder['id'], firstOrder['status']);
      }
    } catch (e) {
      debugPrint('❌ خطأ في الاتصال: $e');
    }
  }

  static Future<void> testStatusUpdate(
    String orderId,
    String currentStatus,
  ) async {
    try {
      debugPrint('🔄 اختبار تحديث حالة الطلب: $orderId');
      debugPrint('📋 الحالة الحالية: $currentStatus');

      // تحويل الحالة الحالية للعربي
      final currentArabic = OrderStatusHelper.getArabicStatus(currentStatus);
      debugPrint('📋 الحالة العربية الحالية: $currentArabic');

      // اختيار حالة جديدة للاختبار
      final availableStatuses = OrderStatusHelper.getAvailableStatuses();
      String newArabicStatus = availableStatuses.first;

      // اختيار حالة مختلفة عن الحالية
      for (final status in availableStatuses) {
        if (status != currentArabic) {
          newArabicStatus = status;
          break;
        }
      }

      debugPrint('📋 الحالة الجديدة (عربي): $newArabicStatus');

      // تحويل للقيمة المناسبة لقاعدة البيانات
      final newDbStatus = OrderStatusHelper.arabicToDatabase(newArabicStatus);
      debugPrint('📋 الحالة الجديدة (قاعدة البيانات): $newDbStatus');

      // تحديث الحالة
      debugPrint('🔄 بدء تحديث الحالة...');
      final client = SupabaseConfig.client;

      final response = await client
          .from('orders')
          .update({
            'status': newDbStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select();

      debugPrint('✅ استجابة التحديث: $response');

      if (response.isNotEmpty) {
        debugPrint('✅ تم تحديث الحالة بنجاح');
        debugPrint(
          '📋 الحالة الجديدة في قاعدة البيانات: ${response.first['status']}',
        );

        // التحقق من التحديث
        await verifyUpdate(orderId, newDbStatus);
      } else {
        debugPrint('❌ لم يتم تحديث أي صف');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الحالة: $e');
      debugPrint('❌ نوع الخطأ: ${e.runtimeType}');
      debugPrint('❌ تفاصيل الخطأ: ${e.toString()}');
    }
  }

  static Future<void> verifyUpdate(
    String orderId,
    String expectedStatus,
  ) async {
    try {
      debugPrint('🔍 التحقق من التحديث...');

      final client = SupabaseConfig.client;
      final order = await client
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .single();

      debugPrint('📋 الحالة المحدثة: ${order['status']}');
      debugPrint('📋 الحالة المتوقعة: $expectedStatus');

      if (order['status'] == expectedStatus) {
        debugPrint('✅ التحديث تم بنجاح!');
      } else {
        debugPrint('❌ التحديث لم يتم بشكل صحيح');
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق: $e');
    }
  }

  static Future<void> testAllStatusConversions() async {
    debugPrint('🧪 اختبار تحويل جميع الحالات...');

    final statuses = OrderStatusHelper.getAvailableStatuses();

    for (final arabicStatus in statuses) {
      final dbStatus = OrderStatusHelper.arabicToDatabase(arabicStatus);
      final backToArabic = OrderStatusHelper.getArabicStatus(dbStatus);

      debugPrint('🔄 $arabicStatus → $dbStatus → $backToArabic');

      if (arabicStatus != backToArabic) {
        debugPrint('❌ خطأ في التحويل!');
      } else {
        debugPrint('✅ التحويل صحيح');
      }
    }
  }

  static Future<void> runAllTests() async {
    debugPrint('🧪 بدء جميع الاختبارات...');
    debugPrint('=' * 50);

    await testAllStatusConversions();
    debugPrint('=' * 50);

    await testConnection();
    debugPrint('=' * 50);

    debugPrint('🎉 انتهت جميع الاختبارات');
  }
}
