// 🏛️ خدمة الطلبات الرسمية والمنظمة
// تطبيق منتجاتي - نظام إدارة الدروب شيبنگ

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_item.dart';
import 'api_service.dart'; // ✅ استخدام ApiService للتواصل مع الباك إند
import 'inventory_service.dart';
// تم حذف Smart Cache

/// خدمة رسمية لإدارة الطلبات مع هيكل قاعدة بيانات موحد
class OfficialOrdersService extends ChangeNotifier {
  static final OfficialOrdersService _instance = OfficialOrdersService._internal();
  factory OfficialOrdersService() => _instance;
  OfficialOrdersService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// إضافة طلب جديد بالهيكل الرسمي
  Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String primaryPhone,
    String? secondaryPhone,
    required String province,
    required String city,
    String? provinceId, // ✅ إضافة معرف المحافظة
    String? cityId, // ✅ إضافة معرف المدينة
    String? regionId, // ✅ إضافة معرف المنطقة
    String? customerAddress,
    String? notes,
    required List<OrderItem> items,
    required Map<String, int> totals,
    String? userPhone, // ✅ إضافة رقم هاتف المستخدم
  }) async {
    try {
      debugPrint('🏛️ === بدء إنشاء طلب رسمي ===');
      debugPrint('👤 العميل: $customerName');
      debugPrint('📱 الهاتف: $primaryPhone');
      debugPrint('📦 عدد العناصر: ${items.length}');

      // 1. توليد معرف طلب فريد
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderId = 'order_${timestamp}_${primaryPhone.substring(primaryPhone.length - 4)}';
      final orderNumber = 'ORD-$timestamp';

      debugPrint('🆔 معرف الطلب: $orderId');
      debugPrint('🔢 رقم الطلب: $orderNumber');

      // 2. ✅ استخدام الربح النهائي المحسوب في ملخص الطلب (بعد خصم تكلفة التوصيل)
      debugPrint('🔍 فحص البيانات المستلمة من ملخص الطلب:');
      debugPrint('   - totals: $totals');

      // 🔍 تشخيص مفصل للربح المستلم
      debugPrint('🔍 === تشخيص الربح في الخدمة ===');
      debugPrint('   - totals[profit]: ${totals['profit']}');
      debugPrint('   - نوع totals[profit]: ${totals['profit'].runtimeType}');
      debugPrint('   - القيمة الخام: ${totals['profit']}');

      int finalProfit = totals['profit'] ?? 0;

      debugPrint('💰 الربح النهائي من ملخص الطلب (بعد خصم التوصيل): $finalProfit د.ع');

      // ✅ استخدام الربح النهائي من ملخص الطلب دائماً (يشمل خصم التوصيل)
      debugPrint('✅ تم استلام الربح النهائي من ملخص الطلب: $finalProfit د.ع');
      debugPrint('ℹ️ هذا الربح يشمل خصم تكلفة التوصيل إذا تم دفعها من الربح');

      // ✅ تحقق نهائي من الربح
      if (finalProfit < 0) {
        debugPrint('🚨 تحذير: الربح النهائي سالب! سيتم تعيينه إلى 0');
        finalProfit = 0;
      } else if (finalProfit == 0) {
        debugPrint('ℹ️ الربح النهائي = 0 (طلب بدون ربح - هذا طبيعي)');
      }

      debugPrint('💰 الربح النهائي المؤكد: $finalProfit د.ع');

      // 3. إعداد بيانات الطلب الرسمية (أسماء الأعمدة الصحيحة)
      debugPrint('🔍 إعداد البيانات للحفظ في قاعدة البيانات:');
      debugPrint('   - subtotal: ${totals['subtotal']} د.ع');
      debugPrint('   - delivery_fee: ${totals['delivery_fee']} د.ع');
      debugPrint('   - total: ${totals['total']} د.ع');
      debugPrint('   - profit (finalProfit): $finalProfit د.ع');

      // الحصول على user_id من رقم الهاتف
      String? userId;
      if (userPhone != null) {
        try {
          final userResponse = await _supabase.from('users').select('id').eq('phone', userPhone).maybeSingle();

          if (userResponse != null) {
            userId = userResponse['id'];
            debugPrint('✅ تم العثور على user_id: $userId');
          } else {
            debugPrint('⚠️ لم يتم العثور على مستخدم برقم: $userPhone');
          }
        } catch (e) {
          debugPrint('❌ خطأ في البحث عن المستخدم: $e');
        }
      }

      final orderData = {
        'id': orderId,
        'order_number': orderNumber,
        'customer_name': customerName,
        'primary_phone': primaryPhone,
        'secondary_phone': secondaryPhone,
        'province': province,
        'city': city,
        'customer_address': customerAddress ?? '$province - $city',
        'customer_notes': notes, // ✅ حفظ في عمود customer_notes
        'subtotal': totals['subtotal'] ?? 0,
        'delivery_fee': totals['delivery_fee'] ?? 0,
        'total': totals['total'] ?? 0,
        'profit': finalProfit, // ✅ الربح النهائي بعد خصم تكلفة التوصيل
        'profit_amount': finalProfit, // ✅ إضافة profit_amount أيضاً
        'delivery_paid_from_profit': totals['deliveryPaidFromProfit'] ?? 0, // ✅ المبلغ المدفوع من الربح
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'user_phone': userPhone ?? '07503597589', // ✅ استخدام رقم المستخدم الحالي
        'user_id': userId, // ✅ إضافة user_id
      };

      debugPrint('📋 بيانات الطلب: $orderData');

      // 4. ✅ إرسال الطلب إلى الباك إند (آمن وسريع)
      debugPrint('🚀 إرسال الطلب إلى الباك إند...');

      // تحضير بيانات العناصر
      final itemsData = items
          .map(
            (item) => {
              'product_id': item.productId,
              'product_name': item.name,
              'product_image': item.image,
              'wholesale_price': item.wholesalePrice.toInt(),
              'customer_price': item.customerPrice.toInt(),
              'quantity': item.quantity,
              'total_price': (item.customerPrice * item.quantity).toInt(),
              'profit_per_item': ((item.customerPrice - item.wholesalePrice) * item.quantity).toInt(),
            },
          )
          .toList();

      // إرسال الطلب عبر ApiService
      final createdOrderId = await ApiService.createOrder(orderData: orderData, items: itemsData);

      debugPrint('✅ تم إنشاء الطلب عبر الباك إند - ID: $createdOrderId');

      // ✅ الباك إند يتولى حفظ العناصر والأرباح تلقائياً
      debugPrint('✅ الباك إند يتولى حفظ العناصر والأرباح');

      // 7. 🔔 تقليل كمية المنتجات ومراقبة المخزون
      for (final item in items) {
        try {
          // تقليل الكمية المتاحة
          await InventoryService.reserveProduct(productId: item.productId, reservedQuantity: item.quantity);

          debugPrint('✅ تم تقليل كمية المنتج ${item.productId} بمقدار ${item.quantity}');
        } catch (e) {
          debugPrint('⚠️ خطأ في تقليل كمية المنتج ${item.productId}: $e');
        }
      }

      debugPrint('🎉 تم إنشاء الطلب بنجاح!');

      // 🚀 تحديث Smart Cache فوراً بعد إنشاء الطلب
      try {
        if (userPhone != null && userPhone.isNotEmpty) {
          debugPrint('🔄 تحديث Smart Cache بعد إنشاء الطلب للمستخدم: $userPhone');

          // تم حذف Smart Cache - لا حاجة لتحديث الكاش

          debugPrint('✅ تم تحديث Smart Cache بنجاح');
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في تحديث Smart Cache: $e');
        // لا نوقف العملية بسبب خطأ في Cache
      }

      return {
        'success': true,
        'message': 'تم إنشاء الطلب بنجاح',
        'orderId': createdOrderId, // ✅ معرف الطلب من الباك إند
        'orderNumber': orderNumber,
        'totalProfit': finalProfit, // ✅ الربح النهائي
      };
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      debugPrint('🔍 نوع الخطأ: ${e.runtimeType}');
      debugPrint('📋 تفاصيل الخطأ: ${e.toString()}');

      // إضافة تفاصيل أكثر للخطأ
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
