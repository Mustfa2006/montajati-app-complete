// شريط علوي موحد لجميع الصفحات
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final List<Widget>? leftActions;
  final List<Widget>? rightActions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CommonHeader({
    super.key,
    required this.title,
    this.leftActions,
    this.rightActions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70, // نفس القياس المستخدم في صفحة المنتجات
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 2),
      child: Stack(
        children: [
          // الأيقونات اليسرى أو زر الرجوع
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                if (showBackButton)
                  GestureDetector(
                    onTap: onBackPressed ?? () => context.pop(),
                    child: _buildHeaderIcon(
                      FontAwesomeIcons.arrowRight, // السهم يشير لليمين
                      const Color(0xFFffd700),
                    ),
                  )
                else if (leftActions != null)
                  Row(children: leftActions!)
                else
                  const SizedBox(width: 32),
              ],
            ),
          ),

          // العنوان في الوسط المطلق
          Positioned.fill(
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
                ).createShader(bounds),
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // الأيقونات اليمنى
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                if (rightActions != null)
                  Row(children: rightActions!)
                else
                  const SizedBox(width: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء أيقونة الشريط العلوي
  Widget _buildHeaderIcon(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }
}
