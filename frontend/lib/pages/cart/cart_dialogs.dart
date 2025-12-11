// 🎯 Cart Dialogs - جميع dialogs صفحة السلة
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../services/cart_service.dart';

/// 🎯 نافذة تحذير الأسعار غير الصحيحة - شفافة مضببة
void showPriceValidationDialog(BuildContext context, List<String> invalidProducts) {
  final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFdc3545).withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FontAwesomeIcons.triangleExclamation, color: Color(0xFFdc3545), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'أسعار غير صحيحة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // المحتوى
                Text(
                  'يرجى تصحيح الأسعار التالية قبل إتمام الطلب:',
                  style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // قائمة المنتجات
                ...invalidProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(FontAwesomeIcons.circleXmark, color: Color(0xFFdc3545), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product,
                            style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // الزر
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFdc3545),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('حسناً', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 🎯 نافذة مسح السلة - شفافة مضببة
void showClearCartDialog(BuildContext context, CartService cartService, VoidCallback onCleared) {
  final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFdc3545).withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FontAwesomeIcons.trash, color: Color(0xFFdc3545), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'مسح السلة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // المحتوى
                Text(
                  'هل أنت متأكد من مسح جميع المنتجات من السلة؟',
                  style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // الأزرار
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر إلغاء
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // زر مسح
                    ElevatedButton(
                      onPressed: () {
                        cartService.clearCart();
                        Navigator.pop(context);
                        onCleared();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdc3545),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('مسح', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 🎯 التحقق من صحة الأسعار
/// يرجع قائمة بالمنتجات ذات الأسعار غير الصحيحة
List<String> validatePrices(CartService cartService) {
  List<String> invalidProducts = [];

  for (var item in cartService.items) {
    if (item.customerPrice <= 0) {
      invalidProducts.add('${item.name} - لم يتم تحديد السعر');
    } else if (item.customerPrice < item.minPrice) {
      invalidProducts.add('${item.name} - السعر أقل من الحد الأدنى (${cartService.formatPrice(item.minPrice)})');
    } else if (item.customerPrice > item.maxPrice) {
      invalidProducts.add('${item.name} - السعر أعلى من الحد الأقصى (${cartService.formatPrice(item.maxPrice)})');
    }
  }

  return invalidProducts;
}
