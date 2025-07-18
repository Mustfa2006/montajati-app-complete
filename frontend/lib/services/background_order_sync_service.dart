import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import 'alwaseet_api_service.dart'; // تم حذف الملف
import 'notification_service.dart';

/// خدمة مراقبة الطلبات في الخلفية بشكل مستمر
/// تعمل حتى لو كان التطبيق مغلق أو المستخدم غير نشط
class BackgroundOrderSyncService {
  static Timer? _syncTimer;
  static Timer? _heartbeatTimer;
  static bool _isRunning = false;
  static bool _isInitialized = false;
  static Isolate? _backgroundIsolate;
  static ReceivePort? _receivePort;

  // إعدادات المراقبة
  static const Duration _syncInterval = Duration(minutes: 1); // كل دقيقة
  static const Duration _heartbeatInterval = Duration(
    seconds: 30,
  ); // نبضة كل 30 ثانية
  static const String _lastSyncKey = 'last_order_sync';
  static const String _syncEnabledKey = 'order_sync_enabled';

  /// تهيئة خدمة المراقبة
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 تهيئة خدمة مراقبة الطلبات في الخلفية...');

      // تهيئة خدمة الإشعارات
      await NotificationService.initialize();

      // التحقق من إعدادات المراقبة
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool(_syncEnabledKey) ?? true;

      if (syncEnabled) {
        await _startBackgroundSync();
      }

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة مراقبة الطلبات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة مراقبة الطلبات: $e');
    }
  }

  /// بدء المراقبة في الخلفية
  static Future<void> _startBackgroundSync() async {
    if (_isRunning) {
      debugPrint('⚠️ خدمة المراقبة تعمل بالفعل');
      return;
    }

    try {
      debugPrint('🔄 بدء مراقبة الطلبات في الخلفية...');
      _isRunning = true;

      // إنشاء Isolate للعمل في الخلفية
      _receivePort = ReceivePort();
      _backgroundIsolate = await Isolate.spawn(
        _backgroundSyncWorker,
        _receivePort!.sendPort,
      );

      // الاستماع لرسائل من الـ Isolate
      _receivePort!.listen((message) {
        _handleBackgroundMessage(message);
      });

      // بدء المراقبة الرئيسية
      _startMainSync();

      // بدء نبضة الحياة
      _startHeartbeat();

      debugPrint('✅ تم بدء مراقبة الطلبات في الخلفية');
    } catch (e) {
      debugPrint('❌ خطأ في بدء مراقبة الطلبات: $e');
      _isRunning = false;
    }
  }

  /// العامل الذي يعمل في الخلفية
  static void _backgroundSyncWorker(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    Timer.periodic(_syncInterval, (timer) async {
      try {
        // إرسال إشارة للمراقبة الرئيسية
        sendPort.send({
          'type': 'sync_request',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        sendPort.send({'type': 'error', 'message': e.toString()});
      }
    });
  }

  /// معالجة الرسائل من الخلفية
  static void _handleBackgroundMessage(dynamic message) {
    if (message is Map<String, dynamic>) {
      switch (message['type']) {
        case 'sync_request':
          _performOrderSync();
          break;
        case 'error':
          debugPrint('❌ خطأ في الخلفية: ${message['message']}');
          break;
      }
    }
  }

  /// بدء المراقبة الرئيسية
  static void _startMainSync() {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _performOrderSync();
    });

    // تشغيل المراقبة فوراً
    _performOrderSync();
  }

  /// بدء نبضة الحياة
  static void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      _sendHeartbeat();
    });
  }

  /// إرسال نبضة حياة
  static void _sendHeartbeat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_heartbeat', DateTime.now().toIso8601String());

      // إرسال إشعار صامت للتأكد من أن الخدمة تعمل
      if (kDebugMode) {
        debugPrint('💓 نبضة حياة - خدمة المراقبة تعمل');
      }
    } catch (e) {
      debugPrint('❌ خطأ في نبضة الحياة: $e');
    }
  }

  /// تنفيذ مراقبة الطلبات
  static Future<void> _performOrderSync() async {
    try {
      debugPrint('🔍 فحص تحديثات الطلبات من شركة الوسيط...');

      // جلب الطلبات من شركة الوسيط (معطل مؤقتاً)
      final waseetOrders = <Map<String, dynamic>>[];

      // جلب الطلبات المحلية
      final localOrders = await _getLocalOrders();

      // مقارنة وتحديث الطلبات
      final updatedOrders = await _compareAndUpdateOrders(
        waseetOrders,
        localOrders,
      );

      // إرسال إشعارات للطلبات المحدثة
      for (final order in updatedOrders) {
        await _sendOrderUpdateNotification(order);
        // إرسال إشعار عبر خادم الإشعارات الجديد
        await _sendOrderStatusNotificationToServer(order);
      }

      // حفظ وقت آخر مراقبة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      debugPrint(
        '✅ تم فحص ${waseetOrders.length} طلب، تم تحديث ${updatedOrders.length} طلب',
      );
    } catch (e) {
      debugPrint('❌ خطأ في مراقبة الطلبات: $e');
    }
  }

  /// جلب الطلبات المحلية
  static Future<List<Map<String, dynamic>>> _getLocalOrders() async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('id, waseet_qr_id, status, waseet_status, customer_name')
          .not('waseet_qr_id', 'is', null);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات المحلية: $e');
      return [];
    }
  }

  /// مقارنة وتحديث الطلبات
  static Future<List<Map<String, dynamic>>> _compareAndUpdateOrders(
    List<Map<String, dynamic>> waseetOrders,
    List<Map<String, dynamic>> localOrders,
  ) async {
    final updatedOrders = <Map<String, dynamic>>[];

    try {
      // إنشاء خريطة للطلبات المحلية
      final localOrdersMap = <String, Map<String, dynamic>>{};
      for (final order in localOrders) {
        final qrId = order['waseet_qr_id']?.toString();
        if (qrId != null) {
          localOrdersMap[qrId] = order;
        }
      }

      // مراجعة كل طلب من الوسيط
      for (final waseetOrder in waseetOrders) {
        final qrId = waseetOrder['id']?.toString();
        final waseetStatus = waseetOrder['status']?.toString();
        final statusId = waseetOrder['status_id']?.toString();

        if (qrId == null) continue;

        final localOrder = localOrdersMap[qrId];
        if (localOrder != null) {
          final localStatus = localOrder['status']?.toString();
          final localWaseetStatus = localOrder['waseet_status']?.toString();

          // تحويل حالة الوسيط إلى حالة محلية
          final newLocalStatus = _mapWaseetStatusToLocal(
            statusId,
            waseetStatus,
          );

          // تحديث إذا كانت الحالة مختلفة
          if (localStatus != newLocalStatus ||
              localWaseetStatus != waseetStatus) {
            await Supabase.instance.client
                .from('orders')
                .update({
                  'status': newLocalStatus,
                  'waseet_status': waseetStatus,
                  'waseet_status_id': statusId,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('waseet_qr_id', qrId);

            updatedOrders.add({
              'qr_id': qrId,
              'customer_name': localOrder['customer_name'],
              'old_status': localStatus,
              'new_status': newLocalStatus,
              'waseet_status': waseetStatus,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في مقارنة الطلبات: $e');
    }

    return updatedOrders;
  }

  /// تحويل حالة الوسيط إلى حالة محلية
  static String _mapWaseetStatusToLocal(
    String? statusId,
    String? waseetStatus,
  ) {
    switch (statusId) {
      case '1':
      case '2':
        return 'confirmed';
      case '3':
        return 'in_transit';
      case '4':
        return 'delivered';
      case '5':
        return 'cancelled';
      case '6':
        return 'returned';
      case '7':
        return 'pending';
      default:
        if (waseetStatus?.contains('تم التسليم') == true) return 'delivered';
        if (waseetStatus?.contains('ملغي') == true) return 'cancelled';
        if (waseetStatus?.contains('في الطريق') == true) return 'in_transit';
        if (waseetStatus?.contains('مؤكد') == true) return 'confirmed';
        if (waseetStatus?.contains('مرتجع') == true) return 'returned';
        return 'pending';
    }
  }

  /// إرسال إشعار تحديث الطلب
  static Future<void> _sendOrderUpdateNotification(
    Map<String, dynamic> order,
  ) async {
    try {
      final customerName = order['customer_name'] ?? 'عميل';
      final qrId = order['qr_id'];
      final newStatus = order['new_status'];
      final waseetStatus = order['waseet_status'];

      String statusText = _getStatusText(newStatus);
      String title = 'تحديث حالة الطلب';
      String body = 'طلب $customerName ($qrId)\nالحالة الجديدة: $statusText';

      await NotificationService.showNotification(
        title: title,
        body: body,
        payload: jsonEncode({
          'type': 'order_update',
          'qr_id': qrId,
          'status': newStatus,
        }),
      );

      debugPrint('📱 تم إرسال إشعار تحديث الطلب: $qrId');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار: $e');
    }
  }

  /// الحصول على نص الحالة
  static String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'in_transit':
        return 'في الطريق';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      case 'returned':
        return 'مرتجع';
      default:
        return status;
    }
  }

  /// إيقاف المراقبة
  static Future<void> stop() async {
    debugPrint('⏹️ إيقاف خدمة مراقبة الطلبات...');

    _isRunning = false;
    _syncTimer?.cancel();
    _heartbeatTimer?.cancel();
    _backgroundIsolate?.kill();
    _receivePort?.close();

    _syncTimer = null;
    _heartbeatTimer = null;
    _backgroundIsolate = null;
    _receivePort = null;

    debugPrint('✅ تم إيقاف خدمة مراقبة الطلبات');
  }

  /// تمكين/تعطيل المراقبة
  static Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, enabled);

    if (enabled && !_isRunning) {
      await _startBackgroundSync();
    } else if (!enabled && _isRunning) {
      await stop();
    }
  }

  /// التحقق من حالة المراقبة
  static bool get isRunning => _isRunning;

  /// الحصول على وقت آخر مراقبة
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      if (lastSyncString != null) {
        return DateTime.parse(lastSyncString);
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب وقت آخر مراقبة: $e');
    }
    return null;
  }

  /// إرسال إشعار تغيير حالة الطلب عبر خادم الإشعارات الجديد
  static Future<void> _sendOrderStatusNotificationToServer(
    Map<String, dynamic> order,
  ) async {
    try {
      debugPrint('📤 إرسال إشعار تغيير حالة الطلب عبر خادم الإشعارات');

      final orderId = order['id']?.toString() ?? '';
      final customerPhone = order['customer_phone']?.toString() ?? '';
      final newStatus = order['new_status']?.toString() ?? '';
      final waseetStatus = order['waseet_status']?.toString() ?? '';
      final qrId = order['qr_id']?.toString() ?? '';

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

      // إرسال الإشعار عبر خادم الإشعارات الجديد
      final response = await http.post(
        Uri.parse('http://localhost:3003/api/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
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
        final responseData = jsonDecode(response.body);
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
