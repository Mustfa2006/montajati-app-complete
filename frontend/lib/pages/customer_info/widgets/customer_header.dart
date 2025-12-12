/// 🎨 الشريط العلوي لصفحة معلومات العميل
/// Customer Header Widget
///
/// ✅ UI فقط - بدون منطق
/// ✅ يستخدم Provider للقراءة فقط


import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';

class CustomerHeader extends StatelessWidget {
  const CustomerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر الرجوع المطور
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Icon(FontAwesomeIcons.arrowRight, color: isDark ? Colors.white : Colors.black87, size: 18),
                ),
              ),
            ),
          ),

          // العنوان مع أيقونة صغيرة
          Row(
            children: [
              Text(
                'معلومات العميل',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                FontAwesomeIcons.fileInvoice,
                color: isDark ? const Color(0xFFffd700) : const Color(0xFFf0ba18),
                size: 20,
              ),
            ],
          ),

          // مساحة فارغة للموازنة
          const SizedBox(width: 45, height: 45),
        ],
      ),
    );
  }
}
