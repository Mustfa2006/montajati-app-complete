// ===================================
// خدمة الإشعارات المستهدفة الاحترافية
// Professional Targeted Notification Service
// ===================================

const { createClient } = require('@supabase/supabase-js');
const firebaseAdminService = require('./firebase_admin_service');

class TargetedNotificationService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.initialized = false;
  }

  /**
   * تهيئة خدمة الإشعارات المستهدفة
   */
  async initialize() {
    try {
      console.log('🎯 بدء تهيئة خدمة الإشعارات المستهدفة...');
      
      // تهيئة Firebase Admin
      const firebaseInitialized = await firebaseAdminService.initialize();
      
      if (!firebaseInitialized) {
        throw new Error('فشل في تهيئة Firebase Admin');
      }
      
      this.initialized = true;
      console.log('✅ تم تهيئة خدمة الإشعارات المستهدفة بنجاح');
      
      return true;
    } catch (error) {
      console.error('❌ خطأ في تهيئة خدمة الإشعارات المستهدفة:', error.message);
      this.initialized = false;
      return false;
    }
  }

  /**
   * الحصول على FCM Token للمستخدم
   * @param {string} userPhone - رقم هاتف المستخدم
   * @returns {Promise<string|null>} FCM Token أو null
   */
  async getUserFCMToken(userPhone) {
    try {
      const { data, error } = await this.supabase
        .rpc('get_user_fcm_token', { p_user_phone: userPhone });

      if (error) {
        console.error('❌ خطأ في الحصول على FCM Token:', error.message);
        return null;
      }

      if (data && data.length > 0) {
        const tokenData = data[0];
        
        // تحديث آخر استخدام للـ Token
        await this.updateTokenLastUsed(userPhone, tokenData.fcm_token);
        
        return tokenData.fcm_token;
      }

      return null;
    } catch (error) {
      console.error('❌ خطأ في الحصول على FCM Token:', error.message);
      return null;
    }
  }

  /**
   * تحديث آخر استخدام للـ Token
   * @param {string} userPhone - رقم هاتف المستخدم
   * @param {string} fcmToken - FCM Token
   */
  async updateTokenLastUsed(userPhone, fcmToken) {
    try {
      await this.supabase
        .from('fcm_tokens')
        .update({ last_used_at: new Date().toISOString() })
        .eq('user_phone', userPhone)
        .eq('fcm_token', fcmToken);
    } catch (error) {
      console.error('⚠️ خطأ في تحديث آخر استخدام للـ Token:', error.message);
    }
  }

  /**
   * إرسال إشعار تحديث حالة الطلب
   * @param {string} userPhone - رقم هاتف المستخدم
   * @param {string} orderId - رقم الطلب
   * @param {string} newStatus - الحالة الجديدة
   * @param {string} customerName - اسم العميل
   * @param {string} notes - ملاحظات إضافية
   * @returns {Promise<Object>} نتيجة الإرسال
   */
  async sendOrderStatusNotification(userPhone, orderId, newStatus, customerName = '', notes = '') {
    try {
      if (!this.initialized) {
        throw new Error('خدمة الإشعارات غير مهيأة');
      }

      console.log(`📱 إرسال إشعار تحديث الطلب للمستخدم: ${userPhone}`);
      
      // الحصول على FCM Token
      const fcmToken = await this.getUserFCMToken(userPhone);
      
      if (!fcmToken) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم: ${userPhone}`);
        return {
          success: false,
          error: 'لا يوجد FCM Token للمستخدم',
          userPhone: userPhone
        };
      }

      // إرسال الإشعار
      const result = await firebaseAdminService.sendOrderStatusNotification(
        fcmToken,
        orderId,
        newStatus,
        customerName
      );

      // تسجيل النتيجة في قاعدة البيانات
      await this.logNotification({
        user_phone: userPhone,
        fcm_token: fcmToken,
        notification_type: 'order_status_update',
        title: '📦 تحديث حالة طلبك',
        message: `تم تحديث حالة طلبك إلى: ${newStatus}`,
        data: {
          orderId: orderId,
          newStatus: newStatus,
          customerName: customerName,
          notes: notes
        },
        success: result.success,
        error_message: result.error || null,
        firebase_message_id: result.messageId || null
      });

      return {
        success: result.success,
        userPhone: userPhone,
        orderId: orderId,
        messageId: result.messageId,
        error: result.error
      };

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار تحديث الطلب:', error.message);
      
      return {
        success: false,
        error: error.message,
        userPhone: userPhone,
        orderId: orderId
      };
    }
  }

  /**
   * إرسال إشعار تحديث طلب السحب
   * @param {string} userPhone - رقم هاتف المستخدم
   * @param {string} requestId - رقم طلب السحب
   * @param {string} amount - المبلغ
   * @param {string} status - حالة الطلب
   * @param {string} reason - سبب التحديث
   * @returns {Promise<Object>} نتيجة الإرسال
   */
  async sendWithdrawalStatusNotification(userPhone, requestId, amount, status, reason = '') {
    try {
      if (!this.initialized) {
        throw new Error('خدمة الإشعارات غير مهيأة');
      }

      console.log(`💰 إرسال إشعار تحديث طلب السحب للمستخدم: ${userPhone}`);
      
      // الحصول على FCM Token
      const fcmToken = await this.getUserFCMToken(userPhone);
      
      if (!fcmToken) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم: ${userPhone}`);
        return {
          success: false,
          error: 'لا يوجد FCM Token للمستخدم',
          userPhone: userPhone
        };
      }

      // إرسال الإشعار
      const result = await firebaseAdminService.sendWithdrawalStatusNotification(
        fcmToken,
        requestId,
        amount,
        status
      );

      // تسجيل النتيجة في قاعدة البيانات
      await this.logNotification({
        user_phone: userPhone,
        fcm_token: fcmToken,
        notification_type: 'withdrawal_status_update',
        title: '💰 تحديث طلب السحب',
        message: `تم تحديث حالة طلب سحب ${amount} ريال إلى: ${status}`,
        data: {
          requestId: requestId,
          amount: amount,
          status: status,
          reason: reason
        },
        success: result.success,
        error_message: result.error || null,
        firebase_message_id: result.messageId || null
      });

      return {
        success: result.success,
        userPhone: userPhone,
        requestId: requestId,
        messageId: result.messageId,
        error: result.error
      };

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار تحديث طلب السحب:', error.message);
      
      return {
        success: false,
        error: error.message,
        userPhone: userPhone,
        requestId: requestId
      };
    }
  }

  /**
   * إرسال إشعار عام للمستخدم
   * @param {string} userPhone - رقم هاتف المستخدم
   * @param {string} title - عنوان الإشعار
   * @param {string} message - نص الإشعار
   * @param {Object} additionalData - بيانات إضافية
   * @returns {Promise<Object>} نتيجة الإرسال
   */
  async sendGeneralNotification(userPhone, title, message, additionalData = {}) {
    try {
      if (!this.initialized) {
        throw new Error('خدمة الإشعارات غير مهيأة');
      }

      console.log(`📢 إرسال إشعار عام للمستخدم: ${userPhone}`);
      
      // الحصول على FCM Token
      const fcmToken = await this.getUserFCMToken(userPhone);
      
      if (!fcmToken) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم: ${userPhone}`);
        return {
          success: false,
          error: 'لا يوجد FCM Token للمستخدم',
          userPhone: userPhone
        };
      }

      // إرسال الإشعار
      const result = await firebaseAdminService.sendGeneralNotification(
        fcmToken,
        title,
        message,
        additionalData
      );

      // تسجيل النتيجة في قاعدة البيانات
      await this.logNotification({
        user_phone: userPhone,
        fcm_token: fcmToken,
        notification_type: 'general',
        title: title,
        message: message,
        data: additionalData,
        success: result.success,
        error_message: result.error || null,
        firebase_message_id: result.messageId || null
      });

      return {
        success: result.success,
        userPhone: userPhone,
        messageId: result.messageId,
        error: result.error
      };

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار العام:', error.message);
      
      return {
        success: false,
        error: error.message,
        userPhone: userPhone
      };
    }
  }

  /**
   * تسجيل الإشعار في قاعدة البيانات
   * @param {Object} notificationData - بيانات الإشعار
   */
  async logNotification(notificationData) {
    try {
      await this.supabase
        .from('notification_logs')
        .insert({
          ...notificationData,
          sent_at: new Date().toISOString()
        });
    } catch (error) {
      console.error('⚠️ خطأ في تسجيل الإشعار:', error.message);
    }
  }

  /**
   * الحصول على معلومات الخدمة
   * @returns {Object} معلومات الخدمة
   */
  getServiceInfo() {
    return {
      initialized: this.initialized,
      firebase: firebaseAdminService.getServiceInfo()
    };
  }
}

// إنشاء instance واحد للخدمة
const targetedNotificationService = new TargetedNotificationService();

module.exports = targetedNotificationService;
