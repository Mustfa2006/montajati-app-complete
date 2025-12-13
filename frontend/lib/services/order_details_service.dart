import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/order_item.dart' as order_item_model;
import 'real_auth_service.dart';

/// ✅ خدمة جلب تفاصيل الطلب من Backend API
/// لا تستدعي قاعدة البيانات مباشرة - آمن وموثوق
class OrderDetailsService {
  static const String baseUrl = 'https://montajati-official-backend-production.up.railway.app';

  /// 📥 جلب تفاصيل طلب محدد من Backend
  static Future<Order> fetchOrderDetails(String orderId) async {
    try {
      debugPrint('📥 جلب تفاصيل الطلب');

      final url = Uri.parse('$baseUrl/api/orders/$orderId');

      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      debugPrint('📨 [OrderDetails] Headers: $headers');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30), onTimeout: () => throw Exception('انتهت مهلة الاتصال'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final orderData = jsonData['data'];
          // Backend returns 'isScheduled' (boolean), logic below handles casting safely
          final isScheduledOrder = orderData['isScheduled'] == true;

          debugPrint('✅ تم جلب الطلب بنجاح');

          // ✅ 1. استخراج البيانات من الكائنات المتداخلة (Backend DTO)
          final customer = orderData['customer'] ?? {};
          final location = orderData['location'] ?? {};
          final financial = orderData['financial'] ?? {};
          final dates = orderData['dates'] ?? {};

          // ✅ 2. تحويل العناصر (Items)
          // Backend returns 'items' array directly in DTO
          final rawItems = orderData['items'] as List?;
          final orderItems =
              rawItems
                  ?.map(
                    (item) => order_item_model.OrderItem(
                      id: item['id']?.toString() ?? '',
                      productId: item['productId']?.toString() ?? '',
                      name: item['name']?.toString() ?? '',
                      image: item['imageUrl']?.toString() ?? '',
                      wholesalePrice: double.tryParse(item['cost']?.toString() ?? '0') ?? 0.0,
                      customerPrice: double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
                      quantity: int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
                    ),
                  )
                  .toList() ??
              [];

          // ✅ 3. تحويل البيانات المالية
          final totalAmount = num.tryParse(financial['total']?.toString() ?? '0') ?? 0;
          final subtotalAmount = num.tryParse(financial['subtotal']?.toString() ?? '0') ?? 0;
          final profitAmount =
              num.tryParse(financial['profitAmount']?.toString() ?? financial['profit']?.toString() ?? '0') ?? 0;

          // ✅ 4. بناء الكائن
          final order = Order(
            id: orderData['id']?.toString() ?? '',
            customerName: customer['name']?.toString() ?? '',
            primaryPhone: customer['phone']?.toString() ?? '',
            secondaryPhone: customer['alternatePhone']?.toString() ?? '',
            province: location['province']?.toString() ?? '',
            city: location['city']?.toString() ?? '',
            total: totalAmount.toInt(), // Model expects int
            subtotal: subtotalAmount.toInt(),
            totalCost: totalAmount.toInt(), // Fallback if no cost field
            totalProfit: profitAmount.toInt(),
            rawStatus: orderData['status']?.toString() ?? 'active',
            notes: orderData['notes']?.toString() ?? '',
            createdAt: DateTime.tryParse(dates['created']?.toString() ?? '') ?? DateTime.now(),
            items: orderItems,
            status: _parseOrderStatus(orderData['status']?.toString() ?? 'pending'),
            scheduledDate: isScheduledOrder ? DateTime.tryParse(orderData['scheduledDate']?.toString() ?? '') : null,
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
