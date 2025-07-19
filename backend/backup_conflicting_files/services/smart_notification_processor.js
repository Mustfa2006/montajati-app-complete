// ===================================
// معالج قائمة انتظار الإشعارات الذكي
// ===================================

const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

class SmartNotificationProcessor {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.isProcessing = false;
    this.processingInterval = null;
    this.config = {
      batchSize: 10,
      processingInterval: 5000, // 5 ثواني
      maxRetries: 3,
      retryDelay: 30000, // 30 ثانية
    };
    
    this.initializeFirebase();
  }

  // ===================================
  // تهيئة Firebase
  // ===================================
  initializeFirebase() {
    try {
      if (admin.apps.length === 0) {
        const firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
          credential: admin.credential.cert(firebaseConfig),
          projectId: firebaseConfig.project_id
        });
        console.log('✅ تم تهيئة Firebase Admin SDK');
      }
    } catch (error) {
      console.error('❌ خطأ في تهيئة Firebase:', error.message);
    }
  }

  // ===================================
  // بدء معالجة قائمة الانتظار
  // ===================================
  startProcessing() {
    if (this.isProcessing) {
      console.log('⚠️ معالج الإشعارات يعمل بالفعل');
      return;
    }

    console.log('🚀 بدء معالج الإشعارات الذكي...');
    this.isProcessing = true;

    // معالجة فورية
    this.processQueue();

    // معالجة دورية
    this.processingInterval = setInterval(() => {
      this.processQueue();
    }, this.config.processingInterval);
  }

  // ===================================
  // إيقاف المعالجة
  // ===================================
  stopProcessing() {
    console.log('⏹️ إيقاف معالج الإشعارات...');
    this.isProcessing = false;
    
    if (this.processingInterval) {
      clearInterval(this.processingInterval);
      this.processingInterval = null;
    }
  }

  // ===================================
  // معالجة قائمة انتظار الإشعارات
  // ===================================
  async processQueue() {
    try {
      // جلب الإشعارات المعلقة مرتبة حسب الأولوية والوقت
      const { data: pendingNotifications, error } = await this.supabase
        .from('notification_queue')
        .select('*')
        .in('status', ['pending', 'failed'])
        .lt('retry_count', this.config.maxRetries)
        .lte('scheduled_at', new Date().toISOString())
        .order('priority', { ascending: false })
        .order('created_at', { ascending: true })
        .limit(this.config.batchSize);

      if (error) {
        console.error('❌ خطأ في جلب قائمة الإشعارات:', error.message);
        return;
      }

      if (!pendingNotifications || pendingNotifications.length === 0) {
        return; // لا توجد إشعارات معلقة
      }

      console.log(`📋 معالجة ${pendingNotifications.length} إشعار معلق...`);

      // معالجة كل إشعار
      for (const notification of pendingNotifications) {
        await this.processNotification(notification);
        
        // تأخير قصير بين الإشعارات لتجنب الحمل الزائد
        await new Promise(resolve => setTimeout(resolve, 100));
      }

    } catch (error) {
      console.error('❌ خطأ في معالجة قائمة الإشعارات:', error.message);
    }
  }

  // ===================================
  // معالجة إشعار واحد
  // ===================================
  async processNotification(notification) {
    try {
      console.log(`📤 معالجة إشعار: ${notification.id} للمستخدم ${notification.user_phone}`);

      // تحديث حالة الإشعار إلى "قيد المعالجة"
      await this.updateNotificationStatus(notification.id, 'processing');

      // الحصول على FCM Token
      const fcmToken = await this.getFCMToken(notification.user_phone);
      
      if (!fcmToken) {
        await this.handleNotificationFailure(
          notification.id,
          'لا يوجد FCM Token للمستخدم'
        );
        return;
      }

      // إرسال الإشعار
      const result = await this.sendFirebaseNotification(fcmToken, notification);

      if (result.success) {
        // نجح الإرسال
        await this.handleNotificationSuccess(notification, fcmToken, result);
      } else {
        // فشل الإرسال
        await this.handleNotificationFailure(notification.id, result.error);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة الإشعار ${notification.id}:`, error.message);
      await this.handleNotificationFailure(notification.id, error.message);
    }
  }

  // ===================================
  // الحصول على FCM Token للمستخدم
  // ===================================
  async getFCMToken(userPhone) {
    try {
      // البحث في جدول user_fcm_tokens
      const { data: tokenData, error } = await this.supabase
        .from('user_fcm_tokens')
        .select('fcm_token')
        .eq('user_phone', userPhone)
        .eq('is_active', true)
        .order('updated_at', { ascending: false })
        .limit(1)
        .single();

      if (error || !tokenData) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${userPhone}`);
        return null;
      }

      return tokenData.fcm_token;
    } catch (error) {
      console.error(`❌ خطأ في جلب FCM Token للمستخدم ${userPhone}:`, error.message);
      return null;
    }
  }

  // ===================================
  // إرسال إشعار Firebase
  // ===================================
  async sendFirebaseNotification(fcmToken, notification) {
    try {
      const notificationData = notification.notification_data;
      
      const message = {
        token: fcmToken,
        notification: {
          title: notificationData.title,
          body: notificationData.message
        },
        data: {
          type: notificationData.type || 'order_status_change',
          order_id: notification.order_id,
          old_status: notification.old_status || '',
          new_status: notification.new_status,
          customer_name: notification.customer_name,
          timestamp: notificationData.timestamp?.toString() || Date.now().toString(),
          emoji: notificationData.emoji || '📋'
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'montajati_notifications',
            sound: 'default',
            vibrationPattern: [1000, 500, 1000],
            priority: 'high'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              alert: {
                title: notificationData.title,
                body: notificationData.message
              }
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      
      console.log(`✅ تم إرسال الإشعار بنجاح: ${response}`);
      
      return {
        success: true,
        messageId: response,
        fcmToken: fcmToken
      };

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار Firebase:', error.message);
      
      return {
        success: false,
        error: error.message,
        errorCode: error.code
      };
    }
  }

  // ===================================
  // معالجة نجاح الإرسال
  // ===================================
  async handleNotificationSuccess(notification, fcmToken, result) {
    try {
      // تحديث حالة الإشعار في قائمة الانتظار
      await this.updateNotificationStatus(notification.id, 'sent', new Date().toISOString());

      // إضافة سجل في notification_logs
      await this.supabase
        .from('notification_logs')
        .insert({
          order_id: notification.order_id,
          user_phone: notification.user_phone,
          notification_type: 'order_status_change',
          status_change: `${notification.old_status || 'غير محدد'} -> ${notification.new_status}`,
          title: notification.notification_data.title,
          message: notification.notification_data.message,
          fcm_token: fcmToken,
          firebase_response: result,
          is_successful: true
        });

      console.log(`✅ تم تسجيل نجاح الإشعار ${notification.id}`);

    } catch (error) {
      console.error(`❌ خطأ في تسجيل نجاح الإشعار ${notification.id}:`, error.message);
    }
  }

  // ===================================
  // معالجة فشل الإرسال
  // ===================================
  async handleNotificationFailure(notificationId, errorMessage) {
    try {
      // جلب بيانات الإشعار الحالية
      const { data: notification } = await this.supabase
        .from('notification_queue')
        .select('retry_count, max_retries')
        .eq('id', notificationId)
        .single();

      if (!notification) return;

      const newRetryCount = (notification.retry_count || 0) + 1;
      const maxRetries = notification.max_retries || this.config.maxRetries;

      if (newRetryCount >= maxRetries) {
        // تجاوز الحد الأقصى للمحاولات
        await this.updateNotificationStatus(notificationId, 'failed', null, errorMessage);
        console.log(`❌ فشل نهائي في الإشعار ${notificationId}: ${errorMessage}`);
      } else {
        // إعادة جدولة للمحاولة مرة أخرى
        const nextAttempt = new Date(Date.now() + this.config.retryDelay);
        
        await this.supabase
          .from('notification_queue')
          .update({
            status: 'pending',
            retry_count: newRetryCount,
            scheduled_at: nextAttempt.toISOString(),
            error_message: errorMessage
          })
          .eq('id', notificationId);

        console.log(`🔄 إعادة جدولة الإشعار ${notificationId} للمحاولة ${newRetryCount}/${maxRetries}`);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة فشل الإشعار ${notificationId}:`, error.message);
    }
  }

  // ===================================
  // تحديث حالة الإشعار
  // ===================================
  async updateNotificationStatus(notificationId, status, processedAt = null, errorMessage = null) {
    const updateData = { status };
    
    if (processedAt) {
      updateData.processed_at = processedAt;
    }
    
    if (errorMessage) {
      updateData.error_message = errorMessage;
    }

    await this.supabase
      .from('notification_queue')
      .update(updateData)
      .eq('id', notificationId);
  }

  // ===================================
  // إحصائيات المعالجة
  // ===================================
  async getProcessingStats() {
    try {
      const { data: stats } = await this.supabase
        .from('notification_queue')
        .select('status')
        .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

      const summary = {
        total: stats?.length || 0,
        pending: stats?.filter(s => s.status === 'pending').length || 0,
        processing: stats?.filter(s => s.status === 'processing').length || 0,
        sent: stats?.filter(s => s.status === 'sent').length || 0,
        failed: stats?.filter(s => s.status === 'failed').length || 0
      };

      return summary;
    } catch (error) {
      console.error('❌ خطأ في جلب إحصائيات المعالجة:', error.message);
      return null;
    }
  }
}

module.exports = SmartNotificationProcessor;
