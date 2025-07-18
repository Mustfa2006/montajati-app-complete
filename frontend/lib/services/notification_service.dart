import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// خدمة الإشعارات المحلية
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 تهيئة خدمة الإشعارات...');

      // طلب الأذونات
      await _requestPermissions();

      // إعدادات Android
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // إعدادات iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // إعدادات التهيئة
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // تهيئة الإشعارات
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
    }
  }

  /// طلب الأذونات
  static Future<void> _requestPermissions() async {
    try {
      // طلب إذن الإشعارات
      final notificationStatus = await Permission.notification.request();
      debugPrint('🔔 حالة إذن الإشعارات: $notificationStatus');

      // طلب إذن الإشعارات في الخلفية (Android)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final scheduleStatus = await Permission.scheduleExactAlarm.request();
        debugPrint('⏰ حالة إذن الإشعارات المجدولة: $scheduleStatus');
      }
    } catch (e) {
      debugPrint('❌ خطأ في طلب الأذونات: $e');
    }
  }

  /// معالجة النقر على الإشعار
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('👆 تم النقر على الإشعار: ${response.payload}');

      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        _handleNotificationAction(data);
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة النقر على الإشعار: $e');
    }
  }

  /// معالجة إجراء الإشعار
  static void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'order_update':
        final qrId = data['qr_id'];
        final status = data['status'];
        debugPrint('📦 تحديث طلب: $qrId - $status');
        // يمكن إضافة منطق للانتقال إلى صفحة الطلب
        break;
      case 'new_order':
        debugPrint('🆕 طلب جديد');
        // يمكن إضافة منطق للانتقال إلى صفحة الطلبات
        break;
      case 'out_of_stock':
        final productId = data['product_id'];
        final productName = data['product_name'];
        debugPrint('🚨 نفاد مخزون: $productName ($productId)');
        // يمكن إضافة منطق للانتقال إلى صفحة المنتج أو المخزون
        break;
      default:
        debugPrint('❓ نوع إشعار غير معروف: $type');
    }
  }

  /// إظهار إشعار
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'order_updates',
        'تحديثات الطلبات',
        channelDescription: 'إشعارات تحديثات حالة الطلبات من شركة الوسيط',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);

      debugPrint('📱 تم إرسال الإشعار: $title');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار: $e');
    }
  }

  /// إظهار إشعار مجدول
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    int id = 0,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'scheduled_notifications',
        'الإشعارات المجدولة',
        channelDescription: 'إشعارات مجدولة للتذكير بالطلبات',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // استخدام الإشعار الفوري بدلاً من المجدول لتجنب مشاكل التوقيت
      await _notifications.show(id, title, body, details, payload: payload);

      debugPrint('⏰ تم إرسال الإشعار: $title');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار: $e');
    }
  }

  /// إلغاء إشعار
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('🚫 تم إلغاء الإشعار: $id');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الإشعار: $e');
    }
  }

  /// إلغاء جميع الإشعارات
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('🚫 تم إلغاء جميع الإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء جميع الإشعارات: $e');
    }
  }

  /// الحصول على الإشعارات المعلقة
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإشعارات المعلقة: $e');
      return [];
    }
  }

  /// إظهار إشعار تحديث الطلب
  static Future<void> showOrderUpdateNotification({
    required String customerName,
    required String qrId,
    required String oldStatus,
    required String newStatus,
  }) async {
    final title = 'تحديث حالة الطلب';
    final body = 'طلب $customerName ($qrId)\nمن: $oldStatus إلى: $newStatus';

    await showNotification(
      title: title,
      body: body,
      payload: jsonEncode({
        'type': 'order_update',
        'qr_id': qrId,
        'customer_name': customerName,
        'old_status': oldStatus,
        'new_status': newStatus,
      }),
      id: qrId.hashCode,
    );
  }

  /// إظهار إشعار طلب جديد
  static Future<void> showNewOrderNotification({
    required String customerName,
    required String qrId,
    required double amount,
  }) async {
    final title = 'طلب جديد';
    final body =
        'طلب جديد من $customerName\nالمبلغ: ${amount.toStringAsFixed(0)} د.ع';

    await showNotification(
      title: title,
      body: body,
      payload: jsonEncode({
        'type': 'new_order',
        'qr_id': qrId,
        'customer_name': customerName,
        'amount': amount,
      }),
      id: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// إظهار إشعار خطأ في المراقبة
  static Future<void> showSyncErrorNotification(String error) async {
    await showNotification(
      title: 'خطأ في مراقبة الطلبات',
      body: 'حدث خطأ في مراقبة تحديثات الطلبات: $error',
      payload: jsonEncode({'type': 'sync_error', 'error': error}),
      id: 999999,
    );
  }

  /// إظهار إشعار نفاد المخزون
  static Future<void> showOutOfStockNotification({
    required String productName,
    required String productId,
  }) async {
    final title = '🚨 تنبيه نفاد المخزون';
    final body =
        'عذراً، المنتج "$productName" نفد من المخزون\n⚠️ المنتج غير متاح حالياً للطلب\n🔄 سيتم إعادة توفيره قريباً إن شاء الله';

    await showNotification(
      title: title,
      body: body,
      payload: jsonEncode({
        'type': 'out_of_stock',
        'product_id': productId,
        'product_name': productName,
      }),
      id: productId.hashCode,
    );
  }

  /// التحقق من حالة الأذونات
  static Future<bool> arePermissionsGranted() async {
    try {
      final notificationStatus = await Permission.notification.status;
      return notificationStatus == PermissionStatus.granted;
    } catch (e) {
      debugPrint('❌ خطأ في فحص الأذونات: $e');
      return false;
    }
  }
}
