import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

/// 🚀 خدمة الكاش الذكية للمنتجات
/// تخزين المنتجات محلياً لتسريع فتح الصفحة
///
/// 📌 استراتيجية الكاش:
/// 1. كاش في الذاكرة (Memory Cache) - الأسرع - يتم فقده عند إغلاق التطبيق
/// 2. كاش محلي (SharedPreferences) - يبقى للأبد حتى يتم تحديثه
///
/// ⚡ بدون وقت انتهاء - الكاش يبقى للأبد ويتم تحديثه في الخلفية
class ProductsCacheService {
  static const String _cacheKey = 'products_cache';
  static const String _cacheVersionKey = 'products_cache_version';
  static const String _currentVersion = '1.0.0';

  // 📦 كاش في الذاكرة للوصول السريع جداً
  static List<Product>? _memoryCache;

  /// تحميل المنتجات من الكاش (سريع جداً) - بدون وقت انتهاء
  static Future<List<Product>?> getCachedProducts() async {
    try {
      // 1️⃣ أولاً: تحقق من الكاش في الذاكرة (الأسرع)
      if (_memoryCache != null && _memoryCache!.isNotEmpty) {
        debugPrint('⚡ تحميل من كاش الذاكرة (${_memoryCache!.length} منتج)');
        return _memoryCache;
      }

      // 2️⃣ ثانياً: تحقق من الكاش المحلي (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();

      // فحص إصدار الكاش
      final cachedVersion = prefs.getString(_cacheVersionKey);
      if (cachedVersion != _currentVersion) {
        debugPrint('🔄 إصدار جديد من الكاش - مسح القديم');
        await clearCache();
        return null;
      }

      // تحميل المنتجات من الكاش
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData == null || cachedData.isEmpty) {
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(cachedData);
      final products = jsonList.map((json) => Product.fromJson(json)).toList();

      // حفظ في كاش الذاكرة
      _memoryCache = products;

      debugPrint('📦 تحميل من الكاش المحلي (${products.length} منتج)');
      return products;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الكاش: $e');
      return null;
    }
  }

  /// حفظ المنتجات في الكاش
  static Future<void> cacheProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // تحويل المنتجات إلى JSON
      final jsonList = products.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // حفظ في SharedPreferences
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setString(_cacheVersionKey, _currentVersion);

      // حفظ في كاش الذاكرة
      _memoryCache = products;

      debugPrint('✅ تم حفظ ${products.length} منتج في الكاش');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الكاش: $e');
    }
  }

  /// مسح الكاش
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      _memoryCache = null;
      debugPrint('🗑️ تم مسح كاش المنتجات');
    } catch (e) {
      debugPrint('❌ خطأ في مسح الكاش: $e');
    }
  }

  /// تحديث الكاش في الذاكرة فقط (للتحديثات الفورية)
  static void updateMemoryCache(List<Product> products) {
    _memoryCache = products;
  }

  /// هل يوجد كاش؟
  static Future<bool> hasCachedProducts() async {
    final cached = await getCachedProducts();
    return cached != null && cached.isNotEmpty;
  }
}
