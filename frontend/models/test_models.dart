// ملف اختبار للنماذج - Test Models
import 'package:flutter/foundation.dart';
import 'order.dart';
import 'order_item.dart';

void testModels() {
  debugPrint('🧪 اختبار النماذج...');

  // اختبار OrderItem
  final testOrderItem = OrderItem(
    id: '1',
    productId: 'prod_1',
    name: 'منتج تجريبي',
    image: 'https://example.com/product.jpg',
    quantity: 2,
    wholesalePrice: 15.0,
    customerPrice: 25.5,
  );

  debugPrint('✅ تم إنشاء OrderItem: ${testOrderItem.name}');
  debugPrint('   الإجمالي: ${testOrderItem.totalPrice}');
  debugPrint('   الربح: ${testOrderItem.totalProfit}');

  // اختبار Order
  final testOrder = Order(
    id: 'order_1',
    customerName: 'أحمد محمد',
    primaryPhone: '07901234567',
    province: 'بغداد',
    city: 'الكرادة',
    totalCost: 100,
    totalProfit: 50,
    subtotal: 100,
    total: 100,
    status: OrderStatus.pending,
    createdAt: DateTime.now(),
    items: [testOrderItem],
  );

  debugPrint('✅ تم إنشاء Order: ${testOrder.customerName}');
  debugPrint('   الحالة: ${testOrder.statusText}');
  debugPrint('   عدد العناصر: ${testOrder.items.length}');

  // اختبار JSON
  final orderJson = testOrder.toJson();
  debugPrint('✅ تم تحويل إلى JSON');

  final orderFromJson = Order.fromJson(orderJson);
  debugPrint('✅ تم إنشاء من JSON: ${orderFromJson.customerName}');

  debugPrint('🎉 جميع الاختبارات نجحت!');
}
