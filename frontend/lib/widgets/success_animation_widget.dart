import 'package:flutter/material.dart';

/// ✨ أنيميشن علامة الصح البسيط والأنيق
class SuccessAnimationWidget extends StatefulWidget {
  const SuccessAnimationWidget({super.key});

  @override
  State<SuccessAnimationWidget> createState() => _SuccessAnimationWidgetState();
}

class _SuccessAnimationWidgetState extends State<SuccessAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // 0.8 ثانية للرسم
      vsync: this,
    );

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // بدء الأنيميشن
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: AnimatedBuilder(
          animation: _checkAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: CheckMarkPainter(animationValue: _checkAnimation.value),
            );
          },
        ),
      ),
    );
  }
}

/// رسام علامة الصح المتحركة
class CheckMarkPainter extends CustomPainter {
  final double animationValue;

  CheckMarkPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFF28a745) // أخضر جميل
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final checkSize = size.width * 0.6;

    // نقاط علامة الصح
    final startPoint = Offset(center.dx - checkSize * 0.3, center.dy);
    final middlePoint = Offset(
      center.dx - checkSize * 0.1,
      center.dy + checkSize * 0.2,
    );
    final endPoint = Offset(
      center.dx + checkSize * 0.4,
      center.dy - checkSize * 0.3,
    );

    final path = Path();

    if (animationValue <= 0.5) {
      // رسم الجزء الأول من الصح (من اليسار للوسط)
      final progress = animationValue * 2;
      final currentPoint = Offset.lerp(startPoint, middlePoint, progress)!;

      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // رسم الجزء الكامل الأول + الجزء الثاني
      final progress = (animationValue - 0.5) * 2;
      final currentPoint = Offset.lerp(middlePoint, endPoint, progress)!;

      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(middlePoint.dx, middlePoint.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
