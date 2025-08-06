class Product {
  final String id;
  final String name;
  final String description;
  final double wholesalePrice;
  final double minPrice;
  final double maxPrice;
  final List<String> images;
  final int minQuantity;
  final int maxQuantity;
  final int availableFrom;
  final int availableTo;
  final int availableQuantity;
  final String category;
  final int displayOrder; // ترتيب عرض المنتج (1 = أول منتج، 2 = ثاني منتج، إلخ)
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.wholesalePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.images,
    required this.minQuantity,
    required this.maxQuantity,
    required this.availableFrom,
    required this.availableTo,
    required this.availableQuantity,
    required this.category,
    this.displayOrder = 999, // قيمة افتراضية عالية للمنتجات الجديدة
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      wholesalePrice: (json['wholesale_price'] ?? 0).toDouble(),
      minPrice: (json['min_price'] ?? 0).toDouble(),
      maxPrice: (json['max_price'] ?? 0).toDouble(),
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      minQuantity: json['min_quantity'] ?? 0,
      maxQuantity: json['max_quantity'] ?? 0,
      availableFrom: json['available_from'] ?? 90,
      availableTo: json['available_to'] ?? 80,
      availableQuantity: json['available_quantity'] ?? 100,
      category: json['category']?.toString() ?? '',
      displayOrder: json['display_order'] ?? 999, // قيمة افتراضية عالية
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'wholesale_price': wholesalePrice,
      'min_price': minPrice,
      'max_price': maxPrice,
      'images': images,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'available_from': availableFrom,
      'available_to': availableTo,
      'available_quantity': availableQuantity,
      'category': category,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? wholesalePrice,
    double? minPrice,
    double? maxPrice,
    List<String>? images,
    int? minQuantity,
    int? maxQuantity,
    int? availableFrom,
    int? availableTo,
    int? availableQuantity,
    String? category,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      images: images ?? this.images,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      category: category ?? this.category,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, wholesalePrice: $wholesalePrice)';
  }
}
