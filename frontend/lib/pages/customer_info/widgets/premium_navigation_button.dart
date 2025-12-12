import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

/// 💎 PremiumNavigationButton
/// زر تنقل فخم جداً "تصميم رهيب"
class PremiumNavigationButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isEnabled;
  final String text;

  const PremiumNavigationButton({super.key, required this.onTap, this.isEnabled = true, this.text = "ملخص الطلب"});

  @override
  State<PremiumNavigationButton> createState() => _PremiumNavigationButtonState();
}

class _PremiumNavigationButtonState extends State<PremiumNavigationButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _controller.reverse();
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          height: 56,
          // ✅ عرض مريح للزر
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // ✅ تدرج لوني فخم: ذهبي عند التفعيل (جاهز)، رمادي داكن عند التعطيل
            gradient: widget.isEnabled
                ? const LinearGradient(
                    colors: [
                      Color(0xFFffd700), // ذهبي ساطع
                      Color(0xFFE6B31E), // ذهبي داكن قليلاً
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(colors: [Colors.grey[800]!, Colors.grey[900]!]),
            boxShadow: widget.isEnabled
                ? [
                    // توهج قوي عند التفعيل لجذب الانتباه
                    BoxShadow(
                      color: const Color(0xFFffd700).withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 5),
                      spreadRadius: 2,
                    ),
                  ]
                : [],
            border: Border.all(
              color: widget.isEnabled ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // نص الزر
              Text(
                widget.text,
                style: GoogleFonts.cairo(
                  // لون أسود عند التفعيل (على الذهبي)، أبيض باهت عند التعطيل
                  color: widget.isEnabled ? const Color(0xFF1A1A1A) : Colors.white38,
                  fontSize: 18, // خط أكبر قليلاً
                  fontWeight: FontWeight.w800, // خط أعرض
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.isEnabled) ...[
                const SizedBox(width: 12),
                // أيقونة السهم في دائرة داكنة (للتنباين مع الذهبي)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(
                    FontAwesomeIcons.arrowLeft,
                    color: Color(0xFF1A1A1A), // أيقونة داكنة
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
