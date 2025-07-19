// ===================================
// خدمة الإشعارات - NotificationService.js
// ===================================

import messaging from '@react-native-firebase/messaging';
import { Alert, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

class NotificationService {
  constructor() {
    this.fcmToken = null;
    this.userPhone = null;
    this.serverUrl = 'https://your-api.com'; // ضع رابط الخادم هنا
  }

  // ===================================
  // تهيئة الإشعارات (يتم استدعاؤها مرة واحدة)
  // ===================================
  async initialize(userPhone) {
    try {
      console.log('🚀 بدء تهيئة الإشعارات...');
      
      this.userPhone = userPhone;
      
      // 1. طلب إذن الإشعارات
      const permission = await this.requestPermission();
      if (!permission) {
        console.log('❌ المستخدم رفض الإشعارات');
        return false;
      }

      // 2. الحصول على FCM Token
      const fcmToken = await this.getFCMToken();
      if (!fcmToken) {
        console.log('❌ فشل في الحصول على FCM Token');
        return false;
      }

      // 3. تسجيل التوكن في الخادم
      const registered = await this.registerToken(fcmToken);
      if (!registered) {
        console.log('❌ فشل في تسجيل التوكن');
        return false;
      }

      // 4. إعداد استقبال الإشعارات
      this.setupMessageHandlers();

      console.log('✅ تم تهيئة الإشعارات بنجاح');
      return true;

    } catch (error) {
      console.error('❌ خطأ في تهيئة الإشعارات:', error);
      return false;
    }
  }

  // ===================================
  // طلب إذن الإشعارات
  // ===================================
  async requestPermission() {
    try {
      const authStatus = await messaging().requestPermission({
        sound: true,
        announcement: true,
        badge: true,
        alert: true,
      });

      const enabled =
        authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
        authStatus === messaging.AuthorizationStatus.PROVISIONAL;

      if (enabled) {
        console.log('✅ تم منح إذن الإشعارات');
        return true;
      } else {
        console.log('❌ تم رفض إذن الإشعارات');
        return false;
      }
    } catch (error) {
      console.error('❌ خطأ في طلب إذن الإشعارات:', error);
      return false;
    }
  }

  // ===================================
  // الحصول على FCM Token
  // ===================================
  async getFCMToken() {
    try {
      // التحقق من وجود توكن محفوظ
      const savedToken = await AsyncStorage.getItem('fcm_token');
      if (savedToken) {
        this.fcmToken = savedToken;
        console.log('✅ تم استخدام FCM Token المحفوظ');
        return savedToken;
      }

      // الحصول على توكن جديد
      const fcmToken = await messaging().getToken();
      if (fcmToken) {
        this.fcmToken = fcmToken;
        // حفظ التوكن محلياً
        await AsyncStorage.setItem('fcm_token', fcmToken);
        console.log('✅ تم الحصول على FCM Token جديد');
        return fcmToken;
      }

      return null;
    } catch (error) {
      console.error('❌ خطأ في الحصول على FCM Token:', error);
      return null;
    }
  }

  // ===================================
  // تسجيل التوكن في الخادم
  // ===================================
  async registerToken(fcmToken) {
    try {
      console.log('📤 تسجيل FCM Token في الخادم...');

      const response = await fetch(`${this.serverUrl}/api/fcm/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_phone: this.userPhone,
          fcm_token: fcmToken,
          device_info: {
            platform: Platform.OS,
            version: Platform.Version,
            timestamp: new Date().toISOString()
          }
        }),
      });

      const result = await response.json();

      if (result.success) {
        console.log('✅ تم تسجيل FCM Token بنجاح');
        // حفظ حالة التسجيل
        await AsyncStorage.setItem('notification_registered', 'true');
        return true;
      } else {
        console.error('❌ فشل في تسجيل FCM Token:', result.message);
        return false;
      }

    } catch (error) {
      console.error('❌ خطأ في تسجيل FCM Token:', error);
      return false;
    }
  }

  // ===================================
  // إعداد استقبال الإشعارات
  // ===================================
  setupMessageHandlers() {
    // استقبال الإشعارات عندما يكون التطبيق مفتوح
    messaging().onMessage(async remoteMessage => {
      console.log('📱 تم استلام إشعار:', remoteMessage);
      
      // عرض الإشعار للمستخدم
      Alert.alert(
        remoteMessage.notification?.title || 'إشعار جديد',
        remoteMessage.notification?.body || 'لديك إشعار جديد',
        [
          {
            text: 'موافق',
            onPress: () => {
              // يمكنك إضافة أي إجراء هنا
              console.log('تم الضغط على الإشعار');
            }
          }
        ]
      );
    });

    // استقبال الإشعارات عندما يكون التطبيق في الخلفية
    messaging().onNotificationOpenedApp(remoteMessage => {
      console.log('📱 تم فتح التطبيق من الإشعار:', remoteMessage);
      
      // يمكنك توجيه المستخدم لصفحة معينة هنا
      // navigation.navigate('OrderDetails', { orderId: remoteMessage.data.order_id });
    });

    // استقبال الإشعارات عندما يكون التطبيق مغلق تماماً
    messaging()
      .getInitialNotification()
      .then(remoteMessage => {
        if (remoteMessage) {
          console.log('📱 تم فتح التطبيق من إشعار (مغلق):', remoteMessage);
          
          // يمكنك توجيه المستخدم لصفحة معينة هنا
          // navigation.navigate('OrderDetails', { orderId: remoteMessage.data.order_id });
        }
      });

    console.log('✅ تم إعداد استقبال الإشعارات');
  }

  // ===================================
  // التحقق من حالة التسجيل
  // ===================================
  async isRegistered() {
    try {
      const registered = await AsyncStorage.getItem('notification_registered');
      return registered === 'true';
    } catch (error) {
      return false;
    }
  }

  // ===================================
  // إلغاء تسجيل الإشعارات
  // ===================================
  async unregister() {
    try {
      if (!this.userPhone) return false;

      const response = await fetch(`${this.serverUrl}/api/fcm/unregister`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_phone: this.userPhone,
          fcm_token: this.fcmToken
        }),
      });

      const result = await response.json();

      if (result.success) {
        // حذف البيانات المحلية
        await AsyncStorage.removeItem('fcm_token');
        await AsyncStorage.removeItem('notification_registered');
        
        console.log('✅ تم إلغاء تسجيل الإشعارات');
        return true;
      }

      return false;
    } catch (error) {
      console.error('❌ خطأ في إلغاء التسجيل:', error);
      return false;
    }
  }
}

// إنشاء instance واحد للاستخدام في التطبيق
const notificationService = new NotificationService();

export default notificationService;
