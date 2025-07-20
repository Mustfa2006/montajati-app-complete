// ===================================
// خدمة Firebase Cloud Messaging الاحترافية
// Professional FCM Service for Push Notifications
// ===================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../firebase_options.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Firebase Messaging instance
  FirebaseMessaging? _messaging;
  
  // Local Notifications
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Service state
  bool _isInitialized = false;
  String? _currentToken;
  
  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentToken => _currentToken;

  /// ✅ تهيئة خدمة FCM محسنة مع معالجة أفضل للأخطاء
  Future<bool> initialize() async {
    try {
      debugPrint('🔥 بدء تهيئة Firebase Cloud Messaging...');

      // التحقق من توفر الخدمات
      if (!kIsWeb && Platform.isIOS) {
        // التحقق من إعدادات iOS
        debugPrint('📱 تشغيل على iOS - التحقق من الإعدادات...');
      } else if (!kIsWeb && Platform.isAndroid) {
        // التحقق من إعدادات Android
        debugPrint('🤖 تشغيل على Android - التحقق من الإعدادات...');
      }

      // تهيئة Firebase مع معالجة الأخطاء
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ تم تهيئة Firebase بنجاح');
      } catch (firebaseError) {
        debugPrint('❌ خطأ في تهيئة Firebase: $firebaseError');
        return false;
      }

      _messaging = FirebaseMessaging.instance;
      
      // طلب الأذونات
      await _requestPermissions();
      
      // تهيئة Local Notifications
      await _initializeLocalNotifications();
      
      // الحصول على FCM Token
      await _getFCMToken();
      
      // إعداد معالجات الإشعارات
      _setupMessageHandlers();
      
      _isInitialized = true;
      debugPrint('✅ تم تهيئة FCM بنجاح');
      
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة FCM: $e');
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
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
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
      
      // الحصول على معلومات الجهاز
      final deviceInfo = await _getDeviceInfo();
      
      // ✅ حفظ Token في قاعدة البيانات مع معالجة الاستجابة
      final response = await _supabase.rpc('upsert_fcm_token', params: {
        'p_user_phone': userPhone,
        'p_fcm_token': token,
        'p_device_info': deviceInfo,
      });

      if (response != null) {
        debugPrint('✅ تم حفظ FCM Token للمستخدم: $userPhone');
      } else {
        debugPrint('⚠️ تم حفظ FCM Token ولكن بدون استجابة من الخادم');
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
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في الحصول على معلومات الجهاز: $e');
    }
    
    return {
      'platform': Platform.operatingSystem,
      'timestamp': DateTime.now().toIso8601String(),
    };
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
    
    // عرض الإشعار محلياً
    await _showLocalNotification(message);
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
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'إشعار جديد',
      message.notification?.body ?? 'لديك تحديث جديد',
      details,
      payload: jsonEncode(message.data),
    );
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
    final instance = FCMService();

    if (!instance.isInitialized) {
      await instance.initialize();
    }

    if (instance.currentToken == null) {
      debugPrint('❌ لا يوجد FCM Token للتسجيل');
      return false;
    }

    try {
      // الحصول على معلومات المستخدم الحالي
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ لا يوجد مستخدم مسجل دخول');
        return false;
      }

      // الحصول على رقم الهاتف من جدول المستخدمين
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('phone')
          .eq('id', user.id)
          .single();

      final userPhone = userResponse['phone'] as String?;
      if (userPhone == null || userPhone.isEmpty) {
        debugPrint('❌ لا يوجد رقم هاتف للمستخدم');
        return false;
      }

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
  Map<String, dynamic> getServiceInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasToken': _currentToken != null,
      'tokenPreview': _currentToken?.substring(0, 20),
    };
  }
}
