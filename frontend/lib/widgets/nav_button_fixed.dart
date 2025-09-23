import 'package:flutter/material.dart';

class NavButton extends StatelessWidget {
  final double position;
  final int length;
  final int index;
  final ValueChanged<int> onTap;
  final Widget child;

  const NavButton({
    super.key,
    required this.onTap,
    required this.position,
    required this.length,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final desiredPosition = 1.0 / length * index;
    final difference = (position - desiredPosition).abs();
    final verticalAlignment = 1 - length * difference;
    final isActive = difference < 1.0 / length * 0.99;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          onTap(index);
        },
        child: SizedBox(
          height: 75.0,
          child: Transform.translate(
            offset: Offset(0, difference < 1.0 / length ? verticalAlignment * 40 : 0),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              padding: EdgeInsets.all(14), // حشو أكبر للزر
              decoration: BoxDecoration(
                // ألوان بسيطة وواضحة
                color: isActive
                    ? const Color(0xFFFFD700) // ذهبي واضح للنشط
                    : Colors.white.withValues(alpha: 0.9), // أبيض واضح للغير نشط
                borderRadius: BorderRadius.circular(12),
                // حدود واضحة
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFB8860B) // ذهبي داكن للنشط
                      : Colors.grey.withValues(alpha: 0.7), // رمادي واضح للغير نشط
                  width: 2.0,
                ),
                // ظل بسيط وواضح
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  // توهج خفيف للزر النشط
                  if (isActive)
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 0),
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Center(
                child: AnimatedScale(
                  duration: Duration(milliseconds: 200),
                  scale: isActive ? 1.1 : 1.0,
                  child: IconTheme(
                    data: IconThemeData(
                      color: isActive
                          ? Colors
                                .white // أبيض واضح للنشط
                          : Colors.grey[700], // رمادي داكن واضح للغير نشط
                      size: isActive ? 30 : 26, // أكبر قليلاً
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
