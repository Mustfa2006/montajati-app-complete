import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system.dart';
import '../../../../providers/theme_provider.dart';

/// حالة الخطأ - فشل في تحميل المنتجات
class ProductsErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ProductsErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة الخطأ
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),

            // العنوان
            Text(
              'تعذّر الاتصال',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // الوصف
            Text(
              message ?? 'تحقق من اتصالك بالإنترنت\nثم حاول مرة أخرى',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),

            // زر إعادة المحاولة
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
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
