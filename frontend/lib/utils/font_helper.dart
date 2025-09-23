import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// مساعد الخطوط - يوفر خطوط احتياطية في حالة فشل تحميل Google Fonts
class FontHelper {
  
  /// خط Cairo مع خط احتياطي
  static TextStyle cairo({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
    Paint? foreground,
  }) {
    try {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        shadows: shadows,
        foreground: foreground,
      );
    } catch (e) {
      // في حالة فشل تحميل Google Fonts، استخدم خط احتياطي
      return TextStyle(
        fontFamily: 'Arial', // خط احتياطي
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        shadows: shadows,
        foreground: foreground,
      );
    }
  }

  /// خط Amiri مع خط احتياطي
  static TextStyle amiri({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
    Paint? foreground,
  }) {
    try {
      return GoogleFonts.amiri(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        shadows: shadows,
        foreground: foreground,
      );
    } catch (e) {
      // في حالة فشل تحميل Google Fonts، استخدم خط احتياطي
      return TextStyle(
        fontFamily: 'Arial', // خط احتياطي
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        shadows: shadows,
        foreground: foreground,
      );
    }
  }

  /// خط افتراضي آمن للنصوص العربية
  static TextStyle defaultArabic({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: 'Arial', // خط آمن يدعم العربية
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.black,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }
}
