// صفحة الترحيب - Welcome Page
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../widgets/shared_components.dart';


// ===== الصفحة الرئيسية =====

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  // ===== متحكمات الحركة =====
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _starsController;

  // ===== الحركات =====
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;

  // ===== البيانات =====
  List<Star> stars = [];

  // ===== دورة حياة الصفحة =====

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateStars();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  // ===== إعداد الحركات =====

  void _initializeAnimations() {
    // متحكمات الحركة
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _starsController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // الحركات
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _generateStars() {
    stars = SharedComponents.generateStars(count: 50);
  }



  /// معالج النقر على زر تسجيل الدخول
  void _handleLoginTap() {
    context.go('/login');
  }

  /// معالج النقر على زر إنشاء حساب
  void _handleRegisterTap() {
    context.go('/register');
  }

  // ===== بناء الواجهة =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SharedComponents.buildGradientBackground(
          child: Stack(
            children: [
              // النجوم المتحركة
              SharedComponents.buildAnimatedStars(stars, _starsController),

              // الطبقة الشفافة العلوية
              SharedComponents.buildOverlay(),

              // المحتوى الرئيسي
              Center(child: _buildMainCard()),
            ],
          ),
        ),
    );
  }

  // ===== البطاقة المركزية =====

  Widget _buildMainCard() {
    return SharedComponents.buildMainCard(
      context: context,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCrownIcon(),
            const SizedBox(height: 30),
            _buildTitle(),
            const SizedBox(height: 25),
            _buildDecorativeLine(),
            const SizedBox(height: 45),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ===== مكونات البطاقة =====

  // بناء أيقونة التاج
  Widget _buildCrownIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationAnimation,
        _floatAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFe6b31e), // #e6b31e
                    Color(0xFFffd700), // #ffd700
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFe6b31e).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(
                      0xFFe6b31e,
                    ).withValues(alpha: _glowAnimation.value * 0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: const Icon(
                FontAwesomeIcons.crown,
                color: Color(0xFF1a1a2e),
                size: 35,
              ),
            ),
          ),
        );
      },
    );
  }

  // بناء العنوان
  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFe6b31e), Colors.white],
          ).createShader(bounds),
          child: Text(
            'منتجاتي',
            style: GoogleFonts.cairo(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
                Shadow(
                  color: const Color(
                    0xFFe6b31e,
                  ).withValues(alpha: _glowAnimation.value * 0.4),
                  blurRadius: 35,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // بناء الخط الزخرفي
  Widget _buildDecorativeLine() {
    return SizedBox(
      width: 250,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الخط الأفقي
          Container(
            width: 250,
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFe6b31e),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // المعين الأوسط
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: math.pi / 4, // 45 درجة
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFe6b31e),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFe6b31e,
                        ).withValues(alpha: _glowAnimation.value),
                        blurRadius: 15,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // بناء أزرار التنقل
  Widget _buildActionButtons() {
    return Column(
      children: [
        // زر تسجيل الدخول
        _buildLoginButton(),

        const SizedBox(height: 25),

        // زر إنشاء حساب
        _buildRegisterButton(),

      ],
    );
  }

  // زر تسجيل الدخول
  Widget _buildLoginButton() {
    return Container(
      width: 300,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xE6FFD700), // rgba(255, 215, 0, 0.9)
            Color(0xFFFFD700), // rgba(255, 215, 0, 1)
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _handleLoginTap(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.rightToBracket,
                  color: Color(0xFF1a1a1a),
                  size: 22,
                ),
                const SizedBox(width: 15),
                Text(
                  'تسجيل الدخول',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a1a1a),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // زر إنشاء حساب
  Widget _buildRegisterButton() {
    return Container(
      width: 300,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _handleRegisterTap(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.userPlus,
                  color: Color(0xFFFFD700),
                  size: 22,
                ),
                const SizedBox(width: 15),
                Text(
                  'إنشاء حساب جديد',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }







}
