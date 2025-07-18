// 🔔 خدمة الإشعارات الجديدة - متوافقة مع نظام FCM المحدث
// تدعم الإشعارات الفورية وتحديثات حالة الطلبات

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NewNotificationService {
  // إعدادات الخدمة
  static const String _baseUrl = 'http://localhost:3003/api';
  static const Duration _timeout = Duration(seconds: 15);
  
  // متغيرات النظام
  static FirebaseMessaging? _firebaseMessaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static String? _fcmToken;
  static bool _isInitialized = false;

  // ===================================
  // تهيئة النظام
  // ===================================

  // تهيئة خدمة الإشعارات
  static Future<bool> initialize() async {
    try {
      debugPrint('🔔 تهيئة خدمة الإشعارات...');

      // تهيئة Firebase Messaging
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // طلب الأذونات
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ تم منح أذونات الإشعارات');
      } else {
        debugPrint('⚠️ لم يتم منح أذونات الإشعارات');
        return false;
      }

      // الحصول على توكن FCM
      _fcmToken = await _firebaseMessaging!.getToken();
      debugPrint('🔑 توكن FCM: $_fcmToken');

      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // إعداد معالجات الإشعارات
      _setupNotificationHandlers();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
      return false;
    }
  }

  // تهيئة الإشعارات المحلية
  static Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

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

    await _localNotifications!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // إعداد معالجات الإشعارات
  static void _setupNotificationHandlers() {
    // معالج الإشعارات في المقدمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 إشعار في المقدمة: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // معالج الإشعارات في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 تم فتح الإشعار: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // معالج تحديث التوكن
    _firebaseMessaging!.onTokenRefresh.listen((String token) {
      debugPrint('🔄 تم تحديث توكن FCM: $token');
      _fcmToken = token;
      _updateTokenOnServer(token);
    });
  }

  // ===================================
  // دوال الإشعارات
  // ===================================

  // عرض إشعار محلي
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_localNotifications == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'montajati_orders',
      'إشعارات الطلبات',
      channelDescription: 'إشعارات تحديثات حالة الطلبات',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
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

    await _localNotifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'منتجاتي',
      message.notification?.body ?? 'لديك إشعار جديد',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  // معالجة النقر على الإشعار
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationData(data);
      } catch (e) {
        debugPrint('❌ خطأ في معالجة بيانات الإشعار: $e');
      }
    }
  }

  // معالجة النقر على إشعار Firebase
  static void _handleNotificationTap(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  // معالجة بيانات الإشعار
  static void _handleNotificationData(Map<String, dynamic> data) {
    debugPrint('📋 معالجة بيانات الإشعار: $data');
    
    final type = data['type'];
    
    switch (type) {
      case 'order_status':
        final orderId = data['orderId'];
        final status = data['status'];
        debugPrint('📦 تحديث حالة الطلب: $orderId -> $status');
        // يمكن إضافة التنقل إلى صفحة تفاصيل الطلب هنا
        break;
        
      case 'welcome':
        debugPrint('👋 إشعار ترحيب');
        // يمكن إضافة التنقل إلى الصفحة الرئيسية هنا
        break;
        
      case 'promotion':
        debugPrint('🎉 إشعار عرض خاص');
        // يمكن إضافة التنقل إلى صفحة العروض هنا
        break;
        
      default:
        debugPrint('📢 إشعار عام');
        break;
    }
  }

  // ===================================
  // دوال التفاعل مع الخادم
  // ===================================

  // تحديث التوكن على الخادم
  static Future<void> _updateTokenOnServer(String token) async {
    try {
      // يمكن إضافة إرسال التوكن إلى الخادم هنا
      debugPrint('🔄 تحديث التوكن على الخادم: $token');
      
      // مثال على إرسال التوكن
      // await _sendPostRequest('/update-fcm-token', {'token': token});
      
    } catch (e) {
      debugPrint('❌ خطأ في تحديث التوكن: $e');
    }
  }

  // تسجيل المستخدم للإشعارات
  static Future<bool> registerUserForNotifications(int userId) async {
    try {
      if (!_isInitialized || _fcmToken == null) {
        debugPrint('⚠️ خدمة الإشعارات غير مهيأة');
        return false;
      }

      final response = await _sendPostRequest('/register-notifications', {
        'userId': userId,
        'fcmToken': _fcmToken,
      });

      if (response['success'] == true) {
        debugPrint('✅ تم تسجيل المستخدم للإشعارات');
        return true;
      } else {
        debugPrint('❌ فشل في تسجيل المستخدم للإشعارات');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل المستخدم للإشعارات: $e');
      return false;
    }
  }

  // إلغاء تسجيل المستخدم من الإشعارات
  static Future<bool> unregisterUserFromNotifications(int userId) async {
    try {
      final response = await _sendPostRequest('/unregister-notifications', {
        'userId': userId,
      });

      if (response['success'] == true) {
        debugPrint('✅ تم إلغاء تسجيل المستخدم من الإشعارات');
        return true;
      } else {
        debugPrint('❌ فشل في إلغاء تسجيل المستخدم من الإشعارات');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء تسجيل المستخدم من الإشعارات: $e');
      return false;
    }
  }

  // ===================================
  // دوال مساعدة
  // ===================================

  // إرسال طلب POST
  static Future<Map<String, dynamic>> _sendPostRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في الطلب: $e');
      rethrow;
    }
  }

  // الحصول على توكن FCM
  static String? getFCMToken() {
    return _fcmToken;
  }

  // التحقق من حالة التهيئة
  static bool isInitialized() {
    return _isInitialized;
  }

  // الحصول على معلومات الخدمة
  static Map<String, dynamic> getServiceInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasFCMToken': _fcmToken != null,
      'fcmToken': _fcmToken,
    };
  }
}
