import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
// import 'alwaseet_api_service.dart'; // تم حذف الملف

class OrderSyncService {
  static Timer? _syncTimer;
  static bool _isRunning = false;
  static const Duration _syncInterval = Duration(
    minutes: 2,
  ); // مراقبة كل دقيقتين

  // بدء مراقبة تحديثات الطلبات
  static void startOrderSync() {
    if (_isRunning) {
      debugPrint('🔄 خدمة مراقبة الطلبات تعمل بالفعل');
      return;
    }

    debugPrint('🚀 بدء خدمة مراقبة تحديثات الطلبات من شركة الوسيط');
    _isRunning = true;

    // تشغيل المراقبة فوراً
    _syncOrders();

    // تشغيل المراقبة بشكل دوري
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _syncOrders();
    });
  }

  // إيقاف مراقبة تحديثات الطلبات
  static void stopOrderSync() {
    debugPrint('⏹️ إيقاف خدمة مراقبة تحديثات الطلبات');
    _syncTimer?.cancel();
    _syncTimer = null;
    _isRunning = false;
  }

  // مراقبة وتحديث الطلبات
  static Future<void> _syncOrders() async {
    try {
      debugPrint('🔄 بدء مراقبة تحديثات الطلبات...');

      // جلب جميع الطلبات من شركة الوسيط (معطل مؤقتاً)
      final waseetOrders = <Map<String, dynamic>>[];
      debugPrint('📦 تم جلب ${waseetOrders.length} طلب من شركة الوسيط');

      // جلب الطلبات المحلية من قاعدة البيانات (استبعاد الحالات النهائية)
      final localOrdersResponse = await Supabase.instance.client
          .from('orders')
          .select('id, waseet_qr_id, status')
          .not('waseet_qr_id', 'is', null)
          // ✅ استبعاد الحالات النهائية التي لا تحتاج مراقبة
          .not('status', 'in', ['تم التسليم للزبون', 'الغاء الطلب', 'رفض الطلب', 'delivered', 'cancelled']);

      final localOrders = localOrdersResponse as List<dynamic>;
      debugPrint('💾 تم جلب ${localOrders.length} طلب محلي');

      // إنشاء خريطة للطلبات المحلية للوصول السريع
      final Map<String, Map<String, dynamic>> localOrdersMap = {};
      for (final order in localOrders) {
        final qrId = order['waseet_qr_id']?.toString();
        if (qrId != null) {
          localOrdersMap[qrId] = order;
        }
      }

      // مراجعة كل طلب من الوسيط وتحديث الحالة المحلية
      for (final waseetOrder in waseetOrders) {
        final qrId = waseetOrder['id']?.toString();
        final waseetStatus = waseetOrder['status']?.toString();
        final statusId = waseetOrder['status_id']?.toString();

        if (qrId == null || waseetStatus == null) continue;

        final localOrder = localOrdersMap[qrId];
        if (localOrder != null) {
          final localStatus = localOrder['status']?.toString();

          // تحويل حالة الوسيط إلى حالة محلية
          final newLocalStatus = _mapWaseetStatusToLocal(
            statusId,
            waseetStatus,
          );

          // تحديث الحالة إذا كانت مختلفة
          if (localStatus != newLocalStatus) {
            // ✅ فحص إذا كانت الحالة الحالية نهائية
            final finalStatuses = ['تم التسليم للزبون', 'الغاء الطلب', 'رفض الطلب', 'delivered', 'cancelled'];
            if (localStatus != null && finalStatuses.contains(localStatus)) {
              debugPrint('⏹️ تم تجاهل تحديث الطلب $qrId - الحالة نهائية: $localStatus');
              continue;
            }

            debugPrint(
              '🔄 تحديث حالة الطلب $qrId من "$localStatus" إلى "$newLocalStatus"',
            );

            await Supabase.instance.client
                .from('orders')
                .update({
                  'status': newLocalStatus,
                  'waseet_status': waseetStatus,
                  'waseet_status_id': statusId,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('waseet_qr_id', qrId);

            debugPrint('✅ تم تحديث حالة الطلب $qrId بنجاح');

            // إرسال إشعار تغيير حالة الطلب للعميل
            await _sendOrderStatusNotification(
              qrId: qrId,
              orderId: localOrder['id']?.toString() ?? '',
              customerPhone: localOrder['customer_phone']?.toString() ?? '',
              newStatus: newLocalStatus,
              waseetStatus: waseetStatus,
            );
          }
        } else {
          // الطلب موجود في الوسيط ولكن غير موجود محلياً
          // يمكن إضافة منطق لإنشاء الطلب محلياً إذا لزم الأمر
          debugPrint('⚠️ الطلب $qrId موجود في الوسيط ولكن غير موجود محلياً');
        }
      }

      debugPrint('✅ تم الانتهاء من مراقبة تحديثات الطلبات');
    } catch (e) {
      debugPrint('❌ خطأ في مراقبة تحديثات الطلبات: $e');
    }
  }

  // تحويل حالة الوسيط إلى حالة محلية
  static String _mapWaseetStatusToLocal(String? statusId, String waseetStatus) {
    // خريطة تحويل حالات الوسيط إلى حالات محلية
    switch (statusId) {
      case '1':
        return 'confirmed'; // تم الاستلام من قبل المندوب
      case '2':
        return 'confirmed'; // تم استلام الطلب من قبل المندوب
      case '3':
        return 'in_transit'; // في الطريق
      case '4':
        return 'delivered'; // تم التسليم
      case '5':
        return 'cancelled'; // ملغي
      case '6':
        return 'returned'; // مرتجع
      case '7':
        return 'pending'; // في الانتظار
      default:
        // إذا لم نتمكن من تحديد الحالة، نستخدم النص كما هو
        if (waseetStatus.contains('تم التسليم') ||
            waseetStatus.contains('مسلم')) {
          return 'delivered';
        } else if (waseetStatus.contains('ملغي') ||
            waseetStatus.contains('مرفوض')) {
          return 'cancelled';
        } else if (waseetStatus.contains('في الطريق') ||
            waseetStatus.contains('خرج للتوصيل')) {
          return 'in_transit';
        } else if (waseetStatus.contains('مؤكد') ||
            waseetStatus.contains('استلام')) {
          return 'confirmed';
        } else if (waseetStatus.contains('مرتجع') ||
            waseetStatus.contains('إرجاع')) {
          return 'returned';
        } else {
          return 'pending';
        }
    }
  }

  // إنشاء طلب محلي بحالة "نشط" (بدون إرسال للوسيط)
  static Future<String?> createLocalOrder({
    required String customerName,
    required String primaryPhone,
    String? secondaryPhone,
    required String province,
    required String city,
    String? provinceId, // ✅ إضافة معرف المحافظة
    String? cityId, // ✅ إضافة معرف المدينة
    String? regionId, // ✅ إضافة معرف المنطقة
    String? notes,
    required List<dynamic> items,
    required Map<String, int> totals,
    Map<String, dynamic>? waseetData, // بيانات الوسيط للاستخدام لاحقاً
  }) async {
    try {
      debugPrint('💾 إنشاء طلب محلي بحالة "نشط"...');

      // إنشاء معرف فريد للطلب
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      // تحضير بيانات الطلب المحلي
      final orderData = {
        'id': orderId,
        'customer_name': customerName,
        'primary_phone': primaryPhone,
        'secondary_phone': secondaryPhone,
        'province': province,
        'city': city,
        'province_id': provinceId, // ✅ إضافة معرف المحافظة
        'city_id': cityId, // ✅ إضافة معرف المدينة
        'region_id': regionId, // ✅ إضافة معرف المنطقة
        'customer_address': '$province - $city', // ✅ العنوان الكامل
        'notes': notes,
        'status': 'active', // حالة نشط - بانتظار الموافقة
        'total': totals['total'],
        'subtotal': totals['subtotal'],
        'delivery_fee': totals['deliveryFee'],
        'profit': totals['profit'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        // حفظ بيانات الوسيط للاستخدام عند الموافقة
        'waseet_data': waseetData != null ? json.encode(waseetData) : null,
      };

      // إدراج الطلب في قاعدة البيانات
      await Supabase.instance.client.from('orders').insert(orderData);

      debugPrint('✅ تم إنشاء الطلب المحلي برقم: $orderId');

      // إدراج عناصر الطلب
      for (final item in items) {
        await Supabase.instance.client.from('order_items').insert({
          'order_id': orderId,
          'product_name': item.name,
          'quantity': item.quantity,
          'price': item.price,
          'profit_per_item': item.profit ?? 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ تم إدراج ${items.length} عنصر للطلب $orderId');
      return orderId;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب المحلي: $e');
      return null;
    }
  }

  // إنشاء طلب محلي مع ربطه بشركة الوسيط
  static Future<int?> createLocalOrderWithWaseet({
    required Map<String, dynamic> waseetOrderData,
    required String customerName,
    required String primaryPhone,
    String? secondaryPhone,
    required String province,
    required String city,
    String? notes,
    required List<dynamic> items,
    required Map<String, int> totals,
  }) async {
    try {
      debugPrint('💾 إنشاء طلب محلي مع ربطه بشركة الوسيط...');

      // تحضير بيانات الطلب المحلي
      final orderData = {
        'customer_name': customerName,
        'primary_phone': primaryPhone,
        'secondary_phone': secondaryPhone,
        'province': province,
        'city': city,
        'notes': notes,
        'status': 'confirmed', // الطلب مؤكد لأنه تم إنشاؤه في الوسيط
        'total': totals['total'],
        'subtotal': totals['subtotal'],
        'delivery_fee': totals['deliveryFee'],
        'profit': totals['profit'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        // بيانات الوسيط
        'waseet_qr_id': waseetOrderData['qr_id']?.toString(),
        'waseet_status': waseetOrderData['status']?.toString(),
        'waseet_status_id': waseetOrderData['status_id']?.toString(),
        'waseet_delivery_price': waseetOrderData['company_price']?.toString(),
        'waseet_merchant_price': waseetOrderData['merchant_price']?.toString(),
        'waseet_order_data': json.encode(waseetOrderData),
      };

      // إدراج الطلب في قاعدة البيانات
      final response = await Supabase.instance.client
          .from('orders')
          .insert(orderData)
          .select('id')
          .single();

      final orderId = response['id'] as int;
      debugPrint('✅ تم إنشاء الطلب المحلي برقم: $orderId');

      // إدراج عناصر الطلب
      for (final item in items) {
        await Supabase.instance.client.from('order_items').insert({
          'order_id': orderId,
          'product_name': item.name,
          'quantity': item.quantity,
          'price': item.price,
          'profit_per_item': item.profit ?? 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ تم إدراج ${items.length} عنصر للطلب $orderId');
      return orderId;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب المحلي: $e');
      return null;
    }
  }

  // إرسال طلب إلى شركة الوسيط باستخدام API الجديد V2.3
  static Future<Map<String, dynamic>?> _sendOrderToWaseetAPI({
    required String clientName,
    required String clientMobile,
    String? clientMobile2,
    required String cityId,
    required String regionId,
    required String location,
    required String typeName,
    required int itemsNumber,
    required int price,
    required String packageSize,
    String? merchantNotes,
    required int replacement,
  }) async {
    try {
      debugPrint('🌐 إرسال طلب إلى شركة الوسيط عبر Proxy Server...');

      final response = await http.post(
        Uri.parse('http://localhost:3003/api/send-order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_name': clientName,
          'client_mobile': clientMobile,
          'client_mobile2': clientMobile2,
          'city_id': cityId,
          'region_id': regionId,
          'location': location,
          'type_name': typeName,
          'items_number': itemsNumber,
          'price': price,
          'package_size': packageSize,
          'merchant_notes': merchantNotes,
          'replacement': replacement,
        }),
      );

      debugPrint('📡 استجابة Proxy Server: ${response.statusCode}');
      debugPrint('📄 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ تم إرسال الطلب بنجاح إلى شركة الوسيط');
          return responseData['data'];
        } else {
          debugPrint('❌ فشل في إرسال الطلب: ${responseData['message']}');
          return null;
        }
      } else {
        debugPrint('❌ خطأ في الاتصال بـ Proxy Server: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الطلب إلى شركة الوسيط: $e');
      return null;
    }
  }

  // إرسال طلب إلى شركة الوسيط عند تغيير الحالة إلى "قيد التوصيل"
  static Future<bool> sendOrderToWaseet(String orderId) async {
    try {
      debugPrint('📦 إرسال الطلب $orderId إلى شركة الوسيط...');

      // جلب بيانات الطلب من قاعدة البيانات
      final orderResponse = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      // استخراج بيانات الوسيط المحفوظة
      final waseetDataString = orderResponse['waseet_data'] as String?;
      if (waseetDataString == null) {
        debugPrint('❌ لا توجد بيانات وسيط محفوظة للطلب $orderId');
        return false;
      }

      final waseetData = json.decode(waseetDataString) as Map<String, dynamic>;

      // إنشاء الطلب في شركة الوسيط باستخدام API الجديد
      final orderResult = await _sendOrderToWaseetAPI(
        clientName: orderResponse['customer_name'],
        clientMobile: orderResponse['primary_phone'],
        clientMobile2: orderResponse['secondary_phone'],
        cityId: waseetData['cityId'],
        regionId: waseetData['regionId'],
        location: orderResponse['notes'] ?? 'عنوان العميل',
        typeName: waseetData['typeName'],
        itemsNumber: waseetData['itemsCount'],
        price: waseetData['totalPrice'],
        packageSize: '1',
        merchantNotes: 'طلب من تطبيق منتجاتي - تم الموافقة عليه',
        replacement: 0,
      );

      if (orderResult != null) {
        debugPrint(
          '✅ تم إنشاء الطلب في شركة الوسيط برقم: ${orderResult['qr_id']}',
        );

        // تحديث الطلب المحلي ببيانات الوسيط
        await Supabase.instance.client
            .from('orders')
            .update({
              'status': 'in_delivery',
              'waseet_qr_id': orderResult['qr_id']?.toString(),
              'waseet_status': orderResult['status']?.toString(),
              'waseet_status_id': orderResult['status_id']?.toString(),
              'waseet_delivery_price': orderResult['company_price']?.toString(),
              'waseet_merchant_price': orderResult['merchant_price']
                  ?.toString(),
              'waseet_order_data': json.encode(orderResult),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId);

        debugPrint('✅ تم تحديث الطلب المحلي ببيانات الوسيط');

        // بدء مراقبة تحديثات هذا الطلب
        startOrderSync();

        return true;
      } else {
        debugPrint('❌ فشل في إنشاء الطلب في شركة الوسيط');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الطلب إلى الوسيط: $e');
      return false;
    }
  }

  // جلب حالات الطلبات من شركة الوسيط وحفظها محلياً
  static Future<void> syncOrderStatuses() async {
    try {
      debugPrint('📊 جلب حالات الطلبات من شركة الوسيط...');

      final statuses = <Map<String, dynamic>>[];
      debugPrint('✅ تم جلب ${statuses.length} حالة طلب');

      // حفظ الحالات في قاعدة البيانات المحلية (إذا كان لديك جدول للحالات)
      for (final status in statuses) {
        debugPrint('📋 حالة: ${status['id']} - ${status['status']}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب حالات الطلبات: $e');
    }
  }

  // فحص حالة طلب معين
  static Future<void> checkOrderStatus(String qrId) async {
    try {
      debugPrint('🔍 فحص حالة الطلب $qrId...');

      final orders = <Map<String, dynamic>>[];
      if (orders.isNotEmpty) {
        final order = orders.first;
        final status = order['status']?.toString();
        final statusId = order['status_id']?.toString();

        debugPrint('📋 حالة الطلب $qrId: $status (ID: $statusId)');

        // تحديث الحالة المحلية
        final newLocalStatus = _mapWaseetStatusToLocal(statusId, status ?? '');

        // ✅ فحص الحالة الحالية قبل التحديث
        final currentOrderResponse = await Supabase.instance.client
            .from('orders')
            .select('status')
            .eq('waseet_qr_id', qrId)
            .single();

        final currentStatus = currentOrderResponse['status'] as String?;

        // ✅ تجاهل التحديث إذا كانت الحالة الحالية نهائية
        final finalStatuses = ['تم التسليم للزبون', 'الغاء الطلب', 'رفض الطلب', 'delivered', 'cancelled'];
        if (currentStatus != null && finalStatuses.contains(currentStatus)) {
          debugPrint('⏹️ تم تجاهل تحديث الطلب $qrId - الحالة نهائية: $currentStatus');
          return;
        }

        await Supabase.instance.client
            .from('orders')
            .update({
              'status': newLocalStatus,
              'waseet_status': status,
              'waseet_status_id': statusId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('waseet_qr_id', qrId);

        debugPrint('✅ تم تحديث حالة الطلب $qrId محلياً');
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص حالة الطلب: $e');
    }
  }

  /// إرسال إشعار تغيير حالة الطلب عبر خادم الإشعارات
  static Future<void> _sendOrderStatusNotification({
    required String qrId,
    required String orderId,
    required String customerPhone,
    required String newStatus,
    required String waseetStatus,
  }) async {
    try {
      debugPrint('📤 إرسال إشعار تغيير حالة الطلب $qrId');

      if (customerPhone.isEmpty) {
        debugPrint('⚠️ لا يوجد رقم هاتف للعميل');
        return;
      }

      // تحديد رسالة الإشعار حسب الحالة
      String title = '';
      String message = '';

      switch (newStatus) {
        case 'pending':
          title = '⏳ طلبك قيد المراجعة';
          message = 'طلبك رقم $qrId قيد المراجعة وسيتم تأكيده قريباً';
          break;
        case 'confirmed':
          title = '✅ تم تأكيد طلبك';
          message = 'تم تأكيد طلبك رقم $qrId وسيتم شحنه قريباً';
          break;
        case 'in_transit':
          title = '🚚 طلبك في الطريق';
          message = 'طلبك رقم $qrId في الطريق إليك الآن';
          break;
        case 'delivered':
          title = '🎉 تم تسليم طلبك';
          message = 'تم تسليم طلبك رقم $qrId بنجاح! نشكرك لثقتك بنا';
          break;
        case 'cancelled':
          title = '❌ تم إلغاء طلبك';
          message = 'تم إلغاء طلبك رقم $qrId';
          break;
        case 'returned':
          title = '↩️ تم إرجاع طلبك';
          message = 'تم إرجاع طلبك رقم $qrId';
          break;
        default:
          title = '🔄 تحديث حالة الطلب';
          message =
              'تم تحديث حالة طلبك رقم $qrId إلى: ${waseetStatus.isNotEmpty ? waseetStatus : newStatus}';
      }

      // إرسال الإشعار عبر خادم الإشعارات على Render
      final response = await http.post(
        Uri.parse('https://montajati-backend.onrender.com/api/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userPhone': customerPhone,
          'title': title,
          'message': message,
          'data': {
            'type': 'order_status_update',
            'orderId': orderId,
            'qrId': qrId,
            'newStatus': newStatus,
            'waseetStatus': waseetStatus,
            'timestamp': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ تم إرسال إشعار تغيير حالة الطلب بنجاح');
          debugPrint('📋 معرف الرسالة: ${responseData['data']['messageId']}');
        } else {
          debugPrint('❌ فشل إرسال الإشعار: ${responseData['message']}');
        }
      } else {
        debugPrint('❌ خطأ في الاتصال بخادم الإشعارات: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار تغيير حالة الطلب: $e');
    }
  }
}
