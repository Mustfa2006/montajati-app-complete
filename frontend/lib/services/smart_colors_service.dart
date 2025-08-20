import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_color.dart';

/// 🎨 خدمة الألوان الذكية المتطورة
/// Smart Colors Service - الأقوى في إدارة الألوان
class SmartColorsService {
  static final _supabase = Supabase.instance.client;

  /// 🎯 الحصول على جميع الألوان المحددة مسبقاً
  static Future<List<PredefinedColor>> getPredefinedColors({
    bool popularOnly = false,
  }) async {
    try {
      debugPrint('🎨 جلب الألوان المحددة مسبقاً...');

      final response = popularOnly
          ? await _supabase
              .from('predefined_colors')
              .select()
              .eq('is_popular', true)
              .order('is_popular', ascending: false)
              .order('usage_count', ascending: false)
              .order('color_arabic_name', ascending: true)
          : await _supabase
              .from('predefined_colors')
              .select()
              .order('is_popular', ascending: false)
              .order('usage_count', ascending: false)
              .order('color_arabic_name', ascending: true);

      final colors = (response as List)
          .map((json) => PredefinedColor.fromJson(json))
          .toList();

      debugPrint('✅ تم جلب ${colors.length} لون محدد مسبقاً');
      return colors;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الألوان المحددة مسبقاً: $e');
      return [];
    }
  }

  /// 🎨 إضافة لون جديد للمنتج
  static Future<Map<String, dynamic>> addColorToProduct({
    required String productId,
    required String colorName,
    required String colorCode,
    required String colorArabicName,
    required int totalQuantity,
    String? userPhone,
  }) async {
    try {
      debugPrint('🎨 إضافة لون جديد للمنتج $productId...');
      debugPrint('🎯 اللون: $colorArabicName ($colorCode)');
      debugPrint('📦 الكمية: $totalQuantity');

      // استدعاء الدالة الذكية في قاعدة البيانات
      final response = await _supabase.rpc('add_product_color', params: {
        'p_product_id': productId,
        'p_color_name': colorName,
        'p_color_code': colorCode,
        'p_color_arabic_name': colorArabicName,
        'p_total_quantity': totalQuantity,
        'p_user_phone': userPhone,
      });

      if (response['success'] == true) {
        debugPrint('✅ تم إضافة اللون بنجاح');
        return {
          'success': true,
          'color_id': response['color_id'],
          'message': response['message'],
        };
      } else {
        debugPrint('❌ فشل في إضافة اللون: ${response['error']}');
        return {
          'success': false,
          'error': response['error'],
          'error_code': response['error_code'],
        };
      }
    } catch (e) {
      debugPrint('❌ خطأ في إضافة اللون: $e');
      return {
        'success': false,
        'error': 'خطأ في الاتصال بقاعدة البيانات',
        'error_code': 'CONNECTION_ERROR',
      };
    }
  }

  /// 📦 الحصول على ألوان المنتج
  static Future<List<ProductColor>> getProductColors({
    required String productId,
    bool includeUnavailable = false,
  }) async {
    try {
      debugPrint('🎨 جلب ألوان المنتج $productId...');

      // استدعاء الدالة الذكية
      final response = await _supabase.rpc('get_product_colors', params: {
        'p_product_id': productId,
        'p_include_unavailable': includeUnavailable,
      });

      if (response['success'] == true) {
        final colorsJson = response['colors'] as List;
        final colors = colorsJson
            .map((json) => ProductColor.fromJson(json))
            .toList();

        debugPrint('✅ تم جلب ${colors.length} لون للمنتج');
        return colors;
      } else {
        debugPrint('❌ فشل في جلب ألوان المنتج: ${response['error']}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب ألوان المنتج: $e');
      return [];
    }
  }

  /// 🛒 حجز لون للطلب
  static Future<Map<String, dynamic>> reserveColorForOrder({
    required String colorId,
    required int quantity,
    String? orderId,
    String? userPhone,
    String reservationType = 'order',
  }) async {
    try {
      debugPrint('🛒 حجز لون للطلب...');
      debugPrint('🎨 معرف اللون: $colorId');
      debugPrint('📦 الكمية: $quantity');

      final response = await _supabase.rpc('reserve_color_for_order', params: {
        'p_color_id': colorId,
        'p_quantity': quantity,
        'p_order_id': orderId,
        'p_user_phone': userPhone,
        'p_reservation_type': reservationType,
      });

      if (response['success'] == true) {
        debugPrint('✅ تم حجز اللون بنجاح');
        return {
          'success': true,
          'reservation_id': response['reservation_id'],
          'reserved_quantity': response['reserved_quantity'],
          'remaining_available': response['remaining_available'],
          'message': response['message'],
        };
      } else {
        debugPrint('❌ فشل في حجز اللون: ${response['error']}');
        return {
          'success': false,
          'error': response['error'],
          'error_code': response['error_code'],
          'available_quantity': response['available_quantity'],
        };
      }
    } catch (e) {
      debugPrint('❌ خطأ في حجز اللون: $e');
      return {
        'success': false,
        'error': 'خطأ في الاتصال بقاعدة البيانات',
        'error_code': 'CONNECTION_ERROR',
      };
    }
  }

  /// 🔄 تحديث كمية اللون
  static Future<Map<String, dynamic>> updateColorQuantity({
    required String colorId,
    required int newQuantity,
    String reason = 'تحديث الكمية',
    String? userPhone,
  }) async {
    try {
      debugPrint('🔄 تحديث كمية اللون...');
      debugPrint('🎨 معرف اللون: $colorId');
      debugPrint('📦 الكمية الجديدة: $newQuantity');

      final response = await _supabase.rpc('update_color_quantity', params: {
        'p_color_id': colorId,
        'p_new_quantity': newQuantity,
        'p_reason': reason,
        'p_user_phone': userPhone,
      });

      if (response['success'] == true) {
        debugPrint('✅ تم تحديث كمية اللون بنجاح');
        return {
          'success': true,
          'old_quantity': response['old_quantity'],
          'new_quantity': response['new_quantity'],
          'message': response['message'],
        };
      } else {
        debugPrint('❌ فشل في تحديث كمية اللون: ${response['error']}');
        return {
          'success': false,
          'error': response['error'],
          'error_code': response['error_code'],
        };
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث كمية اللون: $e');
      return {
        'success': false,
        'error': 'خطأ في الاتصال بقاعدة البيانات',
        'error_code': 'CONNECTION_ERROR',
      };
    }
  }

  /// 🗑️ حذف لون من المنتج
  static Future<Map<String, dynamic>> deleteProductColor({
    required String colorId,
    String? userPhone,
  }) async {
    try {
      debugPrint('🗑️ حذف لون من المنتج...');
      debugPrint('🎨 معرف اللون: $colorId');

      // تحديث حالة اللون إلى غير نشط بدلاً من الحذف
      await _supabase
          .from('product_colors')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', colorId)
          .select()
          .single();

      debugPrint('✅ تم حذف اللون بنجاح');
      return {
        'success': true,
        'message': 'تم حذف اللون بنجاح',
      };
    } catch (e) {
      debugPrint('❌ خطأ في حذف اللون: $e');
      return {
        'success': false,
        'error': 'خطأ في حذف اللون',
        'error_code': 'DELETE_ERROR',
      };
    }
  }

  /// 📊 الحصول على إحصائيات الألوان
  static Future<Map<String, dynamic>> getColorAnalytics({
    required String productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📊 جلب إحصائيات الألوان للمنتج $productId...');

      var query = _supabase
          .from('color_analytics')
          .select('*, product_colors!inner(color_arabic_name, color_code)')
          .eq('product_id', productId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);

      debugPrint('✅ تم جلب إحصائيات الألوان');
      return {
        'success': true,
        'analytics': response,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات الألوان: $e');
      return {
        'success': false,
        'error': 'خطأ في جلب الإحصائيات',
        'analytics': [],
      };
    }
  }

  /// 🎨 البحث في الألوان المحددة مسبقاً
  static Future<List<PredefinedColor>> searchPredefinedColors({
    required String searchTerm,
  }) async {
    try {
      debugPrint('🔍 البحث في الألوان: $searchTerm');

      final response = await _supabase
          .from('predefined_colors')
          .select()
          .or('color_name.ilike.%$searchTerm%,color_arabic_name.ilike.%$searchTerm%')
          .order('is_popular', ascending: false)
          .order('usage_count', ascending: false);

      final colors = (response as List)
          .map((json) => PredefinedColor.fromJson(json))
          .toList();

      debugPrint('✅ تم العثور على ${colors.length} لون');
      return colors;
    } catch (e) {
      debugPrint('❌ خطأ في البحث: $e');
      return [];
    }
  }
}
