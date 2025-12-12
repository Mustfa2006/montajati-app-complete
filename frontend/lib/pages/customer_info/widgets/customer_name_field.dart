/// 👤 حقل اسم المستلم
/// Customer Name Field Widget
///
/// ✅ UI فقط - بدون منطق
/// ✅ يستخدم Provider للـ controller والحالة
/// ❌ لا Validation - التحقق يتم في Provider


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/customer_info_provider.dart';

class CustomerNameField extends StatelessWidget {
  const CustomerNameField({super.key});

  static const Color _activeColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final provider = context.watch<CustomerInfoProvider>();
    final isActive = provider.nameController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: Text(
            'اسم المستلم',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? _activeColor : (isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3)),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      FontAwesomeIcons.user,
                      size: 20,
                      color: isActive ? _activeColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: provider.nameController,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'أدخل الاسم الكامل',
                        hintStyle: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (_) {
                        // ✅ Trigger rebuild via Provider
                        provider.notifyFieldChanged();
                      },
                    ),
                  ),
                  if (isActive)
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Icon(FontAwesomeIcons.circleCheck, color: _activeColor, size: 20),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
