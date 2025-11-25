// تطبيق منتجاتي - نظام إدارة الدروب شيبنگ
import 'utils/app_logger.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config/supabase_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/order_status_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'providers/competitions_provider.dart';

import 'services/fcm_service.dart';
import 'services/global_orders_cache.dart';
import 'services/lazy_loading_service.dart';
import 'services/location_cache_service.dart';
import 'widgets/immersive_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 إعداد النمط الغامر - Status Bar ثابت + Navigation Bar مخفي
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top], // Status Bar ثابت فقط
  );

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
              const Text('حدث خطأ في التطبيق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (kDebugMode)
                Text('الخطأ: ${details.exception}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
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

  // رسالة ترحيب للتطوير
  if (kDebugMode) {
    debugPrint('🎯 ===== تطبيق منتجاتي - فتح فوري =====');
    debugPrint('⚡ التطبيق سيفتح فوراً - جميع الخدمات تُحمل في الخلفية');
    debugPrint('===============================================');
  }

  // ⚡ بدء تحميل جميع الخدمات في الخلفية فوراً (بدون انتظار)
  _initializeAllServicesInBackground();

  // تشغيل التطبيق مع معالجة الأخطاء
  try {
    debugPrint('🚀 بدء تشغيل التطبيق...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => OrderStatusProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => CompetitionsProvider()..load()),
        ],
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
                Text('التطبيق يعمل في الوضع الآمن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('يرجى إعادة تشغيل التطبيق', style: TextStyle(fontSize: 14)),
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
      // تحميل الخدمات الأساسية بالتوازي لتقليل وقت البدء
      await Future.wait([_initializeSupabase(), _initializeOtherServices()], eagerError: false);
    } catch (e) {
      // نطبع فقط الأخطاء الضرورية
      debugPrint('❌ خطأ في تحميل الخدمات في الخلفية: $e');
      // لا نوقف التطبيق حتى لو فشلت الخدمات
    }
  });
}

// تهيئة Supabase
Future<void> _initializeSupabase() async {
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('❌ خطأ في تهيئة Supabase: $e');
  }
}

// تهيئة باقي الخدمات
Future<void> _initializeOtherServices() async {
  try {
    // تهيئة الكاش العالمي للطلبات
    try {
      await GlobalOrdersCache().initialize();
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الكاش العالمي: $e');
    }

    // تهيئة خدمة الإشعارات
    try {
      await FCMService().initialize();
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
    }

    // تحميل باقي الخدمات
    await _initializeAllServices();
  } catch (e) {
    debugPrint('❌ خطأ في تهيئة الخدمات الأخرى: $e');
  }
}

// دالة تهيئة جميع الخدمات (الآن تُستخدم في الخلفية)
Future<void> _initializeAllServices() async {
  try {
    // تهيئة خدمة المواقع فقط (مطلوبة للصفحة الرئيسية)
    try {
      await LocationCacheService.initialize();
    } catch (e) {
      debugPrint('❌ خطأ في خدمة المواقع: $e');
    }

    // باقي الخدمات ستُحمل عند الحاجة
    _scheduleBackgroundServices();

    // بدء التحميل المسبق للصفحات المهمة
    LazyLoadingService.preloadImportantPages();

    // انتظار قليل قبل بدء الخدمات التي تحتاج الشبكة
    await Future.delayed(const Duration(seconds: 2));
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

      // دعم اللغة العربية فقط
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // للغات المدعومة، استخدم اللغة المطلوبة
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }

        // إذا لم تكن مدعومة، استخدم العربية كافتراضي
        return const Locale('ar');
      },

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
        textTheme: GoogleFonts.cairoTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),

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
          titleTextStyle: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),

        // إعدادات الأزرار
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFffd700),
            foregroundColor: const Color(0xFF1a1a2e),
            textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // إعدادات حقول الإدخال
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: InputBorder.none, // ✅ إزالة جميع الحدود
          enabledBorder: InputBorder.none, // ✅ إزالة حدود الحالة العادية
          focusedBorder: InputBorder.none, // ✅ إزالة حدود التركيز
          disabledBorder: InputBorder.none, // ✅ إزالة حدود التعطيل
          errorBorder: InputBorder.none, // ✅ إزالة حدود الخطأ
          focusedErrorBorder: InputBorder.none, // ✅ إزالة حدود الخطأ مع التركيز
          labelStyle: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ),

      // اتجاه النص من اليمين لليسار + النمط الغامر
      builder: (context, child) {
        return ImmersiveWrapper(
          child: Directionality(textDirection: TextDirection.rtl, child: child!),
        );
      },
    );
  }
}

/// جدولة الخدمات في الخلفية بدون تأثير على سرعة التشغيل
void _scheduleBackgroundServices() {
  // حالياً لا نقوم بتشغيل أي خدمات خلفية ثقيلة من هنا
  // يمكن إضافة خدمات خفيفة أو مجدولة عند الحاجة (مثلاً إرسال إحصائيات بسيطة)
}
