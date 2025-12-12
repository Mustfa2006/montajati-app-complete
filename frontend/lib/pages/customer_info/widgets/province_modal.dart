/// 🏛️ Modal اختيار المحافظة
/// Province Modal Widget
///
/// ✅ UI فقط - Container
/// ✅ يقرأ filteredProvinces, isLoadingProvinces, hasProvincesError من Provider
/// ✅ يستدعي provider.selectProvince() و provider.filterProvinces() فقط
/// ❌ لا load / retry logic - كل شيء في Provider


import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/customer_info_provider.dart';
import '../../../models/province.dart';

class ProvinceModal extends StatelessWidget {
  /// Callback عند اختيار محافظة - يُستخدم لإغلاق Modal وتحميل المدن
  final void Function(Province province)? onSelected;

  /// Callback لإعادة المحاولة - تستدعي Provider.loadProvinces من Page
  final VoidCallback? onRetry;

  const ProvinceModal({super.key, this.onSelected, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final provider = context.watch<CustomerInfoProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        children: [
          // المقبض العلوي
          _buildHandle(isDark),

          // العنوان وحقل البحث
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 20),
                _buildSearchField(context, isDark, provider),
              ],
            ),
          ),

          // قائمة المحافظات
          Expanded(child: _buildContent(context, isDark, provider)),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.1 : 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(FontAwesomeIcons.locationDot, color: Color(0xFFffd700), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'اختر المحافظة',
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, bool isDark, CustomerInfoProvider provider) {
    return TextField(
      controller: provider.provinceSearchController,
      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: 'ابحث عن المحافظة...',
        hintStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(
          FontAwesomeIcons.magnifyingGlass,
          color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.7) : Colors.grey,
          size: 16,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFffd700), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      onChanged: (value) {
        // ✅ Filter عبر Provider فقط
        provider.filterProvinces(value);
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, CustomerInfoProvider provider) {
    // حالة الخطأ
    if (provider.hasProvincesError) {
      return _buildErrorState(isDark);
    }

    // حالة التحميل
    if (provider.isLoadingProvinces) {
      return _buildLoadingState(isDark);
    }

    // قائمة المحافظات
    return _buildProvincesList(context, isDark, provider);
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.triangleExclamation, color: Colors.orange.withValues(alpha: 0.8), size: 48),
          const SizedBox(height: 16),
          Text(
            'فشل تحميل المحافظات',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تحقق من اتصالك بالإنترنت',
            style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
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

  Widget _buildLoadingState(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
      itemBuilder: (context, index) {
        // Shimmer بسيط بدون AnimationController
        final opacity = 0.3 + (0.2 * math.sin(index * 0.5));

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: opacity * 0.1)
                : Colors.grey.withValues(alpha: opacity * 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: opacity * 0.1)
                        : Colors.grey.withValues(alpha: opacity * 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: opacity * 0.1)
                          : Colors.grey.withValues(alpha: opacity * 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 50 + (index * 20 % 80).toDouble()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProvincesList(BuildContext context, bool isDark, CustomerInfoProvider provider) {
    final provinces = provider.filteredProvinces;
    final selectedProvince = provider.selectedProvince;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provinces.length,
      itemBuilder: (context, index) {
        final province = provinces[index];
        final isSelected = selectedProvince?.id == province.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFFffd700).withValues(alpha: 0.2),
                            const Color(0xFFffd700).withValues(alpha: 0.1),
                          ]
                        : [
                            const Color(0xFFffd700).withValues(alpha: 0.15),
                            const Color(0xFFffd700).withValues(alpha: 0.05),
                          ],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFffd700)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFffd700).withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.city,
                color: isSelected ? const Color(0xFFffd700) : (isDark ? Colors.white54 : Colors.grey),
                size: 16,
              ),
            ),
            title: Text(
              province.name,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFFffd700) : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            trailing: isSelected ? const Icon(FontAwesomeIcons.check, color: Color(0xFFffd700), size: 16) : null,
            onTap: () {
              // ✅ Select عبر callback فقط
              onSelected?.call(province);
            },
          ),
        );
      },
    );
  }
}
