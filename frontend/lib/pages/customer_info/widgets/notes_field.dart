/// 📝 حقل الملاحظات الإضافية
/// Notes Field Widget
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

class NotesField extends StatelessWidget {
  const NotesField({super.key});

  static const Color _activeColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final provider = context.watch<CustomerInfoProvider>();
    final isActive = provider.notesController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: Text(
            'ملاحظات إضافية (اختياري)',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              constraints: const BoxConstraints(minHeight: 120),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, left: 16, top: 16),
                    child: Icon(
                      FontAwesomeIcons.penToSquare,
                      size: 20,
                      color: isActive ? _activeColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: provider.notesController,
                      maxLines: null,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onChanged: (_) {
                        // ✅ Trigger rebuild via Provider
                        provider.notifyFieldChanged();
                      },
                      decoration: InputDecoration(
                        hintText: 'لون المنتج، تفاصيل الموقع، أو أي ملاحظات أخرى...',
                        hintStyle: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        filled: false,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16),
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
