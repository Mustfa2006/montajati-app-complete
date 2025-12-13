// إعداد Supabase للـ Frontend - محسن للأمان
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ✅ إعدادات Supabase الآمنة - يتم تحميلها من متغيرات البيئة
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fqdhskaolzfavapmqodl.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwODE3MjYsImV4cCI6MjA2NTY1NzcyNn0.tRHMAogrSzjRwSIJ9-m0YMoPhlHeR6U8kfob0wyvf_I',
  );

  // تهيئة Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kDebugMode, // مُفعل في وضع التطوير فقط
    );

    if (kDebugMode) {
      debugPrint('✅ تم تهيئة Supabase للتطوير مع خادم الإنتاج');
      debugPrint('🔗 URL: $supabaseUrl');

      // Check Auth State immediately
      final session = Supabase.instance.client.auth.currentSession;
      debugPrint('👮 [Main] Initial Auth State: ${session != null ? "Logged In" : "Logged Out/Null"}');
      if (session != null) {
        debugPrint('🆔 [Main] User ID: ${session.user.id}');
      }
    }
  }

  // الحصول على عميل Supabase
  static SupabaseClient get client => Supabase.instance.client;

  // الحصول على عميل المصادقة
  static GoTrueClient get auth => client.auth;

  // الحصول على قاعدة البيانات
  static PostgrestClient get database => client.rest;
}
