// 🎨🔢 شريط الألوان والكمية
// Color and Quantity Bar Widget

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/product_color.dart';
import '../../providers/theme_provider.dart';

/// شريط الألوان والكمية المدمج
class ColorQuantityBar extends StatelessWidget {
  final List<ProductColor> colors;
  final String? selectedColorId;
  final int selectedQuantity;
  final int maxQuantity;
  final int minQuantity;
  final ValueChanged<String?> onColorSelected;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ColorQuantityBar({
    super.key,
    required this.colors,
    required this.selectedColorId,
    required this.selectedQuantity,
    required this.maxQuantity,
    required this.minQuantity,
    required this.onColorSelected,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return _build3DGlassCard(
      isDark: isDark,
      blurAmount: 5,
      child: Row(
        children: [
          // قسم الألوان
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette, color: Color(0xFFD4AF37), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'اللون',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // خيار "لا شيء"
                      _buildNoneOption(isDark),
                      // الألوان المتاحة
                      ...colors.map((color) => _buildColorOption(color, isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // فاصل عمودي
          _buildVerticalDivider(),

          // 🎯 قسم الكمية - كلمة الكمية في الوسط 100%
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, // 🎯 محاذاة مركزية
            children: [
              // كلمة الكمية - في الوسط تماماً
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag, color: Color(0xFFD4AF37), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'الكمية',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 🎯 العداد - مضغوط ومحاذي للوسط
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onTap: onDecrement,
                    isDark: isDark,
                    isEnabled: selectedQuantity > minQuantity,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    constraints: const BoxConstraints(minWidth: 24),
                    child: Text(
                      '$selectedQuantity',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onTap: onIncrement,
                    isDark: isDark,
                    isEnabled: selectedQuantity < maxQuantity,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoneOption(bool isDark) {
    final isSelected = selectedColorId == 'none';
    return GestureDetector(
      onTap: () {
        onColorSelected('none');
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.withValues(alpha: 0.5),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
              ),
            ),
            Center(
              child: Transform.rotate(angle: -0.785398, child: Container(width: 20, height: 2, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(ProductColor color, bool isDark) {
    final isSelected = selectedColorId == color.id;
    return GestureDetector(
      onTap: () {
        onColorSelected(color.id);
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.flutterColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.withValues(alpha: 0.5),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, const Color(0xFFFFD700).withValues(alpha: 0.3), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        // 🎯 تصغير الأزرار لتناسق الهواتف
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isEnabled
              ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1))
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isEnabled ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isEnabled
                ? const Color(0xFFD4AF37)
                : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.3)),
            size: 14,
          ),
        ),
      ),
    );
  }

  Widget _build3DGlassCard({
    required bool isDark,
    required Widget child,
    double blurAmount = 5,
    EdgeInsets padding = const EdgeInsets.all(20),
    double borderRadius = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
