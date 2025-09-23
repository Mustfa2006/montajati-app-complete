import 'dart:ui';

import 'package:flutter/material.dart';

import 'nav_button.dart';
import 'nav_custom_clipper.dart';
import 'nav_custom_painter.dart';

typedef LetIndexPage = bool Function(int value);

class CurvedNavigationBar extends StatefulWidget {
  final List<Widget> items;
  final int index;
  final Color color;
  final Color? buttonBackgroundColor;
  final Color backgroundColor;
  final ValueChanged<int>? onTap;
  final LetIndexPage letIndexChange;
  final Curve animationCurve;
  final Duration animationDuration;
  final double height;
  final double? maxWidth;

  CurvedNavigationBar({
    super.key,
    required this.items,
    this.index = 0,
    this.color = Colors.white,
    this.buttonBackgroundColor,
    this.backgroundColor = Colors.blueAccent,
    this.onTap,
    LetIndexPage? letIndexChange,
    this.animationCurve = Curves.elasticOut, // منحنى مبهر
    this.animationDuration = const Duration(milliseconds: 1200), // مدة أطول للتأثير المبهر
    this.height = 75.0, // ارتفاع افتراضي محسن
    this.maxWidth,
  }) : letIndexChange = letIndexChange ?? ((_) => true),
       assert(items.isNotEmpty),
       assert(0 <= index && index < items.length),
       assert(0 <= height && height <= 100.0), // تحديث الحد الأقصى للارتفاع
       assert(maxWidth == null || 0 <= maxWidth);

  @override
  CurvedNavigationBarState createState() => CurvedNavigationBarState();
}

class CurvedNavigationBarState extends State<CurvedNavigationBar> with SingleTickerProviderStateMixin {
  late double _startingPos;
  late int _endingIndex;
  late double _pos;
  double _buttonHide = 0;
  late Widget _icon;
  late AnimationController _animationController;
  late int _length;

  @override
  void initState() {
    super.initState();
    _icon = widget.items[widget.index];
    _length = widget.items.length;
    _pos = widget.index / _length;
    _startingPos = widget.index / _length;
    _endingIndex = widget.index;
    _animationController = AnimationController(vsync: this, value: _pos);
    _animationController.addListener(() {
      setState(() {
        _pos = _animationController.value;
        final endingPos = _endingIndex / widget.items.length;
        final middle = (endingPos + _startingPos) / 2;
        if ((endingPos - _pos).abs() < (_startingPos - _pos).abs()) {
          _icon = widget.items[_endingIndex];
        }
        _buttonHide = (1 - ((middle - _pos) / (_startingPos - middle)).abs()).abs();
      });
    });
  }

  @override
  void didUpdateWidget(CurvedNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      final newPosition = widget.index / _length;
      _startingPos = _pos;
      _endingIndex = widget.index;
      _animationController.animateTo(newPosition, duration: widget.animationDuration, curve: widget.animationCurve);
    }
    if (!_animationController.isAnimating) {
      _icon = widget.items[_endingIndex];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // حساب الأحجام المتجاوبة بناءً على حجم الشاشة
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;

    // ارتفاع الشريط متجاوب مع ضمان مساحة كافية
    final responsiveHeight = isSmallScreen ? 68.0 : (isMediumScreen ? 72.0 : 75.0);

    // حجم الكرة متجاوب مع ضمان وضوح جيد - مصغر قليلاً
    final ballSize = isSmallScreen ? 48.0 : (isMediumScreen ? 52.0 : 55.0);

    // موضع الكرة متجاوب مع ضمان عدم التداخل
    final ballBottomPosition = isSmallScreen ? -38.0 : (isMediumScreen ? -40.0 : -42.0);

    // ارتفاع الحركة متجاوب
    final moveHeight = isSmallScreen ? 72.0 : (isMediumScreen ? 76.0 : 80.0);

    // مساحة إضافية للشاشات الصغيرة لتجنب التداخل
    final extraPadding = isSmallScreen ? 2.0 : 0.0;

    return SizedBox(
      height: responsiveHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return Material(
            color: Colors.transparent,
            child: Container(
              color: Colors.transparent,
              width: maxWidth,
              child: ClipRect(
                clipper: NavCustomClipper(deviceHeight: MediaQuery.sizeOf(context).height),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Positioned(
                      bottom: ballBottomPosition, // موضع متجاوب للكرة
                      left: textDirection == TextDirection.rtl ? null : _pos * maxWidth,
                      right: textDirection == TextDirection.rtl ? _pos * maxWidth : null,
                      width: maxWidth / _length,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, -(1 - _buttonHide) * moveHeight),
                          child: TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            tween: Tween(begin: 0.8, end: 1.0),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // تضبيب خفيف
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 600),
                                      curve: Curves.easeInOutCubic,
                                      width: ballSize, // حجم متجاوب للكرة
                                      height: ballSize, // حجم متجاوب للكرة
                                      decoration: BoxDecoration(
                                        // تدرج عميق متناسق مع الصفحة
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            const Color(0xFF363940).withValues(alpha: 0.8), // نفس لون البطاقات
                                            const Color(0xFF2D3748), // اللون الأساسي
                                            const Color(0xFF1A202C), // عمق في الأسفل
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        // إطار ذهبي مضيء متجاوب
                                        border: Border.all(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.9), // ذهبي مضيء
                                          width: isSmallScreen ? 2.0 : (isMediumScreen ? 2.5 : 3.0),
                                        ),
                                        boxShadow: [
                                          // ظل عميق للكرة
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            offset: Offset(0, 6),
                                            spreadRadius: 2,
                                          ),
                                          // توهج ذهبي مضيء حول الحدود
                                          BoxShadow(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                            blurRadius: 20,
                                            offset: Offset(0, 0),
                                            spreadRadius: 1,
                                          ),
                                          // توهج ذهبي إضافي للتأثير المبهر
                                          BoxShadow(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                            blurRadius: 30,
                                            offset: Offset(0, 0),
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // تأثير إضاءة داخلية
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    const Color(0xFFFFD700).withValues(alpha: 0.1), // توهج ذهبي خفيف
                                                    Colors.transparent,
                                                  ],
                                                  stops: [0.3, 1.0],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // الأيقونة
                                          Center(
                                            child: AnimatedScale(
                                              duration: Duration(milliseconds: 400),
                                              scale: 1.0,
                                              child: AnimatedRotation(
                                                duration: Duration(milliseconds: 800),
                                                turns: 0.0,
                                                child: IconTheme(
                                                  data: IconThemeData(
                                                    color: const Color(0xFFFFD700), // ذهبي مضيء
                                                    size: isSmallScreen
                                                        ? 24.0
                                                        : (isMediumScreen ? 26.0 : 28.0), // حجم متجاوب
                                                  ),
                                                  child: _icon,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0 - (responsiveHeight - responsiveHeight), // موضع متجاوب للرسم
                      child: CustomPaint(
                        painter: NavCustomPainter(_pos, _length, widget.color, textDirection),
                        child: Container(
                          height: responsiveHeight, // ارتفاع متجاوب للرسم
                          color: Colors.transparent, // شفاف تماماً لحل مشكلة السواد
                        ),
                      ),
                    ),
                    Positioned(
                      left: extraPadding, // مساحة إضافية للشاشات الصغيرة
                      right: extraPadding, // مساحة إضافية للشاشات الصغيرة
                      bottom: (isSmallScreen ? 8 : 10) - (responsiveHeight - responsiveHeight), // رفع متجاوب للأزرار
                      child: Container(
                        height: responsiveHeight, // ارتفاع متجاوب للشريط
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 4.0 : (isMediumScreen ? 6.0 : 8.0), // padding أفقي متجاوب
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // توزيع متساوي للأزرار
                          children: widget.items.map((item) {
                            return Expanded(
                              child: NavButton(
                                onTap: _buttonTap,
                                position: _pos,
                                length: _length,
                                index: widget.items.indexOf(item),
                                screenWidth: screenWidth,
                                child: Center(child: item), // تمرير عرض الشاشة للأزرار
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void setPage(int index) {
    _buttonTap(index);
  }

  void _buttonTap(int index) {
    if (!widget.letIndexChange(index) || _animationController.isAnimating) {
      return;
    }
    if (widget.onTap != null) {
      widget.onTap!(index);
    }
    final newPosition = index / _length;
    setState(() {
      _startingPos = _pos;
      _endingIndex = index;
      _animationController.animateTo(newPosition, duration: widget.animationDuration, curve: widget.animationCurve);
    });
  }
}
