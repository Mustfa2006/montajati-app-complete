// ===================================
// خدمة الإشعارات الرسمية المتكاملة
// Official Notification Service
// ===================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

class OfficialNotificationService {
  static final SupabaseClient _supabase = SupabaseConfig.client;
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static String? _fcmToken;

  // ===================================
  // تهيئة الخدمة
  // ===================================
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      debugPrint('🔔 بدء تهيئة خدمة الإشعارات الرسمية...');
      
      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();
      
      // تهيئة Firebase Messaging
      await _initializeFirebaseMessaging();
      
      // طلب الأذونات
      await _requestPermissions();
      
      // الحصول على FCM Token
      await _getFCMToken();
      
      _initialized = true;
      debugPrint('✅ تم تهيئة خدمة الإشعارات الرسمية بنجاح');
      
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
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
    
    await _localNotifications.initialize(initSettings);
    debugPrint('✅ تم تهيئة الإشعارات المحلية');
  }

  // تهيئة Firebase Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // معالجة الإشعارات في المقدمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 وصل إشعار في المقدمة: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // معالجة النقر على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 تم النقر على الإشعار: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    debugPrint('✅ تم تهيئة Firebase Messaging');
  }

  // طلب الأذونات
  static Future<void> _requestPermissions() async {
    // أذونات Firebase
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ تم منح أذونات الإشعارات');
    } else {
      debugPrint('❌ تم رفض أذونات الإشعارات');
    }
  }

  // الحصول على FCM Token
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('✅ تم الحصول على FCM Token: ${_fcmToken!.substring(0, 20)}...');
        
        // حفظ Token في قاعدة البيانات
        await _saveFCMToken(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على FCM Token: $e');
    }
  }

  // حفظ FCM Token في قاعدة البيانات
  static Future<void> _saveFCMToken(String token) async {
    try {
      // الحصول على رقم هاتف المستخدم الحالي
      final currentUserPhone = await _getCurrentUserPhone();
      if (currentUserPhone == null) return;

      // تحديث أو إدراج FCM Token في كلا الجدولين

      // الجدول الأول: fcm_tokens
      try {
        await _supabase
            .from('fcm_tokens')
            .upsert({
              'user_phone': currentUserPhone,
              'token': token,
              'platform': _getPlatform(),
              'device_info': {'app': 'montajati'},
              'is_active': true,
              'last_used_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        debugPrint('✅ تم حفظ FCM Token في جدول fcm_tokens');
      } catch (e) {
        debugPrint('⚠️ خطأ في حفظ FCM Token في جدول fcm_tokens: $e');
      }

      // الجدول الثاني: user_fcm_tokens (للتوافق مع النظام القديم)
      try {
        await _supabase
            .from('user_fcm_tokens')
            .upsert({
              'user_phone': currentUserPhone,
              'fcm_token': token,
              'platform': _getPlatform(),
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            });
        debugPrint('✅ تم حفظ FCM Token في جدول user_fcm_tokens');
      } catch (e) {
        debugPrint('⚠️ خطأ في حفظ FCM Token في جدول user_fcm_tokens: $e');
      }

      debugPrint('✅ تم حفظ FCM Token للمستخدم: $currentUserPhone');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ FCM Token: $e');
    }
  }

  // ===================================
  // إرسال الإشعارات
  // ===================================

  /// إرسال إشعار تغيير حالة الطلب للمستخدم صاحب الطلب
  static Future<bool> sendOrderStatusNotification({
    required String orderId,
    required String userPhone,
    required String newStatus,
    String? notes,
  }) async {
    try {
      debugPrint('🔔 إرسال إشعار تغيير حالة الطلب...');
      debugPrint('📦 معرف الطلب: $orderId');
      debugPrint('📱 رقم المستخدم: $userPhone');
      debugPrint('🔄 الحالة الجديدة: $newStatus');

      // جلب بيانات الطلب
      final orderData = await _getOrderData(orderId);
      if (orderData == null) {
        debugPrint('❌ لم يتم العثور على بيانات الطلب');
        return false;
      }

      // تحديد رسالة الإشعار
      final notificationData = _getStatusNotificationData(newStatus, orderData);
      
      // إرسال الإشعار عبر الخادم الخلفي
      final success = await _sendNotificationViaServer(
        userPhone: userPhone,
        title: notificationData['title']!,
        message: notificationData['message']!,
        data: {
          'type': 'order_status_update',
          'order_id': orderId,
          'new_status': newStatus,
          'order_number': orderData['order_number'],
          'customer_name': orderData['customer_name'],
          if (notes != null) 'notes': notes,
        },
      );

      if (success) {
        debugPrint('✅ تم إرسال إشعار تغيير حالة الطلب بنجاح');
        
        // إرسال إشعار محلي كنسخة احتياطية
        await _showLocalOrderStatusNotification(
          title: notificationData['title']!,
          message: notificationData['message']!,
          orderId: orderId,
        );
        
        return true;
      } else {
        debugPrint('❌ فشل في إرسال الإشعار عبر الخادم');
        return false;
      }

    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار تغيير حالة الطلب: $e');
      return false;
    }
  }

  // إرسال الإشعار عبر الخادم الخلفي
  static Future<bool> _sendNotificationViaServer({
    required String userPhone,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://montajati-backend.onrender.com/api/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userPhone': userPhone,
          'title': title,
          'message': message,
          'data': data,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ تم إرسال الإشعار عبر الخادم بنجاح');
          return true;
        }
      }
      
      debugPrint('❌ فشل الإرسال عبر الخادم: ${response.statusCode}');
      return false;
      
    } catch (e) {
      debugPrint('❌ خطأ في الإرسال عبر الخادم: $e');
      return false;
    }
  }

  // ===================================
  // الوظائف المساعدة
  // ===================================

  // جلب بيانات الطلب
  static Future<Map<String, dynamic>?> _getOrderData(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('id, order_number, customer_name, user_phone, status')
          .eq('id', orderId)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات الطلب: $e');
      return null;
    }
  }

  // تحديد رسالة الإشعار حسب الحالة
  static Map<String, String> _getStatusNotificationData(String status, Map<String, dynamic> orderData) {
    final orderNumber = orderData['order_number'] ?? 'غير محدد';
    final customerName = orderData['customer_name'] ?? 'عميل';

    switch (status) {
      case 'pending':
        return {
          'title': '⏳ طلب جديد قيد المراجعة',
          'message': 'طلب $customerName رقم $orderNumber قيد المراجعة',
        };
      case 'confirmed':
        return {
          'title': '✅ تم تأكيد الطلب',
          'message': 'تم تأكيد طلب $customerName رقم $orderNumber',
        };
      case 'processing':
        return {
          'title': '🔄 جاري تحضير الطلب',
          'message': 'طلب $customerName رقم $orderNumber قيد التحضير',
        };
      case 'in_delivery':
        return {
          'title': '🚚 الطلب قيد التوصيل',
          'message': 'طلب $customerName رقم $orderNumber قيد التوصيل',
        };
      case 'delivered':
        return {
          'title': '🎉 تم تسليم الطلب',
          'message': 'تم تسليم طلب $customerName رقم $orderNumber بنجاح',
        };
      case 'cancelled':
        return {
          'title': '❌ تم إلغاء الطلب',
          'message': 'تم إلغاء طلب $customerName رقم $orderNumber',
        };
      default:
        return {
          'title': '🔄 تحديث حالة الطلب',
          'message': 'تم تحديث حالة طلب $customerName رقم $orderNumber',
        };
    }
  }

  // عرض إشعار محلي
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'montajati_orders',
      'إشعارات الطلبات',
      channelDescription: 'إشعارات تحديث حالة الطلبات',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'إشعار جديد',
      message.notification?.body ?? 'لديك تحديث جديد',
      details,
    );
  }

  // عرض إشعار محلي لحالة الطلب
  static Future<void> _showLocalOrderStatusNotification({
    required String title,
    required String message,
    required String orderId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'montajati_orders',
      'إشعارات الطلبات',
      channelDescription: 'إشعارات تحديث حالة الطلبات',
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

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: orderId,
    );
  }

  // معالجة النقر على الإشعار
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 تم النقر على إشعار: ${message.data}');
    // يمكن إضافة منطق التنقل هنا
  }

  // الحصول على رقم هاتف المستخدم الحالي
  static Future<String?> _getCurrentUserPhone() async {
    try {
      // جلب من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('user_phone');

      if (userPhone != null && userPhone.isNotEmpty) {
        debugPrint('✅ تم جلب رقم هاتف المستخدم من SharedPreferences: $userPhone');
        return userPhone;
      }

      // إذا لم يوجد، استخدم رقم افتراضي للاختبار
      debugPrint('⚠️ لم يتم العثور على رقم هاتف المستخدم، استخدام رقم افتراضي');
      return '07503597589'; // رقم افتراضي للاختبار

    } catch (e) {
      debugPrint('❌ خطأ في جلب رقم هاتف المستخدم: $e');
      return '07503597589'; // رقم افتراضي للاختبار
    }
  }

  // تحديد المنصة
  static String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  // ===================================
  // دوال إضافية للإدارة
  // ===================================

  /// حفظ FCM Token للمستخدم عند تسجيل الدخول
  static Future<bool> saveUserFCMToken(String userPhone) async {
    try {
      debugPrint('💾 حفظ FCM Token للمستخدم: $userPhone');

      if (_fcmToken == null) {
        await _getFCMToken();
      }

      if (_fcmToken == null) {
        debugPrint('❌ لا يوجد FCM Token للحفظ');
        return false;
      }

      // حفظ رقم الهاتف في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', userPhone);

      // حفظ FCM Token في قاعدة البيانات (كلا الجدولين)

      // الجدول الأول: fcm_tokens
      try {
        await _supabase
            .from('fcm_tokens')
            .upsert({
              'user_phone': userPhone,
              'token': _fcmToken!,
              'platform': _getPlatform(),
              'device_info': {'app': 'montajati', 'login': true},
              'is_active': true,
              'last_used_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        debugPrint('✅ تم حفظ FCM Token في جدول fcm_tokens');
      } catch (e) {
        debugPrint('⚠️ خطأ في حفظ FCM Token في جدول fcm_tokens: $e');
      }

      // الجدول الثاني: user_fcm_tokens
      try {
        await _supabase
            .from('user_fcm_tokens')
            .upsert({
              'user_phone': userPhone,
              'fcm_token': _fcmToken!,
              'platform': _getPlatform(),
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            });
        debugPrint('✅ تم حفظ FCM Token في جدول user_fcm_tokens');
      } catch (e) {
        debugPrint('⚠️ خطأ في حفظ FCM Token في جدول user_fcm_tokens: $e');
      }

      debugPrint('✅ تم حفظ FCM Token للمستخدم $userPhone بنجاح');
      debugPrint('🔑 FCM Token: ${_fcmToken!.substring(0, 20)}...');

      return true;

    } catch (e) {
      debugPrint('❌ خطأ في حفظ FCM Token للمستخدم: $e');
      return false;
    }
  }

  /// اختبار إرسال إشعار للمستخدم الحالي
  static Future<bool> testNotificationForCurrentUser() async {
    try {
      final userPhone = await _getCurrentUserPhone();
      if (userPhone == null) {
        debugPrint('❌ لا يوجد رقم هاتف للمستخدم الحالي');
        return false;
      }

      return await sendOrderStatusNotification(
        orderId: 'test_order_${DateTime.now().millisecondsSinceEpoch}',
        userPhone: userPhone,
        newStatus: 'in_delivery',
        notes: 'اختبار إشعار من التطبيق',
      );

    } catch (e) {
      debugPrint('❌ خطأ في اختبار الإشعار: $e');
      return false;
    }
  }

  /// إعادة تهيئة FCM Token
  static Future<void> refreshFCMToken() async {
    try {
      debugPrint('🔄 إعادة تهيئة FCM Token...');

      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        debugPrint('✅ تم تحديث FCM Token: ${_fcmToken!.substring(0, 20)}...');

        final userPhone = await _getCurrentUserPhone();
        if (userPhone != null) {
          await saveUserFCMToken(userPhone);
        }
      }

    } catch (e) {
      debugPrint('❌ خطأ في إعادة تهيئة FCM Token: $e');
    }
  }

  // ===================================
  // Getters
  // ===================================

  static bool get isInitialized => _initialized;
  static String? get fcmToken => _fcmToken;
}
