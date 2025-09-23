import 'package:flutter/material.dart';

/// 🌌 الخلفية الموحدة للتطبيق - تصميم ثلاثي الأبعاد خرافي
class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(seconds: 20), vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.linear));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🌌 الخلفية الثلاثية الأبعاد الخرافية
          _buildFantastic3DBackground(),
          // المحتوى
          widget.child,
        ],
      ),
    );
  }

  /// 🌌 الخلفية الثلاثية الأبعاد الخرافية مع النجوم والإضاءة
  Widget _buildFantastic3DBackground() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // 🌌 الخلفية الأساسية - تدرج عميق ثلاثي الأبعاد
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  const Color(0xFF0F1419), // أسود مزرق عميق
                  const Color(0xFF1A1F2E), // أزرق داكن
                  const Color(0xFF0D1117), // أسود عميق
                  Colors.black, // أسود خالص
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // 💫 النجوم المتحركة - طبقة أولى
          ...List.generate(
            50,
            (index) => _buildAnimatedStar(
              top: (index * 47.3) % MediaQuery.of(context).size.height,
              left: (index * 73.7) % MediaQuery.of(context).size.width,
              size: 1.0 + (index % 3),
              animationDelay: index * 100,
            ),
          ),

          // ⭐ النجوم المتحركة - طبقة ثانية أكبر
          ...List.generate(
            25,
            (index) => _buildAnimatedStar(
              top: (index * 83.1) % MediaQuery.of(context).size.height,
              left: (index * 127.3) % MediaQuery.of(context).size.width,
              size: 2.0 + (index % 2),
              animationDelay: index * 150,
              isLarge: true,
            ),
          ),

          // 💡 الإضاءة الخرافية من الأعلى اليمين
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.15), // ذهبي خفيف
                    const Color(0xFF4A90E2).withValues(alpha: 0.1), // أزرق خفيف
                    const Color(0xFF6B73FF).withValues(alpha: 0.05), // بنفسجي خفيف
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 🌟 الإضاءة الثانوية من الأعلى اليسار
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00CED1).withValues(alpha: 0.12), // تركوازي
                    const Color(0xFF1E90FF).withValues(alpha: 0.08), // أزرق سماوي
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 🔥 الإضاءة الثالثة من الوسط السفلي
          Positioned(
            bottom: -200,
            left: MediaQuery.of(context).size.width * 0.3,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B6B).withValues(alpha: 0.1), // أحمر وردي
                    const Color(0xFFFF8E53).withValues(alpha: 0.08), // برتقالي
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ✨ الإضاءة المتحركة
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: 100 + (50 * _animation.value),
                right: 50 + (30 * _animation.value),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9B59B6).withValues(alpha: 0.15 * (1 - _animation.value)),
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // ✨ تأثير الغبار الكوني
          ...List.generate(
            30,
            (index) => _buildCosmicDust(
              top: (index * 67.4) % MediaQuery.of(context).size.height,
              left: (index * 91.2) % MediaQuery.of(context).size.width,
              animationDelay: index * 200,
            ),
          ),
        ],
      ),
    );
  }

  /// ⭐ بناء نجمة متحركة
  Widget _buildAnimatedStar({
    required double top,
    required double left,
    required double size,
    required int animationDelay,
    bool isLarge = false,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 2000 + animationDelay),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final opacity = (0.3 + 0.7 * (0.5 + 0.5 * value)).clamp(0.0, 1.0);
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isLarge
                  ? const Color(0xFFFFD700).withValues(alpha: opacity)
                  : Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: isLarge
                  ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1)]
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// ✨ بناء غبار كوني متحرك
  Widget _buildCosmicDust({required double top, required double left, required int animationDelay}) {
    return Positioned(
      top: top,
      left: left,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 3000 + animationDelay),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final opacity = (0.1 + 0.3 * value).clamp(0.0, 0.4);
          return Container(
            width: 1.5,
            height: 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFF87CEEB).withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }
}
