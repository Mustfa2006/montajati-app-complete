import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/order_item.dart' as order_item_model;

/// ✅ خدمة جلب تفاصيل الطلب من Backend API
/// لا تستدعي قاعدة البيانات مباشرة - آمن وموثوق
class OrderDetailsService {
  static const String baseUrl = 'https://montajati-official-backend-production.up.railway.app';

  /// 📥 جلب تفاصيل طلب محدد من Backend
  static Future<Order> fetchOrderDetails(String orderId) async {
    try {
      debugPrint('📥 جلب تفاصيل الطلب');

      final url = Uri.parse('$baseUrl/api/orders/$orderId');

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30), onTimeout: () => throw Exception('انتهت مهلة الاتصال'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final orderData = jsonData['data'];
          final isScheduledOrder = jsonData['isScheduledOrder'] ?? false;

          debugPrint('✅ تم جلب الطلب بنجاح');

          // ✅ تحويل عناصر الطلب (حسب نوع الطلب)
          final itemsKey = isScheduledOrder ? 'scheduled_order_items' : 'order_items';
          final orderItems =
              (orderData[itemsKey] as List?)
                  ?.map(
                    (item) => order_item_model.OrderItem(
                      id: item['id']?.toString() ?? '',
                      productId: item['product_id'] ?? '',
                      name: item['product_name'] ?? '',
                      image: item['product_image'] ?? '',
                      wholesalePrice:
                          double.tryParse(item['wholesale_price']?.toString() ?? item['price']?.toString() ?? '0') ??
                          0.0,
                      customerPrice:
                          double.tryParse(item['customer_price']?.toString() ?? item['price']?.toString() ?? '0') ??
                          0.0,
                      quantity: item['quantity'] ?? 1,
                    ),
                  )
                  .toList() ??
              [];

          // ✅ تحويل البيانات إلى Order model
          final totalAmount =
              int.tryParse(orderData['total_amount']?.toString() ?? orderData['total']?.toString() ?? '0') ?? 0;
          final subtotalAmount =
              int.tryParse(orderData['total_amount']?.toString() ?? orderData['subtotal']?.toString() ?? '0') ?? 0;
          final profitAmount =
              int.tryParse(orderData['profit_amount']?.toString() ?? orderData['total_profit']?.toString() ?? '0') ?? 0;

          final order = Order(
            id: orderData['id'] ?? '',
            customerName: orderData['customer_name'] ?? '',
            primaryPhone: isScheduledOrder ? (orderData['customer_phone'] ?? '') : (orderData['primary_phone'] ?? ''),
            secondaryPhone: isScheduledOrder
                ? (orderData['customer_alternate_phone'] ?? '')
                : (orderData['secondary_phone'] ?? ''),
            province: isScheduledOrder ? (orderData['customer_province'] ?? '') : (orderData['province'] ?? ''),
            city: isScheduledOrder ? (orderData['customer_city'] ?? '') : (orderData['city'] ?? ''),
            total: totalAmount,
            subtotal: subtotalAmount,
            totalCost: totalAmount,
            totalProfit: profitAmount,
            rawStatus: orderData['status'] ?? 'active',
            notes: orderData['customer_notes'] ?? orderData['notes'] ?? '',
            createdAt: DateTime.tryParse(orderData['created_at'] ?? '') ?? DateTime.now(),
            items: orderItems,
            status: _parseOrderStatus(orderData['status'] ?? 'pending'),
          );

          return order;
        } else {
          throw Exception(jsonData['error'] ?? 'فشل في جلب الطلب');
        }
      } else if (response.statusCode == 404) {
        throw Exception('الطلب غير موجود');
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب تفاصيل الطلب: $e');
      rethrow;
    }
  }

  /// 🗑️ حذف طلب من Backend
  static Future<bool> deleteOrder(String orderId, String userPhone) async {
    try {
      debugPrint('🗑️ حذف الطلب: $orderId');

      final url = Uri.parse('$baseUrl/api/orders/$orderId?userPhone=$userPhone');

      final response = await http
          .delete(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30), onTimeout: () => throw Exception('انتهت مهلة الاتصال'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          debugPrint('✅ تم حذف الطلب بنجاح');
          return true;
        } else {
          throw Exception(jsonData['error'] ?? 'فشل في حذف الطلب');
        }
      } else if (response.statusCode == 403) {
        throw Exception('غير مصرح لك بحذف هذا الطلب');
      } else if (response.statusCode == 404) {
        throw Exception('الطلب غير موجود');
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في حذف الطلب: $e');
      rethrow;
    }
  }

  /// 🔍 التحقق من اتصال Backend
  static Future<bool> checkBackendConnection() async {
    try {
      final url = Uri.parse('$baseUrl/api/orders');

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('انتهت مهلة الاتصال'));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Backend غير متاح');
      return false;
    }
  }

  /// تحويل نص الحالة إلى OrderStatus enum
  static OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'نشط':
        return OrderStatus.pending;
      case 'confirmed':
      case 'مؤكد':
        return OrderStatus.confirmed;
      case 'in_delivery':
      case 'قيد التوصيل':
        return OrderStatus.inDelivery;
      case 'delivered':
      case 'تم التسليم':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'ملغي':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
