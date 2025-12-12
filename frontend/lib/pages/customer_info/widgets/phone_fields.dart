/// 📞 حقول أرقام الهاتف
/// Phone Fields Widget
///
/// ✅ UI فقط - بدون منطق
/// ✅ يستخدم Provider للـ controllers والحالة
/// ❌ لا Validation - التحقق يتم في Provider


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/customer_info_provider.dart';

class PhoneFields extends StatelessWidget {
  const PhoneFields({super.key});

  static const Color _activeColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final provider = context.watch<CustomerInfoProvider>();

    final isPrimaryActive =
        provider.primaryPhoneController.text.length == 11 && provider.primaryPhoneController.text.startsWith('07');
    final isSecondaryActive =
        provider.secondaryPhoneController.text.length == 11 && provider.secondaryPhoneController.text.startsWith('07');

    return Column(
      children: [
        _buildPhoneInput(
          context: context,
          isDark: isDark,
          provider: provider,
          title: 'رقم الهاتف الأساسي',
          controller: provider.primaryPhoneController,
          isActive: isPrimaryActive,
          icon: FontAwesomeIcons.phone,
          helperText: 'يجب أن يبدأ بـ 07 ويتكون من 11 رقم',
        ),
        const SizedBox(height: 16),
        _buildPhoneInput(
          context: context,
          isDark: isDark,
          provider: provider,
          title: 'رقم الهاتف البديل (اختياري)',
          controller: provider.secondaryPhoneController,
          isActive: isSecondaryActive,
          icon: FontAwesomeIcons.mobileScreen,
        ),
      ],
    );
  }

  Widget _buildPhoneInput({
    required BuildContext context,
    required bool isDark,
    required CustomerInfoProvider provider,
    required String title,
    required TextEditingController controller,
    required bool isActive,
    required IconData icon,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: Text(
            title,
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
                      icon,
                      size: 20,
                      color: isActive ? _activeColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onChanged: (value) {
                        // ✅ تحويل الأرقام العربية عبر Provider
                        final convertedValue = provider.convertArabicToEnglishNumbers(value);
                        if (convertedValue != value) {
                          controller.value = TextEditingValue(
                            text: convertedValue,
                            selection: TextSelection.collapsed(offset: convertedValue.length),
                          );
                        }
                        // ✅ Trigger rebuild via Provider
                        provider.notifyFieldChanged();
                      },
                      decoration: InputDecoration(
                        hintText: '07xxxxxxxxx',
                        hintStyle: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                        counterText: '',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                        fillColor: Colors.transparent,
                      ),
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
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 12),
            child: Text(helperText, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
          ),
      ],
    );
  }
}
