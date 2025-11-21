class OrderItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final double wholesalePrice;
  final double customerPrice;
  final int quantity;

  OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.wholesalePrice,
    required this.customerPrice,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int asInt(dynamic v) {
      if (v == null) return 1;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 1;
      return 1;
    }

    return OrderItem(
      id: (json['id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      name: (json['product_name'] ?? '').toString(),
      image: (json['product_image'] ?? '').toString(),
      wholesalePrice: asDouble(json['wholesale_price']),
      customerPrice: asDouble(json['customer_price'] ?? json['price']),
      quantity: asInt(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': name,
      'product_image': image,
      'wholesale_price': wholesalePrice,
      'customer_price': customerPrice,
      'quantity': quantity,
    };
  }

  double get totalPrice => customerPrice * quantity;
  double get totalProfit => (customerPrice - wholesalePrice) * quantity;

  OrderItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? image,
    double? wholesalePrice,
    double? customerPrice,
    int? quantity,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      customerPrice: customerPrice ?? this.customerPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, name: $name, quantity: $quantity, customerPrice: $customerPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.id == id &&
        other.productId == productId &&
        other.name == name &&
        other.image == image &&
        other.wholesalePrice == wholesalePrice &&
        other.customerPrice == customerPrice &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        productId.hashCode ^
        name.hashCode ^
        image.hashCode ^
        wholesalePrice.hashCode ^
        customerPrice.hashCode ^
        quantity.hashCode;
  }
}
