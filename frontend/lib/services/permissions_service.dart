import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class PermissionsService {
  static const String _permissionsKey = 'permissions_requested';
  
  // طلب الصلاحيات فقط في المرة الأولى
  static Future<bool> requestPermissionsIfNeeded() async {
    if (kIsWeb) return true; // لا نحتاج صلاحيات في الويب
    
    final prefs = await SharedPreferences.getInstance();
    final hasRequestedPermissions = prefs.getBool(_permissionsKey) ?? false;
    
    if (!hasRequestedPermissions) {
      // طلب الصلاحيات للمرة الأولى فقط
      await _requestAllPermissions();
      
      // حفظ أن الصلاحيات تم طلبها
      await prefs.setBool(_permissionsKey, true);
      
      return true; // مستخدم جديد
    }
    
    return false; // مستخدم قديم
  }
  
  // طلب جميع الصلاحيات المطلوبة
  static Future<void> _requestAllPermissions() async {
    // صلاحيات أساسية
    await Permission.storage.request();
    await Permission.photos.request();
    
    // للأندرويد 13+ نحتاج صلاحيات مختلفة
    if (Platform.isAndroid) {
      await Permission.manageExternalStorage.request();
      
      // للإصدارات الحديثة من الأندرويد
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        await Permission.photos.request();
        await Permission.videos.request();
      }
    }
    
    // لـ iOS
    if (Platform.isIOS) {
      await Permission.photosAddOnly.request();
    }
  }
  
  // التحقق من حالة الصلاحيات
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb) return true;
    
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        return await Permission.photos.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    
    if (Platform.isIOS) {
      return await Permission.photosAddOnly.isGranted;
    }
    
    return false;
  }
  
  // الحصول على إصدار الأندرويد
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    
    // هذا يحتاج مكتبة device_info_plus للحصول على الإصدار الدقيق
    // للآن نفترض إصدار حديث
    return 33;
  }
  
  // إعادة تعيين حالة الصلاحيات (للاختبار فقط)
  static Future<void> resetPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsKey);
  }
}
