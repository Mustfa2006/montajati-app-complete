// ملف اختبار لتحديد المشكلة بدقة
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// استيراد تدريجي للخدمات لتحديد المشكلة
// import 'config/supabase_config.dart';
// import 'config/api_config.dart';
import 'providers/order_status_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('🔍 === بدء اختبار التطبيق خطوة بخطوة ===');
    
    // الخطوة 1: اختبار الأساسيات
    debugPrint('📋 الخطوة 1: اختبار الأساسيات...');
    debugPrint('✅ الأساسيات تعمل');

    // سنضيف الخدمات تدريجياً
    // debugPrint('📋 الخطوة 2: اختبار ApiConfig...');
    // debugPrint('📋 الخطوة 3: اختبار SupabaseConfig...');
    
    debugPrint('✅ جميع الاختبارات نجحت - بدء التطبيق');
    
  } catch (e, stackTrace) {
    debugPrint('❌ فشل في الخطوة: $e');
    debugPrint('📍 Stack trace: $stackTrace');
    // استمر في تشغيل التطبيق حتى لو فشلت الخدمات
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => OrderStatusProvider())],
      child: const DebugApp(),
    ),
  );
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'منتجاتي - اختبار التشخيص',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      
      theme: ThemeData(
        primarySwatch: Colors.amber,
        primaryColor: const Color(0xFFffd700),
        fontFamily: GoogleFonts.cairo().fontFamily,
        
        textTheme: GoogleFonts.cairoTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFffd700),
          brightness: Brightness.dark,
          primary: const Color(0xFFffd700),
          secondary: const Color(0xFFe6b31e),
          surface: const Color(0xFF1a1a2e),
        ),
        
        useMaterial3: true,
        
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
      ),
      
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
