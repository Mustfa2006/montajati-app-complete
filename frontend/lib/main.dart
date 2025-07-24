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


import 'services/database_migration_service.dart';
import 'services/background_order_sync_service.dart';
import 'services/location_cache_service.dart';
import 'services/order_monitoring_service.dart';
import 'services/fcm_service.dart';
import 'services/order_status_monitor.dart';
import 'services/smart_profit_transfer.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد معالج الأخطاء العام
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ خطأ Flutter: ${details.exception}');
    if (kDebugMode) {
      debugPrint('📍 Stack trace: ${details.stack}');
    }
  };

  // إعداد ErrorWidget مبسط
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'حدث خطأ في التطبيق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (kDebugMode)
                Text(
                  'الخطأ: ${details.exception}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text('إعادة تشغيل التطبيق'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  try {
    // رسالة ترحيب للتطوير
    if (kDebugMode) {
      debugPrint('🎯 ===== تطبيق منتجاتي - وضع التطوير =====');
      debugPrint('🌐 متصل بخادم الإنتاج: https://montajati-backend.onrender.com');
      debugPrint('🔄 Hot Reload مُفعل للتطوير السريع');
      debugPrint('📱 جاهز للاختبار والتطوير');
      debugPrint('===============================================');
    }

    // إضافة timeout عام للتهيئة
    await Future.any([
      _initializeAllServices(),
      Future.delayed(const Duration(seconds: 30), () {
        debugPrint('⏰ انتهت مهلة التهيئة - سيتم تشغيل التطبيق');
      }),
    ]);

  } catch (e, stackTrace) {
    // في حالة فشل تهيئة الخدمات، استمر في تشغيل التطبيق
    debugPrint('❌ خطأ عام في تهيئة الخدمات: $e');
    debugPrint('📍 Stack trace: $stackTrace');

    // محاولة تشغيل التطبيق حتى لو فشلت بعض الخدمات
    debugPrint('⚠️ سيتم تشغيل التطبيق مع الخدمات المتاحة فقط');
  }

  // تشغيل التطبيق مع معالجة الأخطاء
  try {
    debugPrint('🚀 بدء تشغيل التطبيق...');
    runApp(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => OrderStatusProvider())],
        child: const MontajatiApp(),
      ),
    );
    debugPrint('✅ تم تشغيل التطبيق بنجاح');
  } catch (e, stackTrace) {
    debugPrint('❌ خطأ في تشغيل التطبيق: $e');
    debugPrint('📍 Stack trace: $stackTrace');

    // تشغيل نسخة احتياطية من التطبيق
    runApp(
      MaterialApp(
        title: 'منتجاتي',
        home: Scaffold(
          appBar: AppBar(title: const Text('منتجاتي')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'التطبيق يعمل في الوضع الآمن',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'يرجى إعادة تشغيل التطبيق',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// دالة تهيئة جميع الخدمات
Future<void> _initializeAllServices() async {
  try {
    // طباعة إعدادات API
    try {
      ApiConfig.printConfig();
      debugPrint('✅ تم تحميل إعدادات API بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعدادات API: $e');
    }

    // تهيئة Supabase
    try {
      debugPrint('🔄 بدء تهيئة Supabase...');
      await SupabaseConfig.initialize();
      debugPrint('✅ تم تهيئة Supabase بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة Supabase: $e');
      // لا نوقف التطبيق، نكمل بدون Supabase
    }



    // تشغيل تحديثات قاعدة البيانات
    try {
      debugPrint('🔄 بدء تشغيل تحديثات قاعدة البيانات...');
      await DatabaseMigrationService.runAllMigrations();
      debugPrint('✅ تم تشغيل تحديثات قاعدة البيانات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تحديثات قاعدة البيانات: $e');
      // نكمل بدون التحديثات
    }

    // 🚀 تهيئة خدمة التخزين المؤقت للمواقع (مرة واحدة فقط)
    try {
      debugPrint('🔄 بدء تهيئة خدمة التخزين المؤقت للمواقع...');
      await LocationCacheService.initialize();
      debugPrint('✅ تم تهيئة خدمة التخزين المؤقت للمواقع بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة التخزين المؤقت للمواقع: $e');
      // نكمل بدون الخدمة
    }

    // 🔔 تهيئة خدمة الإشعارات الفورية FCM
    try {
      debugPrint('🔄 بدء تهيئة خدمة الإشعارات...');
      await FCMService().initialize();
      debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
      // نكمل بدون الإشعارات
    }

    // 🧠 تفعيل نظام مراقبة الأرباح الذكي
    try {
      debugPrint('🧠 تفعيل نظام مراقبة الأرباح الذكي...');
      OrderStatusMonitor.startMonitoring();
      debugPrint('✅ تم تفعيل نظام مراقبة الأرباح الذكي');

      // اختبار النظام
      await SmartProfitTransfer.testTransfer();
    } catch (e) {
      debugPrint('❌ خطأ في تفعيل نظام مراقبة الأرباح: $e');
      // نكمل بدون النظام
    }



    // بدء المراقبة التلقائية المستمرة للطلبات
    try {
      debugPrint('🔄 بدء المراقبة التلقائية المستمرة للطلبات...');
      await BackgroundOrderSyncService.initialize();
      debugPrint('✅ تم بدء المراقبة التلقائية المستمرة للطلبات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في بدء المراقبة التلقائية المستمرة للطلبات: $e');
      // نكمل بدون المراقبة التلقائية
    }

    // بدء مراقبة الطلبات في الوقت الفعلي للإشعارات الفورية
    try {
      debugPrint('🔄 بدء مراقبة الطلبات للإشعارات الفورية...');
      await OrderMonitoringService.startMonitoring();
      debugPrint('✅ تم بدء مراقبة الطلبات للإشعارات الفورية بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في بدء مراقبة الطلبات للإشعارات الفورية: $e');
      // نكمل بدون المراقبة الفورية
    }

    debugPrint('✅ تم تهيئة جميع الخدمات بنجاح - المراقبة التلقائية والإشعارات الفورية نشطة');
  } catch (e, stackTrace) {
    // في حالة فشل تهيئة الخدمات، استمر في تشغيل التطبيق
    debugPrint('❌ خطأ عام في تهيئة الخدمات: $e');
    debugPrint('📍 Stack trace: $stackTrace');

    // محاولة تشغيل التطبيق حتى لو فشلت بعض الخدمات
    debugPrint('⚠️ سيتم تشغيل التطبيق مع الخدمات المتاحة فقط');
  }
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
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFffd700), width: 2),
          ),
          labelStyle: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.7),
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
