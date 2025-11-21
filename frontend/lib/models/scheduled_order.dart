class ScheduledOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String? customerAlternatePhone;
  final String customerAddress;
  final String? customerProvince; // اسم المحافظة للعرض (قديم)
  final String? customerCity; // اسم المدينة للعرض (قديم)
  final String? province; // اسم المحافظة (نفس نظام الطلبات العادية)
  final String? city; // اسم المدينة (نفس نظام الطلبات العادية)
  final String? provinceId; // معرف المحافظة في قاعدة البيانات
  final String? cityId; // معرف المدينة في قاعدة البيانات
  final String? customerNotes;
  final double totalAmount;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final String notes;
  final List<ScheduledOrderItem> items;
  final String priority;
  final bool reminderSent;

  ScheduledOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    this.customerAlternatePhone,
    required this.customerAddress,
    this.customerProvince,
    this.customerCity,
    this.province,
    this.city,
    this.provinceId,
    this.cityId,
    this.customerNotes,
    required this.totalAmount,
    required this.scheduledDate,
    required this.createdAt,
    required this.notes,
    required this.items,
    required this.priority,
    required this.reminderSent,
  });

  factory ScheduledOrder.fromJson(Map<String, dynamic> json) {
    return ScheduledOrder(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerAlternatePhone: json['customerAlternatePhone'],
      customerAddress: json['customerAddress'] ?? '',
      customerProvince: json['customerProvince'],
      customerCity: json['customerCity'],
      province: json['province'],
      city: json['city'],
      provinceId: json['provinceId'],
      cityId: json['cityId'],
      customerNotes: json['customerNotes'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      scheduledDate: DateTime.parse(
        json['scheduledDate'] ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      notes: json['notes'] ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => ScheduledOrderItem.fromJson(item))
              .toList() ??
          [],
      priority: json['priority'] ?? 'متوسطة',
      reminderSent: json['reminderSent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'totalAmount': totalAmount,
      'scheduledDate': scheduledDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'priority': priority,
      'reminderSent': reminderSent,
    };
  }

  ScheduledOrder copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? customerAlternatePhone,
    String? customerAddress,
    String? customerProvince,
    String? customerCity,
    String? province,
    String? city,
    String? provinceId,
    String? cityId,
    String? customerNotes,
    double? totalAmount,
    DateTime? scheduledDate,
    DateTime? createdAt,
    String? notes,
    List<ScheduledOrderItem>? items,
    String? priority,
    bool? reminderSent,
  }) {
    return ScheduledOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAlternatePhone:
          customerAlternatePhone ?? this.customerAlternatePhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerProvince: customerProvince ?? this.customerProvince,
      customerCity: customerCity ?? this.customerCity,
      province: province ?? this.province,
      city: city ?? this.city,
      provinceId: provinceId ?? this.provinceId,
      cityId: cityId ?? this.cityId,
      customerNotes: customerNotes ?? this.customerNotes,
      totalAmount: totalAmount ?? this.totalAmount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      priority: priority ?? this.priority,
      reminderSent: reminderSent ?? this.reminderSent,
    );
  }
}

class ScheduledOrderItem {
  final String name;
  final int quantity;
  final double price;
  final String notes;
  final String? productId; // ✅ إضافة معرف المنتج
  final String? productImage; // ✅ إضافة صورة المنتج

  ScheduledOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.notes,
    this.productId, // ✅ إضافة معرف المنتج
    this.productImage, // ✅ إضافة صورة المنتج
  });

  factory ScheduledOrderItem.fromJson(Map<String, dynamic> json) {
    return ScheduledOrderItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
      productId: json['product_id'], // ✅ إضافة معرف المنتج
      productImage: json['product_image'], // ✅ إضافة صورة المنتج
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'notes': notes,
      'product_id': productId, // ✅ إضافة معرف المنتج
      'product_image': productImage, // ✅ إضافة صورة المنتج
    };
  }

  ScheduledOrderItem copyWith({
    String? name,
    int? quantity,
    double? price,
    String? notes,
  }) {
    return ScheduledOrderItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
    );
  }
}
