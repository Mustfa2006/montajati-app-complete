// 🚀 نموذج بيانات مبسط للطلبات - للعرض السريع فقط
import '../services/admin_service.dart';

class OrderSummary {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String province;
  final String city;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // متغير لتتبع ما إذا تم تحميل التفاصيل الكاملة
  bool isDetailLoaded = false;

  OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.province,
    required this.city,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] ?? '',
      orderNumber: json['id']?.toString().substring(0, 8) ?? '',
      customerName: json['customer_name'] ?? 'غير محدد',
      customerPhone: json['primary_phone'] ?? 'غير محدد',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      totalAmount: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'active',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  // تحويل إلى AdminOrder عند الحاجة للتفاصيل الكاملة
  AdminOrder toAdminOrder({
    String? customerAlternatePhone,
    String? customerNotes,
    double? deliveryCost,
    double? profitAmount,
    double? expectedProfit,
    String? userName,
    String? userPhone,
    List<AdminOrderItem>? items,
  }) {
    return AdminOrder(
      id: id,
      orderNumber: orderNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAlternatePhone: customerAlternatePhone,
      customerProvince: province,
      customerCity: city,
      customerAddress: '$province - $city',
      customerNotes: customerNotes,
      totalAmount: totalAmount,
      deliveryCost: deliveryCost ?? 0.0,
      profitAmount: profitAmount ?? 0.0,
      expectedProfit: expectedProfit ?? 0.0,
      itemsCount: items?.length ?? 0,
      status: status,
      createdAt: createdAt,
      userName: userName ?? 'غير محدد',
      userPhone: userPhone ?? 'غير محدد',
      items: items ?? [],
    );
  }
}
