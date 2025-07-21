// نظام إدارة حالات الطلبات - جديد ونظيف 100%
// Order Status Management System - New & Clean

import 'package:flutter/material.dart';

/// مساعد حالات الطلبات - بسيط وفعال
class OrderStatusHelper {
  /// تحويل حالة من قاعدة البيانات إلى نص عربي
  static String getArabicStatus(String? databaseStatus) {
    if (databaseStatus == null || databaseStatus.isEmpty) {
      return 'نشط';
    }

    final status = databaseStatus.toLowerCase().trim();

    // النظام الجديد المبسط - متوافق مع لوحة التحكم
    switch (status) {
      case 'active':
        return 'نشط';
      case 'in_delivery':
        return 'قيد التوصيل';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';

      // القيم القديمة للتوافق
      case 'pending':
      case 'confirmed':
      case 'نشط':
      case '1':
      case 'new':
      case 'open':
        return 'نشط';

      case 'processing':
      case 'shipped':
      case 'قيد التوصيل':
      case '2':
      case 'shipping':
      case 'in_transit':
        return 'قيد التوصيل';

      case 'تم التوصيل':
      case '3':
      case 'completed':
      case 'finished':
      case 'done':
      case 'closed':
        return 'تم التوصيل';

      case 'تم الإلغاء':
      case '4':
      case '5':
      case 'rejected':
      case 'cancel':
      case 'reject':
      case 'ملغي':
      case 'مرفوض':
        return 'ملغي';

      default:
        return 'نشط'; // القيمة الافتراضية
    }
  }

  /// الحصول على لون الحالة
  static Color getStatusColor(String? databaseStatus) {
    final arabicStatus = getArabicStatus(databaseStatus);

    switch (arabicStatus) {
      case 'نشط':
        return const Color(0xFF007bff); // أزرق
      case 'قيد التوصيل':
        return const Color(0xFF17a2b8); // سماوي
      case 'تم التوصيل':
        return const Color(0xFF28a745); // أخضر
      case 'ملغي':
        return const Color(0xFFdc3545); // أحمر
      default:
        return Colors.grey;
    }
  }

  /// الحصول على أيقونة الحالة
  static IconData getStatusIcon(String? databaseStatus) {
    final arabicStatus = getArabicStatus(databaseStatus);

    switch (arabicStatus) {
      case 'نشط':
        return Icons.check_circle_outline;
      case 'قيد التوصيل':
        return Icons.local_shipping;
      case 'تم التوصيل':
        return Icons.check_circle;
      case 'ملغي':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /// تحويل النص العربي إلى قيمة قاعدة البيانات
  static String arabicToDatabase(String arabicStatus) {
    // إرجاع النص كما هو - قاعدة البيانات تدعم النصوص العربية الآن
    return arabicStatus;
  }

  /// الحصول على قائمة الحالات المتاحة للاختيار
  static List<String> getAvailableStatuses() {
    return ['نشط', 'قيد التوصيل', 'تم التوصيل', 'ملغي'];
  }

  /// التحقق من صحة الحالة
  static bool isValidStatus(String? status) {
    if (status == null || status.isEmpty) return false;
    return getAvailableStatuses().contains(getArabicStatus(status));
  }

  /// طباعة معلومات التشخيص (للتطوير فقط)
  static void debugStatus(String? databaseStatus) {
    print('🔍 تشخيص الحالة:');
    print('📋 قيمة قاعدة البيانات: "$databaseStatus"');
    print('📋 النص العربي: "${getArabicStatus(databaseStatus)}"');
    print('📋 اللون: ${getStatusColor(databaseStatus)}');
    print('📋 الأيقونة: ${getStatusIcon(databaseStatus)}');
  }
}
