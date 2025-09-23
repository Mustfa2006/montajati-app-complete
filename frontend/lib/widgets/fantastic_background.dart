// 🌌 الخلفية الخرافية المشتركة لجميع الصفحات
// Fantastic Background Widget for All Pages

import 'package:flutter/material.dart';

/// 🌌 ويدجت الخلفية الخرافية ثلاثية الأبعاد
class FantasticBackground extends StatelessWidget {
  const FantasticBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // 🌌 الخلفية الأساسية - تدرج عميق ثلاثي الأبعاد
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight, // من الأعلى اليمين
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
              context: context,
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
              context: context,
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
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 🌟 إضاءة ثانوية متحركة
          Positioned(
            top: 100,
            right: 50,
            child: TweenAnimationBuilder<double>(
              duration: Duration(seconds: 4),
              tween: Tween(begin: 0.3, end: 0.8),
              builder: (context, value, child) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF9D4EDD).withValues(alpha: value * 0.1),
                        Color(0xFF7209B7).withValues(alpha: value * 0.05),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          ),

          // ✨ تأثير الغبار الكوني
          ...List.generate(
            30,
            (index) => _buildCosmicDust(
              context: context,
              top: (index * 67.4) % MediaQuery.of(context).size.height,
              left: (index * 91.2) % MediaQuery.of(context).size.width,
              animationDelay: index * 200,
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ بناء نجمة متحركة
  static Widget _buildAnimatedStar({
    required BuildContext context,
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
        builder: (context, value, child) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 1500),
            width: size * (0.5 + value * 0.5),
            height: size * (0.5 + value * 0.5),
            decoration: BoxDecoration(
              color: isLarge
                  ? Color(0xFFFFD700).withValues(alpha: 0.8 + value * 0.2)
                  : Colors.white.withValues(alpha: 0.6 + value * 0.4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isLarge ? Color(0xFFFFD700).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2),
                  blurRadius: size * 2,
                  spreadRadius: size * 0.5,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✨ بناء غبار كوني متحرك
  static Widget _buildCosmicDust({
    required BuildContext context,
    required double top,
    required double left,
    required int animationDelay,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 3000 + animationDelay),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Container(
            width: 1.0 + value,
            height: 1.0 + value,
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withValues(alpha: 0.3 + value * 0.2),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }
}
