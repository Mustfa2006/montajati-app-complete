// 🛒 زر إضافة للسلة
// Add To Cart Button Widget

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

/// زر إضافة للسلة
class AddToCartButton extends StatelessWidget {
  final bool isPriceValid;
  final double customerPrice;
  final int selectedQuantity;
  final VoidCallback onPressed;

  const AddToCartButton({
    super.key,
    required this.isPriceValid,
    required this.customerPrice,
    required this.selectedQuantity,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final isEnabled = isPriceValid && customerPrice > 0;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: isEnabled
            ? const Color(0xFFFFD700)
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled
              ? () {
                  HapticFeedback.heavyImpact();
                  onPressed();
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: isEnabled
                    ? Colors.black
                    : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.5)),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                isEnabled ? 'إضافة للسلة' : 'أدخل سعر صحيح',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isEnabled
                      ? Colors.black
                      : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.5)),
                ),
              ),
              if (isEnabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x$selectedQuantity',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
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

