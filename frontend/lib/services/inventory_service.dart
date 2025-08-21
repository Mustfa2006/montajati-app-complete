
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'smart_inventory_manager.dart';
import 'package:http/http.dart' as http;


/// خدمة إدارة المخزون والكميات
class InventoryService {
  static final _supabase = Supabase.instance.client;

  /// تقليل الكمية المتاحة عند إجراء حجز باستخدام النظام الذكي
  static Future<Map<String, dynamic>> reserveProduct({
    required String productId,
    required int reservedQuantity,
  }) async {
    try {
      debugPrint('🧠 بدء الحجز الذكي: $reservedQuantity قطعة من المنتج: $productId');

      // استخدام النظام الذكي للحجز
      final result = await SmartInventoryManager.smartReserveProduct(
        productId: productId,
        requestedQuantity: reservedQuantity,
      );

      if (result['success']) {
        debugPrint('✅ تم الحجز الذكي بنجاح');
        debugPrint('📊 حالة المخزون: ${result['stock_status']}');

        // ملاحظة: مراقبة المخزون تتم تلقائياً في SmartInventoryManager

        // إرسال تنبيه إذا كان المخزون منخفض
        if (result['is_low_stock'] == true) {
          debugPrint('⚠️ تحذير: المخزون منخفض للمنتج ${result['product_name']}');
          _sendLowStockAlert(productId, result['product_name'], result['new_stock']);
        }

        return {
          'success': true,
          'message': result['message'],
          'reserved_quantity': result['reserved_quantity'],
          'new_stock': result['new_stock'],
          'stock_status': result['stock_status'],
          'is_low_stock': result['is_low_stock'],
          'is_out_of_stock': result['is_out_of_stock'],
        };
      } else {
        debugPrint('❌ فشل الحجز الذكي: ${result['message']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحجز الذكي: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام: $e',
        'error': e.toString(),
      };
    }
  }

  /// إرسال تنبيه المخزون المنخفض
  static void _sendLowStockAlert(String productId, String productName, int currentStock) {
    try {
      debugPrint('🚨 إرسال تنبيه مخزون منخفض: $productName (المتبقي: $currentStock)');

      // يمكن إضافة إرسال إشعار للمستخدم هنا
      // مثل Firebase Notification أو Telegram Bot

      // إرسال طلب للخادم لمعالجة التنبيه
      _monitorProductStock(productId);

    } catch (e) {
      debugPrint('❌ خطأ في إرسال تنبيه المخزون المنخفض: $e');
    }
  }

  /// إلغاء حجز وإرجاع الكمية باستخدام النظام الذكي
  static Future<Map<String, dynamic>> cancelReservation({
    required String productId,
    required int returnedQuantity,
  }) async {
    try {
      debugPrint(
        '🧠 بدء إلغاء الحجز الذكي: $returnedQuantity قطعة من المنتج: $productId',
      );

      // استخدام النظام الذكي لإضافة المخزون
      final result = await SmartInventoryManager.addStock(
        productId: productId,
        addedQuantity: returnedQuantity,
      );

      if (result['success']) {
        debugPrint('✅ تم إلغاء الحجز بالنظام الذكي بنجاح');
        debugPrint('🎯 النطاق الجديد: ${result['new_range']}');

        // إرسال طلب مراقبة المنتج للتحقق من تحسن المخزون
        _monitorProductStock(productId);

        return {
          'success': true,
          'message': 'تم إلغاء الحجز بنجاح\n${result['message']}',
          'returned_quantity': result['added_quantity'],
          'previous_stock': result['previous_stock'],
          'new_stock': result['new_stock'],
          'new_range': result['new_range'],
          'product_name': result['product_name'],
        };
      } else {
        debugPrint('❌ فشل إلغاء الحجز الذكي: ${result['message']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الحجز الذكي: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام: $e',
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
    // استخدام الخادم الصحيح حسب البيئة
    const String baseUrl = kDebugMode
        ? 'http://localhost:3003'
  : 'https://montajati-official-backend-production.up.railway.app';

    http
        .post(
          Uri.parse('$baseUrl/api/inventory/monitor/$productId'),
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

        // تم إزالة نظام الإشعارات
        debugPrint('⚠️ تحذير: المنتج $name نفد من المخزون');
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من نفاد المخزون: $e');
    }
  }

  /// تقليل المخزون مباشرة (للطلبات المثبتة) باستخدام النظام الذكي
  static Future<Map<String, dynamic>> reduceStock({
    required String productId,
    required int quantity,
  }) async {
    try {
      debugPrint('🧠 بدء تقليل المخزون الذكي: $quantity قطعة من المنتج $productId');

      // استخدام النظام الذكي لتقليل المخزون (نفس منطق الحجز)
      final result = await SmartInventoryManager.smartReserveProduct(
        productId: productId,
        requestedQuantity: quantity,
      );

      if (result['success']) {
        debugPrint('✅ تم تقليل المخزون بالنظام الذكي بنجاح');
        debugPrint('📊 حالة المخزون: ${result['stock_status']}');
        debugPrint('🎯 النطاق الجديد: ${result['new_range']}');

        // ملاحظة: مراقبة المخزون تتم تلقائياً في SmartInventoryManager

        // إرسال تنبيه إذا كان المخزون منخفض
        if (result['is_low_stock'] == true) {
          debugPrint('⚠️ تحذير: المخزون منخفض للمنتج ${result['product_name']}');
          _sendLowStockAlert(productId, result['product_name'], result['new_stock']);
        }

        return {
          'success': true,
          'message': 'تم تقليل المخزون بنجاح\n${result['message']}',
          'previous_stock': result['previous_stock'],
          'new_stock': result['new_stock'],
          'reduced_quantity': result['reserved_quantity'],
          'product_name': result['product_name'],
          'stock_status': result['stock_status'],
          'new_range': result['new_range'],
          'is_low_stock': result['is_low_stock'],
          'is_out_of_stock': result['is_out_of_stock'],
        };
      } else {
        debugPrint('❌ فشل تقليل المخزون الذكي: ${result['message']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تقليل المخزون الذكي: $e');
      return {'success': false, 'message': 'حدث خطأ في تقليل المخزون: $e'};
    }
  }
}
