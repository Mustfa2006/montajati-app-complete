// ===================================
// خدمة الإشعارات المستهدفة والدقيقة
// Targeted Notification Service
// ===================================

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

class TargetedNotificationService {
  constructor() {
    this.initialized = false;
    this.initializeFirebase();
  }

  // تهيئة Firebase Admin
  async initializeFirebase() {
    try {
      if (!admin.apps.length) {
        // استخدام متغيرات البيئة بدلاً من ملف JSON
        const serviceAccount = {
          type: "service_account",
          project_id: process.env.FIREBASE_PROJECT_ID,
          private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
          private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          client_email: process.env.FIREBASE_CLIENT_EMAIL,
          client_id: process.env.FIREBASE_CLIENT_ID,
          auth_uri: "https://accounts.google.com/o/oauth2/auth",
          token_uri: "https://oauth2.googleapis.com/token",
          auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs"
        };

        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: process.env.FIREBASE_PROJECT_ID
        });
      }
      this.initialized = true;
      console.log('✅ تم تهيئة Firebase Admin للإشعارات المستهدفة');
    } catch (error) {
      console.error('❌ خطأ في تهيئة Firebase Admin:', error.message);
      this.initialized = false;
    }
  }

  // ===================================
  // إشعارات تغيير حالة الطلبات
  // ===================================

  /**
   * إرسال إشعار تغيير حالة الطلب للمستخدم المحدد فقط
   * @param {string} orderId - معرف الطلب
   * @param {string} userId - معرف المستخدم صاحب الطلب
   * @param {string} customerName - اسم العميل
   * @param {string} oldStatus - الحالة القديمة
   * @param {string} newStatus - الحالة الجديدة
   */
  async sendOrderStatusNotification(orderId, userId, customerName, oldStatus, newStatus) {
    try {
      console.log(`🎯 إرسال إشعار حالة الطلب للمستخدم المحدد فقط:`);
      console.log(`📦 الطلب: ${orderId}`);
      console.log(`👤 المستخدم: ${userId}`);
      console.log(`👥 العميل: ${customerName}`);
      console.log(`🔄 تغيير الحالة: ${oldStatus} → ${newStatus}`);

      // الحصول على FCM Token للمستخدم المحدد فقط
      const fcmToken = await this.getUserFCMToken(userId);
      
      if (!fcmToken) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userId}`);
        return { success: false, error: 'FCM Token غير متوفر' };
      }

      // تحديد رسالة الإشعار حسب الحالة الجديدة
      const notificationData = this.getOrderStatusNotificationData(customerName, newStatus);
      
      if (!notificationData) {
        console.log(`⚠️ حالة غير مدعومة: ${newStatus}`);
        return { success: false, error: 'حالة غير مدعومة' };
      }

      // إرسال الإشعار للمستخدم المحدد فقط
      const result = await this.sendNotificationToUser(fcmToken, {
        title: notificationData.title,
        body: notificationData.body,
        data: {
          type: 'order_status_change',
          order_id: orderId,
          user_id: userId,
          customer_name: customerName,
          old_status: oldStatus,
          new_status: newStatus,
          timestamp: new Date().toISOString()
        }
      });

      // تسجيل الإشعار في قاعدة البيانات
      await this.logNotification({
        user_id: userId,
        order_id: orderId,
        type: 'order_status_change',
        title: notificationData.title,
        body: notificationData.body,
        status: result.success ? 'sent' : 'failed',
        fcm_token: fcmToken,
        error_message: result.error || null
      });

      return result;

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار حالة الطلب:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * تحديد بيانات الإشعار حسب حالة الطلب
   */
  getOrderStatusNotificationData(customerName, status) {
    const notifications = {
      'in_delivery': {
        title: '🚚',
        body: `${customerName} - قيد التوصيل`
      },
      'delivered': {
        title: '😊',
        body: `${customerName} - طلبك وصل`
      },
      'cancelled': {
        title: '😢',
        body: `${customerName} - ملغي`
      }
    };

    return notifications[status] || null;
  }

  // ===================================
  // إشعارات طلبات السحب
  // ===================================

  /**
   * إرسال إشعار تحديث طلب السحب للمستخدم المحدد فقط
   * @param {string} userId - معرف المستخدم صاحب طلب السحب
   * @param {string} requestId - معرف طلب السحب
   * @param {number} amount - مبلغ السحب
   * @param {string} status - حالة طلب السحب
   * @param {string} reason - سبب الرفض (اختياري)
   */
  async sendWithdrawalStatusNotification(userId, requestId, amount, status, reason = '') {
    try {
      console.log(`💰 إرسال إشعار طلب السحب للمستخدم المحدد فقط:`);
      console.log(`👤 المستخدم: ${userId}`);
      console.log(`📄 طلب السحب: ${requestId}`);
      console.log(`💵 المبلغ: ${amount}`);
      console.log(`📊 الحالة: ${status}`);

      // الحصول على FCM Token للمستخدم المحدد فقط
      const fcmToken = await this.getUserFCMToken(userId);
      
      if (!fcmToken) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userId}`);
        return { success: false, error: 'FCM Token غير متوفر' };
      }

      // تحديد رسالة الإشعار حسب حالة السحب
      const notificationData = this.getWithdrawalStatusNotificationData(amount, status, reason);
      
      if (!notificationData) {
        console.log(`⚠️ حالة سحب غير مدعومة: ${status}`);
        return { success: false, error: 'حالة سحب غير مدعومة' };
      }

      // إرسال الإشعار للمستخدم المحدد فقط
      const result = await this.sendNotificationToUser(fcmToken, {
        title: notificationData.title,
        body: notificationData.body,
        data: {
          type: 'withdrawal_status_change',
          request_id: requestId,
          user_id: userId,
          amount: amount.toString(),
          status: status,
          reason: reason,
          timestamp: new Date().toISOString()
        }
      });

      // تسجيل الإشعار في قاعدة البيانات
      await this.logNotification({
        user_id: userId,
        request_id: requestId,
        type: 'withdrawal_status_change',
        title: notificationData.title,
        body: notificationData.body,
        status: result.success ? 'sent' : 'failed',
        fcm_token: fcmToken,
        error_message: result.error || null
      });

      return result;

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار طلب السحب:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * تحديد بيانات الإشعار حسب حالة طلب السحب
   */
  getWithdrawalStatusNotificationData(amount, status, reason = '') {
    const notifications = {
      'approved': {
        title: 'تم التحويل',
        body: `تم تحويل مبلغ ${amount} د.ع إلى حسابك`
      },
      'rejected': {
        title: 'تم الغاء طلب سحبك 😔',
        body: `تم الغاء طلب سحبك ${amount} د.ع${reason ? ` - ${reason}` : ''}`
      }
    };

    return notifications[status] || null;
  }

  // ===================================
  // الوظائف المساعدة
  // ===================================

  /**
   * الحصول على FCM Token للمستخدم
   */
  async getUserFCMToken(userId) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('id', userId)
        .single();

      if (error || !data || !data.fcm_token) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userId}`);
        return null;
      }

      return data.fcm_token;
    } catch (error) {
      console.error('❌ خطأ في جلب FCM Token:', error.message);
      return null;
    }
  }

  /**
   * إرسال إشعار لمستخدم واحد محدد
   */
  async sendNotificationToUser(fcmToken, notification) {
    try {
      if (!this.initialized) {
        console.log('⚠️ Firebase غير مهيأ، محاكاة الإرسال');
        return { success: true, messageId: 'simulated' };
      }

      const message = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: notification.data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: 'montajati_notifications',
            sound: 'default',
            vibrationPattern: [1000, 500, 1000]
          }
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

      const response = await admin.messaging().send(message);
      console.log('✅ تم إرسال الإشعار بنجاح:', response);
      
      return { success: true, messageId: response };

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * تسجيل الإشعار في قاعدة البيانات
   */
  async logNotification(notificationData) {
    try {
      const logData = {
        user_phone: notificationData.user_id, // استخدام user_phone بدلاً من user_id مؤقتاً
        order_id: notificationData.order_id || null,
        notification_type: notificationData.type,
        title: notificationData.title,
        body: notificationData.body,
        data: {
          fcm_token: notificationData.fcm_token,
          request_id: notificationData.request_id || null
        },
        status: notificationData.status,
        error_message: notificationData.error_message,
        sent_at: notificationData.status === 'sent' ? new Date().toISOString() : null
      };

      const { error } = await supabase
        .from('notification_logs')
        .insert(logData);

      if (error) {
        console.error('❌ خطأ في تسجيل الإشعار:', error.message);
        // محاولة تسجيل في جدول بديل
        await this.logToSystemLogs(notificationData);
      } else {
        console.log('✅ تم تسجيل الإشعار في قاعدة البيانات');
      }
    } catch (error) {
      console.error('❌ خطأ في تسجيل الإشعار:', error.message);
      await this.logToSystemLogs(notificationData);
    }
  }

  /**
   * تسجيل في جدول system_logs كبديل
   */
  async logToSystemLogs(notificationData) {
    try {
      await supabase
        .from('system_logs')
        .insert({
          event_type: 'notification_sent',
          event_data: notificationData,
          service: 'targeted_notification_service'
        });
      console.log('✅ تم تسجيل الإشعار في system_logs');
    } catch (error) {
      console.error('❌ خطأ في تسجيل الإشعار في system_logs:', error.message);
    }
  }
}

module.exports = new TargetedNotificationService();
