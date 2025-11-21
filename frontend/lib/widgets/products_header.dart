import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class ProductsHeader extends StatefulWidget {
  final VoidCallback? onModeToggle;
  final VoidCallback? onFavoritesPressed;
  final VoidCallback? onCartPressed;
  final VoidCallback? onFilterPressed;
  final int cartItemsCount;
  final bool isDayMode;

  const ProductsHeader({
    super.key,
    this.onModeToggle,
    this.onFavoritesPressed,
    this.onCartPressed,
    this.onFilterPressed,
    this.cartItemsCount = 0,
    this.isDayMode = false,
  });

  @override
  State<ProductsHeader> createState() => _ProductsHeaderState();
}

class _ProductsHeaderState extends State<ProductsHeader>
    with TickerProviderStateMixin {
  // متحكمات الحركة
  late AnimationController _crownRotationController;
  late AnimationController _crownFloatController;
  late AnimationController _heartGlowController;
  late AnimationController _cartPulseController;

  // الحركات
  late Animation<double> _crownRotationAnimation;
  late Animation<double> _crownFloatAnimation;
  late Animation<double> _heartGlowAnimation;
  late Animation<double> _cartPulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // حركة دوران التاج (360° كل 10 ثواني)
    _crownRotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // حركة طفو التاج (±8px كل 3 ثواني)
    _crownFloatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // توهج القلب (كل 4 ثواني)
    _heartGlowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // نبض السلة (كل ثانيتين)
    _cartPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // إعداد الحركات
    _crownRotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _crownRotationController,
      curve: Curves.linear,
    ));

    _crownFloatAnimation = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(
      parent: _crownFloatController,
      curve: Curves.easeInOut,
    ));

    _heartGlowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartGlowController,
      curve: Curves.easeInOut,
    ));

    _cartPulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _cartPulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          stops: [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            // أيقونة التاج (أقصى اليسار)
            _buildCrownIcon(),
            
            // العنوان (الوسط)
            Expanded(child: _buildTitle()),
            
            // الأيقونات (اليمين)
            _buildRightIcons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCrownIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _crownRotationAnimation,
        _crownFloatAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _crownFloatAnimation.value),
          child: Transform.rotate(
            angle: _crownRotationAnimation.value,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFe6b31e), Color(0xFFffd700)],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFe6b31e).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.crown,
                  size: 18,
                  color: Color(0xFF1a1a2e),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFFe6b31e),
            Color(0xFFffd700),
            Color(0xFFe6b31e),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(bounds),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: const Text(
            'منتجاتي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.3),
                  offset: Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // أيقونة الفلتر (155px من اليمين)
        _buildFilterIcon(),
        const SizedBox(width: 10),
        
        // أيقونة السلة (110px من اليمين)
        _buildCartIcon(),
        const SizedBox(width: 10),
        
        // أيقونة المحفوظات (65px من اليمين)
        _buildFavoritesIcon(),
        const SizedBox(width: 10),
        
        // زر تبديل الوضع (15px من اليمين)
        _buildModeToggleIcon(),
      ],
    );
  }

  Widget _buildFilterIcon() {
    return GestureDetector(
      onTap: widget.onFilterPressed,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            colors: [
              const Color(0xFFaf52de).withValues(alpha: 0.15),
              const Color(0xFF5856d6).withValues(alpha: 0.08),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF8a2be2).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFaf52de).withValues(alpha: 0.5),
              blurRadius: 35,
            ),
            BoxShadow(
              color: const Color(0xFF8a2be2).withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 0),
              spreadRadius: -10,
            ),
          ],
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.filter,
            size: 16,
            color: Color(0xFFaf52de),
          ),
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    return GestureDetector(
      onTap: widget.onCartPressed,
      child: AnimatedBuilder(
        animation: _cartPulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _cartPulseAnimation.value,
            child: Stack(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.4),
                      colors: [
                        const Color(0xFF5ac8fa).withValues(alpha: 0.15),
                        const Color(0xFF007aff).withValues(alpha: 0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFc0c0c0).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5ac8fa).withValues(alpha: 0.5),
                        blurRadius: 35,
                      ),
                      BoxShadow(
                        color: const Color(0xFFc0c0c0).withValues(alpha: 0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 0),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.cartShopping,
                      size: 16,
                      color: Color(0xFF5ac8fa),
                    ),
                  ),
                ),
                // عداد السلة
                if (widget.cartItemsCount > 0)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFff4444), Color(0xFFcc0000)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFff4444).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: const Color(0xFFff4444).withValues(alpha: 0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.cartItemsCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesIcon() {
    return GestureDetector(
      onTap: widget.onFavoritesPressed,
      child: AnimatedBuilder(
        animation: _heartGlowAnimation,
        builder: (context, child) {
          return Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4),
                colors: [
                  const Color(0xFFff2d55).withValues(alpha: 0.15),
                  const Color(0xFFff9500).withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFff2d55).withValues(alpha: 0.5 * _heartGlowAnimation.value),
                  blurRadius: 35,
                ),
                BoxShadow(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3 * _heartGlowAnimation.value),
                  blurRadius: 25,
                  offset: const Offset(0, 0),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.heart,
                size: 16,
                color: Color(0xFFff2d55),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeToggleIcon() {
    return GestureDetector(
      onTap: widget.onModeToggle,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: widget.isDayMode
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFFA500),
                    Color(0xFFFF8C00),
                    Color(0xFFFF6347),
                    Color(0xFFFFD700),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2C3E50),
                    Color(0xFF34495E),
                    Color(0xFF4A6741),
                    Color(0xFF5D4E75),
                    Color(0xFF2C3E50),
                  ],
                ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.isDayMode
                  ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                  : const Color(0xFF9370DB).withValues(alpha: 0.6),
              blurRadius: widget.isDayMode ? 30 : 35,
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            widget.isDayMode ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
            size: 18,
            color: widget.isDayMode ? Colors.white : const Color(0xFFE6E6FA),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _crownRotationController.dispose();
    _crownFloatController.dispose();
    _heartGlowController.dispose();
    _cartPulseController.dispose();
    super.dispose();
  }
}
