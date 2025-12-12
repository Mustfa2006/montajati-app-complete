/// 🏙️ حقل المدينة
/// City Field Widget
///
/// ✅ UI فقط - بدون منطق
/// ✅ يقرأ selectedCity من Provider
/// ✅ يستدعي onTap callback فقط (Modal يُعرض من الـ Page)
/// ✅ يكون معطلاً إذا لم يتم اختيار المحافظة


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/customer_info_provider.dart';

class CityField extends StatelessWidget {
  /// Callback عند الضغط - يُستخدم لفتح Modal من الـ Page
  final VoidCallback? onTap;

  const CityField({super.key, this.onTap});

  static const Color _activeColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final provider = context.watch<CustomerInfoProvider>();
    final isSelected = provider.selectedCity != null;
    final isEnabled = provider.selectedProvince != null;
    final selectedName = provider.selectedCityName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: Text(
            'المدينة / القضاء',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isEnabled ? (isDark ? Colors.white70 : Colors.black87) : Colors.grey,
            ),
          ),
        ),
        GestureDetector(
          onTap: isEnabled ? onTap : null,
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
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
                          FontAwesomeIcons.city,
                          size: 20,
                          color: isSelected ? _activeColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          selectedName ?? (isEnabled ? 'اختر المدينة' : 'اختر المحافظة أولاً'),
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
                          child: Icon(FontAwesomeIcons.chevronDown, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
