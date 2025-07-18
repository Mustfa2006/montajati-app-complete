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

      // تحديث أو إدراج FCM Token
      await _supabase
          .from('user_fcm_tokens')
          .upsert({
            'user_phone': currentUserPhone,
            'fcm_token': token,
            'platform': _getPlatform(),
            'updated_at': DateTime.now().toIso8601String(),
          });

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
    // يمكن تحسين هذا حسب نظام المصادقة المستخدم
    try {
      // مثال: جلب من SharedPreferences أو من حالة التطبيق
      return '07503597589'; // مؤقت للاختبار
    } catch (e) {
      return null;
    }
  }

  // تحديد المنصة
  static String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  // ===================================
  // Getters
  // ===================================
  
  static bool get isInitialized => _initialized;
  static String? get fcmToken => _fcmToken;
}
