// ===================================
// خدمة الإشعارات الجاهزة - انسخ هذا الملف للتطبيق
// ===================================

import messaging from '@react-native-firebase/messaging';
import { Alert, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

class NotificationService {
  constructor() {
    this.serverUrl = 'https://your-api.com'; // ضع رابط الخادم هنا
  }

  // ===================================
  // الدالة الرئيسية - استدعيها في App.js
  // ===================================
  async setupNotifications(userPhone) {
    try {
      console.log('🚀 إعداد الإشعارات للمستخدم:', userPhone);
      
      // 1. طلب إذن الإشعارات
      const permission = await messaging().requestPermission();
      const enabled = permission === messaging.AuthorizationStatus.AUTHORIZED ||
                     permission === messaging.AuthorizationStatus.PROVISIONAL;

      if (!enabled) {
        console.log('❌ المستخدم رفض الإشعارات');
        return false;
      }

      // 2. الحصول على FCM Token
      const fcmToken = await messaging().getToken();
      if (!fcmToken) {
        console.log('❌ فشل في الحصول على FCM Token');
        return false;
      }

      console.log('📱 FCM Token:', fcmToken);

      // 3. إرسال التوكن للخادم
      await this.registerToken(userPhone, fcmToken);

      // 4. إعداد استقبال الإشعارات
      this.setupMessageHandlers();

      console.log('✅ تم إعداد الإشعارات بنجاح');
      return true;

    } catch (error) {
      console.error('❌ خطأ في إعداد الإشعارات:', error);
      return false;
    }
  }

  // ===================================
  // تسجيل التوكن في الخادم
  // ===================================
  async registerToken(userPhone, fcmToken) {
    try {
      const response = await fetch(`${this.serverUrl}/api/fcm/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_phone: userPhone,
          fcm_token: fcmToken,
          device_info: {
            platform: Platform.OS,
            version: Platform.Version
          }
        }),
      });

      const result = await response.json();
      
      if (result.success) {
        console.log('✅ تم تسجيل الإشعارات بنجاح');
        await AsyncStorage.setItem('notifications_registered', 'true');
      } else {
        console.error('❌ فشل في تسجيل الإشعارات:', result.message);
      }

    } catch (error) {
      console.error('❌ خطأ في تسجيل الإشعارات:', error);
    }
  }

  // ===================================
  // إعداد استقبال الإشعارات
  // ===================================
  setupMessageHandlers() {
    // عندما يكون التطبيق مفتوح
    messaging().onMessage(async remoteMessage => {
      console.log('📱 إشعار جديد:', remoteMessage);
      
      Alert.alert(
        remoteMessage.notification?.title || 'إشعار جديد',
        remoteMessage.notification?.body || 'لديك إشعار جديد',
        [{ text: 'موافق' }]
      );
    });

    // عندما يتم الضغط على الإشعار
    messaging().onNotificationOpenedApp(remoteMessage => {
      console.log('📱 تم فتح التطبيق من الإشعار:', remoteMessage);
    });

    // عندما يكون التطبيق مغلق
    messaging()
      .getInitialNotification()
      .then(remoteMessage => {
        if (remoteMessage) {
          console.log('📱 تم فتح التطبيق من إشعار (مغلق):', remoteMessage);
        }
      });
  }
}

export default new NotificationService();
