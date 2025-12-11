// 🎯 Cart Header Widget - شريط العنوان لصفحة السلة
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CartHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClearCart;

  const CartHeader({super.key, required this.isDark, required this.onClearCart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر الرجوع
          _buildIconButton(
            onTap: () => context.go('/products'),
            icon: FontAwesomeIcons.arrowRight,
            color: isDark ? Colors.white : Colors.black,
          ),

          // العنوان
          Text(
            'السلة',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          // زر مسح السلة
          _buildIconButton(
            onTap: onClearCart,
            icon: FontAwesomeIcons.trash,
            color: const Color(0xFFff2d55),
            bgColor: const Color(0xFFff2d55).withValues(alpha: 0.15),
            borderColor: const Color(0xFFff2d55).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    Color? bgColor,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor ?? color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? color.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
