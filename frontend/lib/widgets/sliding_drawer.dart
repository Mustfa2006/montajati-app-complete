import 'dart:math' as math;

import 'package:flutter/material.dart';

class SlidingDrawerController extends ChangeNotifier {
  late AnimationController animationController;

  void attach(AnimationController controller) {
    animationController = controller;
  }

  void open() {
    animationController.forward();
  }

  void close() {
    animationController.reverse();
  }

  void toggle() {
    if (animationController.status == AnimationStatus.completed) {
      close();
    } else {
      open();
    }
  }
}

class SlidingDrawer extends StatefulWidget {
  final Widget child;
  final Widget menu;
  final SlidingDrawerController controller;
  final double menuWidthFactor;
  final double endScale;
  final double rotationDegrees;
  final Color backgroundColor;
  final Color? shadowColor;

  const SlidingDrawer({
    super.key,
    required this.child,
    required this.menu,
    required this.controller,
    this.menuWidthFactor = 0.8,
    this.endScale = 0.8,
    this.rotationDegrees = 0.0,
    this.backgroundColor = Colors.white,
    this.shadowColor,
  });

  @override
  State<SlidingDrawer> createState() => _SlidingDrawerState();
}

class _SlidingDrawerState extends State<SlidingDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    widget.controller.attach(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final menuWidth = size.width * widget.menuWidthFactor;

    return Material(
      color: widget.backgroundColor,
      child: Stack(
        children: [
          // نجعل خلفية القائمة (DrawerMenu) تمتد على عرض الشاشة بالكامل
          _buildMenu(size.width),
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              final value = animation.value;

              // لكن نبقي حركة الشاشة الأمامية مرتبطة بعرض القائمة الفعلي (menuWidth)
              return _buildAnimatedChild(menuWidth, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(double width) {
    return SlideTransition(
      position: animation.drive(Tween(begin: const Offset(-1, 0), end: const Offset(0, 0))),
      child: SizedBox(width: width, child: widget.menu),
    );
  }

  double _degToRad(double degrees) {
    return degrees * math.pi / 180.0;
  }

  Widget _buildAnimatedChild(double menuWidth, double value) {
    final scaleValue = 1 - ((1 - widget.endScale) * value);
    final rotationValue = _degToRad(widget.rotationDegrees * value);

    // إرجاع حركة الشاشة الأمامية كما كانت: تتحرك بالكامل بمقدار عرض القائمة
    return Transform.translate(
      offset: Offset(menuWidth * value, 0),
      child: Transform.scale(
        scale: scaleValue,
        child: Transform.rotate(
          angle: rotationValue,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (widget.shadowColor != null) _buildCardLayers(value),

              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (value > 0) {
                    _animationController.reverse();
                  }
                },
                child: Material(
                  elevation: 4,
                  shadowColor: Colors.black87,
                  borderRadius: BorderRadius.circular(32 * value),
                  animationDuration: Duration.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32 * value),
                    child: AbsorbPointer(absorbing: value > 0, child: widget.child),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardLayers(double value) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _cardLayer(
          value,
          offsetX: -48,
          widthFactor: 0.85,
          heightFactor: 0.85,
          color: widget.shadowColor?.withValues(alpha: 0.5),
        ),
        _cardLayer(value, offsetX: -24, widthFactor: 0.9, heightFactor: 0.9, color: widget.shadowColor),
      ],
    );
  }

  Widget _cardLayer(
    double value, {
    required double offsetX,
    required double widthFactor,
    required double heightFactor,
    Color? color,
  }) {
    final size = MediaQuery.sizeOf(context);

    return AnimatedPositioned(
      left: offsetX * value,
      duration: const Duration(milliseconds: 1),
      child: Container(
        width: size.width * widthFactor,
        height: size.height * heightFactor,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32 * value),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
      ),
    );
  }
}
