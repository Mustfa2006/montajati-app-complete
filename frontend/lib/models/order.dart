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
      createdAt: DateTime.parse(json['created_at']),
      items:
          (json['order_items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      scheduleNotes: json['schedule_notes'],
      supportRequested: json['support_requested'],
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
    };
  }

  static int _parseProfit(Map<String, dynamic> json) {
    // ✅ استخدام عمود profit مباشرة (هو العمود الأساسي)
    return (json['profit'] ?? 0) as int;
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
      case 'active': // إضافة دعم للحالة active من قاعدة البيانات
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'in_delivery':
        return OrderStatus.inDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
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
