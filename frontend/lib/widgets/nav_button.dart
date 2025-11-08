import 'package:flutter/material.dart';

class NavButton extends StatelessWidget {
  final double position;
  final int length;
  final int index;
  final ValueChanged<int> onTap;
  final Widget child;
  final double? screenWidth; // إضافة معامل عرض الشاشة

  const NavButton({
    super.key,
    required this.onTap,
    required this.position,
    required this.length,
    required this.index,
    required this.child,
    this.screenWidth, // معامل اختياري لعرض الشاشة
  });



  @override
  Widget build(BuildContext context) {
    final desiredPosition = 1.0 / length * index;
    final difference = (position - desiredPosition).abs();
    final verticalAlignment = 1 - length * difference;
    final opacity = length * difference;

    // حساب الأحجام المتجاوبة بناءً على عرض الشاشة
    final currentScreenWidth = screenWidth ?? MediaQuery.of(context).size.width;
    final isSmallScreen = currentScreenWidth < 360;
    final isMediumScreen = currentScreenWidth >= 360 && currentScreenWidth < 400;

    // ارتفاع الأزرار متجاوب
    final buttonHeight = isSmallScreen ? 60.0 : (isMediumScreen ? 65.0 : 70.0);

    // ارتفاع الحركة متجاوب
    final moveHeight = isSmallScreen ? 35.0 : (isMediumScreen ? 37.0 : 40.0);

    // padding متجاوب
    final topPadding = difference < 1.0 / length
        ? (isSmallScreen ? 6.0 : (isMediumScreen ? 7.0 : 8.0))
        : (isSmallScreen ? 10.0 : (isMediumScreen ? 11.0 : 12.0));

    final sidePadding = isSmallScreen ? 4.0 : (isMediumScreen ? 5.0 : 6.0);

    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          onTap(index);
        },
        child: SizedBox(
            height: buttonHeight, // ارتفاع متجاوب للأزرار
            child: Transform.translate(
              offset: Offset(
                  0, difference < 1.0 / length ? verticalAlignment * moveHeight : 0),
              child: Opacity(
                  opacity: difference < 1.0 / length * 0.99 ? opacity : 1.0,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    padding: EdgeInsets.only(
                      top: topPadding, // padding متجاوب
                      bottom: 4,
                      left: sidePadding,
                      right: sidePadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // الأيقونة مع تصميم خرافي متجاوب
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          width: difference < 1.0 / length
                              ? (isSmallScreen ? 42.0 : (isMediumScreen ? 46.0 : 50.0))
                              : (isSmallScreen ? 36.0 : (isMediumScreen ? 40.0 : 44.0)), // أحجام متجاوبة
                          height: difference < 1.0 / length
                              ? (isSmallScreen ? 42.0 : (isMediumScreen ? 46.0 : 50.0))
                              : (isSmallScreen ? 36.0 : (isMediumScreen ? 40.0 : 44.0)), // أحجام متجاوبة
                          decoration: BoxDecoration(
                            gradient: difference < 1.0 / length
                              ? RadialGradient(
                                  center: Alignment(-0.3, -0.5),
                                  radius: 1.2,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.4), // إضاءة ثلاثية الأبعاد
                                    Colors.white.withValues(alpha: 0.2), // متوسط
                                    Colors.black.withValues(alpha: 0.1), // ظل خفيف
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                )
                              : RadialGradient(
                                  center: Alignment(-0.2, -0.3),
                                  radius: 1.0,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.15), // إضاءة خفيفة
                                    Colors.transparent, // شفاف
                                  ],
                                ),
                            borderRadius: BorderRadius.circular(difference < 1.0 / length
                                ? (isSmallScreen ? 15.0 : (isMediumScreen ? 16.0 : 18.0))
                                : (isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0))), // border radius متجاوب
                            border: difference < 1.0 / length
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.0,
                                )
                              : Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 0.5,
                                ),
                            boxShadow: difference < 1.0 / length
                              ? [
                                  // ظل علوي للإضاءة ثلاثية الأبعاد
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, -2),
                                    spreadRadius: 0,
                                  ),
                                  // ظل سفلي للعمق
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                          ),
                          child: Center(
                            child: AnimatedScale(
                              duration: Duration(milliseconds: 300),
                              scale: difference < 1.0 / length ? 1.0 : 0.85,
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                child: IconTheme(
                                  data: IconThemeData(
                                    color: difference < 1.0 / length
                                      ? Colors.white // أبيض للمحدد
                                      : Colors.white.withValues(alpha: 0.9), // أبيض شفاف للباقي
                                    size: difference < 1.0 / length
                                        ? (isSmallScreen ? 20.0 : (isMediumScreen ? 22.0 : 24.0))
                                        : (isSmallScreen ? 16.0 : (isMediumScreen ? 18.0 : 20.0)), // أحجام أيقونات متجاوبة
                                  ),
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  ),
            ),
            );
  }
}
