import 'package:flutter/foundation.dart';
import 'inventory_service.dart';

// نموذج عنصر السلة
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final int wholesalePrice;
  final int minPrice;
  final int maxPrice;
  int customerPrice;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.wholesalePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.customerPrice,
    this.quantity = 1,
  });

  // تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'image': image,
      'wholesalePrice': wholesalePrice,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'customerPrice': customerPrice,
      'quantity': quantity,
    };
  }

  // إنشاء من Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      productId: map['productId'],
      name: map['name'],
      image: map['image'],
      wholesalePrice: map['wholesalePrice'],
      minPrice: map['minPrice'] ?? 0,
      maxPrice: map['maxPrice'] ?? 0,
      customerPrice: map['customerPrice'],
      quantity: map['quantity'],
    );
  }

  // نسخ مع تعديل
  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? image,
    int? wholesalePrice,
    int? minPrice,
    int? maxPrice,
    int? customerPrice,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      customerPrice: customerPrice ?? this.customerPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

// خدمة إدارة السلة
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  // الحصول على عناصر السلة
  List<CartItem> get items => List.unmodifiable(_items);

  // عدد العناصر في السلة
  int get itemCount => _items.length;

  // التحقق من وجود منتج في السلة
  bool hasProduct(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  // الحصول على عنصر من السلة
  CartItem? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // إضافة منتج إلى السلة بدون حجز الكمية (سيتم الحجز عند إتمام الطلب)
  Future<Map<String, dynamic>> addItem({
    required String productId,
    required String name,
    required String image,
    required int wholesalePrice,
    required int minPrice,
    required int maxPrice,
    required int customerPrice,
    int quantity = 1,
  }) async {
    try {
      // 1. التحقق من توفر الكمية فقط (بدون حجز)
      final availabilityCheck = await InventoryService.checkAvailability(
        productId: productId,
        requestedQuantity: quantity,
      );

      if (!availabilityCheck['success'] || !availabilityCheck['is_available']) {
        // التحقق من نفاد المخزون وإرسال إشعار
        final maxAvailable = availabilityCheck['max_available'] ?? 0;
        if (maxAvailable <= 0) {
          await InventoryService.checkAndNotifyOutOfStock(productId);
        }

        return {
          'success': false,
          'message': 'الكمية المطلوبة غير متوفرة',
          'max_available': maxAvailable,
        };
      }

      // 2. إضافة المنتج للسلة (بدون حجز المخزون)
      final existingItemIndex = _items.indexWhere(
        (item) => item.productId == productId,
      );

      if (existingItemIndex >= 0) {
        // إذا كان المنتج موجود، زيادة الكمية
        _items[existingItemIndex] = _items[existingItemIndex].copyWith(
          quantity: _items[existingItemIndex].quantity + quantity,
          customerPrice: customerPrice, // تحديث السعر
        );
      } else {
        // إضافة منتج جديد
        _items.add(
          CartItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: productId,
            name: name,
            image: image,
            wholesalePrice: wholesalePrice,
            minPrice: minPrice,
            maxPrice: maxPrice,
            customerPrice: customerPrice,
            quantity: quantity,
          ),
        );
      }

      notifyListeners();

      return {'success': true, 'message': 'تم إضافة المنتج للسلة بنجاح'};
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج للسلة: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام',
        'error': e.toString(),
      };
    }
  }

  // تحديث كمية منتج
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final itemIndex = _items.indexWhere((item) => item.productId == productId);
    if (itemIndex >= 0) {
      _items[itemIndex] = _items[itemIndex].copyWith(quantity: newQuantity);
      notifyListeners();
    }
  }

  // تحديث سعر منتج
  void updatePrice(String productId, int newPrice) {
    final itemIndex = _items.indexWhere((item) => item.productId == productId);
    if (itemIndex >= 0) {
      _items[itemIndex] = _items[itemIndex].copyWith(customerPrice: newPrice);
      notifyListeners();
    }
  }

  // حذف منتج من السلة
  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  // مسح السلة بالكامل
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // حساب المجاميع
  Map<String, int> calculateTotals({int deliveryFee = 5000, int discount = 0}) {
    int subtotal = 0;
    int totalCost = 0;
    int totalProfit = 0;

    for (var item in _items) {
      subtotal += item.customerPrice * item.quantity;
      totalCost += item.wholesalePrice * item.quantity;
      totalProfit += (item.customerPrice - item.wholesalePrice) * item.quantity;
    }

    final total = subtotal + deliveryFee - discount;
    final profit = totalProfit;

    return {
      'subtotal': subtotal,
      'totalCost': totalCost,
      'profit': profit,
      'total': total,
      'deliveryFee': deliveryFee,
      'discount': discount,
    };
  }

  // حجز المنتجات عند إتمام الطلب
  Future<Map<String, dynamic>> reserveCartItems() async {
    try {
      List<Map<String, dynamic>> reservationResults = [];
      bool allReservationsSuccessful = true;
      String errorMessage = '';

      for (var item in _items) {
        final result = await InventoryService.reserveProduct(
          productId: item.productId,
          reservedQuantity: item.quantity,
        );

        reservationResults.add({
          'product_id': item.productId,
          'product_name': item.name,
          'quantity': item.quantity,
          'result': result,
        });

        if (!result['success']) {
          allReservationsSuccessful = false;
          errorMessage += '${item.name}: ${result['message']}\n';
        }
      }

      if (allReservationsSuccessful) {
        // إذا نجحت جميع الحجوزات، امسح السلة
        clearCart();
        return {
          'success': true,
          'message': 'تم حجز جميع المنتجات بنجاح',
          'reservations': reservationResults,
        };
      } else {
        // إذا فشل أي حجز، ألغِ جميع الحجوزات الناجحة
        for (var reservation in reservationResults) {
          if (reservation['result']['success']) {
            await InventoryService.cancelReservation(
              productId: reservation['product_id'],
              returnedQuantity: reservation['quantity'],
            );
          }
        }

        return {
          'success': false,
          'message': 'فشل في حجز بعض المنتجات:\n$errorMessage',
          'reservations': reservationResults,
        };
      }
    } catch (e) {
      debugPrint('❌ خطأ في حجز منتجات السلة: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام',
        'error': e.toString(),
      };
    }
  }

  // التحقق من توفر جميع منتجات السلة
  Future<Map<String, dynamic>> checkCartAvailability() async {
    try {
      List<Map<String, dynamic>> availabilityResults = [];
      bool allAvailable = true;
      String warningMessage = '';

      for (var item in _items) {
        final result = await InventoryService.checkAvailability(
          productId: item.productId,
          requestedQuantity: item.quantity,
        );

        availabilityResults.add({
          'product_id': item.productId,
          'product_name': item.name,
          'requested_quantity': item.quantity,
          'result': result,
        });

        if (result['success'] && !result['is_available']) {
          allAvailable = false;
          warningMessage +=
              '${item.name}: متوفر حتى ${result['max_available']} قطعة فقط\n';
        }
      }

      return {
        'success': true,
        'all_available': allAvailable,
        'message': allAvailable ? 'جميع المنتجات متوفرة' : warningMessage,
        'availability': availabilityResults,
      };
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من توفر منتجات السلة: $e');
      return {
        'success': false,
        'message': 'خطأ في النظام',
        'error': e.toString(),
      };
    }
  }

  // تنسيق الأسعار
  String formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
