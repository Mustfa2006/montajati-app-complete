// 💰 قسم عرض وإدخال الأسعار
// Price Section Widget

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../utils/number_formatter.dart';

/// قسم الأسعار - يعرض نطاق الأسعار وحقل الإدخال والأسعار المثبتة
class PriceSection extends StatelessWidget {
  final double minPrice;
  final double maxPrice;
  final double wholesalePrice;
  final double customerPrice;
  final bool isPriceValid;
  final List<double> pinnedPrices;
  final TextEditingController priceController;
  final ValueChanged<String> onPriceChanged;
  final VoidCallback? onPinPrice;
  final ValueChanged<double> onPinnedPriceTap;
  final ValueChanged<double> onPinnedPriceLongPress;

  const PriceSection({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.wholesalePrice,
    required this.customerPrice,
    required this.isPriceValid,
    required this.pinnedPrices,
    required this.priceController,
    required this.onPriceChanged,
    required this.onPinPrice,
    required this.onPinnedPriceTap,
    required this.onPinnedPriceLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // نطاق الأسعار
        _buildPriceRangeCard(isDark),
        const SizedBox(height: 20),

        // عنوان سعر البيع
        Text(
          'سعر البيع للزبون',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        // حقل إدخال السعر
        _buildPriceInput(isDark),

        // مؤشر خطأ السعر
        if (!isPriceValid && customerPrice > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'السعر يجب أن يكون بين ${NumberFormatter.formatCurrency(minPrice)} و ${NumberFormatter.formatCurrency(maxPrice)}',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),

        const SizedBox(height: 16),

        // الأسعار المثبتة
        if (pinnedPrices.isNotEmpty) _buildPinnedPricesSection(isDark),
      ],
    );
  }

  Widget _buildPriceRangeCard(bool isDark) {
    return _build3DGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // سعر الجملة
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Color(0xFF4CAF50), size: 16),
              const SizedBox(width: 8),
              Text(
                'سعر الجملة: ',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                ),
              ),
              Text(
                NumberFormatter.formatCurrency(wholesalePrice),
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الحد الأدنى والأعلى
          Row(
            children: [
              Expanded(
                child: _buildPriceRangeBox(
                  'الحد الأدنى',
                  minPrice,
                  Icons.arrow_downward,
                  const Color(0xFFFFD700),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceRangeBox(
                  'الحد الأعلى',
                  maxPrice,
                  Icons.arrow_upward,
                  const Color(0xFF4A90E2),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeBox(String label, double price, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.cairo(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormatter.formatCurrency(price),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput(bool isDark) {
    return _build3DGlassCard(
      isDark: isDark,
      blurAmount: 5,
      padding: EdgeInsets.zero,
      borderRadius: 20,
      // 🎯 استخدام IntrinsicHeight لجعل الزر يأخذ نفس ارتفاع حقل الإدخال
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildTextField(isDark)),
            _buildPinButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(bool isDark) {
    return TextField(
      controller: priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'أدخل سعر البيع',
        hintStyle: GoogleFonts.cairo(
          color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFD4AF37), size: 20),
        suffixText: 'د.ع',
        suffixStyle: GoogleFonts.cairo(
          color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
      onChanged: onPriceChanged,
    );
  }

  Widget _buildPinButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        topRight: Radius.circular(0),
        bottomRight: Radius.circular(0),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        onTap: onPinPrice,
        // 🎯 إزالة height الثابت وجعل الزر يمتد تلقائيًا مع الشريط
        child: Container(
          width: 52,
          // height تحذف - سيأخذ ارتفاع الشريط تلقائيًا
          decoration: BoxDecoration(
            color: isPriceValid
                ? const Color(0xFFD4AF37)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              topRight: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.push_pin_rounded,
              color: isPriceValid
                  ? Colors.black
                  : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.5)),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedPricesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأسعار المثبتة',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pinnedPrices.map((price) => _buildPinnedPriceChip(price, isDark)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPinnedPriceChip(double price, bool isDark) {
    final isSelected = customerPrice == price;
    return GestureDetector(
      onTap: () => onPinnedPriceTap(price),
      onLongPress: () => onPinnedPriceLongPress(price),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? const Color(0xFFD4AF37).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08))
              : (isSelected ? const Color(0xFFD4AF37).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin_rounded,
              color: isSelected
                  ? const Color(0xFFD4AF37)
                  : (isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6)),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              NumberFormatter.formatCurrency(price),
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFD4AF37)
                    : (isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DGlassCard({
    required bool isDark,
    required Widget child,
    double blurAmount = 5,
    EdgeInsets padding = const EdgeInsets.all(20),
    double borderRadius = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
