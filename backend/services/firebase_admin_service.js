// ===================================
// خدمة Firebase Admin للإشعارات الفورية
// Firebase Admin Service for Push Notifications
// ===================================

const admin = require('firebase-admin');

class FirebaseAdminService {
  constructor() {
    this.initialized = false;
    this.messaging = null;
  }

  /**
   * تهيئة Firebase Admin SDK
   */
  async initialize() {
    try {
      console.log('🔥 بدء تهيئة Firebase Admin SDK...');

      // التحقق من وجود متغير البيئة المطلوب
      if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
        throw new Error('متغير البيئة مفقود: FIREBASE_SERVICE_ACCOUNT');
      }

      // تحليل Service Account JSON
      let serviceAccount;
      try {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      } catch (parseError) {
        throw new Error('خطأ في تحليل FIREBASE_SERVICE_ACCOUNT JSON: ' + parseError.message);
      }

      // التحقق من وجود الحقول المطلوبة
      const requiredFields = ['project_id', 'private_key', 'client_email'];
      for (const field of requiredFields) {
        if (!serviceAccount[field]) {
          throw new Error(`حقل مفقود في Service Account: ${field}`);
        }
      }

      // تهيئة Firebase Admin إذا لم يكن مهيأ مسبقاً
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
      }

      this.messaging = admin.messaging();
      this.initialized = true;

      console.log('✅ تم تهيئة Firebase Admin SDK بنجاح');
      console.log(`📋 Project ID: ${serviceAccount.project_id}`);
      console.log(`📧 Client Email: ${serviceAccount.client_email}`);

      return true;

    } catch (error) {
      console.error('❌ خطأ في تهيئة Firebase Admin SDK:', error.message);
      this.initialized = false;
      return false;
    }
  }

  /**
   * إرسال إشعار فوري لمستخدم واحد
   * @param {string} fcmToken - رمز FCM للمستخدم
   * @param {Object} notification - بيانات الإشعار
   * @param {Object} data - بيانات إضافية
   * @returns {Promise<Object>} نتيجة الإرسال
   */
  async sendNotificationToUser(fcmToken, notification, data = {}) {
    try {
      if (!this.initialized) {
        throw new Error('Firebase Admin غير مهيأ');
      }

      if (!fcmToken || !notification) {
        throw new Error('FCM Token أو بيانات الإشعار مفقودة');
      }

      // إعداد رسالة الإشعار
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title || 'إشعار جديد',
          body: notification.body || 'لديك تحديث جديد',
        },
        data: {
          ...data,
          timestamp: new Date().toISOString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        android: {
          notification: {
            channelId: 'montajati_notifications',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: 'ic_notification',
            color: '#FFD700'
          },
          priority: 'high'
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body
              },
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      // إرسال الإشعار
      const response = await this.messaging.send(message);
      
      console.log('✅ تم إرسال الإشعار بنجاح:', {
        messageId: response,
        token: fcmToken.substring(0, 20) + '...',
        title: notification.title
      });

      return {
        success: true,
        messageId: response,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار:', error.message);
      
      // التعامل مع الأخطاء المختلفة
      let errorType = 'unknown';
      if (error.code === 'messaging/registration-token-not-registered') {
        errorType = 'invalid_token';
      } else if (error.code === 'messaging/invalid-registration-token') {
        errorType = 'invalid_token';
      } else if (error.code === 'messaging/mismatched-credential') {
        errorType = 'auth_error';
      }

      return {
        success: false,
        error: error.message,
        errorType: errorType,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * إرسال إشعار تحديث حالة الطلب
   * @param {string} fcmToken - رمز FCM للمستخدم
   * @param {string} orderId - رقم الطلب
   * @param {string} newStatus - الحالة الجديدة
   * @param {string} customerName - اسم العميل
   * @returns {Promise<Object>} نتيجة الإرسال
   */
  async sendOrderStatusNotification(fcmToken, orderId, newStatus, customerName = '') {
    const statusMessages = {
      'pending': 'في انتظار التأكيد',
      'confirmed': 'تم تأكيد الطلب',
      'processing': 'جاري التحضير',
      'shipped': 'تم الشحن',
      'out_for_delivery': 'في الطريق للتوصيل',
      'delivered': 'تم التوصيل',
      'cancelled': 'تم إلغاء الطلب',
      'returned': 'تم إرجاع الطلب'
    };

    const statusMessage = statusMessages[newStatus] || newStatus;
    const title = '📦 تحديث حالة طلبك';
    const body = customerName 
      ? `مرحباً ${customerName}، تم تحديث حالة طلبك إلى: ${statusMessage}`
      : `تم تحديث حالة طلبك إلى: ${statusMessage}`;

    return await this.sendNotificationToUser(
      fcmToken,
      { title, body },
      {
        type: 'order_status_update',
        orderId: orderId.toString(),
        newStatus: newStatus,
        customerName: customerName || ''
      }
    );
  }

  /**
   * إرسال إشعار تحديث طلب السحب
   * @param {string} fcmToken - رمز FCM للمستخدم
   * @param {string} requestId - رقم طلب السحب
   * @param {string} amount - المبلغ
   * @param {string} status - حالة الطلب
   * @returns {Promise<Object>} نتيجة الإرسال
   */
  async sendWithdrawalStatusNotification(fcmToken, requestId, amount, status) {
    const statusMessages = {
      'pending': 'في انتظار المراجعة',
      'approved': 'تم الموافقة',
      'rejected': 'تم الرفض',
      'processed': 'تم التحويل'
    };

    const statusMessage = statusMessages[status] || status;
    const title = '💰 تحديث طلب السحب';
    const body = `تم تحديث حالة طلب سحب ${amount} ريال إلى: ${statusMessage}`;

    return await this.sendNotificationToUser(
      fcmToken,
      { title, body },
      {
        type: 'withdrawal_status_update',
        requestId: requestId.toString(),
        amount: amount.toString(),
        status: status
      }
    );
  }

  /**
   * إرسال إشعار عام
   * @param {string} fcmToken - رمز FCM للمستخدم
   * @param {string} title - عنوان الإشعار
   * @param {string} message - نص الإشعار
   * @param {Object} additionalData - بيانات إضافية
   * @returns {Promise<Object>} نتيجة الإرسال
   */
  async sendGeneralNotification(fcmToken, title, message, additionalData = {}) {
    return await this.sendNotificationToUser(
      fcmToken,
      { title, body: message },
      {
        type: 'general',
        ...additionalData
      }
    );
  }

  /**
   * التحقق من صحة FCM Token
   * @param {string} fcmToken - رمز FCM للتحقق منه
   * @returns {Promise<boolean>} صحة الرمز
   */
  async validateFCMToken(fcmToken) {
    try {
      if (!this.initialized) {
        return false;
      }

      // إرسال رسالة تجريبية للتحقق من صحة الرمز
      const testMessage = {
        token: fcmToken,
        data: {
          test: 'validation'
        },
        dryRun: true // لا يتم إرسال الرسالة فعلياً
      };

      await this.messaging.send(testMessage);
      return true;

    } catch (error) {
      console.log(`⚠️ FCM Token غير صالح: ${error.message}`);
      return false;
    }
  }

  /**
   * الحصول على معلومات الخدمة
   * @returns {Object} معلومات الخدمة
   */
  getServiceInfo() {
    return {
      initialized: this.initialized,
      hasMessaging: !!this.messaging,
      projectId: process.env.FIREBASE_PROJECT_ID || 'غير محدد'
    };
  }

  /**
   * إيقاف الخدمة
   */
  async shutdown() {
    try {
      console.log('🔄 إيقاف Firebase Admin Service...');
      this.initialized = false;
      this.messaging = null;
      console.log('✅ تم إيقاف Firebase Admin Service بنجاح');
    } catch (error) {
      console.error('❌ خطأ في إيقاف Firebase Admin Service:', error);
    }
  }
}

// إنشاء instance واحد للخدمة
const firebaseAdminService = new FirebaseAdminService();

module.exports = firebaseAdminService;
