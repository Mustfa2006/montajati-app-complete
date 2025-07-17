// ===================================
// خدمة الإشعارات التلقائية
// إرسال إشعارات Firebase عند تحديث حالات الطلبات
// ===================================

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const statusMapper = require('./status_mapper');
require('dotenv').config();

class NotificationService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعداد Firebase Admin
    this.initializeFirebase();

    // إعدادات الإشعارات
    this.notificationConfig = {
      enabled: process.env.NOTIFICATIONS_ENABLED !== 'false',
      retryAttempts: 3,
      retryDelay: 2000, // 2 ثانية
      batchSize: 100
    };

    console.log('🔔 تم تهيئة خدمة الإشعارات التلقائية');
  }

  // ===================================
  // تهيئة Firebase Admin
  // ===================================
  initializeFirebase() {
    try {
      // تهيئة Firebase Admin إذا لم يتم تهيئته بالفعل
      if (!admin.apps.length) {
        let credential;

        // في بيئة الإنتاج، استخدم متغيرات البيئة
        if (process.env.NODE_ENV === 'production' && process.env.FIREBASE_SERVICE_ACCOUNT) {
          console.log('🔥 استخدام Firebase Service Account من متغيرات البيئة');
          const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
          credential = admin.credential.cert(serviceAccount);
        } else {
          // في بيئة التطوير، استخدم ملف الخدمة
          const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
                                     './firebase-service-account.json';
          console.log('🔥 استخدام Firebase Service Account من ملف محلي');
          credential = admin.credential.cert(require(serviceAccountPath));
        }

        admin.initializeApp({
          credential: credential,
          projectId: process.env.FIREBASE_PROJECT_ID || 'withdrawal-notifications'
        });

        console.log('✅ تم تهيئة Firebase Admin بنجاح');
      }

      this.messaging = admin.messaging();
    } catch (error) {
      console.warn('⚠️ تحذير: فشل في تهيئة Firebase Admin:', error.message);
      console.warn('📱 الإشعارات ستكون معطلة');
      if (this.notificationConfig) {
        this.notificationConfig.enabled = false;
      }
    }
  }

  // ===================================
  // إرسال إشعار تحديث حالة الطلب
  // ===================================
  async sendStatusUpdateNotification(order, newStatus) {
    if (!this.notificationConfig.enabled) {
      console.log('📱 الإشعارات معطلة، تخطي الإرسال');
      return;
    }

    try {
      console.log(`📱 إرسال إشعار تحديث الحالة للطلب ${order.order_number}`);

      // الحصول على رقم هاتف العميل
      const customerPhone = order.primary_phone;
      if (!customerPhone) {
        console.warn('⚠️ تحذير: لا يوجد رقم هاتف للعميل');
        return;
      }

      // البحث عن FCM token للعميل
      const fcmToken = await this.getFCMToken(customerPhone);
      if (!fcmToken) {
        console.log(`📱 لا يوجد FCM token للعميل ${customerPhone}`);
        return;
      }

      // إعداد رسالة الإشعار
      const notification = this.buildStatusNotification(order, newStatus);
      
      // إرسال الإشعار
      const result = await this.sendNotification(fcmToken, notification);
      
      // حفظ سجل الإشعار
      await this.saveNotificationLog(order, newStatus, result);

      console.log(`✅ تم إرسال إشعار تحديث الحالة للطلب ${order.order_number}`);

    } catch (error) {
      console.error(`❌ خطأ في إرسال إشعار الطلب ${order.order_number}:`, error.message);
      
      // حفظ سجل الخطأ
      await this.saveNotificationLog(order, newStatus, { 
        success: false, 
        error: error.message 
      });
    }
  }

  // ===================================
  // الحصول على FCM Token للعميل
  // ===================================
  async getFCMToken(customerPhone) {
    try {
      // البحث عن المستخدم بناءً على رقم الهاتف
      const { data: user, error } = await this.supabase
        .from('users')
        .select('fcm_token')
        .eq('phone', customerPhone)
        .single();

      if (error || !user) {
        console.log(`📱 لم يتم العثور على مستخدم برقم ${customerPhone}`);
        return null;
      }

      return user.fcm_token;
    } catch (error) {
      console.error('❌ خطأ في جلب FCM Token:', error.message);
      return null;
    }
  }

  // ===================================
  // بناء رسالة الإشعار
  // ===================================
  buildStatusNotification(order, newStatus) {
    const statusIcon = statusMapper.getStatusIcon(newStatus);
    const statusDescription = statusMapper.getStatusDescription(newStatus);
    const notificationMessage = statusMapper.getNotificationMessage(newStatus);

    return {
      notification: {
        title: `${statusIcon} تحديث حالة الطلب`,
        body: `طلبك ${order.order_number} - ${notificationMessage}`
      },
      data: {
        type: 'order_status_update',
        order_id: order.id,
        order_number: order.order_number,
        old_status: order.status,
        new_status: newStatus,
        status_description: statusDescription,
        timestamp: new Date().toISOString()
      },
      android: {
        notification: {
          icon: 'ic_notification',
          color: statusMapper.getStatusColor(newStatus),
          sound: 'default',
          channelId: 'order_updates'
        },
        priority: 'high'
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };
  }

  // ===================================
  // إرسال الإشعار عبر Firebase
  // ===================================
  async sendNotification(fcmToken, notification) {
    if (!this.messaging) {
      throw new Error('Firebase Messaging غير مهيأ');
    }

    let lastError;
    
    // محاولة الإرسال مع إعادة المحاولة
    for (let attempt = 1; attempt <= this.notificationConfig.retryAttempts; attempt++) {
      try {
        console.log(`📤 محاولة إرسال الإشعار ${attempt}/${this.notificationConfig.retryAttempts}`);
        
        const response = await this.messaging.send({
          token: fcmToken,
          ...notification
        });

        console.log('✅ تم إرسال الإشعار بنجاح:', response);
        
        return {
          success: true,
          messageId: response,
          attempts: attempt
        };

      } catch (error) {
        lastError = error;
        console.warn(`⚠️ فشل في المحاولة ${attempt}: ${error.message}`);
        
        // إذا كان الخطأ متعلق بـ token غير صالح، لا تعيد المحاولة
        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {
          console.log('🗑️ FCM Token غير صالح، إزالته من قاعدة البيانات');
          await this.removeFCMToken(fcmToken);
          break;
        }

        // انتظار قبل إعادة المحاولة
        if (attempt < this.notificationConfig.retryAttempts) {
          await new Promise(resolve => 
            setTimeout(resolve, this.notificationConfig.retryDelay * attempt)
          );
        }
      }
    }

    throw lastError;
  }

  // ===================================
  // إزالة FCM Token غير الصالح
  // ===================================
  async removeFCMToken(fcmToken) {
    try {
      await this.supabase
        .from('users')
        .update({ fcm_token: null })
        .eq('fcm_token', fcmToken);
      
      console.log('🗑️ تم إزالة FCM Token غير الصالح');
    } catch (error) {
      console.warn('⚠️ فشل في إزالة FCM Token:', error.message);
    }
  }

  // ===================================
  // حفظ سجل الإشعار
  // ===================================
  async saveNotificationLog(order, newStatus, result) {
    try {
      await this.supabase
        .from('notifications')
        .insert({
          order_id: order.id,
          customer_phone: order.primary_phone,
          type: 'order_status_update',
          title: 'تحديث حالة الطلب',
          message: `تم تحديث طلبك ${order.order_number} إلى ${statusMapper.getStatusDescription(newStatus)}`,
          status: result.success ? 'sent' : 'failed',
          sent_at: result.success ? new Date().toISOString() : null,
          firebase_response: result,
          created_at: new Date().toISOString()
        });
    } catch (error) {
      console.warn('⚠️ فشل في حفظ سجل الإشعار:', error.message);
    }
  }

  // ===================================
  // إرسال إشعار مخصص
  // ===================================
  async sendCustomNotification(customerPhone, title, message, data = {}) {
    if (!this.notificationConfig.enabled) {
      console.log('📱 الإشعارات معطلة، تخطي الإرسال');
      return;
    }

    try {
      const fcmToken = await this.getFCMToken(customerPhone);
      if (!fcmToken) {
        console.log(`📱 لا يوجد FCM token للعميل ${customerPhone}`);
        return;
      }

      const notification = {
        notification: { title, body: message },
        data: {
          type: 'custom',
          ...data,
          timestamp: new Date().toISOString()
        }
      };

      const result = await this.sendNotification(fcmToken, notification);
      console.log('✅ تم إرسال الإشعار المخصص بنجاح');
      
      return result;
    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار المخصص:', error.message);
      throw error;
    }
  }

  // ===================================
  // فحص صحة خدمة الإشعارات
  // ===================================
  async healthCheck() {
    try {
      const isFirebaseReady = !!this.messaging;
      const isEnabled = this.notificationConfig.enabled;

      return {
        status: isFirebaseReady && isEnabled ? 'healthy' : 'degraded',
        firebase_ready: isFirebaseReady,
        notifications_enabled: isEnabled,
        config: this.notificationConfig,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
}

// تصدير مثيل واحد من الخدمة (Singleton)
const notifier = new NotificationService();

module.exports = notifier;
