// 🔔 خدمة الإشعارات المرنة - تدعم Firebase Cloud Messaging
// تتعامل مع إشعارات حالة الطلبات والإشعارات العامة

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FlexibleNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  static String? _currentFcmToken;

  // ===================================
  // تهيئة الخدمة
  // ===================================

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 تهيئة خدمة الإشعارات المرنة...');

      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // تهيئة Firebase Messaging
      await _initializeFirebaseMessaging();

      // طلب الأذونات
      await _requestPermissions();

      // الحصول على FCM Token
      await _getFcmToken();

      // إعداد معالجات الإشعارات
      _setupNotificationHandlers();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة الإشعارات المرنة بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات المرنة: $e');
    }
  }

  // تهيئة الإشعارات المحلية
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // تهيئة Firebase Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // إعداد معالج الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // طلب الأذونات
  static Future<void> _requestPermissions() async {
    // طلب أذونات Firebase
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('🔔 حالة أذونات الإشعارات: ${settings.authorizationStatus}');

    // طلب أذونات الإشعارات المحلية (Android)
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }

  // الحصول على FCM Token
  static Future<void> _getFcmToken() async {
    try {
      _currentFcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $_currentFcmToken');

      if (_currentFcmToken != null) {
        await _saveFcmTokenToDatabase();
      }

      // مراقبة تغيير التوكن
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 تم تحديث FCM Token: $newToken');
        _currentFcmToken = newToken;
        _saveFcmTokenToDatabase();
      });

    } catch (e) {
      debugPrint('❌ خطأ في الحصول على FCM Token: $e');
    }
  }

  // حفظ FCM Token في قاعدة البيانات
  static Future<void> _saveFcmTokenToDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('current_user_phone');

      if (userPhone != null && _currentFcmToken != null) {
        await Supabase.instance.client
            .from('notification_settings')
            .upsert({
              'user_phone': userPhone,
              'fcm_token': _currentFcmToken,
              'order_status_notifications': true,
              'promotional_notifications': true,
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            });

        debugPrint('✅ تم حفظ FCM Token في قاعدة البيانات');
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ FCM Token: $e');
    }
  }

  // إعداد معالجات الإشعارات
  static void _setupNotificationHandlers() {
    // معالج الإشعارات عندما يكون التطبيق مفتوحاً
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالج الإشعارات عند النقر عليها (التطبيق في الخلفية)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // معالج الإشعارات عند فتح التطبيق من إشعار
    _handleInitialMessage();
  }

  // ===================================
  // معالجات الإشعارات
  // ===================================

  // معالج الإشعارات في المقدمة
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 إشعار جديد في المقدمة: ${message.notification?.title}');

    // عرض الإشعار محلياً
    await _showLocalNotification(
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  // معالج الإشعارات في الخلفية
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('📱 إشعار جديد في الخلفية: ${message.notification?.title}');
    
    // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
  }

  // معالج النقر على الإشعار
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('👆 تم النقر على الإشعار: ${message.data}');
    
    // التنقل حسب نوع الإشعار
    await _navigateBasedOnNotification(message.data);
  }

  // معالج الإشعار الأولي (عند فتح التطبيق من إشعار)
  static Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 تم فتح التطبيق من إشعار: ${initialMessage.data}');
      await _navigateBasedOnNotification(initialMessage.data);
    }
  }

  // معالج النقر على الإشعار المحلي
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 تم النقر على الإشعار المحلي: ${response.payload}');
    
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _navigateBasedOnNotification(data);
    }
  }

  // ===================================
  // عرض الإشعارات
  // ===================================

  // عرض إشعار محلي
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_updates',
      'تحديثات الطلبات',
      channelDescription: 'إشعارات تحديثات حالة الطلبات',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: data != null ? json.encode(data) : null,
    );
  }

  // ===================================
  // إرسال الإشعارات
  // ===================================

  // إرسال إشعار تحديث حالة الطلب
  static Future<void> sendOrderStatusNotification({
    required String userPhone,
    required String orderId,
    required String oldStatus,
    required String newStatus,
    String? orderDetails,
  }) async {
    try {
      final title = 'تحديث حالة الطلب';
      final body = 'تم تحديث حالة طلبك من "$oldStatus" إلى "$newStatus"';
      
      final data = {
        'type': 'order_status_update',
        'order_id': orderId,
        'old_status': oldStatus,
        'new_status': newStatus,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // حفظ الإشعار في قاعدة البيانات
      await Supabase.instance.client
          .from('notification_logs')
          .insert({
            'user_phone': userPhone,
            'order_id': orderId,
            'notification_type': 'order_status_update',
            'title': title,
            'body': body,
            'data': data,
            'status': 'sent',
            'sent_at': DateTime.now().toIso8601String(),
          });

      debugPrint('✅ تم إرسال إشعار تحديث حالة الطلب');

    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار حالة الطلب: $e');
    }
  }

  // ===================================
  // التنقل والمعالجة
  // ===================================

  // التنقل حسب نوع الإشعار
  static Future<void> _navigateBasedOnNotification(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'order_status_update':
        final orderId = data['order_id'] as String?;
        if (orderId != null) {
          // التنقل إلى صفحة تفاصيل الطلب
          debugPrint('🔄 التنقل إلى تفاصيل الطلب: $orderId');
          // يمكن إضافة منطق التنقل هنا
        }
        break;
      
      case 'promotional':
        // التنقل إلى صفحة العروض
        debugPrint('🎯 التنقل إلى صفحة العروض');
        break;
      
      default:
        debugPrint('📱 نوع إشعار غير معروف: $type');
    }
  }

  // ===================================
  // إدارة الإعدادات
  // ===================================

  // تحديث إعدادات الإشعارات
  static Future<void> updateNotificationSettings({
    required bool orderStatusNotifications,
    required bool promotionalNotifications,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('current_user_phone');

      if (userPhone != null) {
        await Supabase.instance.client
            .from('notification_settings')
            .upsert({
              'user_phone': userPhone,
              'order_status_notifications': orderStatusNotifications,
              'promotional_notifications': promotionalNotifications,
              'updated_at': DateTime.now().toIso8601String(),
            });

        debugPrint('✅ تم تحديث إعدادات الإشعارات');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث إعدادات الإشعارات: $e');
    }
  }

  // الحصول على إعدادات الإشعارات
  static Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('current_user_phone');

      if (userPhone != null) {
        final response = await Supabase.instance.client
            .from('notification_settings')
            .select('order_status_notifications, promotional_notifications')
            .eq('user_phone', userPhone)
            .eq('is_active', true)
            .maybeSingle();

        if (response != null) {
          return {
            'order_status_notifications': response['order_status_notifications'] ?? true,
            'promotional_notifications': response['promotional_notifications'] ?? true,
          };
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب إعدادات الإشعارات: $e');
    }

    // القيم الافتراضية
    return {
      'order_status_notifications': true,
      'promotional_notifications': true,
    };
  }

  // ===================================
  // دوال مساعدة
  // ===================================

  // الحصول على FCM Token الحالي
  static String? getCurrentFcmToken() {
    return _currentFcmToken;
  }

  // فحص ما إذا كانت الخدمة مهيأة
  static bool isInitialized() {
    return _isInitialized;
  }

  // إعادة تهيئة الخدمة
  static Future<void> reinitialize() async {
    _isInitialized = false;
    await initialize();
  }
}
