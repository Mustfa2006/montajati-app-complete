import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 نظام التصميم الموحد للتطبيق
/// مستخرج من صفحة المنتجات الرئيسية لضمان التناسق الكامل
class AppDesignSystem {
  
  // ==================== الألوان الأساسية ====================
  
  /// الخلفية الرئيسية للتطبيق
  static const Color primaryBackground = Color(0xFF1F2125);
  
  /// لون الشريط السفلي
  static const Color bottomNavColor = Color(0xFF2D3748);
  
  /// لون الكرة النشطة في الشريط السفلي
  static const Color activeButtonColor = Color(0xFF1A202C);
  
  /// اللون الذهبي للأيقونات والعناصر المهمة
  static const Color goldColor = Color(0xFFFFD700);
  
  /// لون العناصر الثانوية
  static const Color secondaryColor = Color(0xFF6B7180);
  
  /// لون النصوص الأساسية
  static const Color primaryTextColor = Colors.white;
  
  /// لون النصوص الثانوية
  static const Color secondaryTextColor = Color(0xFFB0B0B0);
  
  // ==================== التدرجات اللونية ====================
  
  /// تدرج البطاقات الرئيسية
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF363940),
      Color(0xFF2D3748),
      Color(0x003D414B),
    ],
    stops: [0.0, 0.7, 1.0],
  );
  
  /// تدرج البانر الرئيسي
  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B7180), Color(0xFF4A5058)],
  );
  
  /// تدرج السعر
  static const LinearGradient priceGradient = LinearGradient(
    colors: [
      Color(0x99FFC107), // Colors.amber.withValues(alpha: 0.6)
      Color(0x66FF9800), // Colors.orange.withValues(alpha: 0.4)
    ],
  );
  
  /// تدرج الأزرار الخضراء (نجاح)
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF45A049), Color(0xFF388E3C)],
  );
  
  /// تدرج الأزرار الرمادية (غير نشط)
  static const LinearGradient inactiveGradient = LinearGradient(
    colors: [Color(0xFF6F757F), Color(0xFF4A5568), Color(0xFF2D3748)],
  );
  
  // ==================== الظلال ====================
  
  /// ظل البطاقات الأساسي
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: secondaryColor.withValues(alpha: 0.1),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
  
  /// ظل خفيف للعناصر الصغيرة
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// ظل السعر
  static List<BoxShadow> get priceShadow => [
    BoxShadow(
      color: Colors.amber.withValues(alpha: 0.2),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  
  // ==================== الحدود ====================
  
  /// حدود البطاقات الأساسية
  static Border get cardBorder => Border.all(
    color: Colors.white.withValues(alpha: 0.1),
    width: 1,
  );
  
  /// حدود العناصر الذهبية
  static Border get goldBorder => Border.all(
    color: goldColor.withValues(alpha: 0.3),
    width: 0.5,
  );
  
  /// نصف قطر الحدود الأساسي
  static const double primaryBorderRadius = 24.0;
  
  /// نصف قطر الحدود الثانوي
  static const double secondaryBorderRadius = 20.0;
  
  /// نصف قطر الحدود الصغير
  static const double smallBorderRadius = 12.0;
  
  // ==================== أنماط النصوص ====================
  
  /// عنوان التطبيق الرئيسي
  static TextStyle get appTitleStyle => GoogleFonts.poppins(
    color: primaryTextColor,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
  );
  
  /// عنوان القسم
  static TextStyle get sectionTitleStyle => GoogleFonts.poppins(
    color: primaryTextColor,
    fontSize: 26,
    fontWeight: FontWeight.w600,
  );
  
  /// عنوان البطاقة
  static TextStyle get cardTitleStyle => GoogleFonts.cairo(
    color: primaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  
  /// نص السعر
  static TextStyle get priceTextStyle => GoogleFonts.cairo(
    color: primaryTextColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  
  /// نص ثانوي
  static TextStyle get secondaryTextStyle => GoogleFonts.cairo(
    color: secondaryTextColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  
  // ==================== المسافات ====================
  
  /// المسافة الكبيرة
  static const double largeSpacing = 25.0;
  
  /// المسافة المتوسطة
  static const double mediumSpacing = 16.0;
  
  /// المسافة الصغيرة
  static const double smallSpacing = 8.0;
  
  /// المسافة الدقيقة
  static const double tinySpacing = 4.0;
  
  // ==================== الأحجام ====================
  
  /// ارتفاع البطاقة الأساسي
  static const double cardHeight = 380.0;
  
  /// ارتفاع البانر
  static const double bannerHeight = 200.0;
  
  /// حجم الأيقونة الكبيرة
  static const double largeIconSize = 28.0;
  
  /// حجم الأيقونة المتوسطة
  static const double mediumIconSize = 20.0;
  
  /// حجم الأيقونة الصغيرة
  static const double smallIconSize = 16.0;
  
  // ==================== دوال مساعدة ====================
  
  /// إنشاء حاوية بالتصميم الموحد
  static Container createCard({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(mediumSpacing),
      margin: margin,
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(primaryBorderRadius),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: child,
    );
  }
  
  /// إنشاء زر بالتصميم الموحد
  static Widget createButton({
    required Widget child,
    required VoidCallback onTap,
    bool isActive = true,
    double? width,
    double? height,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(
          horizontal: mediumSpacing,
          vertical: smallSpacing,
        ),
        decoration: BoxDecoration(
          gradient: isActive ? successGradient : inactiveGradient,
          borderRadius: BorderRadius.circular(smallBorderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: isActive ? 0.3 : 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
              blurRadius: isActive ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
