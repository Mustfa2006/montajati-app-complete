import 'dart:math';
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
  final Gradient? gradient; // ✨ إضافة التدرج اللوني
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
    this.gradient, // ✨
    this.buttonBackgroundColor,
    this.backgroundColor = Colors.blueAccent,
    this.onTap,
    LetIndexPage? letIndexChange,
    this.animationCurve = Curves.easeOut,
    this.animationDuration = const Duration(milliseconds: 600),
    this.height = 65.0, // 📏 تقليل الارتفاع الافتراضي قليلاً ليبدو أجمل
    this.maxWidth,
  }) : letIndexChange = letIndexChange ?? ((_) => true),
       assert(items.isNotEmpty),
       assert(0 <= index && index < items.length),
       assert(0 <= height && height <= 75.0),
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
        final distance = (_startingPos - middle).abs();
        if (distance < 0.0001) {
          _buttonHide = 0; // 🛡️ حماية من القسمة على صفر
        } else {
          _buttonHide = (1 - ((middle - _pos) / distance).abs()).abs();
        }
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

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = min(constraints.maxWidth, widget.maxWidth ?? constraints.maxWidth);

          return Align(
            alignment: textDirection == TextDirection.ltr ? Alignment.bottomLeft : Alignment.bottomRight,
            child: Container(
              color: widget.backgroundColor,
              width: maxWidth,
              child: ClipRect(
                clipper: NavCustomClipper(deviceHeight: MediaQuery.sizeOf(context).height),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Positioned(
                      bottom: -40 - (75.0 - widget.height),
                      left: textDirection == TextDirection.rtl ? null : _pos * maxWidth,
                      right: textDirection == TextDirection.rtl ? _pos * maxWidth : null,
                      width: maxWidth / _length,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, -(1 - _buttonHide) * 80),
                          child: _buildActiveBall(), // ✨ استخدام الكرة المتطورة
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0 - (75.0 - widget.height),
                      child: CustomPaint(
                        painter: NavCustomPainter(
                          _pos,
                          _length,
                          widget.color,
                          textDirection,
                          gradient: widget.gradient,
                        ), // ✨ تمرير التدرج
                        child: Container(height: 75.0),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0 - (75.0 - widget.height),
                      child: SizedBox(
                        height: 100.0,
                        child: Row(
                          children: widget.items.map((item) {
                            return NavButton(
                              onTap: _buttonTap,
                              position: _pos,
                              length: _length,
                              index: widget.items.indexOf(item),
                              child: Center(child: item),
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

  // كرة الزر النشطة بتصميم رهيب ومبهر ✨🔥
  Widget _buildActiveBall() {
    const double ballSize = 50.0; // 📏 تصغير الكرة لتكون أنيقة ومناسبة للهاتف

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: ballSize,
            height: ballSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ✨ تدرج لوني فخم للكرة
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF2D3748), const Color(0xFF1A202C), const Color(0xFF000000)],
              ),
              // ✨ إطار ذهبي أنيق (أقل سماكة قليلاً)
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.8), width: 2.0),
              // ✨ ظلال هادئة (توهج أقل)
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15), // تقليل الشفافية
                  blurRadius: 10, // تقليل الانتشار
                  spreadRadius: 0, // إزالة التمدد الزائد
                  offset: const Offset(0, 0),
                ),
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ✨ لمعة داخلية
                Positioned(
                  top: 5,
                  left: 10,
                  child: Container(
                    width: 15,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // الأيقونة
                IconTheme(
                  data: const IconThemeData(color: Color(0xFFFFD700), size: 30.0),
                  child: _icon,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void setPage(int index) {
    _buttonTap(index);
  }

  void _buttonTap(int index) {
    // 🛡️ منع النقر على نفس القسم الحالي أو القسم الذي يتم الانتقال إليه حالياً
    if (index == _endingIndex) {
      return;
    }

    if (!widget.letIndexChange(index)) {
      return;
    }
    if (widget.onTap != null) {
      widget.onTap!(index);
    }
    final newPosition = index / _length;

    // 🚀 إيقاف الحركة الحالية فوراً قبل بدء حركة جديدة (حل مشكلة النقرات السريعة)
    if (_animationController.isAnimating) {
      _animationController.stop(canceled: false);
    }

    setState(() {
      _startingPos = _pos;
      _endingIndex = index;
      _animationController.animateTo(newPosition, duration: widget.animationDuration, curve: widget.animationCurve);
    });
  }
}
