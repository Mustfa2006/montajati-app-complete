// 🎯 Repository لتفاصيل المنتج
// مسؤول عن جلب البيانات من Supabase و SharedPreferences

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_color.dart';
import '../services/smart_colors_service.dart';

/// Repository للتعامل مع بيانات تفاصيل المنتج
class ProductDetailsRepository {
  final SupabaseClient _supabase;

  ProductDetailsRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 📦 جلب بيانات المنتج من Supabase
  Future<Map<String, dynamic>?> fetchProduct(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single();
      return response;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المنتج: $e');
      return null;
    }
  }

  /// 🎨 جلب ألوان المنتج
  Future<List<ProductColor>> fetchProductColors(String productId) async {
    try {
      return await SmartColorsService.getProductColors(
        productId: productId,
        includeUnavailable: false,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب ألوان المنتج: $e');
      return [];
    }
  }

  /// 📌 تحميل الأسعار المثبتة من SharedPreferences
  Future<List<double>> loadPinnedPrices(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pinned_prices_$productId';
      final savedPrices = prefs.getStringList(key);

      if (savedPrices != null) {
        final prices = savedPrices
            .map((e) => double.tryParse(e) ?? 0)
            .where((p) => p > 0)
            .toList();
        debugPrint('✅ تم تحميل ${prices.length} سعر مثبت للمنتج $productId');
        return prices;
      }
      return [];
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأسعار المثبتة: $e');
      return [];
    }
  }

  /// 📌 حفظ الأسعار المثبتة في SharedPreferences
  Future<bool> savePinnedPrices(String productId, List<double> prices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pinned_prices_$productId';
      final priceStrings = prices.map((p) => p.toString()).toList();
      await prefs.setStringList(key, priceStrings);
      debugPrint('✅ تم حفظ ${prices.length} سعر مثبت للمنتج $productId');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الأسعار المثبتة: $e');
      return false;
    }
  }
}

