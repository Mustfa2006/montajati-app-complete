// ===================================
// خدمة Firebase Cloud Messaging الاحترافية
// Professional FCM Service for Push Notifications
// ===================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../firebase_options.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Firebase Messaging instance
  FirebaseMessaging? _messaging;

  // Local Notifications
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Service state
  bool _isInitialized = false;
  String? _currentToken;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentToken => _currentToken;

  /// تهيئة خدمة FCM
  Future<bool> initialize() async {
    try {
      debugPrint('🚀 بدء تهيئة خدمة FCM...');

      // تهيئة Firebase
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint('✅ تم تهيئة Firebase');

      _messaging = FirebaseMessaging.instance;
      debugPrint('✅ تم إنشاء مثيل FirebaseMessaging');

      // طلب الأذونات
      await _requestPermissions();
      debugPrint('✅ تم طلب الأذونات');

      // تهيئة Local Notifications
      await _initializeLocalNotifications();
      debugPrint('✅ تم تهيئة Local Notifications');

      // الحصول على FCM Token
      await _getFCMToken();
      debugPrint('✅ تم الحصول على FCM Token');

      // إعداد تحديث Token التلقائي
      await _setupTokenRefresh();
      debugPrint('✅ تم إعداد تحديث Token التلقائي');

      // إعداد معالجات الإشعارات
      _setupMessageHandlers();
      debugPrint('✅ تم إعداد معالجات الإشعارات');

      _isInitialized = true;
      debugPrint('🎉 تم تهيئة خدمة FCM بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة FCM: $e');
      return false;
    }
  }

  /// طلب أذونات الإشعارات
  Future<void> _requestPermissions() async {
    if (_messaging == null) return;

    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 حالة أذونات الإشعارات: ${settings.authorizationStatus}');
  }

  /// تهيئة Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTapped);

    // إنشاء notification channel للأندرويد
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  /// إنشاء notification channel للأندرويد
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'montajati_notifications',
      'إشعارات منتجاتي',
      description: 'إشعارات تحديث حالة الطلبات',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// الحصول على FCM Token
  Future<void> _getFCMToken() async {
    try {
      if (_messaging == null) return;

      _currentToken = await _messaging!.getToken();

      if (_currentToken != null) {
        debugPrint('🔑 FCM Token: ${_currentToken!.substring(0, 20)}...');

        // حفظ Token في قاعدة البيانات
        await _saveFCMToken(_currentToken!);

        // الاستماع لتحديثات Token
        _messaging!.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 تم تحديث FCM Token');
          _currentToken = newToken;
          _saveFCMToken(newToken);
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على FCM Token: $e');
    }
  }

  /// حفظ FCM Token في قاعدة البيانات
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('user_phone');

      if (userPhone == null || userPhone.isEmpty) {
        debugPrint('⚠️ لا يوجد رقم هاتف للمستخدم - لن يتم حفظ FCM Token');
        return;
      }

      debugPrint('📱 حفظ FCM Token للمستخدم: $userPhone');

      // ✅ حذف جميع الـ tokens القديمة للمستخدم أولاً
      try {
        await _supabase.from('fcm_tokens').delete().eq('user_phone', userPhone);
        debugPrint('🗑️ تم حذف جميع الـ tokens القديمة');
      } catch (e) {
        debugPrint('⚠️ خطأ في حذف الـ tokens القديمة: $e');
      }

      // الحصول على معلومات الجهاز
      final deviceInfo = await _getDeviceInfo();

      // ✅ إنشاء Token جديد فقط
      try {
        await _supabase.from('fcm_tokens').insert({
          'user_phone': userPhone,
          'fcm_token': token,
          'device_info': deviceInfo,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'last_used_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ تم حفظ FCM Token الجديد بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في حفظ FCM Token: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ FCM Token: $e');
    }
  }

  /// الحصول على معلومات الجهاز
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {'platform': 'ios', 'model': iosInfo.model, 'name': iosInfo.name, 'version': iosInfo.systemVersion};
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في الحصول على معلومات الجهاز: $e');
    }

    return {'platform': Platform.operatingSystem, 'timestamp': DateTime.now().toIso8601String()};
  }

  /// إعداد معالجات الإشعارات
  void _setupMessageHandlers() {
    if (_messaging == null) return;

    // معالج الإشعارات في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // معالج الإشعارات عند النقر (التطبيق في الخلفية)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // معالج الإشعارات عند فتح التطبيق من إشعار
    _handleInitialMessage();
  }

  /// معالجة الإشعارات في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 تم استلام إشعار في المقدمة: ${message.messageId}');
    debugPrint('📱 عنوان الإشعار: ${message.notification?.title}');
    debugPrint('📱 نص الإشعار: ${message.notification?.body}');
    debugPrint('📱 بيانات الإشعار: ${message.data}');

    // عرض الإشعار محلياً
    await _showLocalNotification(message);
    debugPrint('✅ تم عرض الإشعار المحلي بنجاح');
  }

  /// معالجة النقر على الإشعار
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 تم النقر على الإشعار: ${message.messageId}');
    _processNotificationData(message.data);
  }

  /// معالجة الإشعار الأولي عند فتح التطبيق
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging?.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 تم فتح التطبيق من إشعار: ${initialMessage.messageId}');
      _processNotificationData(initialMessage.data);
    }
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      debugPrint('🔔 بدء عرض الإشعار المحلي...');

      const androidDetails = AndroidNotificationDetails(
        'montajati_notifications',
        'إشعارات منتجاتي',
        channelDescription: 'إشعارات تحديث حالة الطلبات',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final title = message.notification?.title ?? 'إشعار جديد';
      final body = message.notification?.body ?? 'لديك تحديث جديد';

      debugPrint('🔔 عرض إشعار: $title - $body');

      await _localNotifications.show(message.hashCode, title, body, details, payload: jsonEncode(message.data));

      debugPrint('✅ تم عرض الإشعار المحلي بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في عرض الإشعار المحلي: $e');
    }
  }

  /// معالجة النقر على الإشعار المحلي
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _processNotificationData(data);
    }
  }

  /// معالجة بيانات الإشعار
  void _processNotificationData(Map<String, dynamic> data) {
    debugPrint('📊 معالجة بيانات الإشعار: $data');

    // يمكن إضافة منطق التنقل هنا حسب نوع الإشعار
    final orderId = data['orderId'] ?? data['order_id'];
    if (orderId != null) {
      // التنقل إلى صفحة تفاصيل الطلب
      debugPrint('🔗 التنقل إلى الطلب: $orderId');
    }
  }

  /// تحديث آخر استخدام للـ Token
  Future<void> updateTokenLastUsed() async {
    if (_currentToken == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('user_phone');

      if (userPhone != null) {
        await _supabase
            .from('fcm_tokens')
            .update({'last_used_at': DateTime.now().toIso8601String()})
            .eq('user_phone', userPhone)
            .eq('fcm_token', _currentToken!);
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في تحديث آخر استخدام للـ Token: $e');
    }
  }

  /// تسجيل FCM Token للمستخدم الحالي
  static Future<bool> registerCurrentUserToken() async {
    try {
      debugPrint('🔄 بدء تسجيل FCM Token للمستخدم الحالي...');

      final instance = FCMService();

      // التأكد من تهيئة FCM service
      if (!instance.isInitialized) {
        debugPrint('🔄 تهيئة FCM service...');
        final initSuccess = await instance.initialize();
        if (!initSuccess) {
          debugPrint('❌ فشل في تهيئة FCM service');
          return false;
        }
      }

      // التأكد من وجود FCM token
      if (instance.currentToken == null) {
        debugPrint('⚠️ لا يوجد FCM Token، محاولة الحصول عليه...');
        await instance._getFCMToken();

        if (instance.currentToken == null) {
          debugPrint('❌ فشل في الحصول على FCM Token');
          return false;
        }
      }

      // الحصول على رقم الهاتف من SharedPreferences (أسرع من قاعدة البيانات)
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('user_phone');

      if (userPhone == null || userPhone.isEmpty) {
        debugPrint('❌ لا يوجد رقم هاتف في SharedPreferences');
        return false;
      }

      debugPrint('📱 تسجيل FCM Token للمستخدم: $userPhone');

      // تسجيل الـ Token في قاعدة البيانات
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_phone': userPhone,
        'fcm_token': instance.currentToken,
        'device_info': {'platform': 'Flutter', 'app': 'Montajati'},
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_used_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ تم تسجيل FCM Token بنجاح للمستخدم: $userPhone');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل FCM Token: $e');
      return false;
    }
  }

  /// الحصول على معلومات الخدمة
  /// إعداد تحديث FCM Token التلقائي
  Future<void> _setupTokenRefresh() async {
    if (_messaging == null) return;

    // 1. مراقبة تحديث Token تلقائياً
    _messaging!.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 تم تحديث FCM Token تلقائياً');
      debugPrint('🆕 Token الجديد: ${newToken.substring(0, 20)}...');

      _currentToken = newToken;

      // تحديث Token في قاعدة البيانات
      await _updateTokenInDatabase(newToken);
    });

    // 2. فحص وتحديث Token عند بدء التطبيق
    await _checkAndRefreshToken();

    // 3. إعداد فحص دوري للـ Token
    _setupPeriodicTokenCheck();
  }

  /// فحص وتحديث Token عند الحاجة
  Future<void> _checkAndRefreshToken() async {
    try {
      // الحصول على Token الحالي
      final currentToken = await _messaging?.getToken();

      if (currentToken != null && currentToken != _currentToken) {
        debugPrint('🔄 تم العثور على Token محدث');
        _currentToken = currentToken;
        await _updateTokenInDatabase(currentToken);
      }

      // فحص صحة Token الحالي
      await _validateCurrentToken();
    } catch (e) {
      debugPrint('⚠️ خطأ في فحص Token: $e');
    }
  }

  /// التحقق من صحة Token الحالي (بدون إرسال إشعارات)
  Future<void> _validateCurrentToken() async {
    if (_currentToken == null) return;

    try {
      // فقط تحديث آخر استخدام في قاعدة البيانات بدون اختبار Firebase
      final response = await http.post(
        Uri.parse('https://montajati-official-backend-production.up.railway.app/api/fcm/update-last-used'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcmToken': _currentToken, 'userPhone': await _getCurrentUserPhone()}),
      );

      if (response.statusCode != 200) {
        debugPrint('⚠️ فشل في تحديث آخر استخدام للـ Token');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في التحقق من Token: $e');
    }
  }

  /// إجبار تحديث Token
  Future<void> _forceTokenRefresh() async {
    try {
      debugPrint('🔄 إجبار تحديث FCM Token...');

      // حذف Token الحالي
      await _messaging?.deleteToken();

      // الحصول على Token جديد
      final newToken = await _messaging?.getToken();

      if (newToken != null) {
        debugPrint('✅ تم الحصول على Token جديد');
        _currentToken = newToken;
        await _updateTokenInDatabase(newToken);
      }
    } catch (e) {
      debugPrint('❌ خطأ في إجبار تحديث Token: $e');
    }
  }

  /// إعداد فحص دوري للـ Token
  void _setupPeriodicTokenCheck() {
    // فحص Token كل 8 ساعات (أقل استهلاكاً للبطارية)
    Timer.periodic(const Duration(hours: 8), (timer) async {
      debugPrint('🔍 فحص دوري لـ FCM Token...');
      await _checkAndRefreshToken();
    });

    // فحص Token عند العودة للتطبيق من الخلفية
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  /// تحديث Token في قاعدة البيانات
  Future<void> _updateTokenInDatabase(String token) async {
    try {
      final userPhone = await _getCurrentUserPhone();
      if (userPhone == null) return;

      final response = await http.post(
        Uri.parse('https://montajati-official-backend-production.up.railway.app/api/fcm/update-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userPhone': userPhone,
          'fcmToken': token,
          'deviceInfo': {'platform': 'Flutter', 'app': 'Montajati', 'timestamp': DateTime.now().toIso8601String()},
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ تم تحديث FCM Token في قاعدة البيانات');
      } else {
        debugPrint('⚠️ فشل في تحديث FCM Token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث Token في قاعدة البيانات: $e');
    }
  }

  /// الحصول على رقم هاتف المستخدم الحالي
  Future<String?> _getCurrentUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_phone');
    } catch (e) {
      return null;
    }
  }

  /// دالة عامة لتحديث Token يدوياً
  Future<void> refreshToken() async {
    debugPrint('🔄 تحديث FCM Token يدوياً...');
    await _forceTokenRefresh();
  }

  Map<String, dynamic> getServiceInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasToken': _currentToken != null,
      'tokenPreview': _currentToken?.substring(0, 20),
    };
  }
}

/// مراقب دورة حياة التطبيق لتحديث Token
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final FCMService _fcmService;

  _AppLifecycleObserver(this._fcmService);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // عند العودة للتطبيق، فحص Token
      _fcmService._checkAndRefreshToken();
    }
  }
}
