// تطبيق منتجاتي - نظام إدارة الدروب شيبنگ
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';

import 'providers/order_status_provider.dart';

import 'router.dart';


import 'services/database_migration_service.dart';
import 'services/background_order_sync_service.dart';
import 'services/location_cache_service.dart';
import 'services/order_monitoring_service.dart';
import 'services/fcm_service.dart';
import 'services/order_status_monitor.dart';
import 'services/smart_profit_transfer.dart';
import 'services/lazy_loading_service.dart';
import 'services/global_orders_cache.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد معالج الأخطاء العام
  FlutterError.onError = (FlutterErrorDetails details) {
    // معالجة صامتة للأخطاء
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

  // تشغيل صامت

  // ⚡ بدء تحميل جميع الخدمات في الخلفية فوراً (بدون انتظار)
  _initializeAllServicesInBackground();

  // تشغيل التطبيق مع معالجة الأخطاء
  try {
    runApp(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => OrderStatusProvider())],
        child: const MontajatiApp(),
      ),
    );
  } catch (e) {
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

// ⚡ دالة تهيئة جميع الخدمات في الخلفية (بدون انتظار)
void _initializeAllServicesInBackground() {
  // تشغيل في الخلفية فوراً بدون انتظار
  Future.microtask(() async {
    try {
      // تحميل الخدمات بالتوازي لتوفير الوقت
      await Future.wait([
        _initializeSupabase(),
        _initializeOtherServices(),
      ], eagerError: false);

    } catch (e) {
      // لا نوقف التطبيق حتى لو فشلت الخدمات
    }
  });
}

// تهيئة Supabase
Future<void> _initializeSupabase() async {
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    // تهيئة صامتة
  }
}

// تهيئة باقي الخدمات
Future<void> _initializeOtherServices() async {
  try {
    // إعدادات API (سريع جداً)
    try {
      // تحميل صامت
    } catch (e) {
      // تحميل صامت
    }

    // تهيئة الكاش العالمي للطلبات
    try {
      await GlobalOrdersCache().initialize();
    } catch (e) {
      // تهيئة صامتة
    }

    // تهيئة خدمة الإشعارات
    try {
      await FCMService().initialize();
    } catch (e) {
      // تهيئة صامتة
    }

    // تحميل باقي الخدمات
    await _initializeAllServices();

  } catch (e) {
    // تهيئة صامتة
  }
}

// دالة تهيئة جميع الخدمات (الآن تُستخدم في الخلفية)
Future<void> _initializeAllServices() async {
  try {
    // تحميل إعدادات API
    try {
      // تحميل صامت
    } catch (e) {
      // تحميل صامت
    }

    // Supabase تم تهيئته بالفعل في الخدمات الأساسية



    // التحميل الذكي: فقط الأساسيات عند البدء

    // تهيئة خدمة المواقع فقط (مطلوبة للصفحة الرئيسية)
    try {
      await LocationCacheService.initialize();
    } catch (e) {
      // تهيئة صامتة
    }

    // باقي الخدمات ستُحمل عند الحاجة
    _scheduleBackgroundServices();

    // بدء التحميل المسبق للصفحات المهمة
    LazyLoadingService.preloadImportantPages();

    // انتظار قليل قبل بدء الخدمات التي تحتاج الشبكة
    await Future.delayed(const Duration(seconds: 2));

    // بدء مراقبة الطلبات في الوقت الفعلي للإشعارات الفورية
    try {
      await OrderMonitoringService.startMonitoring();
    } catch (e) {
      // نكمل بدون المراقبة الفورية
    }

  } catch (e) {
    // في حالة فشل تهيئة الخدمات، استمر في تشغيل التطبيق
    // تشغيل صامت
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

/// جدولة الخدمات في الخلفية بدون تأثير على سرعة التشغيل
void _scheduleBackgroundServices() {
  // تأخير 3 ثوان ثم بدء الخدمات في الخلفية
  Future.delayed(const Duration(seconds: 3), () async {
    // تهيئة مراقبة الأرباح
    try {
      OrderStatusMonitor.startMonitoring();
      await SmartProfitTransfer.testTransfer();
    } catch (e) {
      // تهيئة صامتة
    }

    // تهيئة المزامنة التلقائية
    try {
      await BackgroundOrderSyncService.initialize();
    } catch (e) {
      // تهيئة صامتة
    }

    // تشغيل تحديثات قاعدة البيانات في الخلفية
    try {
      await DatabaseMigrationService.runAllMigrations();
    } catch (e) {
      // تهيئة صامتة
    }
  });
}
