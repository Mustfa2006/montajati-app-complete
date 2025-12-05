import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/user_provider.dart';
import '../../../../services/cart_service.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/theme_colors.dart';

/// شريط الترويسة العلوي للصفحة
class ProductsHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onMenuTap;

  const ProductsHeader({super.key, required this.isDark, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final greetingData = UserService.getGreeting();
    final greeting = greetingData['greeting']!;
    final emoji = greetingData['emoji']!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Consumer<UserProvider>(
                      builder: (context, userProvider, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$greeting ${userProvider.firstName} ',
                                  style: GoogleFonts.cairo(
                                    color: ThemeColors.textColor(isDark),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: emoji, style: const TextStyle(fontSize: 12, fontFamily: null)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userProvider.phoneNumber,
                            style: GoogleFonts.cairo(
                              color: ThemeColors.secondaryTextColor(isDark),
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer<CartService>(
                        builder: (context, cart, _) => _HeaderButton(
                          icon: Icons.shopping_bag_outlined,
                          onTap: () => context.go('/cart'),
                          isDark: isDark,
                          badge: cart.itemCount > 0 ? cart.itemCount : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _HeaderButton(icon: Icons.menu_rounded, onTap: onMenuTap ?? () {}, isDark: isDark),
                    ],
                  ),
                ],
              ),
              // عنوان منتجاتي في المنتصف
              Positioned.fill(
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFB8860B), Color(0xFFDAA520)],
                      stops: [0.0, 0.3, 0.7, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'منتجاتي',
                      style: GoogleFonts.amiri(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// زر الترويسة (سلة / قائمة)
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final int? badge;

  const _HeaderButton({required this.icon, required this.onTap, required this.isDark, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.7),
                size: 21,
              ),
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 0),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badge! > 9 ? '9+' : badge.toString(),
                      style: GoogleFonts.cairo(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
