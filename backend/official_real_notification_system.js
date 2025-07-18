// ===================================
// نظام الإشعارات الرسمي الحقيقي
// بدون محاكاة - Firebase حقيقي 100%
// ===================================

require('dotenv').config();
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

class RealOfficialNotificationSystem {
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
      processingInterval: 3000, // 3 ثواني للاستجابة السريعة
      maxRetries: 3,
      retryDelay: 30000 // 30 ثانية
    };
    
    this.initializeRealFirebase();
  }

  // ===================================
  // تهيئة Firebase الحقيقي
  // ===================================
  initializeRealFirebase() {
    try {
      console.log('🔥 تهيئة Firebase الحقيقي...');
      
      if (admin.apps.length === 0) {
        const firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        
        // التحقق من صحة الإعدادات
        if (!firebaseConfig.project_id || !firebaseConfig.private_key || !firebaseConfig.client_email) {
          throw new Error('إعدادات Firebase غير مكتملة');
        }
        
        admin.initializeApp({
          credential: admin.credential.cert(firebaseConfig),
          projectId: firebaseConfig.project_id
        });
        
        console.log(`✅ تم تهيئة Firebase الحقيقي بنجاح`);
        console.log(`📱 Project ID: ${firebaseConfig.project_id}`);
        console.log(`📧 Service Account: ${firebaseConfig.client_email}`);
        this.firebaseInitialized = true;
      } else {
        console.log('✅ Firebase مهيأ مسبقاً');
        this.firebaseInitialized = true;
      }
      
    } catch (error) {
      console.error('❌ خطأ في تهيئة Firebase الحقيقي:', error.message);
      this.firebaseInitialized = false;
      throw error;
    }
  }

  // ===================================
  // بدء النظام الرسمي الحقيقي
  // ===================================
  async startRealSystem() {
    try {
      console.log('🚀 بدء نظام الإشعارات الرسمي الحقيقي...\n');

      // التحقق من Firebase
      if (!this.firebaseInitialized) {
        throw new Error('Firebase الحقيقي غير مهيأ بشكل صحيح');
      }

      // التحقق من قاعدة البيانات
      await this.validateDatabase();

      // بدء معالجة قائمة الانتظار
      this.startRealProcessing();

      // عرض معلومات النظام الحقيقي
      this.showRealSystemInfo();

      // إعداد الإيقاف الآمن
      this.setupGracefulShutdown();

      console.log('\n🔥 نظام الإشعارات الرسمي الحقيقي يعمل بالكامل!');
      console.log('📱 الإشعارات الحقيقية ستصل للمستخدمين فوراً');
      console.log('🌐 حتى لو كان التطبيق مغلق أو المستخدم غير نشط');
      console.log('🔔 النظام يراقب تغييرات حالة الطلبات تلقائياً');
      console.log('⏹️ لإيقاف النظام: Ctrl+C');

    } catch (error) {
      console.error('❌ خطأ في بدء النظام الرسمي الحقيقي:', error.message);
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
  // بدء معالجة حقيقية
  // ===================================
  startRealProcessing() {
    if (this.isRunning) {
      console.log('⚠️ المعالج الحقيقي يعمل بالفعل');
      return;
    }

    console.log('🔄 بدء معالج الإشعارات الحقيقي...');
    this.isRunning = true;

    // معالجة فورية
    this.processRealQueue();

    // معالجة دورية سريعة
    this.processingInterval = setInterval(() => {
      this.processRealQueue();
    }, this.config.processingInterval);
  }

  // ===================================
  // معالجة قائمة الانتظار الحقيقية
  // ===================================
  async processRealQueue() {
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

      console.log(`📋 معالجة ${pendingNotifications.length} إشعار حقيقي...`);

      // معالجة كل إشعار حقيقي
      for (const notification of pendingNotifications) {
        await this.processRealNotification(notification);
        
        // تأخير قصير بين الإشعارات
        await new Promise(resolve => setTimeout(resolve, 100));
      }

    } catch (error) {
      console.error('❌ خطأ في معالجة قائمة الإشعارات الحقيقية:', error.message);
    }
  }

  // ===================================
  // معالجة إشعار حقيقي واحد
  // ===================================
  async processRealNotification(notification) {
    try {
      console.log(`🔥 معالجة إشعار حقيقي: ${notification.id.substring(0, 8)}...`);
      console.log(`👤 المستخدم: ${notification.user_phone}`);
      console.log(`📄 الرسالة: ${notification.notification_data?.title}`);

      // تحديث حالة الإشعار إلى "قيد المعالجة"
      await this.supabase
        .from('notification_queue')
        .update({ status: 'processing' })
        .eq('id', notification.id);

      // الحصول على FCM Token الحقيقي
      const fcmToken = await this.getRealFCMToken(notification.user_phone);
      
      if (!fcmToken) {
        await this.handleRealNotificationFailure(
          notification.id,
          'لا يوجد FCM Token للمستخدم'
        );
        return;
      }

      // إرسال الإشعار الحقيقي عبر Firebase
      const result = await this.sendRealFirebaseNotification(fcmToken, notification);

      if (result.success) {
        await this.handleRealNotificationSuccess(notification, fcmToken, result);
      } else {
        await this.handleRealNotificationFailure(notification.id, result.error);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة الإشعار الحقيقي ${notification.id}:`, error.message);
      await this.handleRealNotificationFailure(notification.id, error.message);
    }
  }

  // ===================================
  // الحصول على FCM Token حقيقي
  // ===================================
  async getRealFCMToken(userPhone) {
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

      console.log(`📱 تم العثور على FCM Token حقيقي للمستخدم ${userPhone}`);
      return tokenData.fcm_token;
      
    } catch (error) {
      console.error(`❌ خطأ في جلب FCM Token للمستخدم ${userPhone}:`, error.message);
      return null;
    }
  }

  // ===================================
  // إرسال إشعار Firebase حقيقي
  // ===================================
  async sendRealFirebaseNotification(fcmToken, notification) {
    try {
      if (!this.firebaseInitialized) {
        throw new Error('Firebase الحقيقي غير مهيأ');
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
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: 'ic_notification',
            color: '#FF6B35'
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
              'content-available': 1,
              'mutable-content': 1
            }
          }
        }
      };

      console.log('🔥 إرسال إشعار حقيقي عبر Firebase...');
      console.log(`📱 إلى Token: ${fcmToken.substring(0, 20)}...`);
      
      const response = await admin.messaging().send(message);
      
      console.log(`✅ تم إرسال الإشعار الحقيقي بنجاح!`);
      console.log(`📨 Message ID: ${response}`);
      console.log(`🔔 الإشعار وصل للمستخدم (حتى لو كان التطبيق مغلق)`);
      
      return {
        success: true,
        messageId: response,
        fcmToken: fcmToken,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار Firebase الحقيقي:', error.message);
      
      // التعامل مع أخطاء FCM Token غير صالح
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log('🗑️ FCM Token غير صالح، سيتم إزالته');
        await this.removeInvalidFCMToken(fcmToken);
      }
      
      return {
        success: false,
        error: error.message,
        errorCode: error.code,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // إزالة FCM Token غير صالح
  // ===================================
  async removeInvalidFCMToken(fcmToken) {
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
  // معالجة نجاح الإرسال الحقيقي
  // ===================================
  async handleRealNotificationSuccess(notification, fcmToken, result) {
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

      console.log(`✅ تم تسجيل نجاح الإشعار الحقيقي`);

    } catch (error) {
      console.error(`❌ خطأ في تسجيل نجاح الإشعار الحقيقي:`, error.message);
    }
  }

  // ===================================
  // معالجة فشل الإرسال الحقيقي
  // ===================================
  async handleRealNotificationFailure(notificationId, errorMessage) {
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

        console.log(`❌ فشل نهائي في الإشعار الحقيقي: ${errorMessage}`);
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

        console.log(`🔄 إعادة جدولة الإشعار الحقيقي للمحاولة ${newRetryCount}/${maxRetries}`);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة فشل الإشعار الحقيقي:`, error.message);
    }
  }

  // ===================================
  // عرض معلومات النظام الحقيقي
  // ===================================
  showRealSystemInfo() {
    console.log('\n📋 معلومات النظام الحقيقي:');
    console.log('═══════════════════════════════');
    console.log('🔥 Firebase: حقيقي 100% (ليس محاكاة)');
    console.log('📱 الإشعارات: تصل فوراً للمستخدمين');
    console.log('🌐 المستخدمين غير النشطين: سيحصلون على الإشعارات');
    console.log('📲 التطبيق المغلق: الإشعارات تصل أيضاً');
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
        
        console.log('✅ تم إيقاف نظام الإشعارات الحقيقي بأمان');
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
  // اختبار إشعار حقيقي
  // ===================================
  async testRealNotification(userPhone, testMessage = 'اختبار النظام الحقيقي 🔥') {
    try {
      console.log(`🧪 اختبار إرسال إشعار حقيقي للمستخدم: ${userPhone}`);

      // الحصول على FCM Token
      const fcmToken = await this.getRealFCMToken(userPhone);
      
      if (!fcmToken) {
        console.log(`❌ لا يوجد FCM Token للمستخدم ${userPhone}`);
        console.log('💡 تأكد من أن المستخدم سجل دخول في التطبيق وحفظ FCM Token');
        return false;
      }

      // إنشاء إشعار اختبار حقيقي
      const testNotification = {
        id: 'real-test-' + Date.now(),
        order_id: 'REAL-TEST-ORDER',
        user_phone: userPhone,
        customer_name: 'اختبار حقيقي',
        old_status: 'active',
        new_status: 'in_delivery',
        notification_data: {
          title: 'اختبار النظام الحقيقي 🔥',
          message: testMessage,
          type: 'test',
          emoji: '🔥',
          priority: 1,
          timestamp: Date.now()
        }
      };

      // إرسال الإشعار الحقيقي
      const result = await this.sendRealFirebaseNotification(fcmToken, testNotification);
      
      if (result.success) {
        console.log(`✅ تم إرسال الإشعار الحقيقي بنجاح!`);
        console.log(`📱 Message ID: ${result.messageId}`);
        console.log('🔔 يجب أن يصل الإشعار للمستخدم الآن (حتى لو كان التطبيق مغلق)');
        return true;
      } else {
        console.log(`❌ فشل في إرسال الإشعار الحقيقي: ${result.error}`);
        return false;
      }
      
    } catch (error) {
      console.error('❌ خطأ في اختبار الإشعار الحقيقي:', error.message);
      return false;
    }
  }
}

module.exports = RealOfficialNotificationSystem;
