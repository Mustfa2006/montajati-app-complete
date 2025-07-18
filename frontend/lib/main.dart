// تطبيق منتجاتي - نظام إدارة الدروب شيبنگ
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/api_config.dart';
import 'providers/order_status_provider.dart';
import 'router.dart';
import 'services/firebase_service.dart';
import 'services/official_notification_service.dart';
import 'services/database_migration_service.dart';

import 'services/background_order_sync_service.dart';
import 'services/notification_service.dart';
import 'services/location_cache_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إخفاء شريط الحالة لجميع الصفحات
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    // رسالة ترحيب للتطوير
    if (kDebugMode) {
      debugPrint('🎯 ===== تطبيق منتجاتي - وضع التطوير =====');
      debugPrint('🌐 متصل بخادم الإنتاج: https://montajati-backend.onrender.com');
      debugPrint('🔄 Hot Reload مُفعل للتطوير السريع');
      debugPrint('📱 جاهز للاختبار والتطوير');
      debugPrint('===============================================');
    }

    // طباعة إعدادات API
    ApiConfig.printConfig();

    // تهيئة Supabase
    await SupabaseConfig.initialize();

    // تهيئة Firebase للإشعارات
    await FirebaseService.initialize();

    // تهيئة نظام الإشعارات الرسمي
    await OfficialNotificationService.initialize();

    // تشغيل تحديثات قاعدة البيانات
    debugPrint('🔄 تشغيل تحديثات قاعدة البيانات...');
    await DatabaseMigrationService.runAllMigrations();

    // 🚀 تهيئة خدمة التخزين المؤقت للمواقع (مرة واحدة فقط)
    debugPrint('📍 تهيئة خدمة التخزين المؤقت للمواقع...');
    await LocationCacheService.initialize();

    // تهيئة خدمة الإشعارات
    debugPrint('🔔 تهيئة خدمة الإشعارات...');
    await NotificationService.initialize();

    // بدء المراقبة التلقائية المستمرة للطلبات
    debugPrint('🚀 بدء المراقبة التلقائية المستمرة للطلبات...');
    await BackgroundOrderSyncService.initialize();



    debugPrint('✅ تم تهيئة جميع الخدمات بنجاح - المراقبة التلقائية نشطة');
  } catch (e) {
    // في حالة فشل تهيئة الخدمات، استمر في تشغيل التطبيق
    debugPrint('❌ خطأ في تهيئة الخدمات: $e');
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => OrderStatusProvider())],
      child: const MontajatiApp(),
    ),
  );
}

class MontajatiApp extends StatelessWidget {
  const MontajatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'منتجاتي - نظام إدارة الدروب شيبنگ',
      debugShowCheckedModeBanner: false,

      // إعدادات التطبيق
      routerConfig: AppRouter.router,

      // إعدادات الثيم
      theme: ThemeData(
        // الألوان الأساسية
        primarySwatch: Colors.amber,
        primaryColor: const Color(0xFFffd700),

        // خط التطبيق
        fontFamily: GoogleFonts.cairo().fontFamily,

        // إعدادات النصوص
        textTheme: GoogleFonts.cairoTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),

        // إعدادات الألوان العامة
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFffd700),
          brightness: Brightness.dark,
          primary: const Color(0xFFffd700),
          secondary: const Color(0xFFe6b31e),
          surface: const Color(0xFF1a1a2e),
        ),

        // إعدادات Material 3
        useMaterial3: true,

        // إعدادات AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF16213e),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // إعدادات الأزرار
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFffd700),
            foregroundColor: const Color(0xFF1a1a2e),
            textStyle: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // إعدادات حقول الإدخال
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFffd700), width: 2),
          ),
          labelStyle: GoogleFonts.cairo(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),

      // إعدادات اللغة والاتجاه
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'), // العربية
        Locale('en', 'US'), // الإنجليزية
      ],

      // إعدادات الترجمة
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // اتجاه النص من اليمين لليسار
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
