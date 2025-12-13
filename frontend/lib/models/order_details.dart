class OrderDetails {
  final String id;
  final bool isScheduled;
  final String status;
  final DateTime? scheduledDate;
  final CustomerInfo customer;
  final LocationInfo location;
  final String? notes; // Customer notes preferred
  final List<OrderItemDetail> items;
  final FinancialInfo financial;
  final WaseetInfo? waseet;
  final DateInfo dates;

  OrderDetails({
    required this.id,
    required this.isScheduled,
    required this.status,
    this.scheduledDate,
    required this.customer,
    required this.location,
    this.notes,
    required this.items,
    required this.financial,
    this.waseet,
    required this.dates,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      id: json['id'].toString(),
      isScheduled: json['isScheduled'] ?? false,
      status: json['status']?.toString() ?? 'unknown',
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
      customer: CustomerInfo.fromJson(json['customer']),
      location: LocationInfo.fromJson(json['location']),
      notes: json['notes']?.toString(),
      items: (json['items'] as List).map((i) => OrderItemDetail.fromJson(i)).toList(),
      financial: FinancialInfo.fromJson(json['financial']),
      waseet: json['waseet'] != null ? WaseetInfo.fromJson(json['waseet']) : null,
      dates: DateInfo.fromJson(json['dates']),
    );
  }
}

class CustomerInfo {
  final String name;
  final String phone;
  final String? alternatePhone;

  CustomerInfo({required this.name, required this.phone, this.alternatePhone});

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'].toString(),
      phone: json['phone'].toString(),
      alternatePhone: json['alternatePhone']?.toString(),
    );
  }
}

class LocationInfo {
  final String province;
  final String city;

  LocationInfo({required this.province, required this.city});

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(province: json['province']?.toString() ?? '', city: json['city']?.toString() ?? '');
  }
}

class OrderItemDetail {
  final String id;
  final String productId;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double price;
  final double profit;

  OrderItemDetail({
    required this.id,
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.price,
    required this.profit,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      id: json['id'].toString(),
      productId: json['productId'].toString(),
      name: json['name'].toString(),
      imageUrl: json['imageUrl'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FinancialInfo {
  final double total;
  final double subtotal;
  final double discount;
  final double shipping;
  final double profit;

  FinancialInfo({
    required this.total,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.profit,
  });

  factory FinancialInfo.fromJson(Map<String, dynamic> json) {
    return FinancialInfo(
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WaseetInfo {
  final String? id;
  final String? status;

  WaseetInfo({this.id, this.status});

  factory WaseetInfo.fromJson(Map<String, dynamic> json) {
    return WaseetInfo(id: json['id']?.toString(), status: json['status']?.toString());
  }
}

class DateInfo {
  final DateTime created;
  final DateTime updated;

  DateInfo({required this.created, required this.updated});

  factory DateInfo.fromJson(Map<String, dynamic> json) {
    return DateInfo(created: DateTime.parse(json['created']), updated: DateTime.parse(json['updated']));
  }
}
