import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/edit_order_provider.dart';
import '../../../providers/theme_provider.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EditOrderProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.triangleExclamation, color: Colors.orange.withValues(alpha: 0.8), size: 48),
          const SizedBox(height: 16),
          Text(
            'فشل تحميل الطلب',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.failure?.message ?? 'حدث خطأ غير متوقع',
            style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => provider.loadData(), // was retry() before? No, loadData in simplified provider.
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFffd700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FontAwesomeIcons.arrowsRotate, color: Color(0xFFffd700), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFffd700)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
