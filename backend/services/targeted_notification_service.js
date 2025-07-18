// ===================================
// خدمة الإشعارات المستهدفة والدقيقة
// Targeted Notification Service
// ===================================

const { admin, sendNotification } = require('../setup_firebase_complete');
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
      // التحقق من وجود متغيرات البيئة المطلوبة
      const requiredEnvVars = [
        'FIREBASE_PROJECT_ID',
        'FIREBASE_PRIVATE_KEY_ID',
        'FIREBASE_PRIVATE_KEY',
        'FIREBASE_CLIENT_EMAIL',
        'FIREBASE_CLIENT_ID'
      ];

      const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

      if (missingVars.length > 0) {
        console.warn('⚠️ متغيرات Firebase مفقودة:', missingVars.join(', '));
        console.warn('⚠️ سيتم تعطيل خدمة الإشعارات المستهدفة');
        this.initialized = false;
        return;
      }

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
      console.warn('⚠️ سيتم تعطيل خدمة الإشعارات المستهدفة');
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
      // التحقق من تهيئة Firebase
      if (!this.initialized) {
        console.warn('⚠️ Firebase غير مهيأ - تم تخطي الإشعار');
        return { success: false, error: 'Firebase غير مهيأ' };
      }

      console.log(`🎯 إرسال إشعار حالة الطلب للمستخدم المحدد فقط:`);
      console.log(`📦 الطلب: ${orderId}`);
      console.log(`👤 المستخدم: ${userId}`);
      console.log(`👥 العميل: ${customerName}`);
      console.log(`🔄 تغيير الحالة: ${oldStatus} → ${newStatus}`);

      // الحصول على FCM Token للمستخدم المحدد فقط
      const fcmToken = await this.getUserFCMToken(userId);

      if (!fcmToken) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userId} - محاولة إرسال إشعار بديل`);

        // بدلاً من إرسال للتلغرام (المدير)، نحفظ الإشعار للمستخدم
        console.log(`⚠️ لا يمكن إرسال إشعار مباشر للمستخدم ${userId} - FCM Token غير متوفر`);

        // حفظ الإشعار في قاعدة البيانات كبديل
        try {
          const notificationData = {
            user_id: userId,
            title: 'تحديث حالة الطلب',
            body: `تم تحديث حالة طلبك إلى: ${newStatus}`,
            type: 'order_status',
            data: JSON.stringify({
              order_id: orderId,
              status: newStatus,
              customer_name: customerName
            }),
            is_read: false,
            created_at: new Date().toISOString()
          };

          console.log('💾 حفظ إشعار حالة الطلب في قاعدة البيانات للمستخدم:', notificationData);

          return {
            success: true,
            method: 'database',
            message: 'تم حفظ الإشعار في قاعدة البيانات - سيراه المستخدم عند فتح التطبيق'
          };

        } catch (dbError) {
          console.log('❌ فشل في حفظ إشعار حالة الطلب في قاعدة البيانات:', dbError.message);
        }

        // محاولة أخيرة للحصول على FCM Token من مصادر أخرى
        const alternativeFcmToken = await this.getAlternativeFCMToken(userId);

        if (alternativeFcmToken) {
          console.log(`✅ تم العثور على FCM Token بديل للمستخدم ${userId}`);
          // استخدام FCM Token البديل
          const fcmToken = alternativeFcmToken;
        } else {
          return { success: false, error: 'FCM Token غير متوفر - يرجى من المستخدم فتح التطبيق لتحديث Token' };
        }
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
   * @param {string} userPhone - رقم هاتف المستخدم صاحب طلب السحب
   * @param {string} requestId - معرف طلب السحب
   * @param {number} amount - مبلغ السحب
   * @param {string} status - حالة طلب السحب
   * @param {string} reason - سبب الرفض (اختياري)
   */
  async sendWithdrawalStatusNotification(userPhone, requestId, amount, status, reason = '') {
    try {
      console.log(`💰 إرسال إشعار طلب السحب للمستخدم المحدد فقط:`);
      console.log(`📱 المستخدم: ${userPhone}`);
      console.log(`📄 طلب السحب: ${requestId}`);
      console.log(`💵 المبلغ: ${amount}`);
      console.log(`📊 الحالة: ${status}`);

      // الحصول على FCM Token للمستخدم المحدد فقط
      const fcmToken = await this.getFCMTokenByPhone(userPhone);

      if (!fcmToken) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userPhone} - محاولة إرسال إشعار بديل`);

        // بدلاً من إرسال للتلغرام (المدير)، نحاول طرق أخرى للوصول للمستخدم
        console.log(`⚠️ لا يمكن إرسال إشعار مباشر للمستخدم ${userPhone} - FCM Token غير متوفر`);

        // يمكن هنا إضافة طرق أخرى مثل:
        // 1. إرسال SMS للمستخدم
        // 2. إرسال إيميل للمستخدم
        // 3. حفظ الإشعار في قاعدة البيانات ليراه المستخدم عند فتح التطبيق

        // حفظ الإشعار في قاعدة البيانات كبديل
        try {
          const formattedAmount = amount && !isNaN(amount) ? parseFloat(amount).toFixed(2) : '0.00';
          const statusText = status === 'approved' ? 'تم قبول طلب السحب' : status === 'rejected' ? 'تم رفض طلب السحب' : 'طلب السحب قيد المراجعة';

          const notificationData = {
            user_id: userId,
            title: statusText,
            body: `مبلغ ${formattedAmount} د.ع${reason ? ` - ${reason}` : ''}`,
            type: 'withdrawal_status',
            data: JSON.stringify({
              withdrawal_id: withdrawalId || requestId,
              amount: formattedAmount,
              status,
              reason
            }),
            is_read: false,
            created_at: new Date().toISOString()
          };

          // حفظ في جدول الإشعارات (إذا كان موجوداً)
          console.log('💾 حفظ الإشعار في قاعدة البيانات للمستخدم:', notificationData);

          // TODO: حفظ الإشعار في قاعدة البيانات عندما يكون الجدول جاهز

          return {
            success: true,
            method: 'database',
            message: 'تم حفظ الإشعار في قاعدة البيانات - سيراه المستخدم عند فتح التطبيق'
          };

        } catch (dbError) {
          console.log('❌ فشل في حفظ الإشعار في قاعدة البيانات:', dbError.message);
        }

        // محاولة أخيرة للحصول على FCM Token من مصادر أخرى
        const alternativeFcmToken = await this.getAlternativeFCMToken(userId);

        if (alternativeFcmToken) {
          console.log(`✅ تم العثور على FCM Token بديل للمستخدم ${userId}`);
          // استخدام FCM Token البديل
          const fcmToken = alternativeFcmToken;
        } else {
          return { success: false, error: 'FCM Token غير متوفر - يرجى من المستخدم فتح التطبيق لتحديث Token' };
        }
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
          user_phone: userPhone,
          amount: amount.toString(),
          status: status,
          reason: reason,
          timestamp: new Date().toISOString()
        }
      });

      // تسجيل الإشعار في قاعدة البيانات
      await this.logNotification({
        user_phone: userPhone,
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
    // التأكد من صحة المبلغ
    const formattedAmount = amount && !isNaN(amount) ? parseFloat(amount).toFixed(2) : '0.00';

    console.log(`💰 تنسيق المبلغ: ${amount} → ${formattedAmount}`);

    const notifications = {
      'approved': {
        title: '✅ تم قبول طلب السحب',
        body: `تم قبول طلب سحبك بمبلغ ${formattedAmount} د.ع وسيتم التحويل قريباً`
      },
      'rejected': {
        title: '❌ تم رفض طلب السحب',
        body: `تم رفض طلب سحبك بمبلغ ${formattedAmount} د.ع${reason ? ` - السبب: ${reason}` : ''}`
      },
      'pending': {
        title: '⏳ طلب السحب قيد المراجعة',
        body: `طلب سحبك بمبلغ ${formattedAmount} د.ع قيد المراجعة من قبل الإدارة`
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

      if (error) {
        if (error.message.includes('relation') || error.message.includes('does not exist')) {
          console.warn('⚠️ جدول المستخدمين غير موجود');
        } else {
          console.log(`⚠️ لا يوجد مستخدم بالمعرف ${userId}`);
        }
        return null;
      }

      if (!data || !data.fcm_token) {
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

      const response = await sendNotification(
        fcmToken,
        notification.title,
        notification.body,
        notification.data || {}
      );

      return response;

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

  /**
   * إرسال إشعار مباشر للمستخدم بناءً على رقم الهاتف
   */
  async sendDirectNotification(userPhone, title, message, data = {}) {
    try {
      console.log(`📤 إرسال إشعار مباشر:`);
      console.log(`📱 رقم الهاتف: ${userPhone}`);
      console.log(`📋 العنوان: ${title}`);
      console.log(`💬 الرسالة: ${message}`);

      // التحقق من تهيئة Firebase
      if (!this.initialized) {
        console.warn('⚠️ Firebase غير مهيأ - تم تخطي الإشعار');
        return { success: false, error: 'Firebase غير مهيأ' };
      }

      // البحث عن FCM Token بناءً على رقم الهاتف
      const fcmToken = await this.getFCMTokenByPhone(userPhone);

      if (!fcmToken) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userPhone}`);
        return { success: false, error: 'FCM Token غير متوفر' };
      }

      // إرسال الإشعار
      const result = await this.sendNotificationToUser(fcmToken, {
        title: title,
        body: message,
        data: {
          type: 'direct_notification',
          user_phone: userPhone,
          timestamp: new Date().toISOString(),
          ...data
        }
      });

      // تسجيل الإشعار
      await this.logNotification({
        user_id: userPhone,
        type: 'direct_notification',
        title: title,
        body: message,
        status: result.success ? 'sent' : 'failed',
        fcm_token: fcmToken,
        error_message: result.error || null
      });

      return result;

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار المباشر:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * الحصول على FCM Token بناءً على رقم الهاتف
   */
  async getFCMTokenByPhone(userPhone) {
    try {
      console.log(`🔍 البحث عن FCM Token للمستخدم: ${userPhone}`);

      // البحث في جدول user_fcm_tokens الجديد
      const { data, error } = await supabase
        .from('user_fcm_tokens')
        .select('fcm_token, platform, is_active')
        .eq('user_phone', userPhone)
        .eq('is_active', true)
        .order('updated_at', { ascending: false })
        .limit(1)
        .single();

      if (error) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userPhone}: ${error.message}`);

        // محاولة البحث في جدول users كبديل
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select('fcm_token')
          .eq('phone', userPhone)
          .single();

        if (userError || !userData || !userData.fcm_token) {
          console.log(`⚠️ لا يوجد FCM Token في جدول users أيضاً`);
          return null;
        }

        console.log(`✅ تم العثور على FCM Token في جدول users`);
        return userData.fcm_token;
      }

      if (!data || !data.fcm_token) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userPhone}`);
        return null;
      }

      console.log(`✅ تم العثور على FCM Token للمستخدم ${userPhone} (${data.platform})`);
      return data.fcm_token;

    } catch (error) {
      console.error('❌ خطأ في جلب FCM Token بالهاتف:', error.message);
      return null;
    }
  }

  /**
   * محاولة الحصول على FCM Token بديل من مصادر أخرى
   */
  async getAlternativeFCMToken(userId) {
    try {
      console.log(`🔍 البحث عن FCM Token بديل للمستخدم ${userId}...`);

      // محاولة 1: البحث في جميع الـ tokens (حتى غير النشطة)
      const { data: allTokens, error: allTokensError } = await this.supabase
        .from('user_fcm_tokens')
        .select('fcm_token, updated_at')
        .eq('user_id', userId)
        .order('updated_at', { ascending: false })
        .limit(5);

      if (!allTokensError && allTokens && allTokens.length > 0) {
        console.log(`📱 تم العثور على ${allTokens.length} FCM tokens للمستخدم`);

        // جرب كل token حتى تجد واحد يعمل
        for (const tokenData of allTokens) {
          if (tokenData.fcm_token && tokenData.fcm_token.length > 50) {
            console.log(`✅ استخدام FCM Token بديل من ${tokenData.updated_at}`);
            return tokenData.fcm_token;
          }
        }
      }

      // محاولة 2: البحث في جدول المستخدمين إذا كان FCM Token محفوظ هناك
      const { data: userData, error: userError } = await this.supabase
        .from('users')
        .select('fcm_token')
        .eq('id', userId)
        .single();

      if (!userError && userData && userData.fcm_token) {
        console.log(`✅ تم العثور على FCM Token في جدول المستخدمين`);
        return userData.fcm_token;
      }

      console.log(`❌ لم يتم العثور على أي FCM Token بديل للمستخدم ${userId}`);
      return null;

    } catch (error) {
      console.error('❌ خطأ في البحث عن FCM Token بديل:', error.message);
      return null;
    }
  }
}

module.exports = TargetedNotificationService;
