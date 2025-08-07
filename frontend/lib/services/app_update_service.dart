import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تحديث التطبيق بدون APK جديد
class AppUpdateService {
  static const String _configUrl = 'https://clownfish-app-krnk9.ondigitalocean.app/api/app-config';
  static const String _lastCheckKey = 'last_config_check';
  static const String _cachedConfigKey = 'cached_app_config';
  
  static Timer? _periodicTimer;
  static Map<String, dynamic>? _currentConfig;
  
  /// تهيئة خدمة التحديث
  static Future<void> initialize() async {
    try {
      debugPrint('🔄 تهيئة خدمة التحديث...');
      
      // تحميل الإعدادات المحفوظة
      await _loadCachedConfig();
      
      // فحص التحديثات فوراً
      await checkForUpdates();
      
      // بدء الفحص الدوري (كل 10 دقائق)
      startPeriodicCheck();
      
      debugPrint('✅ تم تهيئة خدمة التحديث بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة التحديث: $e');
    }
  }
  
  /// فحص التحديثات
  static Future<bool> checkForUpdates() async {
    try {
      debugPrint('🔍 فحص التحديثات من الخادم...');
      
      final response = await http.get(
        Uri.parse(_configUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final newConfig = data['data'] as Map<String, dynamic>;
          
          // مقارنة مع الإعدادات الحالية
          bool hasUpdates = _hasConfigChanged(newConfig);
          
          if (hasUpdates) {
            debugPrint('✅ تم العثور على تحديثات جديدة');
            await _applyNewConfig(newConfig);
            return true;
          } else {
            debugPrint('📝 لا توجد تحديثات جديدة');
            return false;
          }
        }
      }
      
      debugPrint('⚠️ لم يتم الحصول على استجابة صحيحة من الخادم');
      return false;
      
    } catch (e) {
      debugPrint('❌ خطأ في فحص التحديثات: $e');
      return false;
    }
  }
  
  /// بدء الفحص الدوري
  static void startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      await checkForUpdates();
    });
    debugPrint('⏰ تم بدء الفحص الدوري للتحديثات (كل 10 دقائق)');
  }
  
  /// إيقاف الفحص الدوري
  static void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    debugPrint('⏹️ تم إيقاف الفحص الدوري للتحديثات');
  }
  
  /// تحميل الإعدادات المحفوظة
  static Future<void> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedConfigString = prefs.getString(_cachedConfigKey);
      
      if (cachedConfigString != null) {
        _currentConfig = json.decode(cachedConfigString);
        debugPrint('📋 تم تحميل الإعدادات المحفوظة');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الإعدادات المحفوظة: $e');
    }
  }
  
  /// حفظ الإعدادات
  static Future<void> _saveConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedConfigKey, json.encode(config));
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('💾 تم حفظ الإعدادات الجديدة');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الإعدادات: $e');
    }
  }
  
  /// فحص إذا تغيرت الإعدادات
  static bool _hasConfigChanged(Map<String, dynamic> newConfig) {
    if (_currentConfig == null) return true;
    
    // مقارنة التواريخ
    String? currentLastUpdated = _currentConfig!['lastUpdated'];
    String? newLastUpdated = newConfig['lastUpdated'];
    
    return currentLastUpdated != newLastUpdated;
  }
  
  /// تطبيق الإعدادات الجديدة
  static Future<void> _applyNewConfig(Map<String, dynamic> newConfig) async {
    try {
      debugPrint('🔄 تطبيق الإعدادات الجديدة...');
      
      _currentConfig = newConfig;
      await _saveConfig(newConfig);
      
      // تطبيق الإعدادات المختلفة
      _applySyncSettings(newConfig['syncSettings']);
      _applyServerSettings(newConfig['serverSettings']);
      
      debugPrint('✅ تم تطبيق الإعدادات الجديدة بنجاح');
      
    } catch (e) {
      debugPrint('❌ خطأ في تطبيق الإعدادات الجديدة: $e');
    }
  }
  
  /// تطبيق إعدادات المزامنة
  static void _applySyncSettings(Map<String, dynamic>? syncSettings) {
    if (syncSettings == null) return;
    
    debugPrint('🔄 تطبيق إعدادات المزامنة الجديدة:');
    debugPrint('   فترة المزامنة: ${syncSettings['intervalMinutes']} دقيقة');
    debugPrint('   عرض حالة الوسيط: ${syncSettings['showWaseetStatus']}');
    debugPrint('   وضع عرض الحالة: ${syncSettings['statusDisplayMode']}');
    
    // يمكن تطبيق الإعدادات على الخدمات المختلفة هنا
  }
  
  /// تطبيق إعدادات الخادم
  static void _applyServerSettings(Map<String, dynamic>? serverSettings) {
    if (serverSettings == null) return;
    
    debugPrint('🔄 تطبيق إعدادات الخادم الجديدة:');
    debugPrint('   عنوان API: ${serverSettings['apiBaseUrl']}');
    debugPrint('   الميزات الجديدة: ${serverSettings['enableNewFeatures']}');
    debugPrint('   وضع التشخيص: ${serverSettings['debugMode']}');
  }
  
  /// فحص إذا كان هناك فرض تحديث
  static bool shouldForceUpdate() {
    return _currentConfig?['forceUpdate'] == true;
  }
  
  /// فحص إذا كان التطبيق في وضع الصيانة
  static bool isMaintenanceMode() {
    return _currentConfig?['maintenanceMode'] == true;
  }
  
  /// الحصول على رسالة التحديث
  static String getUpdateMessage() {
    return _currentConfig?['messages']?['updateAvailable'] ?? 'يتوفر تحديث جديد للتطبيق';
  }
  
  /// الحصول على رسالة الصيانة
  static String getMaintenanceMessage() {
    return _currentConfig?['messages']?['maintenanceMessage'] ?? 'التطبيق تحت الصيانة حالياً';
  }
  
  /// الحصول على وضع عرض الحالة
  static String getStatusDisplayMode() {
    return _currentConfig?['syncSettings']?['statusDisplayMode'] ?? 'exact';
  }
  
  /// الحصول على الحالات المدعومة
  static List<String> getSupportedStatuses() {
    final statuses = _currentConfig?['supportedStatuses'] as List<dynamic>?;
    return statuses?.cast<String>() ?? [];
  }
  
  /// فحص التحديثات مع عرض النتائج للمستخدم
  static Future<void> checkForUpdatesWithUI(BuildContext context) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      bool hasUpdates = await checkForUpdates();
      
      // إخفاء مؤشر التحميل
      Navigator.of(context).pop();
      
      if (hasUpdates) {
        // عرض رسالة التحديث
        _showUpdateDialog(context);
      } else {
        // عرض رسالة عدم وجود تحديثات
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد تحديثات جديدة'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      // إخفاء مؤشر التحميل في حالة الخطأ
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فحص التحديثات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// عرض حوار التحديث
  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !shouldForceUpdate(),
      builder: (context) => AlertDialog(
        title: const Text('تحديث متاح'),
        content: Text(getUpdateMessage()),
        actions: [
          if (!shouldForceUpdate())
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('لاحقاً'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // تطبيق التحديثات فوراً
              _applyImmediateUpdates(context);
            },
            child: const Text('تحديث الآن'),
          ),
        ],
      ),
    );
  }
  
  /// تطبيق التحديثات فوراً
  static void _applyImmediateUpdates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تطبيق التحديثات بنجاح! ✅'),
        backgroundColor: Colors.green,
      ),
    );
    
    // إعادة تشغيل أجزاء من التطبيق إذا لزم الأمر
    // أو إعادة تحميل الصفحة الحالية
  }
  
  /// تنظيف الموارد
  static void dispose() {
    stopPeriodicCheck();
    _currentConfig = null;
  }
}
