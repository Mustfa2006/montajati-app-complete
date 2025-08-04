// ===================================
// نظام إدارة المخزون الذكي مع نطاق "من - إلى"
// Smart Inventory Management System with Range
// ===================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class SmartInventoryManager {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// نظام ذكي لحساب النطاق المثالي للمخزون
  /// Smart system to calculate optimal inventory range
  static Map<String, int> calculateSmartRange(int totalQuantity) {
    if (totalQuantity <= 0) {
      return {'min': 0, 'max': 0, 'current': 0};
    }

    // 🧠 خوارزمية ذكية لحساب النطاق
    int minRange, maxRange;
    
    if (totalQuantity <= 10) {
      // للكميات الصغيرة: نطاق ضيق
      minRange = max(0, totalQuantity - 2);
      maxRange = totalQuantity;
    } else if (totalQuantity <= 50) {
      // للكميات المتوسطة: نطاق 5-10%
      int variance = (totalQuantity * 0.1).round();
      minRange = max(0, totalQuantity - variance);
      maxRange = totalQuantity;
    } else if (totalQuantity <= 100) {
      // للكميات الكبيرة: نطاق 5%
      int variance = (totalQuantity * 0.05).round();
      minRange = max(0, totalQuantity - variance);
      maxRange = totalQuantity;
    } else {
      // للكميات الكبيرة جداً: نطاق 3-5%
      int variance = (totalQuantity * 0.03).round();
      minRange = max(0, totalQuantity - variance);
      maxRange = totalQuantity;
    }

    return {
      'min': minRange,
      'max': maxRange,
      'current': totalQuantity,
    };
  }

  /// تحديث المنتج بالنظام الذكي للمخزون
  /// Update product with smart inventory system
  static Future<Map<String, dynamic>> updateProductWithSmartInventory({
    required String productId,
    required String name,
    required String description,
    required double wholesalePrice,
    required double minPrice,
    required double maxPrice,
    required int totalQuantity,
    required String category,
    List<String>? images,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🧠 بدء تحديث المنتج بالنظام الذكي للمخزون...');
        debugPrint('📊 الكمية الإجمالية: $totalQuantity');
      }

      // 1. حساب النطاق الذكي
      final smartRange = calculateSmartRange(totalQuantity);
      final minQuantity = smartRange['min']!;
      final maxQuantity = smartRange['max']!;

      if (kDebugMode) {
        debugPrint('🎯 النطاق الذكي: من $minQuantity إلى $maxQuantity');
      }

      // 2. تحديث قاعدة البيانات مع النطاق الذكي
      final updateData = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'wholesale_price': wholesalePrice,
        'min_price': minPrice,
        'max_price': maxPrice,
        'stock_quantity': totalQuantity,
        'available_quantity': totalQuantity,
        'minimum_stock': minQuantity,
        'maximum_stock': maxQuantity,
        'available_from': minQuantity,
        'available_to': maxQuantity,
        'category': category,
        'smart_range_enabled': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // إضافة الصور إذا كانت متوفرة
      if (images != null && images.isNotEmpty) {
        updateData['image_url'] = images.first;
      }

      await _supabase.from('products').update(updateData).eq('id', productId);

      if (kDebugMode) {
        debugPrint('✅ تم تحديث المنتج بالنظام الذكي بنجاح');
      }

      // 🔔 إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
      _monitorProductStock(productId);

      return {
        'success': true,
        'message': 'تم تحديث المنتج بالنظام الذكي بنجاح',
        'smart_range': smartRange,
        'total_quantity': totalQuantity,
        'min_quantity': minQuantity,
        'max_quantity': maxQuantity,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحديث المنتج بالنظام الذكي: $e');
      }
      return {
        'success': false,
        'message': 'خطأ في تحديث المنتج: $e',
      };
    }
  }

  /// إضافة منتج جديد بالنظام الذكي
  /// Add new product with smart inventory system
  static Future<Map<String, dynamic>> addProductWithSmartInventory({
    required String name,
    required String description,
    required double wholesalePrice,
    required double minPrice,
    required double maxPrice,
    required int totalQuantity,
    required String category,
    required String userPhone, // مطلوب لربط المنتج بالمستخدم
    List<String>? images,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🧠 بدء إضافة منتج جديد بالنظام الذكي...');
        debugPrint('📊 الكمية الإجمالية: $totalQuantity');
      }

      // 1. العثور على المستخدم بناءً على رقم الهاتف
      String? ownerId;
      try {
        final userResponse = await _supabase
            .from('users')
            .select('id')
            .eq('phone', userPhone)
            .maybeSingle();

        if (userResponse != null) {
          ownerId = userResponse['id'];
          if (kDebugMode) {
            debugPrint('👤 تم العثور على المستخدم: $ownerId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ لم يتم العثور على المستخدم برقم الهاتف: $userPhone');
        }
      }

      // 2. حساب النطاق الذكي
      final smartRange = calculateSmartRange(totalQuantity);
      final minQuantity = smartRange['min']!;
      final maxQuantity = smartRange['max']!;

      if (kDebugMode) {
        debugPrint('🎯 النطاق الذكي: من $minQuantity إلى $maxQuantity');
      }

      // 3. إضافة المنتج مع النطاق الذكي
      final productData = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'wholesale_price': wholesalePrice,
        'min_price': minPrice,
        'max_price': maxPrice,
        'available_quantity': totalQuantity,
        'category': category,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'stock_quantity': totalQuantity,
        'minimum_stock': minQuantity,
        'maximum_stock': maxQuantity,
        'available_from': minQuantity,
        'available_to': maxQuantity,
        'smart_range_enabled': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // إضافة owner_id إذا تم العثور على المستخدم
      if (ownerId != null) {
        productData['owner_id'] = ownerId;
      }

      // إضافة الصور إذا كانت متوفرة
      if (images != null && images.isNotEmpty) {
        productData['image_url'] = images.first;
        productData['images'] = images;
      }

      final response = await _supabase.from('products').insert(productData).select().single();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة المنتج بالنظام الذكي بنجاح');
      }

      // 🔔 إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
      final String productId = response['id'];
      _monitorProductStock(productId);

      return {
        'success': true,
        'message': 'تم إضافة المنتج بالنظام الذكي بنجاح',
        'product': response,
        'smart_range': smartRange,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في إضافة المنتج بالنظام الذكي: $e');
      }

      // معالجة أخطاء مختلفة
      String errorMessage = 'فشل في إضافة المنتج';

      if (e.toString().contains('column') && e.toString().contains('does not exist')) {
        errorMessage = 'خطأ في هيكل قاعدة البيانات';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'ليس لديك صلاحية لإضافة المنتجات';
      } else if (e.toString().contains('network')) {
        errorMessage = 'مشكلة في الاتصال بالإنترنت';
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    }
  }

  /// حجز ذكي للمنتج مع توازن النطاق
  /// Smart product reservation with range balancing
  static Future<Map<String, dynamic>> smartReserveProduct({
    required String productId,
    required int requestedQuantity,
  }) async {
    try {
      debugPrint('🧠 بدء الحجز الذكي للمنتج: $productId');
      debugPrint('📊 الكمية المطلوبة: $requestedQuantity');

      // 1. جلب بيانات المنتج الحالية مع حقول "من - إلى"
      final productResponse = await _supabase
          .from('products')
          .select('available_quantity, minimum_stock, maximum_stock, name, available_from, available_to, stock_quantity')
          .eq('id', productId)
          .single();

      final int currentAvailable = productResponse['available_quantity'] ?? 0;
      final int minStock = productResponse['minimum_stock'] ?? 0;
      final int maxStock = productResponse['maximum_stock'] ?? 0;
      final String productName = productResponse['name'] ?? '';
      final int currentFrom = productResponse['available_from'] ?? 0;
      final int currentTo = productResponse['available_to'] ?? 0;
      final int totalStock = productResponse['stock_quantity'] ?? 0;

      debugPrint('📊 الكمية الحالية: $currentAvailable');
      debugPrint('🎯 النطاق الذكي: من $minStock إلى $maxStock');
      debugPrint('📈 النطاق المعروض: من $currentFrom إلى $currentTo');
      debugPrint('📦 المخزون الإجمالي: $totalStock');

      // 2. التحقق من توفر الكمية
      if (currentAvailable < requestedQuantity) {
        return {
          'success': false,
          'message': 'الكمية المطلوبة ($requestedQuantity) غير متوفرة. المتاح: $currentAvailable',
          'available_stock': currentAvailable,
          'requested_quantity': requestedQuantity,
        };
      }

      // 3. حساب الكميات الجديدة بعد الحجز
      final int newAvailable = currentAvailable - requestedQuantity;
      final int newTotalStock = totalStock - requestedQuantity;

      // 4. حساب النطاق الجديد "من - إلى" بناءً على الكمية الجديدة
      final newRange = calculateSmartRange(newAvailable);
      final int newFrom = newRange['min']!;
      final int newTo = newRange['max']!;

      debugPrint('🔢 الكمية بعد الحجز: $newAvailable');
      debugPrint('📦 المخزون الإجمالي الجديد: $newTotalStock');
      debugPrint('🎯 النطاق الجديد: من $newFrom إلى $newTo');

      // 5. تحديث قاعدة البيانات مع جميع الحقول
      await _supabase.from('products').update({
        'available_quantity': newAvailable,
        'stock_quantity': newTotalStock,
        'available_from': newFrom,
        'available_to': newTo,
        'minimum_stock': newFrom, // تحديث الحد الأدنى الذكي
        'maximum_stock': newTo,   // تحديث الحد الأقصى الذكي
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', productId);

      // 6. تحليل حالة المخزون الجديدة
      String stockStatus = _analyzeStockStatus(newAvailable, newFrom, newTo);

      debugPrint('✅ تم الحجز الذكي بنجاح');
      debugPrint('📊 حالة المخزون: $stockStatus');

      // 🔔 إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
      _monitorProductStock(productId);

      return {
        'success': true,
        'message': 'تم حجز $requestedQuantity قطعة من $productName بنجاح\nالنطاق الجديد: من $newFrom إلى $newTo',
        'product_name': productName,
        'reserved_quantity': requestedQuantity,
        'previous_stock': currentAvailable,
        'new_stock': newAvailable,
        'previous_total_stock': totalStock,
        'new_total_stock': newTotalStock,
        'previous_range': {'from': currentFrom, 'to': currentTo},
        'new_range': {'from': newFrom, 'to': newTo},
        'stock_status': stockStatus,
        'min_stock': newFrom,
        'max_stock': newTo,
        'is_low_stock': newAvailable <= newFrom,
        'is_out_of_stock': newAvailable == 0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في الحجز الذكي: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام: $e',
      };
    }
  }

  /// تحليل حالة المخزون
  /// Analyze stock status
  static String _analyzeStockStatus(int currentStock, int minStock, int maxStock) {
    if (currentStock == 0) {
      return 'نفد المخزون';
    } else if (currentStock <= minStock) {
      return 'مخزون منخفض';
    } else if (currentStock >= maxStock * 0.8) {
      return 'مخزون جيد';
    } else {
      return 'مخزون متوسط';
    }
  }

  /// إعادة حساب النطاق الذكي لمنتج موجود مع تحديث "من - إلى"
  /// Recalculate smart range for existing product with from-to update
  static Future<Map<String, dynamic>> recalculateSmartRange(String productId) async {
    try {
      debugPrint('🔄 إعادة حساب النطاق الذكي للمنتج: $productId');

      // 1. جلب الكمية الحالية
      final productResponse = await _supabase
          .from('products')
          .select('stock_quantity, available_quantity')
          .eq('id', productId)
          .single();

      final int totalQuantity = productResponse['stock_quantity'] ?? 0;
      final int availableQuantity = productResponse['available_quantity'] ?? 0;

      // 2. حساب النطاق الجديد بناءً على الكمية المتاحة
      final smartRange = calculateSmartRange(availableQuantity);

      // 3. تحديث النطاق في قاعدة البيانات مع حقول "من - إلى"
      await _supabase.from('products').update({
        'minimum_stock': smartRange['min'],
        'maximum_stock': smartRange['max'],
        'available_from': smartRange['min'],
        'available_to': smartRange['max'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', productId);

      debugPrint('✅ تم إعادة حساب النطاق الذكي بنجاح');
      debugPrint('🎯 النطاق الجديد: من ${smartRange['min']} إلى ${smartRange['max']}');

      return {
        'success': true,
        'message': 'تم إعادة حساب النطاق الذكي بنجاح',
        'smart_range': smartRange,
        'total_quantity': totalQuantity,
        'available_quantity': availableQuantity,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إعادة حساب النطاق: $e');
      return {
        'success': false,
        'message': 'خطأ في إعادة حساب النطاق: $e',
      };
    }
  }

  /// إضافة مخزون جديد مع إعادة حساب النطاق الذكي
  /// Add new stock with smart range recalculation
  static Future<Map<String, dynamic>> addStock({
    required String productId,
    required int addedQuantity,
  }) async {
    try {
      debugPrint('📈 إضافة $addedQuantity قطعة للمنتج: $productId');

      // 1. جلب بيانات المنتج الحالية
      final productResponse = await _supabase
          .from('products')
          .select('available_quantity, stock_quantity, name')
          .eq('id', productId)
          .single();

      final int currentAvailable = productResponse['available_quantity'] ?? 0;
      final int currentTotal = productResponse['stock_quantity'] ?? 0;
      final String productName = productResponse['name'] ?? '';

      // 2. حساب الكميات الجديدة
      final int newAvailable = currentAvailable + addedQuantity;
      final int newTotal = currentTotal + addedQuantity;

      // 3. حساب النطاق الجديد
      final newRange = calculateSmartRange(newAvailable);

      // 4. تحديث قاعدة البيانات
      await _supabase.from('products').update({
        'available_quantity': newAvailable,
        'stock_quantity': newTotal,
        'available_from': newRange['min'],
        'available_to': newRange['max'],
        'minimum_stock': newRange['min'],
        'maximum_stock': newRange['max'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', productId);

      debugPrint('✅ تم إضافة المخزون بنجاح');
      debugPrint('📊 الكمية الجديدة: $newAvailable');
      debugPrint('🎯 النطاق الجديد: من ${newRange['min']} إلى ${newRange['max']}');

      // 🔔 إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
      _monitorProductStock(productId);

      return {
        'success': true,
        'message': 'تم إضافة $addedQuantity قطعة لـ $productName بنجاح',
        'product_name': productName,
        'added_quantity': addedQuantity,
        'previous_stock': currentAvailable,
        'new_stock': newAvailable,
        'new_range': newRange,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المخزون: $e');
      return {
        'success': false,
        'message': 'خطأ في إضافة المخزون: $e',
      };
    }
  }

  /// إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
  static void _monitorProductStock(String productId) {
    // إرسال طلب غير متزامن لمراقبة المنتج
    // استخدام الخادم الصحيح حسب البيئة
    final String baseUrl = kDebugMode
        ? 'http://localhost:3003'
        : 'https://clownfish-app-krnk9.ondigitalocean.app';

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
}
