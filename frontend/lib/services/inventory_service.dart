import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'notification_service.dart';

/// خدمة إدارة المخزون والكميات
class InventoryService {
  static final _supabase = Supabase.instance.client;

  /// تقليل الكمية المتاحة عند إجراء حجز
  static Future<Map<String, dynamic>> reserveProduct({
    required String productId,
    required int reservedQuantity,
  }) async {
    try {
      debugPrint('🔄 بدء حجز $reservedQuantity قطعة من المنتج: $productId');

      // 1. جلب بيانات المنتج الحالية (العدد الإجمالي فقط)
      final productResponse = await _supabase
          .from('products')
          .select('available_quantity')
          .eq('id', productId)
          .single();

      final int currentStock = productResponse['available_quantity'] ?? 0;

      debugPrint('📊 الكمية الحالية: $currentStock قطعة');

      // 2. التحقق من توفر الكمية
      if (currentStock < reservedQuantity) {
        return {
          'success': false,
          'message': 'الكمية المطلوبة غير متوفرة في المخزون',
          'available_stock': currentStock,
        };
      }

      // 3. حساب الكمية الجديدة
      final int newStock = currentStock - reservedQuantity;

      debugPrint('🔢 الكمية الجديدة: $newStock قطعة');

      // 4. تحديث قاعدة البيانات (العدد الإجمالي فقط)
      await _supabase
          .from('products')
          .update({
            'available_quantity': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      debugPrint('✅ تم تحديث الكمية بنجاح');

      // 🔔 إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
      _monitorProductStock(productId);

      return {
        'success': true,
        'message': 'تم حجز الكمية بنجاح',
        'reserved_quantity': reservedQuantity,
        'new_stock': newStock,
      };
    } catch (e) {
      debugPrint('❌ خطأ في حجز المنتج: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام',
        'error': e.toString(),
      };
    }
  }

  /// إلغاء حجز وإرجاع الكمية (يعتمد على العدد الإجمالي فقط)
  static Future<Map<String, dynamic>> cancelReservation({
    required String productId,
    required int returnedQuantity,
  }) async {
    try {
      debugPrint(
        '🔄 بدء إلغاء حجز $returnedQuantity قطعة من المنتج: $productId',
      );

      // 1. جلب بيانات المنتج الحالية
      final productResponse = await _supabase
          .from('products')
          .select('available_quantity')
          .eq('id', productId)
          .single();

      final int currentStock = productResponse['available_quantity'] ?? 0;

      // 2. حساب الكمية الجديدة (إضافة الكمية المُلغاة)
      final int newStock = currentStock + returnedQuantity;

      debugPrint('🔢 الكمية بعد الإلغاء: $newStock قطعة');

      // 3. تحديث قاعدة البيانات
      await _supabase
          .from('products')
          .update({
            'available_quantity': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      debugPrint('✅ تم إلغاء الحجز وإرجاع الكمية بنجاح');

      // 🔔 إرسال طلب مراقبة المنتج للتحقق من تحسن المخزون
      _monitorProductStock(productId);

      return {
        'success': true,
        'message': 'تم إلغاء الحجز بنجاح',
        'returned_quantity': returnedQuantity,
        'new_stock': newStock,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الحجز: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام',
        'error': e.toString(),
      };
    }
  }

  /// التحقق من توفر الكمية (يعتمد على العدد الإجمالي فقط)
  static Future<Map<String, dynamic>> checkAvailability({
    required String productId,
    required int requestedQuantity,
  }) async {
    try {
      final productResponse = await _supabase
          .from('products')
          .select('available_quantity, name')
          .eq('id', productId)
          .single();

      final int stock = productResponse['available_quantity'] ?? 0;
      final String name = productResponse['name'] ?? 'منتج غير معروف';

      final bool isAvailable = requestedQuantity <= stock;

      return {
        'success': true,
        'is_available': isAvailable,
        'product_name': name,
        'requested_quantity': requestedQuantity,
        'stock': stock,
        'max_available': stock,
      };
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من التوفر: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام',
        'error': e.toString(),
      };
    }
  }

  /// جلب إحصائيات المخزون (يعتمد على العدد الإجمالي فقط)
  static Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final response = await _supabase
          .from('products')
          .select('available_quantity')
          .eq('is_active', true);

      int totalStock = 0;
      int lowStockCount = 0;
      int outOfStockCount = 0;

      for (final product in response) {
        final int stock = product['available_quantity'] ?? 0;

        totalStock += stock;

        if (stock == 0) {
          outOfStockCount++;
        } else if (stock <= 5) {
          lowStockCount++;
        }
      }

      return {
        'success': true,
        'total_products': response.length,
        'total_stock': totalStock,
        'low_stock_count': lowStockCount,
        'out_of_stock_count': outOfStockCount,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات المخزون: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام',
        'error': e.toString(),
      };
    }
  }

  /// إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
  static void _monitorProductStock(String productId) {
    // إرسال طلب غير متزامن لمراقبة المنتج
    http
        .post(
          Uri.parse('http://localhost:3003/api/inventory/monitor/$productId'),
          headers: {'Content-Type': 'application/json'},
        )
        .then((response) {
          if (response.statusCode == 200) {
            debugPrint('✅ تم إرسال طلب مراقبة المنتج: $productId');
          } else {
            debugPrint(
              '⚠️ فشل في إرسال طلب مراقبة المنتج: ${response.statusCode}',
            );
          }
        })
        .catchError((error) {
          debugPrint('⚠️ خطأ في إرسال طلب مراقبة المنتج: $error');
        });
  }

  /// التحقق من نفاد المخزون وإرسال إشعار محلي
  static Future<void> checkAndNotifyOutOfStock(String productId) async {
    try {
      final productResponse = await _supabase
          .from('products')
          .select('id, name, available_quantity')
          .eq('id', productId)
          .single();

      final int stock = productResponse['available_quantity'] ?? 0;
      final String name = productResponse['name'] ?? 'منتج غير معروف';

      if (stock <= 0) {
        debugPrint('🚨 تم اكتشاف نفاد مخزون: $name');

        // إرسال إشعار محلي
        await NotificationService.showOutOfStockNotification(
          productName: name,
          productId: productId,
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من نفاد المخزون: $e');
    }
  }

  /// تقليل المخزون مباشرة (للطلبات المثبتة)
  static Future<Map<String, dynamic>> reduceStock({
    required String productId,
    required int quantity,
  }) async {
    try {
      debugPrint('📉 بدء تقليل المخزون: $quantity قطعة من المنتج $productId');

      // 1. جلب بيانات المنتج الحالية
      final productResponse = await _supabase
          .from('products')
          .select('available_quantity, name')
          .eq('id', productId)
          .single();

      final int currentStock = productResponse['available_quantity'] ?? 0;
      final String productName = productResponse['name'] ?? 'منتج غير محدد';

      debugPrint('📊 الكمية الحالية: $currentStock قطعة');

      // 2. التحقق من توفر الكمية
      if (currentStock < quantity) {
        debugPrint(
          '⚠️ الكمية المطلوبة ($quantity) أكبر من المتوفر ($currentStock)',
        );
        return {
          'success': false,
          'message': 'الكمية المطلوبة غير متوفرة في المخزون',
          'available_stock': currentStock,
          'requested_quantity': quantity,
        };
      }

      // 3. حساب الكمية الجديدة
      final int newStock = currentStock - quantity;
      debugPrint('🔢 الكمية الجديدة: $newStock قطعة');

      // 4. تحديث قاعدة البيانات
      await _supabase
          .from('products')
          .update({
            'available_quantity': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      debugPrint('✅ تم تقليل مخزون المنتج $productName بمقدار $quantity قطعة');

      // 5. إرسال طلب مراقبة المخزون للخادم الخلفي
      _monitorProductStock(productId);

      return {
        'success': true,
        'message': 'تم تقليل المخزون بنجاح',
        'previous_stock': currentStock,
        'new_stock': newStock,
        'reduced_quantity': quantity,
        'product_name': productName,
      };
    } catch (e) {
      debugPrint('❌ خطأ في تقليل المخزون: $e');
      return {'success': false, 'message': 'حدث خطأ في تقليل المخزون: $e'};
    }
  }
}
