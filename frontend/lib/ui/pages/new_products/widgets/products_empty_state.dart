import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system.dart';
import '../../../../providers/theme_provider.dart';

/// حالة فارغة - لا توجد منتجات
class ProductsEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;

  const ProductsEmptyState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: isDark ? const Color(0xFFFFD700).withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),

            // العنوان
            Text(
              'لا توجد منتجات متاحة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // الوصف
            Text(
              'لم نجد أي منتجات حالياً\nجرب تحديث الصفحة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),

            // زر التحديث
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text('تحديث', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
