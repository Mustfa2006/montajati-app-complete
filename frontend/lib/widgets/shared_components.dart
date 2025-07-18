// مكونات مشتركة للتطبيق
import 'package:flutter/material.dart';
import 'dart:math' as math;

// ===== نماذج البيانات المشتركة =====

// كلاس النجمة المتحركة
class Star {
  double x;
  double y;
  double size;
  double opacity;
  double speed;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}

// ===== الرسامات المشتركة =====

// كلاس رسم النجوم
class StarsPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarsPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFffd700).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (final star in stars) {
      double x = (star.x + animationValue * star.speed) % 1.0;
      double y = (star.y + animationValue * star.speed * 0.5) % 1.0;

      double screenX = x * size.width;
      double screenY = y * size.height;

      paint.color = const Color(0xFFffd700).withOpacity(star.opacity * 0.8);
      canvas.drawCircle(
        Offset(screenX, screenY),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ===== مولدات المكونات المشتركة =====

class SharedComponents {
  // توليد النجوم
  static List<Star> generateStars({int count = 50}) {
    final random = math.Random();
    List<Star> stars = [];
    
    for (int i = 0; i < count; i++) {
      stars.add(Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        opacity: random.nextDouble() * 0.8 + 0.2,
        speed: random.nextDouble() * 0.5 + 0.1,
      ));
    }
    
    return stars;
  }

  // بناء النجوم المتحركة
  static Widget buildAnimatedStars(List<Star> stars, AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: StarsPainter(stars, controller.value),
        );
      },
    );
  }

  // بناء الطبقة الشفافة
  static Widget buildOverlay({double opacity = 0.8}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1a1a2e).withValues(alpha: opacity),
    );
  }

  // بناء الخلفية المتدرجة
  static Widget buildGradientBackground({required Widget child}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e), // #1a1a2e
            Color(0xFF16213e), // #16213e
          ],
        ),
      ),
      child: child,
    );
  }

  // بناء البطاقة الرئيسية
  static Widget buildMainCard({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    double maxWidth = 400,
  }) {
    return Container(
      width: width ?? MediaQuery.of(context).size.width * 0.9,
      height: height,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}
