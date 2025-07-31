import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scheduled_order.dart';
import 'simple_orders_service.dart';

class ScheduledOrdersService extends ChangeNotifier {
  static final ScheduledOrdersService _instance =
      ScheduledOrdersService._internal();
  factory ScheduledOrdersService() => _instance;
  ScheduledOrdersService._internal();

  final List<ScheduledOrder> _scheduledOrders = [];
  bool _isLoading = false;

  List<ScheduledOrder> get scheduledOrders =>
      List.unmodifiable(_scheduledOrders);
  bool get isLoading => _isLoading;

  // تحميل الطلبات المجدولة من قاعدة البيانات
  Future<void> loadScheduledOrders({String? userPhone}) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔄 بدء تحميل الطلبات المجدولة من قاعدة البيانات...');

      // جلب الطلبات المجدولة مع أسماء المحافظات والمدن
      var query = Supabase.instance.client
          .from('scheduled_orders')
          .select('''
            *,
            scheduled_order_items (
              id,
              product_name,
              quantity,
              price,
              notes,
              product_id,
              product_image
            )
          ''')
          .eq('is_converted', false);

      // فلترة حسب المستخدم إذا تم تمرير رقم الهاتف
      if (userPhone != null && userPhone.isNotEmpty) {
        query = query.eq('user_phone', userPhone);
        debugPrint('🔍 فلترة الطلبات المجدولة للمستخدم: $userPhone');
      }

      final response = await query.order('created_at', ascending: false);

      debugPrint('📋 استلام ${response.length} طلب مجدول من قاعدة البيانات');

      _scheduledOrders.clear();

      for (final orderData in response) {
        try {
          // جلب عناصر الطلب من البيانات المدمجة
          final items =
              (orderData['scheduled_order_items'] as List<dynamic>?)
                  ?.map(
                    (item) => ScheduledOrderItem(
                      name: item['product_name'] ?? '',
                      quantity: (item['quantity'] ?? 0).toInt(),
                      price: (item['price'] ?? 0.0).toDouble(),
                      notes: item['notes'] ?? '',
                      productId: item['product_id'], // ✅ إضافة معرف المنتج
                      productImage:
                          item['product_image'], // ✅ إضافة صورة المنتج
                    ),
                  )
                  .toList() ??
              [];

          // استخدام أسماء المحافظة والمدينة مباشرة من الأعمدة الجديدة (نفس نظام الطلبات العادية)
          String? provinceName =
              orderData['province'] ?? orderData['customer_province'];
          String? cityName = orderData['city'] ?? orderData['customer_city'];

          debugPrint('🏛️ اسم المحافظة: $provinceName');
          debugPrint('🏙️ اسم المدينة: $cityName');

          final order = ScheduledOrder(
            id: orderData['id'] ?? '',
            orderNumber: orderData['order_number'] ?? '',
            customerName: orderData['customer_name'] ?? '',
            customerPhone: orderData['customer_phone'] ?? '',
            customerAlternatePhone: orderData['customer_alternate_phone'],
            customerAddress: orderData['customer_address'] ?? '',
            customerProvince: orderData['customer_province'],
            customerCity: orderData['customer_city'],
            province: provinceName, // استخدام العمود الجديد
            city: cityName, // استخدام العمود الجديد
            provinceId: orderData['province_id'],
            cityId: orderData['city_id'],
            customerNotes: orderData['customer_notes'],
            totalAmount:
                (orderData['total_amount'] ?? orderData['total'] ?? 0.0)
                    .toDouble(),
            scheduledDate: DateTime.parse(orderData['scheduled_date']),
            createdAt: DateTime.parse(orderData['created_at']),
            notes: orderData['notes'] ?? '',
            items: items,
            priority: orderData['priority'] ?? 'متوسطة',
            reminderSent: orderData['reminder_sent'] ?? false,
          );

          _scheduledOrders.add(order);
        } catch (e) {
          debugPrint('❌ خطأ في معالجة طلب مجدول: $e');
        }
      }

      // ✅ ترتيب نهائي للطلبات المجدولة لضمان أن الأحدث دائماً في المقدمة
      _scheduledOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('✅ تم تحميل ${_scheduledOrders.length} طلب مجدول بنجاح مع الترتيب الصحيح');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الطلبات المجدولة: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // إضافة طلب مجدول جديد
  Future<Map<String, dynamic>> addScheduledOrder({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double totalAmount,
    required DateTime scheduledDate,
    required List<ScheduledOrderItem> items,
    String? notes,
    String priority = 'متوسطة',
    String? customerAlternatePhone,
    String? customerProvince, // اسم المحافظة للعرض
    String? customerCity, // اسم المدينة للعرض
    String? provinceId, // معرف المحافظة في قاعدة البيانات
    String? cityId, // معرف المدينة في قاعدة البيانات
    String? customerNotes,
    double? deliveryCost,
    double? profitAmount,
    String? userPhone, // ✅ إضافة رقم هاتف المستخدم
  }) async {
    try {
      debugPrint('🔄 بدء إنشاء طلب مجدول جديد...');

      // التحقق من صحة البيانات الأساسية
      if (customerName.trim().isEmpty) {
        throw Exception('اسم العميل مطلوب');
      }

      if (customerPhone.trim().isEmpty) {
        throw Exception('رقم هاتف العميل مطلوب');
      }

      if (items.isEmpty) {
        throw Exception('يجب أن يحتوي الطلب على عنصر واحد على الأقل');
      }

      debugPrint('✅ تم التحقق من صحة البيانات الأساسية');

      // توليد رقم طلب فريد
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderNumber = 'SCH-${timestamp.toString().substring(8)}';

      // جلب أسماء المحافظة والمدينة من المعرفات
      String? provinceName;
      String? cityName;

      debugPrint('🔍 جلب أسماء المحافظة والمدينة...');
      debugPrint('🏛️ معرف المحافظة: $provinceId');
      debugPrint('🏙️ معرف المدينة: $cityId');

      if (provinceId != null) {
        try {
          final provinceResponse = await Supabase.instance.client
              .from('provinces')
              .select('name')
              .eq('id', provinceId)
              .single();
          provinceName = provinceResponse['name'];
          debugPrint('✅ تم جلب اسم المحافظة: $provinceName');
        } catch (e) {
          debugPrint('❌ خطأ في جلب اسم المحافظة: $e');
        }
      }

      if (cityId != null) {
        try {
          final cityResponse = await Supabase.instance.client
              .from('cities')
              .select('name')
              .eq('id', cityId)
              .single();
          cityName = cityResponse['name'];
          debugPrint('✅ تم جلب اسم المدينة: $cityName');
        } catch (e) {
          debugPrint('❌ خطأ في جلب اسم المدينة: $e');
        }
      }

      // إنشاء الطلب المجدول
      debugPrint('💾 حفظ الطلب المجدول مع البيانات التالية:');
      debugPrint('🏛️ المحافظة: ${provinceName ?? customerProvince}');
      debugPrint('🏙️ المدينة: ${cityName ?? customerCity}');

      final orderResponse = await Supabase.instance.client
          .from('scheduled_orders')
          .insert({
            'order_number': orderNumber,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'customer_alternate_phone': customerAlternatePhone,
            'customer_province':
                customerProvince, // للتوافق مع البيانات القديمة
            'customer_city': customerCity, // للتوافق مع البيانات القديمة
            'province':
                provinceName ??
                customerProvince, // الاسم المباشر (نفس نظام الطلبات العادية)
            'city':
                cityName ??
                customerCity, // الاسم المباشر (نفس نظام الطلبات العادية)
            'province_id': provinceId, // معرف المحافظة الجديد
            'city_id': cityId, // معرف المدينة الجديد
            'customer_address': customerAddress,
            'customer_notes': customerNotes,
            'total_amount':
                totalAmount, // ✅ استخدام total_amount بدلاً من total
            'delivery_cost': deliveryCost ?? 0,
            'profit_amount':
                profitAmount ?? 0, // ✅ استخدام profit_amount بدلاً من profit
            'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
            'priority': priority,
            'notes': notes,
            'reminder_sent': false,
            'is_converted': false,
            'user_phone': userPhone, // ✅ إضافة رقم هاتف المستخدم
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // إضافة عناصر الطلب
      if (items.isNotEmpty) {
        debugPrint('📦 إضافة ${items.length} عنصر للطلب المجدول...');

        final itemsData = items
            .where((item) => item.name.isNotEmpty && item.quantity > 0)
            .map(
              (item) => {
                'scheduled_order_id': orderId,
                'product_name': item.name.trim(),
                'quantity': item.quantity,
                'price': item.price,
                'notes': item.notes.trim(),
                'product_id': item.productId, // ✅ إضافة معرف المنتج
                'product_image': item.productImage, // ✅ إضافة صورة المنتج
              },
            )
            .toList();

        if (itemsData.isEmpty) {
          throw Exception('لا توجد عناصر صالحة لإضافتها للطلب');
        }

        await Supabase.instance.client
            .from('scheduled_order_items')
            .insert(itemsData);

        debugPrint('✅ تم إضافة ${itemsData.length} عنصر بنجاح');
      }

      // ✅ الأرباح ستُضاف تلقائياً بواسطة Database Trigger
      debugPrint('💰 سيتم إضافة الأرباح تلقائياً بواسطة Database Trigger');

      // إضافة الطلب للقائمة المحلية
      final newOrder = ScheduledOrder(
        id: orderId,
        orderNumber: orderNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAlternatePhone: customerAlternatePhone,
        customerAddress: customerAddress,
        customerProvince: customerProvince,
        customerCity: customerCity,
        provinceId: provinceId,
        cityId: cityId,
        customerNotes: customerNotes,
        totalAmount: totalAmount,
        scheduledDate: scheduledDate,
        createdAt: DateTime.now(),
        notes: notes ?? '',
        items: items,
        priority: priority,
        reminderSent: false,
      );

      _scheduledOrders.add(newOrder);
      _scheduledOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();

      debugPrint('✅ تم إنشاء الطلب المجدول بنجاح: $orderNumber');

      return {
        'success': true,
        'message': 'تم إنشاء الطلب المجدول بنجاح',
        'orderId': orderId,
        'orderNumber': orderNumber,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب المجدول: $e');
      return {
        'success': false,
        'message': 'فشل في إنشاء الطلب المجدول: ${e.toString()}',
      };
    }
  }

  // تحويل الطلبات المجدولة إلى طلبات نشطة تلقائياً
  Future<int> convertScheduledOrdersToActive() async {
    try {
      debugPrint('🔄 بدء التحويل التلقائي للطلبات المجدولة...');

      // تعطيل التحويل التلقائي مؤقتاً بسبب مشكلة في قاعدة البيانات
      debugPrint(
        '⚠️ التحويل التلقائي معطل مؤقتاً - يتطلب إصلاح قاعدة البيانات',
      );
      return 0;

      // الكود الأصلي معطل مؤقتاً
      /*
      final result = await Supabase.instance.client.rpc(
        'convert_scheduled_orders_to_active',
      );

      final convertedCount = result as int? ?? 0;

      debugPrint('✅ تم تحويل $convertedCount طلب مجدول إلى نشط');

      // إعادة تحميل الطلبات المجدولة لتحديث القائمة
      if (convertedCount > 0) {
        await loadScheduledOrders();
      }

      return convertedCount;
      */
    } catch (e) {
      debugPrint('❌ خطأ في التحويل التلقائي: $e');
      return 0;
    }
  }

  // حذف طلب مجدول
  Future<bool> deleteScheduledOrder(String orderId) async {
    try {
      await Supabase.instance.client
          .from('scheduled_orders')
          .delete()
          .eq('id', orderId);

      _scheduledOrders.removeWhere((order) => order.id == orderId);
      notifyListeners();

      debugPrint('✅ تم حذف الطلب المجدول: $orderId');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الطلب المجدول: $e');
      return false;
    }
  }

  // تحديث حالة إرسال التذكير
  Future<bool> updateReminderStatus(String orderId, bool sent) async {
    try {
      await Supabase.instance.client
          .from('scheduled_orders')
          .update({'reminder_sent': sent})
          .eq('id', orderId);

      final index = _scheduledOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        // إنشاء نسخة جديدة مع تحديث حالة التذكير
        final updatedOrder = ScheduledOrder(
          id: _scheduledOrders[index].id,
          orderNumber: _scheduledOrders[index].orderNumber,
          customerName: _scheduledOrders[index].customerName,
          customerPhone: _scheduledOrders[index].customerPhone,
          customerAddress: _scheduledOrders[index].customerAddress,
          totalAmount: _scheduledOrders[index].totalAmount,
          scheduledDate: _scheduledOrders[index].scheduledDate,
          createdAt: _scheduledOrders[index].createdAt,
          notes: _scheduledOrders[index].notes,
          items: _scheduledOrders[index].items,
          priority: _scheduledOrders[index].priority,
          reminderSent: sent,
        );

        _scheduledOrders[index] = updatedOrder;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة التذكير: $e');
      return false;
    }
  }

  // الحصول على الطلبات المجدولة لتاريخ معين
  List<ScheduledOrder> getOrdersForDate(DateTime date) {
    return _scheduledOrders.where((order) {
      return order.scheduledDate.year == date.year &&
          order.scheduledDate.month == date.month &&
          order.scheduledDate.day == date.day;
    }).toList();
  }

  // الحصول على الطلبات المتأخرة
  List<ScheduledOrder> getOverdueOrders() {
    final now = DateTime.now();
    return _scheduledOrders.where((order) {
      return order.scheduledDate.isBefore(now) &&
          !_isSameDay(order.scheduledDate, now);
    }).toList();
  }

  // الحصول على طلبات اليوم
  List<ScheduledOrder> getTodayOrders() {
    return getOrdersForDate(DateTime.now());
  }

  // الحصول على طلبات الغد
  List<ScheduledOrder> getTomorrowOrders() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return getOrdersForDate(tomorrow);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // تشغيل التحويل التلقائي دورياً (يمكن استدعاؤها من التطبيق)
  Future<void> runPeriodicConversion() async {
    debugPrint('🔄 تشغيل التحويل التلقائي الدوري...');
    await convertScheduledOrdersToActive();
  }

  // تحويل طلب مجدول محدد إلى طلب نشط يدوياً
  Future<Map<String, dynamic>> convertScheduledOrderToActive(
    String scheduledOrderId,
  ) async {
    try {
      debugPrint('🔄 بدء تحويل الطلب المجدول $scheduledOrderId إلى طلب نشط...');

      // جلب الطلب المجدول
      final scheduledOrderResponse = await Supabase.instance.client
          .from('scheduled_orders')
          .select('''
            *,
            scheduled_order_items (
              id,
              product_name,
              quantity,
              price,
              notes,
              product_id,
              product_image
            )
          ''')
          .eq('id', scheduledOrderId)
          .eq('is_converted', false)
          .single();

      debugPrint(
        '📋 تم جلب الطلب المجدول: ${scheduledOrderResponse['order_number']}',
      );

      // توليد رقم طلب جديد
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newOrderNumber =
          'ORD-$timestamp-${(1000 + (scheduledOrderResponse['order_number'].hashCode % 9000))}';

      // الحصول على بيانات المستخدم الحالي
      final user = Supabase.instance.client.auth.currentUser;

      // توليد معرف فريد للطلب الجديد
      final newOrderId = DateTime.now().millisecondsSinceEpoch.toString();

      // إنشاء الطلب النشط الجديد - استخدام أسماء الأعمدة الصحيحة
      final orderData = {
        'id': newOrderId, // ✅ تحديد معرف صريح للطلب
        'order_number': newOrderNumber,
        'customer_name': scheduledOrderResponse['customer_name'] ?? 'غير محدد',
        'primary_phone':
            scheduledOrderResponse['customer_phone'] ?? '07xxxxxxxx',
        'secondary_phone':
            scheduledOrderResponse['customer_alternate_phone'] ?? '',
        'province':
            scheduledOrderResponse['province'] ??
            scheduledOrderResponse['customer_province'] ??
            'بغداد',
        'city':
            scheduledOrderResponse['city'] ??
            scheduledOrderResponse['customer_city'] ??
            'الكرخ',
        'customer_address': scheduledOrderResponse['customer_address'] ?? '',
        'customer_notes':
            scheduledOrderResponse['customer_notes'] ??
            scheduledOrderResponse['notes'] ??
            '',
        'subtotal':
            (scheduledOrderResponse['total_amount'] as num?)?.toInt() ??
            (scheduledOrderResponse['total'] as num?)?.toInt() ??
            0,
        'delivery_fee':
            (scheduledOrderResponse['delivery_cost'] as num?)?.toInt() ?? 0,
        'total':
            (scheduledOrderResponse['total_amount'] as num?)?.toInt() ??
            (scheduledOrderResponse['total'] as num?)?.toInt() ??
            0,
        'profit':
            (scheduledOrderResponse['profit_amount'] as num?)?.toInt() ??
            (scheduledOrderResponse['profit'] as num?)?.toInt() ??
            0,
        'status': 'active',
        'user_id': user?.id, // ✅ إضافة معرف المستخدم (UUID أو null)
        'customer_id': null, // ✅ تعيين null صراحة لتجنب مشاكل القيود
        'user_phone':
            scheduledOrderResponse['user_phone'], // ✅ إضافة رقم هاتف المستخدم
        'notes':
            scheduledOrderResponse['customer_notes'] ??
            '', // نسخ الملاحظات الأصلية
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final newOrderResponse = await Supabase.instance.client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      debugPrint('✅ تم إنشاء الطلب النشط: ${newOrderResponse['order_number']}');

      // نسخ عناصر الطلب وتقليل المخزون
      final scheduledItems =
          scheduledOrderResponse['scheduled_order_items'] as List? ?? [];

      if (scheduledItems.isNotEmpty) {
        for (final item in scheduledItems) {
          try {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            final productId = item['product_id'] as String?;
            final productImage = item['product_image'] as String?;

            await Supabase.instance.client.from('order_items').insert({
              'order_id': newOrderResponse['id'],
              'product_name': item['product_name'] ?? 'منتج غير محدد',
              'wholesale_price': 0, // سعر الجملة (افتراضي)
              'customer_price': price, // سعر العميل
              'quantity': quantity,
              'total_price': price * quantity,
              'product_id': productId, // ✅ إضافة معرف المنتج
              'product_image': productImage, // ✅ إضافة صورة المنتج
              'created_at': DateTime.now().toIso8601String(),
            });

            debugPrint('✅ تم نسخ العنصر: ${item['product_name']}');
            debugPrint('📷 صورة المنتج: ${productImage ?? 'غير متوفرة'}');

            // 📝 ملاحظة: تقليل المخزون سيتم في صفحة ملخص الطلب عند النقر على "إتمام الطلب"
            // مثل الطلبات العادية تماماً - لا نقلل المخزون هنا
            debugPrint(
              '📋 تم تحضير عنصر الطلب: ${item['product_name']} (الكمية: $quantity)',
            );
          } catch (itemError) {
            debugPrint(
              '❌ خطأ في نسخ العنصر ${item['product_name']}: $itemError',
            );
            // نستمر في نسخ باقي العناصر حتى لو فشل عنصر واحد
          }
        }
      }

      debugPrint('✅ تم نسخ ${scheduledItems.length} عنصر للطلب الجديد');

      // 📝 ملاحظة: تقليل المخزون تم بالفعل في صفحة ملخص الطلب عند النقر على "إتمام الطلب"
      // مثل الطلبات العادية تماماً - لا نقلل المخزون مرة أخرى هنا
      debugPrint(
        '📋 تثبيت الطلب المجدول - المخزون تم تقليله مسبقاً في ملخص الطلب',
      );

      // تحديث الطلب المجدول كمحول
      await Supabase.instance.client
          .from('scheduled_orders')
          .update({
            'is_converted': true,
            'converted_order_id': newOrderResponse['id'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', scheduledOrderId);

      debugPrint('✅ تم تحديث الطلب المجدول كمحول');

      // ✅ لا حاجة لإضافة الأرباح مرة أخرى عند التثبيت
      // الأرباح تم إضافتها بالفعل عند إنشاء الطلب المجدول
      // والآن سيتم تحويلها من طلب مجدول إلى طلب نشط فقط
      debugPrint('💰 الأرباح موجودة بالفعل في النظام، لا حاجة لإضافة مزدوجة');

      // إزالة الطلب من القائمة المحلية
      _scheduledOrders.removeWhere((order) => order.id == scheduledOrderId);
      notifyListeners();

      // ✅ إعادة تحميل الطلبات العادية لإظهار الطلب الجديد
      try {
        final ordersService = SimpleOrdersService();
        await ordersService.loadOrders(forceRefresh: true);
        debugPrint('✅ تم إعادة تحميل الطلبات العادية بعد التحويل');
      } catch (e) {
        debugPrint('⚠️ خطأ في إعادة تحميل الطلبات العادية: $e');
      }

      return {
        'success': true,
        'message': 'تم تحويل الطلب بنجاح',
        'newOrderNumber': newOrderNumber,
        'newOrderId': newOrderResponse['id'],
      };
    } catch (e) {
      debugPrint('❌ خطأ في تحويل الطلب المجدول: $e');
      return {'success': false, 'message': 'فشل في تحويل الطلب: $e'};
    }
  }
}
