import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flexible_delivery_service.dart';


/// 🚀 خدمة التخزين المؤقت الذكي للمحافظات والمدن
/// 
/// هذه الخدمة تحمل البيانات مرة واحدة فقط عند أول تشغيل للتطبيق
/// وتحفظها في الذاكرة المؤقتة للوصول السريع
class LocationCacheService {
  static const String _provincesKey = 'cached_provinces_v2';
  static const String _citiesKey = 'cached_cities_v2';
  static const String _lastUpdateKey = 'location_cache_last_update';
  static const String _versionKey = 'location_cache_version';
  static const String _currentVersion = '2.0';
  
  // مدة انتهاء صلاحية الكاش (7 أيام)
  static const Duration _cacheExpiry = Duration(days: 7);
  
  // الكاش في الذاكرة للوصول الفوري
  static List<Map<String, dynamic>>? _memoryProvinces;
  static final Map<String, List<Map<String, dynamic>>> _memoryCities = {};
  static bool _isInitialized = false;
  static bool _isLoading = false;

  /// 🔄 تهيئة الخدمة - يتم استدعاؤها مرة واحدة عند بدء التطبيق
  static Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;
    
    _isLoading = true;
    debugPrint('🚀 === بدء تهيئة خدمة التخزين المؤقت للمواقع ===');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // فحص إصدار الكاش
      final cachedVersion = prefs.getString(_versionKey);
      if (cachedVersion != _currentVersion) {
        debugPrint('🔄 إصدار جديد من الكاش - مسح البيانات القديمة');
        await _clearCache();
        await prefs.setString(_versionKey, _currentVersion);
      }
      
      // فحص صلاحية الكاش
      final lastUpdate = prefs.getString(_lastUpdateKey);
      final isExpired = _isCacheExpired(lastUpdate);
      
      if (isExpired) {
        debugPrint('⏰ انتهت صلاحية الكاش - تحديث البيانات');
        await _refreshCache();
      } else {
        debugPrint('✅ الكاش صالح - تحميل من التخزين المحلي');
        await _loadFromCache();
      }
      
      _isInitialized = true;
      debugPrint('✅ === تم تهيئة خدمة التخزين المؤقت بنجاح ===');
      
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة التخزين المؤقت: $e');
      // في حالة الخطأ، نحاول تحميل البيانات مباشرة
      await _refreshCache();
    } finally {
      _isLoading = false;
    }
  }

  /// 📦 الحصول على المحافظات (فوري من الذاكرة)
  static Future<List<Map<String, dynamic>>> getProvinces() async {
    // التأكد من التهيئة
    if (!_isInitialized) {
      await initialize();
    }
    
    // إرجاع البيانات من الذاكرة فوراً
    if (_memoryProvinces != null) {
      debugPrint('⚡ إرجاع ${_memoryProvinces!.length} محافظة من الذاكرة (فوري)');
      return List<Map<String, dynamic>>.from(_memoryProvinces!);
    }
    
    // في حالة عدم وجود بيانات، نحاول التحميل
    debugPrint('⚠️ لا توجد محافظات في الذاكرة - محاولة التحميل');
    await _refreshCache();
    return _memoryProvinces ?? [];
  }

  /// 🏙️ الحصول على المدن لمحافظة معينة
  static Future<List<Map<String, dynamic>>> getCitiesForProvince(String provinceId) async {
    // التأكد من التهيئة
    if (!_isInitialized) {
      await initialize();
    }
    
    // فحص الذاكرة أولاً
    if (_memoryCities.containsKey(provinceId)) {
      debugPrint('⚡ إرجاع ${_memoryCities[provinceId]!.length} مدينة للمحافظة $provinceId من الذاكرة (فوري)');
      return List<Map<String, dynamic>>.from(_memoryCities[provinceId]!);
    }
    
    // تحميل من التخزين المحلي
    final cities = await _loadCitiesFromCache(provinceId);
    if (cities.isNotEmpty) {
      _memoryCities[provinceId] = cities;
      debugPrint('📱 تم تحميل ${cities.length} مدينة للمحافظة $provinceId من التخزين المحلي');
      return cities;
    }
    
    // تحميل من الخادم وحفظ
    debugPrint('🌐 تحميل مدن المحافظة $provinceId من الخادم...');
    final freshCities = await FlexibleDeliveryService.getCitiesForProvince(provinceId);
    if (freshCities.isNotEmpty) {
      await _saveCitiesToCache(provinceId, freshCities);
      _memoryCities[provinceId] = freshCities;
      debugPrint('✅ تم تحميل وحفظ ${freshCities.length} مدينة للمحافظة $provinceId');
    }
    
    return freshCities;
  }

  /// 🔄 تحديث الكاش يدوياً
  static Future<void> refreshCache() async {
    debugPrint('🔄 تحديث الكاش يدوياً...');
    await _refreshCache();
  }

  /// 🗑️ مسح الكاش
  static Future<void> clearCache() async {
    debugPrint('🗑️ مسح الكاش...');
    await _clearCache();
    _memoryProvinces = null;
    _memoryCities.clear();
    _isInitialized = false;
  }

  // ===== الدوال الداخلية =====

  /// فحص انتهاء صلاحية الكاش
  static bool _isCacheExpired(String? lastUpdateStr) {
    if (lastUpdateStr == null) return true;
    
    try {
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      return now.difference(lastUpdate) > _cacheExpiry;
    } catch (e) {
      return true;
    }
  }

  /// تحديث الكاش من الخادم
  static Future<void> _refreshCache() async {
    try {
      debugPrint('🌐 تحميل المحافظات من الخادم...');
      final provinces = await FlexibleDeliveryService.getProvinces();
      
      if (provinces.isNotEmpty) {
        await _saveProvincesToCache(provinces);
        _memoryProvinces = provinces;
        debugPrint('✅ تم تحديث ${provinces.length} محافظة في الكاش');
        
        // تحديث وقت آخر تحديث
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الكاش: $e');
    }
  }

  /// تحميل المحافظات من التخزين المحلي
  static Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final provincesJson = prefs.getString(_provincesKey);
      
      if (provincesJson != null) {
        final List<dynamic> provincesList = json.decode(provincesJson);
        _memoryProvinces = provincesList.cast<Map<String, dynamic>>();
        debugPrint('📱 تم تحميل ${_memoryProvinces!.length} محافظة من التخزين المحلي');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المحافظات من الكاش: $e');
    }
  }

  /// حفظ المحافظات في التخزين المحلي
  static Future<void> _saveProvincesToCache(List<Map<String, dynamic>> provinces) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final provincesJson = json.encode(provinces);
      await prefs.setString(_provincesKey, provincesJson);
      debugPrint('💾 تم حفظ ${provinces.length} محافظة في التخزين المحلي');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ المحافظات: $e');
    }
  }

  /// تحميل المدن من التخزين المحلي
  static Future<List<Map<String, dynamic>>> _loadCitiesFromCache(String provinceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final citiesJson = prefs.getString('${_citiesKey}_$provinceId');
      
      if (citiesJson != null) {
        final List<dynamic> citiesList = json.decode(citiesJson);
        return citiesList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المدن من الكاش: $e');
    }
    return [];
  }

  /// حفظ المدن في التخزين المحلي
  static Future<void> _saveCitiesToCache(String provinceId, List<Map<String, dynamic>> cities) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final citiesJson = json.encode(cities);
      await prefs.setString('${_citiesKey}_$provinceId', citiesJson);
      debugPrint('💾 تم حفظ ${cities.length} مدينة للمحافظة $provinceId في التخزين المحلي');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ المدن: $e');
    }
  }

  /// مسح جميع البيانات المخزنة
  static Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_provincesKey) || 
        key.startsWith(_citiesKey) ||
        key == _lastUpdateKey ||
        key == _versionKey
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('🗑️ تم مسح جميع بيانات الكاش');
    } catch (e) {
      debugPrint('❌ خطأ في مسح الكاش: $e');
    }
  }

  /// 📊 معلومات الكاش للتشخيص
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_lastUpdateKey);
    final version = prefs.getString(_versionKey);
    
    return {
      'isInitialized': _isInitialized,
      'provincesInMemory': _memoryProvinces?.length ?? 0,
      'citiesInMemory': _memoryCities.length,
      'lastUpdate': lastUpdate,
      'version': version,
      'isExpired': _isCacheExpired(lastUpdate),
    };
  }
}
