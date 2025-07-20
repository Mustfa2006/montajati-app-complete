// ===================================
// مساعد تشخيص FCM للتطبيق
// FCM Debug Helper for Flutter App
// ===================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fcm_service.dart';
import '../config/supabase_config.dart';

class FCMDebugHelper {
  
  /// تشخيص شامل لحالة FCM في التطبيق
  static Future<Map<String, dynamic>> runFullDiagnosis() async {
    debugPrint('🔍 بدء التشخيص الشامل لـ FCM في التطبيق...');
    
    final results = <String, dynamic>{};
    
    try {
      // 1. فحص SharedPreferences
      results['sharedPreferences'] = await _checkSharedPreferences();
      
      // 2. فحص حالة FCM Service
      results['fcmService'] = await _checkFCMService();
      
      // 3. فحص الاتصال بـ Supabase
      results['supabase'] = await _checkSupabaseConnection();
      
      // 4. فحص FCM tokens في قاعدة البيانات
      results['database'] = await _checkDatabaseTokens();
      
      // 5. اختبار تسجيل token
      results['tokenRegistration'] = await _testTokenRegistration();
      
      debugPrint('✅ انتهى التشخيص الشامل');
      return results;
      
    } catch (e) {
      debugPrint('❌ خطأ في التشخيص: $e');
      results['error'] = e.toString();
      return results;
    }
  }
  
  /// فحص SharedPreferences
  static Future<Map<String, dynamic>> _checkSharedPreferences() async {
    debugPrint('📋 فحص SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final result = {
        'user_phone': prefs.getString('user_phone'),
        'current_user_id': prefs.getString('current_user_id'),
        'current_user_name': prefs.getString('current_user_name'),
        'current_user_phone': prefs.getString('current_user_phone'),
        'auth_token': prefs.getString('auth_token'),
        'current_user_is_admin': prefs.getBool('current_user_is_admin'),
      };
      
      debugPrint('✅ SharedPreferences:');
      result.forEach((key, value) {
        debugPrint('   - $key: ${value ?? 'null'}');
      });
      
      return {'success': true, 'data': result};
      
    } catch (e) {
      debugPrint('❌ خطأ في فحص SharedPreferences: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// فحص حالة FCM Service
  static Future<Map<String, dynamic>> _checkFCMService() async {
    debugPrint('🔥 فحص حالة FCM Service...');
    
    try {
      final fcmService = FCMService();
      final serviceInfo = fcmService.getServiceInfo();
      
      debugPrint('✅ FCM Service:');
      debugPrint('   - مُهيأ: ${serviceInfo['isInitialized']}');
      debugPrint('   - يحتوي على Token: ${serviceInfo['hasToken']}');
      debugPrint('   - معاينة Token: ${serviceInfo['tokenPreview']}');
      
      return {'success': true, 'data': serviceInfo};
      
    } catch (e) {
      debugPrint('❌ خطأ في فحص FCM Service: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// فحص الاتصال بـ Supabase
  static Future<Map<String, dynamic>> _checkSupabaseConnection() async {
    debugPrint('🗄️ فحص الاتصال بـ Supabase...');
    
    try {
      final supabase = SupabaseConfig.client;
      
      // اختبار بسيط للاتصال
      final response = await supabase
          .from('users')
          .select('count')
          .limit(1);
      
      debugPrint('✅ الاتصال بـ Supabase يعمل');
      return {'success': true, 'connected': true};
      
    } catch (e) {
      debugPrint('❌ خطأ في الاتصال بـ Supabase: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// فحص FCM tokens في قاعدة البيانات
  static Future<Map<String, dynamic>> _checkDatabaseTokens() async {
    debugPrint('📱 فحص FCM tokens في قاعدة البيانات...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('user_phone');
      
      if (userPhone == null) {
        debugPrint('⚠️ لا يوجد رقم هاتف في SharedPreferences');
        return {'success': false, 'error': 'No user phone found'};
      }
      
      final supabase = SupabaseConfig.client;
      
      // جلب tokens للمستخدم الحالي
      final response = await supabase
          .from('fcm_tokens')
          .select('*')
          .eq('user_phone', userPhone)
          .order('created_at', ascending: false);
      
      debugPrint('📊 عدد FCM tokens للمستخدم $userPhone: ${response.length}');
      
      if (response.isNotEmpty) {
        debugPrint('📋 آخر tokens:');
        for (int i = 0; i < response.length && i < 3; i++) {
          final token = response[i];
          debugPrint('   ${i + 1}. ${token['fcm_token'].toString().substring(0, 20)}... (${token['is_active'] ? 'نشط' : 'غير نشط'})');
        }
      }
      
      return {
        'success': true,
        'userPhone': userPhone,
        'tokenCount': response.length,
        'tokens': response
      };
      
    } catch (e) {
      debugPrint('❌ خطأ في فحص قاعدة البيانات: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// اختبار تسجيل token
  static Future<Map<String, dynamic>> _testTokenRegistration() async {
    debugPrint('🧪 اختبار تسجيل FCM Token...');
    
    try {
      final success = await FCMService.registerCurrentUserToken();
      
      if (success) {
        debugPrint('✅ تم تسجيل FCM Token بنجاح');
        return {'success': true, 'registered': true};
      } else {
        debugPrint('❌ فشل في تسجيل FCM Token');
        return {'success': false, 'registered': false};
      }
      
    } catch (e) {
      debugPrint('❌ خطأ في اختبار التسجيل: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// طباعة تقرير مفصل
  static void printDetailedReport(Map<String, dynamic> results) {
    debugPrint('\n' + '=' * 50);
    debugPrint('📊 تقرير تشخيص FCM مفصل');
    debugPrint('=' * 50);
    
    // SharedPreferences
    final prefs = results['sharedPreferences'];
    debugPrint('\n📋 SharedPreferences:');
    if (prefs['success']) {
      final data = prefs['data'] as Map<String, dynamic>;
      data.forEach((key, value) {
        final status = value != null ? '✅' : '❌';
        debugPrint('   $status $key: $value');
      });
    } else {
      debugPrint('   ❌ خطأ: ${prefs['error']}');
    }
    
    // FCM Service
    final fcm = results['fcmService'];
    debugPrint('\n🔥 FCM Service:');
    if (fcm['success']) {
      final data = fcm['data'] as Map<String, dynamic>;
      debugPrint('   ${data['isInitialized'] ? '✅' : '❌'} مُهيأ: ${data['isInitialized']}');
      debugPrint('   ${data['hasToken'] ? '✅' : '❌'} يحتوي على Token: ${data['hasToken']}');
      if (data['hasToken']) {
        debugPrint('   🔑 معاينة Token: ${data['tokenPreview']}...');
      }
    } else {
      debugPrint('   ❌ خطأ: ${fcm['error']}');
    }
    
    // Database
    final db = results['database'];
    debugPrint('\n📱 قاعدة البيانات:');
    if (db['success']) {
      debugPrint('   ✅ المستخدم: ${db['userPhone']}');
      debugPrint('   📊 عدد Tokens: ${db['tokenCount']}');
    } else {
      debugPrint('   ❌ خطأ: ${db['error']}');
    }
    
    // Token Registration
    final reg = results['tokenRegistration'];
    debugPrint('\n🧪 اختبار التسجيل:');
    if (reg['success']) {
      debugPrint('   ${reg['registered'] ? '✅' : '❌'} تسجيل Token: ${reg['registered'] ? 'نجح' : 'فشل'}');
    } else {
      debugPrint('   ❌ خطأ: ${reg['error']}');
    }
    
    debugPrint('\n' + '=' * 50);
  }
  
  /// تشغيل تشخيص سريع
  static Future<void> quickDiagnosis() async {
    final results = await runFullDiagnosis();
    printDetailedReport(results);
  }
}
