// نظام إدارة حالات الطلبات - جديد ونظيف 100%
// Order Status Management System - New & Clean

import 'package:flutter/material.dart';

/// مساعد حالات الطلبات - بسيط وفعال
class OrderStatusHelper {
  /// عرض النص الدقيق للحالة كما هو في قاعدة البيانات
  static String getArabicStatus(String? databaseStatus) {
    if (databaseStatus == null || databaseStatus.isEmpty) {
      return 'نشط';
    }

    final status = databaseStatus.trim();

    // عرض النصوص الطويلة من قاعدة البيانات كما هي بالضبط
    switch (status) {
      case 'تم التسليم للزبون':
      case 'تم تغيير محافظة الزبون':
      case 'تغيير المندوب':
      case 'لا يرد':
      case 'لا يرد بعد الاتفاق':
      case 'مغلق':
      case 'مغلق بعد الاتفاق':
      case 'الغاء الطلب':
      case 'رفض الطلب':
      case 'مفصول عن الخدمة':
      case 'طلب مكرر':
      case 'مستلم مسبقا':
      case 'الرقم غير معرف':
      case 'الرقم غير داخل في الخدمة':
      case 'لا يمكن الاتصال بالرقم':
      case 'العنوان غير دقيق':
      case 'لم يطلب':
      case 'حظر المندوب':
      case 'قيد التوصيل الى الزبون (في عهدة المندوب)':
      case 'مؤجل':
      case 'مؤجل لحين اعادة الطلب لاحقا':
        return status; // إرجاع النص كما هو بالضبط
    }

    final statusLower = databaseStatus.toLowerCase().trim();

    // النظام الجديد المبسط - متوافق مع لوحة التحكم
    switch (statusLower) {
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
      case 'قيد التوصيل الى الزبون (في عهدة المندوب)':
      case '2':
      case '3': // قيد التوصيل الى الزبون (في عهدة المندوب)
      case 'shipping':
      case 'in_transit':
        return 'قيد التوصيل';

      case 'تم التوصيل':
      case '4': // تم التسليم للزبون
      case 'completed':
      case 'finished':
      case 'done':
      case 'closed':
        return 'تم التوصيل';

      // حالات الإلغاء والرفض - جميع الحالات السلبية
      case 'تم الإلغاء':
      case '5':
      case '25': // لا يرد
      case '26': // لا يرد بعد الاتفاق
      case '27': // مغلق
      case '28': // مغلق بعد الاتفاق
      case '31': // الغاء الطلب
      case '32': // رفض الطلب
      case '33': // مفصول عن الخدمة
      case '34': // طلب مكرر
      case '35': // مستلم مسبقا
      case '36': // الرقم غير معرف
      case '37': // الرقم غير داخل في الخدمة
      case '38': // العنوان غير دقيق
      case '39': // لم يطلب
      case '40': // حظر المندوب
      case '41': // لا يمكن الاتصال بالرقم
      case 'rejected':
      case 'cancel':
      case 'reject':
      case 'ملغي':
      case 'مرفوض':
        return 'ملغي';

      // حالات خاصة - مؤجلة
      case '29': // مؤجل
      case '30': // مؤجل لحين اعادة الطلب لاحقا
        return 'مؤجل';

      // حالات خاصة - تعتبر نشطة
      case '24': // تم تغيير محافظة الزبون
      case '42': // تغيير المندوب
        return 'نشط';

      default:
        return 'نشط'; // القيمة الافتراضية
    }
  }

  /// الحصول على لون الحالة بناءً على النص الدقيق
  static Color getStatusColor(String? databaseStatus) {
    if (databaseStatus == null || databaseStatus.isEmpty) {
      return const Color(0xFFffc107); // ذهبي للنشط (افتراضي)
    }

    final status = databaseStatus.trim();

    // ألوان للحالات المكتملة (أخضر)
    if (status == 'تم التسليم للزبون') {
      return const Color(0xFF28a745); // أخضر
    }

    // ألوان للحالة النشطة (ذهبي)
    if (status == 'نشط') {
      return const Color(0xFFffc107); // ذهبي للنشط
    }

    // ألوان للحالات التي تحتاج معالجة (برتقالي)
    if (status == 'تم تغيير محافظة الزبون' ||
        status == 'تغيير المندوب') {
      return const Color(0xFFff6b35); // برتقالي للمعالجة
    }

    // ألوان للحالات قيد التوصيل (سماوي)
    if (status == 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
      return const Color(0xFF17a2b8); // سماوي
    }

    // ألوان للحالات المؤجلة (أصفر)
    if (status == 'مؤجل' || status == 'مؤجل لحين اعادة الطلب لاحقا') {
      return const Color(0xFFffc107); // أصفر
    }

    // ألوان للحالات الملغية (أحمر)
    if (status == 'لا يرد' ||
        status == 'لا يرد بعد الاتفاق' ||
        status == 'مغلق' ||
        status == 'مغلق بعد الاتفاق' ||
        status == 'الغاء الطلب' ||
        status == 'رفض الطلب' ||
        status == 'مفصول عن الخدمة' ||
        status == 'طلب مكرر' ||
        status == 'مستلم مسبقا' ||
        status == 'الرقم غير معرف' ||
        status == 'الرقم غير داخل في الخدمة' ||
        status == 'لا يمكن الاتصال بالرقم' ||
        status == 'العنوان غير دقيق' ||
        status == 'لم يطلب' ||
        status == 'حظر المندوب') {
      return const Color(0xFFdc3545); // أحمر
    }

    // للحالات القديمة والأرقام
    final statusLower = status.toLowerCase();
    if (statusLower.contains('تم') || statusLower.contains('delivered')) {
      return const Color(0xFF28a745); // أخضر
    } else if (statusLower.contains('قيد') || statusLower.contains('delivery')) {
      return const Color(0xFF17a2b8); // سماوي
    } else if (statusLower.contains('ملغي') || statusLower.contains('cancelled')) {
      return const Color(0xFFdc3545); // أحمر
    } else if (statusLower.contains('مؤجل') || statusLower.contains('postponed')) {
      return const Color(0xFFffc107); // أصفر
    }

    return const Color(0xFFffc107); // ذهبي افتراضي (مثل نشط)
  }

  /// الحصول على أيقونة الحالة بناءً على النص الدقيق
  static IconData getStatusIcon(String? databaseStatus) {
    if (databaseStatus == null || databaseStatus.isEmpty) {
      return Icons.check_circle_outline;
    }

    final status = databaseStatus.trim();

    // أيقونات للحالات المكتملة
    if (status == 'تم التسليم للزبون') {
      return Icons.check_circle;
    }

    // أيقونات للحالات النشطة
    if (status == 'تم تغيير محافظة الزبون' ||
        status == 'تغيير المندوب' ||
        status == 'نشط') {
      return Icons.check_circle_outline;
    }

    // أيقونات للحالات قيد التوصيل
    if (status == 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
      return Icons.local_shipping;
    }

    // أيقونات للحالات المؤجلة
    if (status == 'مؤجل' || status == 'مؤجل لحين اعادة الطلب لاحقا') {
      return Icons.schedule;
    }

    // أيقونات للحالات الملغية
    if (status == 'لا يرد' ||
        status == 'لا يرد بعد الاتفاق' ||
        status == 'مغلق' ||
        status == 'مغلق بعد الاتفاق' ||
        status == 'الغاء الطلب' ||
        status == 'رفض الطلب' ||
        status == 'مفصول عن الخدمة' ||
        status == 'طلب مكرر' ||
        status == 'مستلم مسبقا' ||
        status == 'الرقم غير معرف' ||
        status == 'الرقم غير داخل في الخدمة' ||
        status == 'لا يمكن الاتصال بالرقم' ||
        status == 'العنوان غير دقيق' ||
        status == 'لم يطلب' ||
        status == 'حظر المندوب') {
      return Icons.cancel;
    }

    return Icons.help; // افتراضي
  }

  /// تحويل النص العربي إلى قيمة قاعدة البيانات
  static String arabicToDatabase(String arabicStatus) {
    // إرجاع النص كما هو - قاعدة البيانات تدعم النصوص العربية الآن
    return arabicStatus;
  }

  /// الحصول على قائمة الحالات المتاحة للاختيار
  static List<String> getAvailableStatuses() {
    return ['نشط', 'قيد التوصيل', 'تم التوصيل', 'ملغي', 'مؤجل'];
  }

  /// التحقق من صحة الحالة
  static bool isValidStatus(String? status) {
    if (status == null || status.isEmpty) return false;
    return getAvailableStatuses().contains(getArabicStatus(status));
  }

  /// طباعة معلومات التشخيص (للتطوير فقط)
  static void debugStatus(String? databaseStatus) {
    debugPrint('🔍 تشخيص الحالة:');
    debugPrint('📋 قيمة قاعدة البيانات: "$databaseStatus"');
    debugPrint('📋 النص العربي: "${getArabicStatus(databaseStatus)}"');
    debugPrint('📋 اللون: ${getStatusColor(databaseStatus)}');
    debugPrint('📋 الأيقونة: ${getStatusIcon(databaseStatus)}');
  }
}
