import 'package:flutter/foundation.dart';

import 'order_item.dart';

enum OrderStatus { pending, confirmed, inDelivery, delivered, cancelled }

class Order {
  final String id;
  final String customerName;
  final String primaryPhone;
  final String? secondaryPhone;
  final String province;
  final String city;
  final String? notes;
  final int totalCost;
  final int totalProfit;
  final int subtotal;
  final int total;
  final OrderStatus status;
  final String rawStatus; // النص الأصلي من قاعدة البيانات
  final DateTime createdAt;
  final List<OrderItem> items;
  final DateTime? scheduledDate;
  final String? scheduleNotes;
  final bool? supportRequested;
  final String? waseetOrderId; // رقم الطلب في الوسيط

  Order({
    required this.id,
    required this.customerName,
    required this.primaryPhone,
    this.secondaryPhone,
    required this.province,
    required this.city,
    this.notes,
    required this.totalCost,
    required this.totalProfit,
    required this.subtotal,
    required this.total,
    required this.status,
    this.rawStatus = 'نشط', // قيمة افتراضية
    required this.createdAt,
    required this.items,
    this.scheduledDate,
    this.scheduleNotes,
    this.supportRequested,
    this.waseetOrderId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? '',
      primaryPhone: json['primary_phone'] ?? '',
      secondaryPhone: json['secondary_phone'],
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      notes: json['notes'],
      totalCost: (json['total'] ?? 0),
      totalProfit: _parseProfit(json),
      subtotal: (json['subtotal'] ?? 0),
      total: (json['total'] ?? 0),
      status: _parseOrderStatus(json['status']),
      rawStatus: json['status'] ?? 'نشط', // الاحتفاظ بالنص الأصلي
      createdAt: _parseDateTime(json['created_at']), // ✅ معالجة آمنة للتاريخ
      items: (json['order_items'] as List?)?.map((item) => OrderItem.fromJson(item)).toList() ?? [],
      scheduledDate: _parseOptionalDateTime(json['scheduled_date']), // ✅ معالجة آمنة
      scheduleNotes: json['schedule_notes'],
      supportRequested: json['support_requested'],
      waseetOrderId: json['waseet_order_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'primary_phone': primaryPhone,
      'secondary_phone': secondaryPhone,
      'province': province,
      'city': city,
      'notes': notes,
      'total': total,
      'subtotal': subtotal,
      'profit': totalProfit,
      'status': _orderStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'order_items': items.map((item) => item.toJson()).toList(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'schedule_notes': scheduleNotes,
      'waseet_order_id': waseetOrderId,
    };
  }

  static int _parseProfit(Map<String, dynamic> json) {
    // ✅ استخدام عمود profit مباشرة (هو العمود الأساسي)
    return (json['profit'] ?? 0) as int;
  }

  // ✅ دالة معالجة آمنة للتاريخ
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('⚠️ خطأ في تحويل التاريخ: $value - $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // ✅ دالة معالجة آمنة للتاريخ الاختياري
  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('⚠️ خطأ في تحويل التاريخ الاختياري: $value - $e');
        return null;
      }
    }
    return null;
  }

  static OrderStatus _parseOrderStatus(String? status) {
    if (status == null) return OrderStatus.pending;

    final statusLower = status.toLowerCase();

    // حالات نشطة/معالجة
    if (statusLower.contains('نشط') ||
        statusLower.contains('active') ||
        statusLower.contains('pending') ||
        statusLower.contains('معالجة') ||
        statusLower.contains('processing')) {
      return OrderStatus.pending;
    }

    // حالات مؤكدة
    if (statusLower.contains('confirmed') || statusLower.contains('مؤكد')) {
      return OrderStatus.confirmed;
    }

    // حالات قيد التوصيل
    if (statusLower.contains('قيد التوصيل') ||
        statusLower.contains('في عهدة المندوب') ||
        statusLower.contains('shipping') ||
        statusLower.contains('shipped') ||
        statusLower.contains('in_delivery')) {
      return OrderStatus.inDelivery;
    }

    // حالات تم التسليم
    if (statusLower.contains('تم التسليم') ||
        statusLower.contains('delivered') ||
        statusLower.contains('مكتمل') ||
        statusLower.contains('completed')) {
      return OrderStatus.delivered;
    }

    // حالات ملغية
    if (statusLower.contains('الغاء') ||
        statusLower.contains('رفض') ||
        statusLower.contains('ارجاع') ||
        statusLower.contains('cancelled') ||
        statusLower.contains('canceled') ||
        statusLower.contains('ملغي')) {
      return OrderStatus.cancelled;
    }

    // الافتراضي
    return OrderStatus.pending;
  }

  static String _orderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.inDelivery:
        return 'in_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'في انتظار التأكيد';
      case OrderStatus.confirmed:
        return 'تم التأكيد';
      case OrderStatus.inDelivery:
        return 'في الطريق';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  Order copyWith({
    String? id,
    String? customerName,
    String? primaryPhone,
    String? secondaryPhone,
    String? province,
    String? city,
    String? notes,
    int? totalCost,
    int? totalProfit,
    int? subtotal,
    int? total,
    OrderStatus? status,
    String? rawStatus,
    DateTime? createdAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      province: province ?? this.province,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      totalCost: totalCost ?? this.totalCost,
      totalProfit: totalProfit ?? this.totalProfit,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
