import 'package:flutter/material.dart';

/// ???? ???? ????? ?????? ?????? (curved_navigation_bar)
/// ???? ????? ?? ???????? ?????? ?????? [color]
class NavCustomPainter extends CustomPainter {
  late double loc;
  late double s;
  Color color;
  Gradient? gradient; // ✨ إضافة التدرج اللوني
  TextDirection textDirection;

  NavCustomPainter(double startingLoc, int itemsLength, this.color, this.textDirection, {this.gradient}) {
    final span = 1.0 / itemsLength;
    s = 0.2;
    final l = startingLoc + (span - s) / 2;
    loc = textDirection == TextDirection.rtl ? 0.8 - l : l;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ✨ تطبيق التدرج اللوني إذا وجد
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    // ??? ?????? ?? ????????
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo((loc - 0.1) * size.width, 0)
      ..cubicTo(
        (loc + s * 0.20) * size.width,
        size.height * 0.05,
        loc * size.width,
        size.height * 0.60,
        (loc + s * 0.50) * size.width,
        size.height * 0.60,
      )
      ..cubicTo(
        (loc + s) * size.width,
        size.height * 0.60,
        (loc + s - s * 0.20) * size.width,
        size.height * 0.05,
        (loc + s + 0.1) * size.width,
        0,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // ✨ رسم خط ذهبي علوي "رهيب" يتبع القوس
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
          .withValues(alpha: 0.5) // ذهبي خفيف وراقي
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          1.5 // سمك ناعم
      ..strokeCap = StrokeCap.round; // حواف ناعمة

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo((loc - 0.1) * size.width, 0)
      ..cubicTo(
        (loc + s * 0.20) * size.width,
        size.height * 0.05,
        loc * size.width,
        size.height * 0.60,
        (loc + s * 0.50) * size.width,
        size.height * 0.60,
      )
      ..cubicTo(
        (loc + s) * size.width,
        size.height * 0.60,
        (loc + s - s * 0.20) * size.width,
        size.height * 0.05,
        (loc + s + 0.1) * size.width,
        0,
      )
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return this != oldDelegate;
  }
}
