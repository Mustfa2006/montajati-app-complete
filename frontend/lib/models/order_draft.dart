/// 📝 نموذج مسودة الطلب
/// Order Draft Model - DTO فقط (بدون Validation)


import 'province.dart';
import 'city.dart';

class OrderDraft {
  // بيانات العميل
  final String customerName;
  final String primaryPhone;
  final String? secondaryPhone;
  final String? notes;

  // بيانات الموقع - كـ Objects وليس IDs منفصلة
  final Province province;
  final City city;
  final String? regionId;

  // بيانات الجدولة (اختياري)
  final DateTime? scheduledDate;
  final String? scheduleNotes;

  const OrderDraft({
    required this.customerName,
    required this.primaryPhone,
    this.secondaryPhone,
    this.notes,
    required this.province,
    required this.city,
    this.regionId,
    this.scheduledDate,
    this.scheduleNotes,
  });
}
