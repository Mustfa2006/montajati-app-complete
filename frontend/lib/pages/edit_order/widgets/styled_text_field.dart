import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/theme_provider.dart';

class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool showIcon;

  const StyledTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    // We can use ValueListenableBuilder if we want reactive color change on typing without setState
    // But for simplicity, we keep it static or rely on parent rebuilds.
    // Ideally, the controller listener should trigger rebuilds if we want "active" color.
    // Let's use ValueListenableBuilder to make it reactive!
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final isActive = value.text.isNotEmpty && (!isRequired || value.text.trim().isNotEmpty);
        const activeColor = Color(0xFF4CAF50);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: Text(
                label,
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
                  height: maxLines > 1 ? null : 60,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive ? activeColor : (isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3)),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      if (showIcon)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 0),
                          child: Icon(
                            icon,
                            size: 20,
                            color: isActive ? activeColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: showIcon ? 0 : 16, vertical: maxLines > 1 ? 8 : 0),
                          child: TextField(
                            controller: controller,
                            keyboardType: keyboardType,
                            maxLines: maxLines,
                            maxLength: maxLength,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'أدخل $label',
                              hintStyle: GoogleFonts.cairo(
                                fontSize: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: maxLines > 1 ? const EdgeInsets.all(8) : EdgeInsets.zero,
                              counterText: '',
                              filled: false,
                              fillColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      if (isActive && maxLines == 1)
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Icon(FontAwesomeIcons.circleCheck, color: activeColor, size: 20),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
