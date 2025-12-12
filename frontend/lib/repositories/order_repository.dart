import '../models/order_details.dart';
import '../models/update_order_request.dart';
import '../services/order_api_service.dart';
import '../core/error/edit_order_failure.dart';

abstract class OrderRepository {
  Future<OrderDetails> getOrder(String id);
  Future<OrderDetails> getScheduledOrder(String id);
  Future<void> updateOrder(UpdateOrderRequest request);
}

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<OrderDetails> getOrder(String id) async {
    try {
      return await OrderApiService.getOrder(id);
    } catch (e) {
      throw EditOrderFailure.network('فشل تحميل الطلب: ${e.toString()}');
    }
  }

  @override
  Future<OrderDetails> getScheduledOrder(String id) async {
    try {
      return await OrderApiService.getScheduledOrder(id);
    } catch (e) {
      throw EditOrderFailure.network('فشل تحميل الطلب المجدول: ${e.toString()}');
    }
  }

  @override
  Future<void> updateOrder(UpdateOrderRequest request) async {
    try {
      if (request.isScheduled) {
        await OrderApiService.updateScheduledOrder(request.orderId, request.toJson());
      } else {
        await OrderApiService.updateOrder(request.orderId, request.toJson());
      }
    } catch (e) {
      throw EditOrderFailure.network('فشل تحديث الطلب: ${e.toString()}');
    }
  }
}
