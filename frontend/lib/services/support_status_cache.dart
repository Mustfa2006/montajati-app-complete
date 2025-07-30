import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة ذكية لحفظ حالة الدعم محلياً كطبقة حماية إضافية
/// تضمن عدم فقدان حالة الأزرار حتى لو تم حذف التطبيق وإعادة تثبيته
class SupportStatusCache {
  static const String _cacheKey = 'support_status_cache';
  static const String _userCachePrefix = 'support_status_user_';
  
  /// حفظ حالة الدعم لطلب معين
  static Future<void> setSupportRequested(String orderId, bool requested) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على معرف المستخدم الحالي
      final currentUserPhone = prefs.getString('current_user_phone') ?? '';
      if (currentUserPhone.isEmpty) return;
      
      // مفتاح فريد للمستخدم
      final userCacheKey = '$_userCachePrefix$currentUserPhone';
      
      // جلب البيانات المحفوظة للمستخدم
      final existingDataStr = prefs.getString(userCacheKey) ?? '{}';
      final Map<String, dynamic> userData = json.decode(existingDataStr);
      
      // تحديث حالة الطلب
      userData[orderId] = {
        'support_requested': requested,
        'timestamp': DateTime.now().toIso8601String(),
        'user_phone': currentUserPhone,
      };
      
      // حفظ البيانات المحدثة
      await prefs.setString(userCacheKey, json.encode(userData));
      
      print('💾 تم حفظ حالة الدعم للطلب $orderId: $requested');
    } catch (e) {
      print('❌ خطأ في حفظ حالة الدعم: $e');
    }
  }
  
  /// جلب حالة الدعم لطلب معين
  static Future<bool?> getSupportRequested(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على معرف المستخدم الحالي
      final currentUserPhone = prefs.getString('current_user_phone') ?? '';
      if (currentUserPhone.isEmpty) return null;
      
      // مفتاح فريد للمستخدم
      final userCacheKey = '$_userCachePrefix$currentUserPhone';
      
      // جلب البيانات المحفوظة للمستخدم
      final existingDataStr = prefs.getString(userCacheKey) ?? '{}';
      final Map<String, dynamic> userData = json.decode(existingDataStr);
      
      // البحث عن الطلب
      final orderData = userData[orderId];
      if (orderData != null && orderData is Map<String, dynamic>) {
        return orderData['support_requested'] as bool?;
      }
      
      return null;
    } catch (e) {
      print('❌ خطأ في جلب حالة الدعم: $e');
      return null;
    }
  }
  
  /// جلب جميع الطلبات التي تم إرسال دعم لها للمستخدم الحالي
  static Future<Set<String>> getAllSupportRequestedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على معرف المستخدم الحالي
      final currentUserPhone = prefs.getString('current_user_phone') ?? '';
      if (currentUserPhone.isEmpty) return {};
      
      // مفتاح فريد للمستخدم
      final userCacheKey = '$_userCachePrefix$currentUserPhone';
      
      // جلب البيانات المحفوظة للمستخدم
      final existingDataStr = prefs.getString(userCacheKey) ?? '{}';
      final Map<String, dynamic> userData = json.decode(existingDataStr);
      
      // استخراج الطلبات التي تم إرسال دعم لها
      final supportedOrders = <String>{};
      userData.forEach((orderId, orderData) {
        if (orderData is Map<String, dynamic> && 
            orderData['support_requested'] == true) {
          supportedOrders.add(orderId);
        }
      });
      
      return supportedOrders;
    } catch (e) {
      print('❌ خطأ في جلب الطلبات المدعومة: $e');
      return {};
    }
  }
  
  /// مزامنة البيانات المحلية مع قاعدة البيانات
  static Future<void> syncWithDatabase(Map<String, bool> databaseData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على معرف المستخدم الحالي
      final currentUserPhone = prefs.getString('current_user_phone') ?? '';
      if (currentUserPhone.isEmpty) return;
      
      // مفتاح فريد للمستخدم
      final userCacheKey = '$_userCachePrefix$currentUserPhone';
      
      // جلب البيانات المحلية
      final existingDataStr = prefs.getString(userCacheKey) ?? '{}';
      final Map<String, dynamic> localData = json.decode(existingDataStr);
      
      // مزامنة البيانات
      bool hasChanges = false;
      databaseData.forEach((orderId, supportRequested) {
        final localOrderData = localData[orderId];
        if (localOrderData == null || 
            localOrderData['support_requested'] != supportRequested) {
          localData[orderId] = {
            'support_requested': supportRequested,
            'timestamp': DateTime.now().toIso8601String(),
            'user_phone': currentUserPhone,
            'synced_from_db': true,
          };
          hasChanges = true;
        }
      });
      
      // حفظ التغييرات إذا وجدت
      if (hasChanges) {
        await prefs.setString(userCacheKey, json.encode(localData));
        print('🔄 تم مزامنة ${databaseData.length} طلب مع البيانات المحلية');
      }
    } catch (e) {
      print('❌ خطأ في مزامنة البيانات: $e');
    }
  }
  
  /// مسح البيانات المحلية للمستخدم الحالي
  static Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على معرف المستخدم الحالي
      final currentUserPhone = prefs.getString('current_user_phone') ?? '';
      if (currentUserPhone.isEmpty) return;
      
      // مفتاح فريد للمستخدم
      final userCacheKey = '$_userCachePrefix$currentUserPhone';
      
      // مسح البيانات
      await prefs.remove(userCacheKey);
      print('🗑️ تم مسح بيانات الدعم المحلية للمستخدم');
    } catch (e) {
      print('❌ خطأ في مسح البيانات المحلية: $e');
    }
  }
  
  /// إحصائيات البيانات المحلية
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على معرف المستخدم الحالي
      final currentUserPhone = prefs.getString('current_user_phone') ?? '';
      if (currentUserPhone.isEmpty) return {};
      
      // مفتاح فريد للمستخدم
      final userCacheKey = '$_userCachePrefix$currentUserPhone';
      
      // جلب البيانات المحفوظة للمستخدم
      final existingDataStr = prefs.getString(userCacheKey) ?? '{}';
      final Map<String, dynamic> userData = json.decode(existingDataStr);
      
      int totalOrders = userData.length;
      int supportedOrders = 0;
      
      userData.forEach((orderId, orderData) {
        if (orderData is Map<String, dynamic> && 
            orderData['support_requested'] == true) {
          supportedOrders++;
        }
      });
      
      return {
        'total_orders': totalOrders,
        'supported_orders': supportedOrders,
        'user_phone': currentUserPhone,
        'cache_key': userCacheKey,
      };
    } catch (e) {
      print('❌ خطأ في جلب إحصائيات البيانات: $e');
      return {};
    }
  }
}
