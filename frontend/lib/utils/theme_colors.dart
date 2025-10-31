import 'package:flutter/material.dart';

/// 🎨 ألوان التطبيق حسب الوضع (ليلي/نهاري)
class ThemeColors {
  /// لون النص الأساسي
  static Color textColor(bool isDark) {
    return isDark ? Colors.white : Colors.black;
  }

  /// لون النص الثانوي
  static Color secondaryTextColor(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6);
  }

  /// لون خلفية المربعات
  static Color cardBackground(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
  }

  /// لون حدود المربعات
  static Color cardBorder(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2);
  }

  /// لون الأيقونات
  static Color iconColor(bool isDark) {
    return isDark ? Colors.white : Colors.black87;
  }

  /// لون الأيقونات الثانوية
  static Color secondaryIconColor(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.5);
  }

  /// لون الخلفية للأزرار
  static Color buttonBackground(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04);
  }

  /// لون النص في الأزرار
  static Color buttonTextColor(bool isDark) {
    return isDark ? Colors.white : Colors.black87;
  }

  /// لون الظل
  static Color shadowColor(bool isDark) {
    return isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1);
  }

  /// لون الخلفية للـ Divider
  static Color dividerColor(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
  }

  /// لون الخلفية للـ TextField
  static Color textFieldBackground(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
  }

  /// لون النص في الـ TextField
  static Color textFieldTextColor(bool isDark) {
    return isDark ? Colors.white : Colors.black87;
  }

  /// لون الـ hint في الـ TextField
  static Color textFieldHintColor(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4);
  }

  /// لون الخلفية للـ AppBar
  static Color appBarBackground(bool isDark) {
    return isDark ? Colors.transparent : Colors.white;
  }

  /// لون النص في الـ AppBar
  static Color appBarTextColor(bool isDark) {
    return isDark ? Colors.white : Colors.black;
  }

  /// لون الخلفية للـ BottomSheet
  static Color bottomSheetBackground(bool isDark) {
    return isDark ? const Color(0xFF1a1f2e) : Colors.white;
  }

  /// لون الخلفية للـ Dialog
  static Color dialogBackground(bool isDark) {
    return isDark ? const Color(0xFF1a1f2e) : Colors.white;
  }

  /// لون الخلفية للـ Chip
  static Color chipBackground(bool isDark) {
    return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);
  }

  /// لون النص في الـ Chip
  static Color chipTextColor(bool isDark) {
    return isDark ? Colors.white : Colors.black87;
  }

  /// لون الخلفية للـ Badge
  static Color badgeBackground(bool isDark) {
    return isDark ? const Color(0xFFffd700) : const Color(0xFFffd700);
  }

  /// لون النص في الـ Badge
  static Color badgeTextColor(bool isDark) {
    return Colors.black;
  }

  /// لون الخلفية للـ Loading Indicator
  static Color loadingIndicatorColor(bool isDark) {
    return const Color(0xFFffd700);
  }

  /// لون الخلفية للـ Error
  static Color errorColor(bool isDark) {
    return Colors.red;
  }

  /// لون الخلفية للـ Success
  static Color successColor(bool isDark) {
    return Colors.green;
  }

  /// لون الخلفية للـ Warning
  static Color warningColor(bool isDark) {
    return Colors.orange;
  }

  /// لون الخلفية للـ Info
  static Color infoColor(bool isDark) {
    return Colors.blue;
  }
}
