// ===================================
// شاشة التحميل الذكية والسريعة
// Smart & Fast Splash Screen
// ===================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SmartSplashPage extends StatefulWidget {
  const SmartSplashPage({super.key});

  @override
  State<SmartSplashPage> createState() => _SmartSplashPageState();
}

class _SmartSplashPageState extends State<SmartSplashPage>
    with TickerProviderStateMixin {
  
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _progressValue;
  
  String _statusText = 'جاري التحميل...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSmartInitialization();
  }

  void _initializeAnimations() {
    // حركة الشعار - سريعة جداً
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 400), // مخفضة من 800ms
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate( // بداية أكبر
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut), // منحنى أسرع
    );

    _logoOpacity = Tween<double>(begin: 0.3, end: 1.0).animate( // بداية أوضح
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // حركة شريط التقدم - سريعة جداً
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 600), // مخفضة من 1500ms
      vsync: this,
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut), // منحنى أسرع
    );

    // بدء الحركات فوراً
    _logoController.forward();
    _progressController.forward();
  }

  Future<void> _startSmartInitialization() async {
    try {
      // 🚀 التحميل الفوري - بدون انتظار
      final prefs = await SharedPreferences.getInstance();

      String targetRoute = '/welcome';

      // فحص فوري لحالة تسجيل الدخول (بدون انتظار)
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userPhone = prefs.getString('current_user_phone');
      final userRole = prefs.getString('user_role');

      if (isLoggedIn && userPhone != null && userPhone.isNotEmpty) {
        if (userRole == 'admin') {
          targetRoute = '/admin';
        } else {
          targetRoute = '/products';
        }
      }

      // تحديث النص بسرعة
      setState(() => _statusText = 'جاري التحميل...');

      // انتظار قصير جداً فقط للحركة (500ms بدلاً من 1000ms+)
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _statusText = 'مرحباً بك!');

      // بدء الحركات بشكل متوازي
      _logoController.forward();
      _progressController.forward();

      // انتظار قصير للحركة ثم الانتقال فوراً
      await Future.delayed(const Duration(milliseconds: 300));

      // التنقل الفوري
      if (mounted) {
        context.go(targetRoute);
      }

    } catch (e) {
      debugPrint('❌ خطأ في التهيئة: $e');
      // في حالة الخطأ، انتقل فوراً للصفحة الرئيسية
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // المساحة العلوية
              const Spacer(flex: 2),
              
              // الشعار المتحرك
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFffd700),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFffd700).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          FontAwesomeIcons.store,
                          color: Color(0xFF1a1a2e),
                          size: 50,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              // اسم التطبيق
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Text(
                      'منتجاتي',
                      style: GoogleFonts.cairo(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 10),
              
              // الوصف
              Text(
                'إدارة ذكية لمنتجاتك',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w300,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // شريط التقدم المتحرك
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressValue.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFffd700),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFffd700).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // نص الحالة
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusText,
                        key: ValueKey(_statusText),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 1),
              
              // معلومات الإصدار
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  'الإصدار 1.0.4',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
