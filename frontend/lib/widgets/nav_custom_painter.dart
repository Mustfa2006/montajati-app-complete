import 'package:flutter/material.dart';

class NavCustomPainter extends CustomPainter {
  late double loc;
  late double s;
  Color color;
  TextDirection textDirection;

  NavCustomPainter(
      double startingLoc, int itemsLength, this.color, this.textDirection) {
    final span = 1.0 / itemsLength;
    s = 0.18; // توسيع الفتحة إلى اليمين واليسار
    // تحسين المحاذاة لتكون التقويسة تحت الكرة بالضبط
    double l = startingLoc + (span - s) / 2;
    loc = textDirection == TextDirection.rtl ? 1.0 - l - s : l;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // تدرج ثلاثي الأبعاد خيالي بنفس لون الصفحة
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2D3748).withValues(alpha: 0.95), // لون الصفحة الأساسي
        const Color(0xFF1A202C).withValues(alpha: 0.9),  // أغمق للعمق
        const Color(0xFF171923).withValues(alpha: 0.85), // أعمق للتأثير ثلاثي الأبعاد
        const Color(0xFF0D1117).withValues(alpha: 0.8),  // الأعمق في الأسفل
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // طلاء الإطار الذهبي الخفيف
    final goldenBorderPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.6) // ذهبي خفيف
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      // بداية مقوسة من اليسار
      ..moveTo(15, 0) // بداية مقوسة بدلاً من الزاوية
      ..quadraticBezierTo(0, 0, 0, 15) // قوس خفيف في الزاوية اليسرى
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 15) // قوس خفيف في الزاوية اليمنى
      ..quadraticBezierTo(size.width, 0, size.width - 15, 0) // قوس خفيف
      ..lineTo((loc + s + 0.05) * size.width, 0) // خط إلى بداية القوس
      ..cubicTo(
        (loc + s - s * 0.15) * size.width,
        size.height * 0.02,
        (loc + s) * size.width,
        size.height * 0.75,
        (loc + s * 0.50) * size.width,
        size.height * 0.75,
      )
      ..cubicTo(
        loc * size.width,
        size.height * 0.75,
        (loc + s * 0.15) * size.width,
        size.height * 0.02,
        (loc - 0.05) * size.width,
        0,
      )
      ..close();
    // رسم الشريط الأساسي بالتدرج الخيالي
    canvas.drawPath(path, paint);

    // رسم الإطار الذهبي الخفيف على الأطراف العلوية والقوس
    final borderPath = Path()
      // الخط العلوي مع الأطراف المقوسة
      ..moveTo(15, 0)
      ..quadraticBezierTo(0, 0, 0, 15)
      ..moveTo(15, 0)
      ..lineTo((loc - 0.05) * size.width, 0)
      // القوس المنحني
      ..cubicTo(
        (loc + s * 0.15) * size.width,
        size.height * 0.02,
        loc * size.width,
        size.height * 0.75,
        (loc + s * 0.50) * size.width,
        size.height * 0.75,
      )
      ..cubicTo(
        (loc + s) * size.width,
        size.height * 0.75,
        (loc + s - s * 0.15) * size.width,
        size.height * 0.02,
        (loc + s + 0.05) * size.width,
        0,
      )
      // باقي الخط العلوي
      ..lineTo(size.width - 15, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 15);

    canvas.drawPath(borderPath, goldenBorderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return this != oldDelegate;
  }
}
