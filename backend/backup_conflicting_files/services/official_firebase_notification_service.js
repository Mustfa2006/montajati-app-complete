// ===================================
// خدمة الإشعارات الرسمية عبر Firebase
// ===================================

require('dotenv').config();
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

class OfficialFirebaseNotificationService {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.isRunning = false;
    this.processingInterval = null;
    this.firebaseInitialized = false;
    
    this.config = {
      batchSize: 10,
      processingInterval: 5000, // 5 ثواني
      maxRetries: 3,
      retryDelay: 30000 // 30 ثانية
    };
    
    this.initializeFirebase();
  }

  // ===================================
  // تهيئة Firebase الرسمي
  // ===================================
  initializeFirebase() {
    try {
      console.log('🔥 تهيئة Firebase Admin SDK الرسمي...');
      
      if (admin.apps.length === 0) {
        const firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        
        admin.initializeApp({
          credential: admin.credential.cert(firebaseConfig),
          projectId: firebaseConfig.project_id
        });
        
        console.log(`✅ تم تهيئة Firebase بنجاح - Project: ${firebaseConfig.project_id}`);
        this.firebaseInitialized = true;
      } else {
        console.log('✅ Firebase مهيأ مسبقاً');
        this.firebaseInitialized = true;
      }
      
    } catch (error) {
      console.error('❌ خطأ في تهيئة Firebase:', error.message);
      this.firebaseInitialized = false;
    }
  }

  // ===================================
  // بدء النظام الرسمي
  // ===================================
  async startOfficialSystem() {
    try {
      console.log('🚀 بدء نظام الإشعارات الرسمي...\n');

      // التحقق من Firebase
      if (!this.firebaseInitialized) {
        throw new Error('Firebase غير مهيأ بشكل صحيح');
      }

      // التحقق من قاعدة البيانات
      await this.validateDatabase();

      // بدء معالجة قائمة الانتظار
      this.startProcessing();

      // عرض معلومات النظام
      this.showSystemInfo();

      // إعداد الإيقاف الآمن
      this.setupGracefulShutdown();

      console.log('\n✅ نظام الإشعارات الرسمي يعمل بالكامل!');
      console.log('📱 الإشعارات ستصل للمستخدمين حتى لو كان التطبيق مغلق');
      console.log('🔔 النظام يراقب تغييرات حالة الطلبات تلقائياً');
      console.log('⏹️ لإيقاف النظام: Ctrl+C');

    } catch (error) {
      console.error('❌ خطأ في بدء النظام الرسمي:', error.message);
      process.exit(1);
    }
  }

  // ===================================
  // التحقق من قاعدة البيانات
  // ===================================
  async validateDatabase() {
    console.log('🔍 التحقق من قاعدة البيانات...');

    const tables = ['notification_queue', 'notification_logs', 'user_fcm_tokens'];
    
    for (const table of tables) {
      const { error } = await this.supabase
        .from(table)
        .select('*')
        .limit(1);

      if (error) {
        throw new Error(`جدول ${table} غير متاح: ${error.message}`);
      }
    }

    console.log('✅ جميع جداول قاعدة البيانات متاحة');
  }

  // ===================================
  // بدء معالجة قائمة الانتظار
  // ===================================
  startProcessing() {
    if (this.isRunning) {
      console.log('⚠️ المعالج يعمل بالفعل');
      return;
    }

    console.log('🔄 بدء معالج قائمة انتظار الإشعارات الرسمي...');
    this.isRunning = true;

    // معالجة فورية
    this.processQueue();

    // معالجة دورية
    this.processingInterval = setInterval(() => {
      this.processQueue();
    }, this.config.processingInterval);
  }

  // ===================================
  // معالجة قائمة الانتظار
  // ===================================
  async processQueue() {
    try {
      // جلب الإشعارات المعلقة
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
        await this.processOfficialNotification(notification);
        
        // تأخير قصير بين الإشعارات
        await new Promise(resolve => setTimeout(resolve, 200));
      }

    } catch (error) {
      console.error('❌ خطأ في معالجة قائمة الإشعارات:', error.message);
    }
  }

  // ===================================
  // معالجة إشعار رسمي واحد
  // ===================================
  async processOfficialNotification(notification) {
    try {
      console.log(`📤 معالجة إشعار رسمي: ${notification.id.substring(0, 8)}...`);
      console.log(`👤 المستخدم: ${notification.user_phone}`);
      console.log(`📄 الرسالة: ${notification.notification_data?.title}`);

      // تحديث حالة الإشعار إلى "قيد المعالجة"
      await this.supabase
        .from('notification_queue')
        .update({ status: 'processing' })
        .eq('id', notification.id);

      // الحصول على FCM Token
      const fcmToken = await this.getFCMToken(notification.user_phone);
      
      if (!fcmToken) {
        await this.handleNotificationFailure(
          notification.id,
          'لا يوجد FCM Token للمستخدم'
        );
        return;
      }

      // إرسال الإشعار الرسمي عبر Firebase
      const result = await this.sendOfficialFirebaseNotification(fcmToken, notification);

      if (result.success) {
        await this.handleNotificationSuccess(notification, fcmToken, result);
      } else {
        await this.handleNotificationFailure(notification.id, result.error);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة الإشعار ${notification.id}:`, error.message);
      await this.handleNotificationFailure(notification.id, error.message);
    }
  }

  // ===================================
  // الحصول على FCM Token
  // ===================================
  async getFCMToken(userPhone) {
    try {
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

      console.log(`📱 تم العثور على FCM Token للمستخدم ${userPhone}`);
      return tokenData.fcm_token;
      
    } catch (error) {
      console.error(`❌ خطأ في جلب FCM Token للمستخدم ${userPhone}:`, error.message);
      return null;
    }
  }

  // ===================================
  // إرسال إشعار Firebase رسمي
  // ===================================
  async sendOfficialFirebaseNotification(fcmToken, notification) {
    try {
      if (!this.firebaseInitialized) {
        throw new Error('Firebase غير مهيأ');
      }

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
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true
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
              },
              'content-available': 1
            }
          }
        }
      };

      console.log('🔥 إرسال إشعار رسمي عبر Firebase...');
      const response = await admin.messaging().send(message);
      
      console.log(`✅ تم إرسال الإشعار الرسمي بنجاح: ${response}`);
      
      return {
        success: true,
        messageId: response,
        fcmToken: fcmToken
      };

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار Firebase الرسمي:', error.message);
      
      // التعامل مع أخطاء FCM Token غير صالح
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log('🗑️ FCM Token غير صالح، سيتم إزالته');
        await this.removeFCMToken(fcmToken);
      }
      
      return {
        success: false,
        error: error.message,
        errorCode: error.code
      };
    }
  }

  // ===================================
  // إزالة FCM Token غير صالح
  // ===================================
  async removeFCMToken(fcmToken) {
    try {
      await this.supabase
        .from('user_fcm_tokens')
        .update({ is_active: false })
        .eq('fcm_token', fcmToken);
        
      console.log('🗑️ تم إلغاء تفعيل FCM Token غير صالح');
    } catch (error) {
      console.error('❌ خطأ في إزالة FCM Token:', error.message);
    }
  }

  // ===================================
  // معالجة نجاح الإرسال
  // ===================================
  async handleNotificationSuccess(notification, fcmToken, result) {
    try {
      // تحديث حالة الإشعار
      await this.supabase
        .from('notification_queue')
        .update({ 
          status: 'sent',
          processed_at: new Date().toISOString()
        })
        .eq('id', notification.id);

      // إضافة سجل في notification_logs
      await this.supabase
        .from('notification_logs')
        .insert({
          order_id: notification.order_id,
          user_phone: notification.user_phone,
          notification_type: 'order_status_change',
          status_change: `${notification.old_status || 'غير محدد'} -> ${notification.new_status}`,
          title: notification.notification_data?.title || '',
          message: notification.notification_data?.message || '',
          fcm_token: fcmToken,
          firebase_response: result,
          is_successful: true
        });

      console.log(`✅ تم تسجيل نجاح الإشعار الرسمي`);

    } catch (error) {
      console.error(`❌ خطأ في تسجيل نجاح الإشعار:`, error.message);
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
        await this.supabase
          .from('notification_queue')
          .update({
            status: 'failed',
            error_message: errorMessage,
            processed_at: new Date().toISOString()
          })
          .eq('id', notificationId);

        console.log(`❌ فشل نهائي في الإشعار: ${errorMessage}`);
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

        console.log(`🔄 إعادة جدولة الإشعار للمحاولة ${newRetryCount}/${maxRetries}`);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة فشل الإشعار:`, error.message);
    }
  }

  // ===================================
  // عرض معلومات النظام
  // ===================================
  showSystemInfo() {
    console.log('\n📋 معلومات النظام الرسمي:');
    console.log('═══════════════════════════════');
    console.log('🔥 Firebase: مفعل ويعمل');
    console.log('📱 الإشعارات: حقيقية (ليست محاكاة)');
    console.log('🌐 المستخدمين غير النشطين: سيحصلون على الإشعارات');
    console.log(`🔄 فترة المعالجة: ${this.config.processingInterval / 1000} ثانية`);
    console.log(`📦 حجم الدفعة: ${this.config.batchSize} إشعار`);
    console.log(`🔁 الحد الأقصى للمحاولات: ${this.config.maxRetries}`);
    console.log('═══════════════════════════════');
  }

  // ===================================
  // إعداد الإيقاف الآمن
  // ===================================
  setupGracefulShutdown() {
    const shutdown = async (signal) => {
      console.log(`\n📡 تم استلام إشارة ${signal}، بدء الإيقاف الآمن...`);
      
      try {
        this.isRunning = false;
        
        if (this.processingInterval) {
          clearInterval(this.processingInterval);
        }
        
        console.log('✅ تم إيقاف نظام الإشعارات الرسمي بأمان');
        process.exit(0);
        
      } catch (error) {
        console.error('❌ خطأ في الإيقاف الآمن:', error.message);
        process.exit(1);
      }
    };

    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
  }

  // ===================================
  // إيقاف النظام
  // ===================================
  async stop() {
    if (!this.isRunning) {
      console.log('⚠️ النظام غير مشغل');
      return;
    }

    console.log('⏹️ إيقاف نظام الإشعارات الرسمي...');
    
    this.isRunning = false;
    
    if (this.processingInterval) {
      clearInterval(this.processingInterval);
    }
    
    console.log('✅ تم إيقاف النظام الرسمي');
  }
}

module.exports = OfficialFirebaseNotificationService;
