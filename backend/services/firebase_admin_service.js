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
   * ✅ تهيئة Firebase Admin SDK محسنة للأمان
   */
  async initialize() {
    try {
      console.log('🔥 بدء تهيئة Firebase Admin SDK...');

      // ✅ طرق متعددة لتحميل Firebase credentials
      let serviceAccount;

      // الطريقة الأولى: من متغير البيئة JSON
      if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        try {
          serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
          console.log('✅ تم تحميل Firebase credentials من FIREBASE_SERVICE_ACCOUNT');
        } catch (parseError) {
          console.warn('⚠️ خطأ في تحليل FIREBASE_SERVICE_ACCOUNT JSON:', parseError.message);
        }
      }

      // الطريقة الثانية: من متغيرات البيئة المنفصلة (للحل مع Render)
      if (!serviceAccount && process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
        serviceAccount = {
          type: "service_account",
          project_id: process.env.FIREBASE_PROJECT_ID,
          private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID || "",
          private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'), // ✅ إصلاح مشكلة الأسطر الجديدة
          client_email: process.env.FIREBASE_CLIENT_EMAIL,
          client_id: process.env.FIREBASE_CLIENT_ID || "",
          auth_uri: "https://accounts.google.com/o/oauth2/auth",
          token_uri: "https://oauth2.googleapis.com/token",
          auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
          client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL || ""
        };
        console.log('✅ تم تحميل Firebase credentials من متغيرات البيئة المنفصلة');
      }

      // التحقق من وجود Service Account
      if (!serviceAccount) {
        throw new Error('❌ لم يتم العثور على Firebase credentials. تأكد من وجود FIREBASE_SERVICE_ACCOUNT أو متغيرات البيئة المطلوبة');
      }

      // التحقق من وجود الحقول المطلوبة
      const requiredFields = ['project_id', 'private_key', 'client_email'];
      for (const field of requiredFields) {
        if (!serviceAccount[field]) {
          throw new Error(`❌ حقل مفقود في Service Account: ${field}`);
        }
      }

      // تهيئة Firebase Admin إذا لم يكن مهيأ مسبقاً
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
        console.log('✅ تم تهيئة Firebase Admin بنجاح');
      } else {
        console.log('✅ Firebase Admin مهيأ مسبقاً');
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
          body: notification.body || 'لديك تحديث جديد'
          // ✅ إزالة الصورة الثابتة - ستُضاف حسب نوع الإشعار
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
            icon: '@mipmap/ic_launcher',
            color: '#FFD700'
            // ✅ إزالة imageUrl الثابت - سيُضاف حسب نوع الإشعار
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

      // ✅ إضافة الصورة فقط إذا تم تمريرها
      if (notification.image) {
        message.notification.image = notification.image;
        message.android.notification.imageUrl = notification.image;
      }

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
    const customerDisplayName = customerName || 'عزيزي العميل';

    let title = '';
    let body = '';

    // تحديد العنوان والرسالة حسب الحالة مع الإيموجي المناسب
    const statusConfig = {
      // الحالات الأساسية
      'active': {
        title: '📦 نشط',
        message: 'نشط'
      },
      'in_delivery': {
        title: '🚗 قيد التوصيل',
        message: 'قيد التوصيل'
      },
      'delivered': {
        title: '✅ تم التسليم',
        message: 'تم التسليم'
      },
      'cancelled': {
        title: '❌ ملغي',
        message: 'ملغي'
      },

      // حالات الوسيط التفصيلية
      'فعال': {
        title: '📦 فعال',
        message: 'فعال'
      },
      'قيد التوصيل الى الزبون (في عهدة المندوب)': {
        title: '🚗 قيد التوصيل',
        message: 'قيد التوصيل'
      },
      'تم تغيير محافظة الزبون': {
        title: '📍 تغيير المحافظة',
        message: 'تم تغيير محافظة الزبون'
      },
      'لا يرد': {
        title: '📞 لا يرد',
        message: 'لا يرد'
      },
      'لا يرد بعد الاتفاق': {
        title: '📞 لا يرد بعد الاتفاق',
        message: 'لا يرد بعد الاتفاق'
      },
      'مغلق': {
        title: '🔒 مغلق',
        message: 'مغلق'
      },
      'مغلق بعد الاتفاق': {
        title: '🔒 مغلق بعد الاتفاق',
        message: 'مغلق بعد الاتفاق'
      },
      'مؤجل': {
        title: '⏰ مؤجل',
        message: 'مؤجل'
      },
      'مؤجل لحين اعادة الطلب لاحقا': {
        title: '⏰ مؤجل لاحقاً',
        message: 'مؤجل لحين اعادة الطلب لاحقا'
      },
      'الغاء الطلب': {
        title: '❌ إلغاء الطلب',
        message: 'الغاء الطلب'
      },
      'رفض الطلب': {
        title: '🚫 رفض الطلب',
        message: 'رفض الطلب'
      },
      'مفصول عن الخدمة': {
        title: '⛔ مفصول عن الخدمة',
        message: 'مفصول عن الخدمة'
      },
      'طلب مكرر': {
        title: '🔄 طلب مكرر',
        message: 'طلب مكرر'
      },
      'مستلم مسبقا': {
        title: '✅ مستلم مسبقاً',
        message: 'مستلم مسبقا'
      },
      'الرقم غير معرف': {
        title: '📱 رقم غير معرف',
        message: 'الرقم غير معرف'
      },
      'الرقم غير داخل في الخدمة': {
        title: '📱 رقم خارج الخدمة',
        message: 'الرقم غير داخل في الخدمة'
      },
      'العنوان غير دقيق': {
        title: '📍 عنوان غير دقيق',
        message: 'العنوان غير دقيق'
      },
      'لم يطلب': {
        title: '🤷 لم يطلب',
        message: 'لم يطلب'
      },
      'حظر المندوب': {
        title: '🚫 حظر المندوب',
        message: 'حظر المندوب'
      },
      'لا يمكن الاتصال بالرقم': {
        title: '📞 لا يمكن الاتصال',
        message: 'لا يمكن الاتصال بالرقم'
      },
      'تغيير المندوب': {
        title: '👤 تغيير المندوب',
        message: 'تغيير المندوب'
      }
    };

    // الحصول على تكوين الحالة
    const config = statusConfig[newStatus];

    if (config) {
      title = config.title;
      body = `${customerDisplayName} - (${config.message})`;
    } else {
      // للحالات غير المعرفة
      title = '📦 تحديث حالة الطلب';
      body = `${customerDisplayName} - (${newStatus})`;
    }

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
    let title = '';
    let body = '';

    // تحديد العنوان والرسالة حسب الحالة
    if (status === 'processed' || status === 'completed') {
      // عند تحويل المبلغ
      title = '💛💛💛';
      body = `تم تحويل مبلغ ${amount} د.ع الى محفظتك`;
    } else if (status === 'rejected' || status === 'cancelled') {
      // عند إلغاء عملية السحب
      title = '💔💔💔';
      body = `تم الغاء عملية سحبك ${amount} د.ع`;
    } else {
      // للحالات الأخرى (pending, approved, etc.)
      const statusMessages = {
        'pending': 'في انتظار المراجعة',
        'approved': 'تم الموافقة'
      };
      const statusMessage = statusMessages[status] || status;
      title = '💰 تحديث طلب السحب';
      body = `تم تحديث حالة طلب سحب ${amount} د.ع إلى: ${statusMessage}`;
    }

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
   * إرسال إشعار (دالة مختصرة للتوافق)
   * @param {string} fcmToken - رمز FCM للمستخدم
   * @param {Object} notification - بيانات الإشعار
   * @param {Object} data - بيانات إضافية
   * @returns {Promise<Object>} نتيجة الإرسال
   */
  async sendNotification(fcmToken, notification, data = {}) {
    return await this.sendNotificationToUser(fcmToken, notification, data);
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

module.exports = { FirebaseAdminService, firebaseAdminService };
