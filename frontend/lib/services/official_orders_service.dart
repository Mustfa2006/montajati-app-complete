// 🏛️ خدمة الطلبات الرسمية والمنظمة
// تطبيق منتجاتي - نظام إدارة الدروب شيبنگ

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_item.dart';
import 'api_service.dart'; // ✅ استخدام ApiService للتواصل مع الباك إند
// ❌ تم حذف inventory_service - Backend يتولى المخزون
// تم حذف Smart Cache

/// خدمة رسمية لإدارة الطلبات مع هيكل قاعدة بيانات موحد
class OfficialOrdersService extends ChangeNotifier {
  static final OfficialOrdersService _instance = OfficialOrdersService._internal();
  factory OfficialOrdersService() => _instance;
  OfficialOrdersService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔐 إضافة طلب جديد (نظام آمن - الحسابات في السيرفر)
  /// ✅ Flutter يرسل فقط البيانات الأساسية
  /// ✅ Backend يحسب الأسعار، الربح، التوصيل، المجموع
  Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String primaryPhone,
    String? secondaryPhone,
    required String province,
    required String city,
    String? provinceId,
    String? cityId,
    String? regionId,
    String? customerAddress,
    String? notes,
    required List<OrderItem> items,
    required Map<String, int> totals, // سيتم تجاهلها في السيرفر
    String? userPhone,
    Function(String status, int attempt)? onStatusChange,
  }) async {
    try {
      debugPrint('🔐 ══════════════════════════════════════════');
      debugPrint('🔐 إنشاء طلب آمن (Server-Side Calculations)');
      debugPrint('👤 العميل: $customerName');
      debugPrint('📱 الهاتف: $primaryPhone');
      debugPrint('📦 عدد العناصر: ${items.length}');
      debugPrint('🔐 ══════════════════════════════════════════');

      // ═══════════════════════════════════════════
      // 🔐 إعداد البيانات الأساسية فقط (لا حسابات!)
      // ═══════════════════════════════════════════
      // ✅ Flutter يرسل: المنتجات، الكميات، سعر العميل، خيار التوصيل
      // ✅ Backend يحسب: سعر الجملة، الربح، التوصيل، المجموع

      // تحضير بيانات العناصر (الأساسية فقط)
      final List<Map<String, dynamic>> itemsData = items.map((item) {
        return <String, dynamic>{
          'product_id': item.productId,
          'quantity': item.quantity,
          'customer_price': item.customerPrice.toInt(), // سعر العميل (يحدده التاجر)
        };
      }).toList();

      // تحديد خيار التوصيل
      final deliveryPaidFromProfit = totals['deliveryPaidFromProfit'] ?? 0;
      String deliveryOption;
      if (deliveryPaidFromProfit > 0) {
        deliveryOption = deliveryPaidFromProfit.toString(); // المبلغ المخصوم من الربح
      } else {
        deliveryOption = 'customer_pays'; // العميل يدفع كل التوصيل
      }

      // بيانات الطلب الأساسية (بدون حسابات!)
      final orderData = {
        'customer_name': customerName,
        'primary_phone': primaryPhone,
        'secondary_phone': secondaryPhone,
        'province': province,
        'city': city,
        'province_id': provinceId,
        'city_id': cityId,
        'customer_address': customerAddress ?? '$province - $city',
        'customer_notes': notes,
        'user_phone': userPhone,
        'delivery_option': deliveryOption, // ✅ خيار التوصيل
      };

      debugPrint('📤 إرسال البيانات الأساسية فقط إلى Backend...');
      debugPrint('📦 عدد العناصر: ${itemsData.length}');
      debugPrint('🚚 خيار التوصيل: $deliveryOption');

      // ═══════════════════════════════════════════
      // 🚀 إرسال الطلب إلى الباك إند
      // ═══════════════════════════════════════════
      // Backend يحسب كل شيء: الأسعار، الربح، التوصيل، المجموع

      final createdOrderId = await ApiService.createOrder(
        orderData: orderData,
        items: itemsData,
        onStatusChange: onStatusChange,
      );

      debugPrint('✅ ══════════════════════════════════════════');
      debugPrint('✅ تم إنشاء الطلب بنجاح!');
      debugPrint('🆔 معرف الطلب: $createdOrderId');
      debugPrint('✅ Backend حسب الأسعار والربح والتوصيل');
      debugPrint('✅ ══════════════════════════════════════════');

      // ❌ لا نقلل المخزون هنا - Backend يتولى ذلك
      debugPrint('ℹ️ Backend يتولى تحديث المخزون');

      return {'success': true, 'message': 'تم إنشاء الطلب بنجاح', 'orderId': createdOrderId};
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      debugPrint('🔍 نوع الخطأ: ${e.runtimeType}');

      String errorMessage = 'فشل في إنشاء الطلب';
      if (e.toString().contains('timeout')) {
        errorMessage = 'انتهت مهلة الاتصال - تحقق من الإنترنت';
      } else if (e.toString().contains('network')) {
        errorMessage = 'مشكلة في الشبكة - تحقق من الاتصال';
      } else if (e.toString().contains('duplicate')) {
        errorMessage = 'الطلب موجود مسبقاً';
      } else if (e.toString().contains('foreign key')) {
        errorMessage = 'خطأ في ربط البيانات';
      } else {
        errorMessage = 'فشل في إنشاء الطلب: ${e.toString()}';
      }

      return {'success': false, 'message': errorMessage, 'error': e.toString(), 'errorType': e.runtimeType.toString()};
    }
  }

  /// جلب الطلبات للمستخدم
  Future<List<Map<String, dynamic>>> getUserOrders(String userPhone) async {
    try {
      debugPrint('📋 جلب طلبات المستخدم: $userPhone');

      final ordersResponse = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              id,
              product_id,
              product_name,
              product_image,
              wholesale_price,
              customer_price,
              quantity,
              total_price,
              profit_per_item
            )
          ''')
          .eq('primary_phone', userPhone)
          .order('created_at', ascending: false);

      debugPrint('✅ تم جلب ${ordersResponse.length} طلب');
      return List<Map<String, dynamic>>.from(ordersResponse);
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  /// تحديث حالة الطلب
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      debugPrint('🔄 تحديث حالة الطلب: $orderId → $newStatus');

      await _supabase
          .from('orders')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      debugPrint('✅ تم تحديث حالة الطلب');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  /// حذف طلب
  Future<bool> deleteOrder(String orderId) async {
    try {
      debugPrint('🗑️ حذف الطلب: $orderId');

      // ✅ الخطوة 1: حذف معاملات الربح أولاً (مهم لتجنب خطأ Foreign Key)
      final deleteProfitResponse = await _supabase
          .from('profit_transactions')
          .delete()
          .eq('order_id', orderId)
          .select();

      debugPrint('✅ تم حذف ${deleteProfitResponse.length} معاملة ربح للطلب');

      // ✅ الخطوة 2: حذف الطلب (ستُحذف order_items تلقائياً بسبب CASCADE)
      await _supabase.from('orders').delete().eq('id', orderId);

      debugPrint('✅ تم حذف الطلب وعناصره ومعاملات الربح بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الطلب: $e');
      return false;
    }
  }

  /// الحصول على إحصائيات الطلبات
  Future<Map<String, dynamic>> getOrdersStatistics(String userPhone) async {
    try {
      final ordersResponse = await _supabase
          .from('orders')
          .select('status, total, profit')
          .eq('primary_phone', userPhone);

      int totalOrders = ordersResponse.length;
      int activeOrders = 0;
      int deliveredOrders = 0;
      int cancelledOrders = 0;
      int totalSales = 0;
      int totalProfits = 0;

      for (var order in ordersResponse) {
        final status = order['status'] as String;
        final total = (order['total'] as num?)?.toInt() ?? 0;
        final profit = (order['profit'] as num?)?.toInt() ?? 0;

        totalSales += total;
        totalProfits += profit;

        switch (status) {
          case 'confirmed':
          case 'active':
          case 'in_delivery':
            activeOrders++;
            break;
          case 'delivered':
            deliveredOrders++;
            break;
          case 'cancelled':
          case 'rejected':
            cancelledOrders++;
            break;
        }
      }

      return {
        'totalOrders': totalOrders,
        'activeOrders': activeOrders,
        'deliveredOrders': deliveredOrders,
        'cancelledOrders': cancelledOrders,
        'totalSales': totalSales,
        'totalProfits': totalProfits,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات الطلبات: $e');
      return {};
    }
  }
}
