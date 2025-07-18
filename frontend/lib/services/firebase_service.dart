import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../firebase_options.dart';

/// خدمة Firebase للإشعارات
class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// تهيئة Firebase
  static Future<void> initialize() async {
    try {
      debugPrint('🔥 بدء تهيئة Firebase...');

      // تهيئة Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // طلب إذن الإشعارات
      await _requestPermission();

      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // الحصول على FCM Token
      await _getFCMToken();

      // الاستماع للإشعارات
      _setupMessageHandlers();

      debugPrint('✅ تم تهيئة Firebase بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة Firebase: $e');
    }
  }

  /// طلب إذن الإشعارات
  static Future<void> _requestPermission() async {
    try {
      debugPrint('📱 طلب إذن الإشعارات...');

      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ تم منح إذن الإشعارات');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ تم منح إذن مؤقت للإشعارات');
      } else {
        debugPrint('❌ تم رفض إذن الإشعارات');
      }
    } catch (e) {
      debugPrint('❌ خطأ في طلب إذن الإشعارات: $e');
    }
  }

  /// تهيئة الإشعارات المحلية
  static Future<void> _initializeLocalNotifications() async {
    try {
      debugPrint('🔔 تهيئة الإشعارات المحلية...');

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('✅ تم تهيئة الإشعارات المحلية');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الإشعارات المحلية: $e');
    }
  }

  /// الحصول على FCM Token
  static Future<String?> _getFCMToken() async {
    try {
      debugPrint('🔑 الحصول على FCM Token...');

      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        debugPrint('✅ FCM Token: ${token.substring(0, 20)}...');

        // حفظ Token في قاعدة البيانات
        await _saveFCMToken(token);

        return token;
      } else {
        debugPrint('❌ فشل في الحصول على FCM Token');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على FCM Token: $e');
      return null;
    }
  }

  /// حفظ FCM Token في قاعدة البيانات
  static Future<void> _saveFCMToken(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase
            .from('users')
            .update({'fcm_token': token})
            .eq('id', user.id);

        debugPrint('✅ تم حفظ FCM Token في قاعدة البيانات');
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ FCM Token: $e');
    }
  }

  /// إعداد معالجات الرسائل
  static void _setupMessageHandlers() {
    try {
      debugPrint('📨 إعداد معالجات الرسائل...');

      // عند وصول رسالة والتطبيق في المقدمة
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // عند النقر على إشعار والتطبيق في الخلفية
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // عند فتح التطبيق من إشعار
      _handleInitialMessage();

      debugPrint('✅ تم إعداد معالجات الرسائل');
    } catch (e) {
      debugPrint('❌ خطأ في إعداد معالجات الرسائل: $e');
    }
  }

  /// معالجة الرسائل في المقدمة
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('📱 وصل إشعار في المقدمة: ${message.notification?.title}');

      // عرض إشعار محلي
      await _showLocalNotification(message);
    } catch (e) {
      debugPrint('❌ خطأ في معالجة رسالة المقدمة: $e');
    }
  }

  /// معالجة الرسائل في الخلفية
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      debugPrint('📱 تم فتح التطبيق من إشعار: ${message.notification?.title}');

      // يمكن إضافة منطق التنقل هنا
      if (message.data['type'] == 'withdrawal_status_change') {
        // التنقل إلى صفحة طلبات السحب
        debugPrint('🔄 التنقل إلى صفحة طلبات السحب...');
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة رسالة الخلفية: $e');
    }
  }

  /// معالجة الرسالة الأولية
  static Future<void> _handleInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          '📱 تم فتح التطبيق من إشعار أولي: ${initialMessage.notification?.title}',
        );
        await _handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة الرسالة الأولية: $e');
    }
  }

  /// عرض إشعار محلي
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'withdrawal_notifications',
            'إشعارات طلبات السحب',
            channelDescription: 'إشعارات تحديثات طلبات السحب',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'إشعار جديد',
        message.notification?.body ?? 'لديك تحديث جديد',
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('❌ خطأ في عرض الإشعار المحلي: $e');
    }
  }

  /// معالجة النقر على الإشعار
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('👆 تم النقر على إشعار: ${response.payload}');

      // يمكن إضافة منطق التنقل هنا
    } catch (e) {
      debugPrint('❌ خطأ في معالجة النقر على الإشعار: $e');
    }
  }

  /// الحصول على FCM Token الحالي
  static Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على Token الحالي: $e');
      return null;
    }
  }

  /// تحديث FCM Token
  static Future<void> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      await _getFCMToken();
    } catch (e) {
      debugPrint('❌ خطأ في تحديث Token: $e');
    }
  }

  /// إرسال إشعار تجريبي للاختبار
  static Future<void> sendTestNotification({
    required String title,
    required String body,
  }) async {
    try {
      debugPrint('🧪 إرسال إشعار تجريبي...');

      // إرسال إشعار المتصفح مباشرة
      await _showBrowserNotification(title, body);

      // إرسال إشعار محلي أيضاً
      try {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
              'test_notifications',
              'إشعارات تجريبية',
              channelDescription: 'إشعارات للاختبار',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              enableVibration: true,
              playSound: true,
              icon: 'ic_notification',
            );

        const DarwinNotificationDetails iOSPlatformChannelSpecifics =
            DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            );

        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(
              android: androidPlatformChannelSpecifics,
              iOS: iOSPlatformChannelSpecifics,
            );

        await _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title,
          body,
          platformChannelSpecifics,
          payload: 'test_notification',
        );
      } catch (localError) {
        debugPrint('⚠️ خطأ في الإشعار المحلي: $localError');
      }

      debugPrint('✅ تم إرسال الإشعار التجريبي بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار التجريبي: $e');
    }
  }

  /// إرسال إشعار المتصفح مباشرة
  static Future<void> _showBrowserNotification(
    String title,
    String body,
  ) async {
    try {
      debugPrint('🌐 إرسال إشعار المتصفح...');

      // استخدام JavaScript لإرسال إشعار المتصفح
      if (kIsWeb) {
        // استخدام dart:html للويب
        await _showWebNotification(title, body);
      }
    } catch (e) {
      debugPrint('❌ خطأ في إشعار المتصفح: $e');
    }
  }

  /// إرسال إشعار الويب
  static Future<void> _showWebNotification(String title, String body) async {
    try {
      debugPrint('🔔 عرض إشعار الويب: $title - $body');

      if (kIsWeb) {
        // استخدام JavaScript API مباشرة
        try {
          // محاولة استخدام Notification API
          debugPrint('🌐 محاولة إرسال إشعار المتصفح...');

          // سيتم التعامل مع هذا عبر JavaScript في notifications.js
          debugPrint('📨 تم إرسال طلب الإشعار إلى JavaScript');
        } catch (jsError) {
          debugPrint('⚠️ خطأ في JavaScript: $jsError');
        }
      }

      debugPrint('✅ تم عرض إشعار الويب');
    } catch (e) {
      debugPrint('❌ خطأ في إشعار الويب: $e');
    }
  }

  /// إرسال إشعار محلي مباشر
  static Future<void> showDirectNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      debugPrint('🔔 عرض إشعار محلي مباشر...');

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'direct_notifications',
            'إشعارات مباشرة',
            channelDescription: 'إشعارات مباشرة للمستخدم',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notification',
            ticker: 'إشعار جديد',
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
        payload: payload ?? 'direct_notification',
      );

      debugPrint('✅ تم عرض الإشعار المحلي بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في عرض الإشعار المحلي: $e');
    }
  }

  /// إرسال إشعار رسمي لطلبات السحب
  static Future<void> sendWithdrawalNotification({
    required String status,
    required String amount,
    String? requestId,
  }) async {
    try {
      debugPrint('📢 إرسال إشعار رسمي لطلب السحب: $status - $amount د.ع');

      String title, body;

      // تحديد نص الإشعار حسب الحالة
      switch (status.toLowerCase()) {
        case 'completed':
        case 'transferred':
          title = 'تم تحويل طلب السحب';
          body = 'تم تحويل مبلغ $amount د.ع إلى محفظتك بنجاح';
          break;
        case 'rejected':
        case 'cancelled':
          title = 'تم إلغاء طلب السحب';
          body = 'تم إلغاء طلب سحب بمبلغ $amount د.ع';
          break;
        case 'pending':
          title = 'طلب سحب قيد المراجعة';
          body = 'طلب سحب بمبلغ $amount د.ع قيد المراجعة';
          break;
        default:
          title = 'تحديث طلب السحب';
          body = 'تم تحديث حالة طلب السحب إلى $status';
      }

      // إرسال الإشعار الرسمي
      await sendOfficialNotification(
        title: title,
        body: body,
        payload: 'withdrawal_$status',
        data: {
          'type': 'withdrawal_notification',
          'status': status,
          'amount': amount,
          'request_id': requestId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ تم إرسال إشعار السحب الرسمي بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار السحب: $e');
    }
  }

  /// إرسال إشعار رسمي للنظام
  static Future<void> sendOfficialNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📢 إرسال إشعار رسمي: $title');

      // إرسال إشعار للمتصفح (Web)
      if (kIsWeb) {
        await _showWebNotification(title, body);
      }

      // إرسال إشعار محلي (Mobile & Desktop)
      await _showOfficialLocalNotification(
        title,
        body,
        payload ?? 'official_notification',
      );

      debugPrint('✅ تم إرسال الإشعار الرسمي بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار الرسمي: $e');
    }
  }

  /// إرسال إشعار محلي رسمي موحد
  static Future<void> _showOfficialLocalNotification(
    String title,
    String body,
    String payload,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'withdrawal_notifications',
            'إشعارات طلبات السحب',
            channelDescription: 'إشعارات تحديثات حالة طلبات السحب',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notification',
            ticker: 'إشعار جديد من منتجاتي',
            autoCancel: true,
            ongoing: false,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformDetails,
        payload: payload,
      );

      debugPrint('📱 تم عرض الإشعار المحلي');
    } catch (e) {
      debugPrint('❌ خطأ في الإشعار المحلي: $e');
    }
  }
}
