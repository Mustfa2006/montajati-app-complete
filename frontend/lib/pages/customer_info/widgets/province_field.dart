/// 🏛️ حقل المحافظة
/// Province Field Widget
///
/// ✅ UI فقط - بدون منطق
/// ✅ يقرأ selectedProvince من Provider
/// ✅ يستدعي onTap callback فقط (Modal يُعرض من الـ Page)


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/customer_info_provider.dart';

class ProvinceField extends StatelessWidget {
  /// Callback عند الضغط - يُستخدم لفتح Modal من الـ Page
  final VoidCallback? onTap;

  const ProvinceField({super.key, this.onTap});

  static const Color _activeColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final provider = context.watch<CustomerInfoProvider>();
    final isSelected = provider.selectedProvince != null;
    final selectedName = provider.selectedProvinceName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: Text(
            'المحافظة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        FontAwesomeIcons.mapLocationDot,
                        size: 20,
                        color: isSelected ? _activeColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        selectedName ?? 'اختر المحافظة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(FontAwesomeIcons.circleCheck, color: _activeColor, size: 20),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          FontAwesomeIcons.chevronDown,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.grey[400],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
