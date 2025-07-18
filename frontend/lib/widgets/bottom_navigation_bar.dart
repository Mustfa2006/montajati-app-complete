import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final String currentRoute;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 8),
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            FontAwesomeIcons.store,
            'منتجاتي',
            '/products',
          ),
          _buildNavItem(
            context,
            FontAwesomeIcons.bagShopping,
            'الطلبات',
            '/orders',
          ),
          _buildNavItem(
            context,
            FontAwesomeIcons.chartLine,
            'الأرباح',
            '/profits',
          ),
          _buildNavItem(
            context,
            FontAwesomeIcons.user,
            'الحساب',
            '/account',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final bool isActive = currentRoute == route;

    return InkWell(
      onTap: () {
        // منع النقر المتكرر السريع
        if (currentRoute != route) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: const Color(0xFFffd700).withValues(alpha: 0.2),
      highlightColor: const Color(0xFFffd700).withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isActive
                    ? const Color(0xFFffd700)
                    : Colors.white.withValues(alpha: 0.6),
                size: isActive ? 20 : 18,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.cairo(
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? const Color(0xFFffd700)
                    : Colors.white.withValues(alpha: 0.6),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
