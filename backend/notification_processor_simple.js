#!/usr/bin/env node

// ===================================
// معالج قائمة انتظار الإشعارات المبسط
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

class SimpleNotificationProcessor {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.isProcessing = false;
    this.processingInterval = null;
    
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
      } else {
        console.log('✅ Firebase Admin SDK مهيأ مسبقاً');
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

    this.isProcessing = true;
    console.log('🚀 بدء معالجة قائمة انتظار الإشعارات...');

    // معالجة فورية
    this.processQueue();

    // معالجة دورية كل 10 ثواني
    this.processingInterval = setInterval(() => {
      this.processQueue();
    }, 10000);
  }

  // ===================================
  // إيقاف المعالجة
  // ===================================
  stopProcessing() {
    if (this.processingInterval) {
      clearInterval(this.processingInterval);
      this.processingInterval = null;
    }
    this.isProcessing = false;
    console.log('⏹️ تم إيقاف معالج الإشعارات');
  }

  // ===================================
  // معالجة قائمة الانتظار
  // ===================================
  async processQueue() {
    try {
      // جلب الإشعارات المعلقة
      const { data: notifications, error } = await this.supabase
        .from('notification_queue')
        .select('*')
        .eq('status', 'pending')
        .order('priority', { ascending: false })
        .order('created_at', { ascending: true })
        .limit(5);

      if (error) {
        console.error('❌ خطأ في جلب الإشعارات:', error.message);
        return;
      }

      if (!notifications || notifications.length === 0) {
        return; // لا توجد إشعارات معلقة
      }

      console.log(`📬 معالجة ${notifications.length} إشعار...`);

      for (const notification of notifications) {
        await this.processNotification(notification);
      }

    } catch (error) {
      console.error('❌ خطأ في معالجة قائمة الانتظار:', error.message);
    }
  }

  // ===================================
  // معالجة إشعار واحد
  // ===================================
  async processNotification(notification) {
    try {
      console.log(`📱 معالجة إشعار: ${notification.order_id} → ${notification.user_phone}`);

      // تحديث حالة الإشعار إلى "processing"
      await this.supabase
        .from('notification_queue')
        .update({ status: 'processing' })
        .eq('id', notification.id);

      // محاولة إرسال الإشعار
      const success = await this.sendNotification(notification);

      if (success) {
        // تحديث حالة الإشعار إلى "sent"
        await this.supabase
          .from('notification_queue')
          .update({ 
            status: 'sent',
            processed_at: new Date().toISOString()
          })
          .eq('id', notification.id);

        // إضافة سجل الإشعار
        await this.logNotification(notification, true);

        console.log(`✅ تم إرسال الإشعار بنجاح: ${notification.order_id}`);
      } else {
        // زيادة عداد المحاولات
        const newRetryCount = (notification.retry_count || 0) + 1;
        
        if (newRetryCount >= 3) {
          // فشل نهائي
          await this.supabase
            .from('notification_queue')
            .update({ 
              status: 'failed',
              retry_count: newRetryCount,
              error_message: 'تجاوز الحد الأقصى للمحاولات'
            })
            .eq('id', notification.id);

          console.log(`❌ فشل نهائي في إرسال الإشعار: ${notification.order_id}`);
        } else {
          // إعادة المحاولة
          await this.supabase
            .from('notification_queue')
            .update({ 
              status: 'pending',
              retry_count: newRetryCount,
              scheduled_at: new Date(Date.now() + 30000).toISOString() // إعادة المحاولة بعد 30 ثانية
            })
            .eq('id', notification.id);

          console.log(`🔄 إعادة جدولة الإشعار: ${notification.order_id} (محاولة ${newRetryCount})`);
        }

        await this.logNotification(notification, false);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة الإشعار ${notification.id}:`, error.message);
      
      // تحديث حالة الإشعار إلى خطأ
      await this.supabase
        .from('notification_queue')
        .update({ 
          status: 'failed',
          error_message: error.message
        })
        .eq('id', notification.id);
    }
  }

  // ===================================
  // إرسال الإشعار
  // ===================================
  async sendNotification(notification) {
    try {
      // محاولة الحصول على FCM token للمستخدم من جدولين
      let tokens = [];

      // أولاً: جدول fcm_tokens
      const { data: fcmTokens } = await this.supabase
        .from('fcm_tokens')
        .select('token')
        .eq('user_phone', notification.user_phone)
        .eq('is_active', true);

      if (fcmTokens && fcmTokens.length > 0) {
        tokens = fcmTokens;
      } else {
        // ثانياً: جدول user_fcm_tokens (البديل)
        const { data: userTokens } = await this.supabase
          .from('user_fcm_tokens')
          .select('fcm_token as token')
          .eq('user_phone', notification.user_phone)
          .eq('is_active', true);

        if (userTokens && userTokens.length > 0) {
          tokens = userTokens;
        }
      }

      if (!tokens || tokens.length === 0) {
        console.log(`⚠️ لا يوجد FCM token للمستخدم: ${notification.user_phone}`);
        return false;
      }

      const notificationData = notification.notification_data;
      
      // إعداد رسالة Firebase
      const message = {
        notification: {
          title: notificationData.title,
          body: notificationData.message,
        },
        data: {
          order_id: notification.order_id,
          type: notificationData.type,
          priority: notificationData.priority.toString(),
          timestamp: notificationData.timestamp.toString()
        },
        android: {
          notification: {
            sound: 'default',
            priority: 'high'
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

      // إرسال لجميع الـ tokens
      let successCount = 0;
      for (const tokenData of tokens) {
        try {
          message.token = tokenData.token;
          await admin.messaging().send(message);
          successCount++;
        } catch (tokenError) {
          console.log(`⚠️ فشل في إرسال للتوكن: ${tokenError.message}`);
        }
      }

      return successCount > 0;

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار:', error.message);
      return false;
    }
  }

  // ===================================
  // تسجيل الإشعار
  // ===================================
  async logNotification(notification, isSuccessful) {
    try {
      await this.supabase
        .from('notification_logs')
        .insert({
          order_id: notification.order_id,
          user_phone: notification.user_phone,
          notification_type: 'order_status_change',
          status_change: `${notification.old_status} -> ${notification.new_status}`,
          title: notification.notification_data.title,
          message: notification.notification_data.message,
          is_successful: isSuccessful,
          sent_at: new Date().toISOString()
        });
    } catch (error) {
      console.error('❌ خطأ في تسجيل الإشعار:', error.message);
    }
  }
}

// تشغيل المعالج
if (require.main === module) {
  const processor = new SimpleNotificationProcessor();
  processor.startProcessing();

  // إيقاف نظيف عند الإنهاء
  process.on('SIGINT', () => {
    console.log('\n🛑 إيقاف معالج الإشعارات...');
    processor.stopProcessing();
    process.exit(0);
  });

  console.log('🎯 معالج الإشعارات يعمل... اضغط Ctrl+C للإيقاف');
}

module.exports = SimpleNotificationProcessor;
