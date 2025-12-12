import 'dart:convert';

import 'package:flutter/foundation.dart';

class Product {
  final String id;

  // 🎯 دالة مساعدة آمنة لتحويل التبليغات من JSON
  static List<String> _parseNotificationTags(dynamic tags) {
    if (tags == null) return <String>[];

    try {
      if (tags is List) {
        // تحويل آمن لكل عنصر في القائمة
        return tags
            .where((tag) => tag != null) // إزالة القيم الفارغة
            .map((tag) => tag.toString())
            .where((tag) => tag.isNotEmpty) // إزالة النصوص الفارغة
            .toList();
      } else if (tags is String && tags.isNotEmpty) {
        // محاولة تحويل النص إلى JSON
        try {
          final decoded = json.decode(tags);
          if (decoded is List) {
            return _parseNotificationTags(decoded);
          }
        } catch (_) {
          // إذا فشل التحويل، إرجاع قائمة فارغة
        }
      }
      return <String>[];
    } catch (e) {
      debugPrint('خطأ في تحويل التبليغات: $e');
      return <String>[];
    }
  }

  // 🖼️ دالة مساعدة آمنة لتحويل الصور من JSON
  // تدعم كلا الحقلين: images (قائمة) و image_url (نص مفرد)
  static List<String> _parseImages(Map<String, dynamic> json) {
    try {
      // 1. أولاً: تحقق من حقل images (القائمة)
      if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
        return List<String>.from(json['images']);
      }

      // 2. ثانياً: تحقق من حقل image_url (نص مفرد - للتوافق مع المنتجات القديمة)
      if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
        return [json['image_url'].toString()];
      }

      // 3. ثالثاً: تحقق من حقل product_image (اسم بديل محتمل)
      if (json['product_image'] != null && json['product_image'].toString().isNotEmpty) {
        return [json['product_image'].toString()];
      }

      return <String>[];
    } catch (e) {
      debugPrint('خطأ في تحويل الصور: $e');
      return <String>[];
    }
  }

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
  final List<String> notificationTags; // 🎯 تبليغات ذكية للمنتج
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
    this.notificationTags = const [], // 🎯 قائمة فارغة افتراضياً
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
      // ✅ دعم كلا الحقلين: images (قائمة) و image_url (نص مفرد)
      images: _parseImages(json),
      minQuantity: json['min_quantity'] ?? 0,
      maxQuantity: json['max_quantity'] ?? 0,
      availableFrom: json['available_from'] ?? 90,
      availableTo: json['available_to'] ?? 80,
      availableQuantity: json['available_quantity'] ?? 100,
      category: json['category']?.toString() ?? '',
      displayOrder: json['display_order'] ?? 999, // قيمة افتراضية عالية
      notificationTags: _parseNotificationTags(json['notification_tags']), // 🎯 تحويل آمن للتبليغات
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
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
      'notification_tags': notificationTags, // 🎯 إضافة التبليغات للـ JSON
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
