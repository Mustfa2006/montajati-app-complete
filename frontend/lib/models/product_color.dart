import 'package:flutter/material.dart';

/// 🎨 نموذج لون المنتج - النظام الذكي المتطور
class ProductColor {
  final String id;
  final String productId;
  final String colorName;
  final String colorCode; // HEX color code (#FF0000)
  final String? colorRgb; // RGB values (255,0,0)
  final String colorArabicName;
  final int totalQuantity;
  final int availableQuantity;
  final int reservedQuantity;
  final int soldQuantity;
  final bool isActive;
  final int displayOrder;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductColor({
    required this.id,
    required this.productId,
    required this.colorName,
    required this.colorCode,
    this.colorRgb,
    required this.colorArabicName,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.reservedQuantity,
    required this.soldQuantity,
    this.isActive = true,
    this.displayOrder = 1,
    required this.createdAt,
    required this.updatedAt,
  }) : isAvailable = availableQuantity > 0;

  /// تحويل من JSON
  factory ProductColor.fromJson(Map<String, dynamic> json) {
    return ProductColor(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      colorName: json['color_name']?.toString() ?? '',
      colorCode: json['color_code']?.toString() ?? '#000000',
      colorRgb: json['color_rgb']?.toString(),
      colorArabicName: json['color_arabic_name']?.toString() ?? '',
      totalQuantity: json['total_quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      reservedQuantity: json['reserved_quantity'] ?? 0,
      soldQuantity: json['sold_quantity'] ?? 0,
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'color_name': colorName,
      'color_code': colorCode,
      'color_rgb': colorRgb,
      'color_arabic_name': colorArabicName,
      'total_quantity': totalQuantity,
      'available_quantity': availableQuantity,
      'reserved_quantity': reservedQuantity,
      'sold_quantity': soldQuantity,
      'is_active': isActive,
      'display_order': displayOrder,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// الحصول على لون Flutter من الكود السادس عشري
  Color get flutterColor {
    try {
      String hexColor = colorCode.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  /// الحصول على لون النص المناسب (أبيض أو أسود) حسب لون الخلفية
  Color get textColor {
    final color = flutterColor;
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  /// الحصول على لون الحدود المناسب
  Color get borderColor {
    return flutterColor.withValues(alpha: 0.3);
  }

  /// الحصول على نسبة التوفر
  double get availabilityPercentage {
    if (totalQuantity == 0) return 0.0;
    return (availableQuantity / totalQuantity) * 100;
  }

  /// التحقق من انخفاض المخزون
  bool get isLowStock {
    return availableQuantity > 0 && availableQuantity <= (totalQuantity * 0.1);
  }

  /// التحقق من نفاد المخزون
  bool get isOutOfStock {
    return availableQuantity <= 0;
  }

  /// الحصول على حالة المخزون
  String get stockStatus {
    if (isOutOfStock) return 'نفد المخزون';
    if (isLowStock) return 'مخزون منخفض';
    return 'متوفر';
  }

  /// الحصول على لون حالة المخزون
  Color get stockStatusColor {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  /// نسخ مع تعديل
  ProductColor copyWith({
    String? id,
    String? productId,
    String? colorName,
    String? colorCode,
    String? colorRgb,
    String? colorArabicName,
    int? totalQuantity,
    int? availableQuantity,
    int? reservedQuantity,
    int? soldQuantity,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductColor(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      colorName: colorName ?? this.colorName,
      colorCode: colorCode ?? this.colorCode,
      colorRgb: colorRgb ?? this.colorRgb,
      colorArabicName: colorArabicName ?? this.colorArabicName,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProductColor(id: $id, colorArabicName: $colorArabicName, availableQuantity: $availableQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductColor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 🎨 نموذج اللون المحدد مسبقاً
class PredefinedColor {
  final int id;
  final String colorName;
  final String colorCode;
  final String? colorRgb;
  final String colorArabicName;
  final bool isPopular;
  final int usageCount;
  final DateTime createdAt;

  PredefinedColor({
    required this.id,
    required this.colorName,
    required this.colorCode,
    this.colorRgb,
    required this.colorArabicName,
    this.isPopular = false,
    this.usageCount = 0,
    required this.createdAt,
  });

  factory PredefinedColor.fromJson(Map<String, dynamic> json) {
    return PredefinedColor(
      id: json['id'] ?? 0,
      colorName: json['color_name']?.toString() ?? '',
      colorCode: json['color_code']?.toString() ?? '#000000',
      colorRgb: json['color_rgb']?.toString(),
      colorArabicName: json['color_arabic_name']?.toString() ?? '',
      isPopular: json['is_popular'] ?? false,
      usageCount: json['usage_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// الحصول على لون Flutter
  Color get flutterColor {
    try {
      String hexColor = colorCode.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  /// الحصول على لون النص المناسب
  Color get textColor {
    final color = flutterColor;
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}
