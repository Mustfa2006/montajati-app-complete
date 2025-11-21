import 'package:intl/intl.dart';

/// دالة مساعدة لتنسيق الأرقام بالفواصل العشرية
class NumberFormatter {
  /// تنسيق الأرقام بالفواصل العشرية (5,000 - 500,000 - 1,000,000)
  static String formatNumber(dynamic number) {
    if (number == null) return '0';

    // تحويل إلى رقم
    double numValue;
    if (number is String) {
      numValue = double.tryParse(number) ?? 0.0;
    } else if (number is int) {
      numValue = number.toDouble();
    } else if (number is double) {
      numValue = number;
    } else {
      return '0';
    }

    // إنشاء منسق الأرقام
    final formatter = NumberFormat('#,##0', 'en_US');

    // تنسيق الرقم
    if (numValue == numValue.toInt()) {
      // إذا كان الرقم صحيح (بدون كسور عشرية)
      return formatter.format(numValue.toInt());
    } else {
      // إذا كان الرقم يحتوي على كسور عشرية
      final formatterWithDecimals = NumberFormat('#,##0.0', 'en_US');
      return formatterWithDecimals.format(numValue);
    }
  }

  /// تنسيق المبالغ مع إضافة وحدة العملة
  static String formatCurrency(dynamic amount, {String currency = 'د.ع'}) {
    final formattedNumber = formatNumber(amount);
    return '$formattedNumber $currency';
  }

  /// تنسيق النسب المئوية
  static String formatPercentage(dynamic percentage) {
    if (percentage == null) return '0%';

    double numValue;
    if (percentage is String) {
      numValue = double.tryParse(percentage) ?? 0.0;
    } else if (percentage is int) {
      numValue = percentage.toDouble();
    } else if (percentage is double) {
      numValue = percentage;
    } else {
      return '0%';
    }

    return '${numValue.toStringAsFixed(1)}%';
  }

  /// تنسيق الأرقام الكبيرة (K, M, B)
  static String formatCompactNumber(dynamic number) {
    if (number == null) return '0';

    double numValue;
    if (number is String) {
      numValue = double.tryParse(number) ?? 0.0;
    } else if (number is int) {
      numValue = number.toDouble();
    } else if (number is double) {
      numValue = number;
    } else {
      return '0';
    }

    if (numValue >= 1000000000) {
      return '${(numValue / 1000000000).toStringAsFixed(1)}B';
    } else if (numValue >= 1000000) {
      return '${(numValue / 1000000).toStringAsFixed(1)}M';
    } else if (numValue >= 1000) {
      return '${(numValue / 1000).toStringAsFixed(1)}K';
    } else {
      return formatNumber(numValue);
    }
  }
}
