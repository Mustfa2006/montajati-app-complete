// ===================================
// تشغيل نظام الإشعارات الذكي النهائي
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

class FinalNotificationSystem {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.isRunning = false;
    this.processingInterval = null;
    this.config = {
      batchSize: 10,
      processingInterval: 5000, // 5 ثواني
      maxRetries: 3
    };
  }

  // ===================================
  // بدء النظام الكامل
  // ===================================
  async startSystem() {
    try {
      console.log('🚀 بدء نظام الإشعارات الذكي النهائي...\n');

      // 1. التحقق من النظام
      await this.validateSystem();

      // 2. بدء معالجة قائمة الانتظار
      this.startProcessing();

      // 3. عرض معلومات النظام
      this.showSystemInfo();

      // 4. إعداد الإيقاف الآمن
      this.setupGracefulShutdown();

      console.log('\n✅ نظام الإشعارات الذكي يعمل بالكامل!');
      console.log('📋 النظام جاهز لاستقبال تغييرات حالة الطلبات');
      console.log('⏹️ لإيقاف النظام: Ctrl+C');

    } catch (error) {
      console.error('❌ خطأ في بدء النظام:', error.message);
      process.exit(1);
    }
  }

  // ===================================
  // التحقق من صحة النظام
  // ===================================
  async validateSystem() {
    console.log('🔍 التحقق من صحة النظام...');

    // التحقق من متغيرات البيئة
    const requiredVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
    const missingVars = requiredVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
      throw new Error(`متغيرات البيئة المطلوبة مفقودة: ${missingVars.join(', ')}`);
    }

    // التحقق من الجداول
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

    console.log('✅ جميع المتطلبات متوفرة');
  }

  // ===================================
  // بدء معالجة قائمة الانتظار
  // ===================================
  startProcessing() {
    if (this.isRunning) {
      console.log('⚠️ المعالج يعمل بالفعل');
      return;
    }

    console.log('🔄 بدء معالج قائمة انتظار الإشعارات...');
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
        await this.processNotification(notification);
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
      console.log(`📤 معالجة إشعار: ${notification.id.substring(0, 8)}... للمستخدم ${notification.user_phone}`);

      // تحديث حالة الإشعار إلى "قيد المعالجة"
      await this.supabase
        .from('notification_queue')
        .update({ status: 'processing' })
        .eq('id', notification.id);

      // الحصول على FCM Token
      const { data: tokenData } = await this.supabase
        .from('user_fcm_tokens')
        .select('fcm_token')
        .eq('user_phone', notification.user_phone)
        .eq('is_active', true)
        .order('updated_at', { ascending: false })
        .limit(1)
        .single();

      if (!tokenData) {
        await this.handleNotificationFailure(
          notification.id,
          'لا يوجد FCM Token للمستخدم'
        );
        return;
      }

      // محاكاة إرسال الإشعار (يمكن استبدالها بـ Firebase حقيقي)
      const result = await this.simulateNotificationSend(tokenData.fcm_token, notification);

      if (result.success) {
        await this.handleNotificationSuccess(notification, tokenData.fcm_token, result);
      } else {
        await this.handleNotificationFailure(notification.id, result.error);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة الإشعار ${notification.id}:`, error.message);
      await this.handleNotificationFailure(notification.id, error.message);
    }
  }

  // ===================================
  // محاكاة إرسال الإشعار
  // ===================================
  async simulateNotificationSend(fcmToken, notification) {
    try {
      // محاكاة تأخير الشبكة
      await new Promise(resolve => setTimeout(resolve, 100));

      console.log(`📱 إرسال إشعار: ${notification.notification_data?.title}`);
      console.log(`📄 الرسالة: ${notification.notification_data?.message}`);

      // محاكاة نجاح الإرسال (يمكن استبدالها بـ Firebase حقيقي)
      return {
        success: true,
        messageId: `sim_${Date.now()}`,
        fcmToken: fcmToken
      };

    } catch (error) {
      return {
        success: false,
        error: error.message
      };
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

      console.log(`✅ تم إرسال الإشعار بنجاح`);

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
        const nextAttempt = new Date(Date.now() + 30000); // 30 ثانية
        
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
    console.log('\n📋 معلومات النظام:');
    console.log('═══════════════════════════════');
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
        
        console.log('✅ تم إيقاف نظام الإشعارات بأمان');
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
  // عرض الإحصائيات
  // ===================================
  async showStats() {
    try {
      console.log('📊 إحصائيات نظام الإشعارات:');
      console.log('═══════════════════════════════');

      // إحصائيات قائمة الانتظار
      const { data: queueStats } = await this.supabase
        .from('notification_queue')
        .select('status');

      if (queueStats) {
        const pending = queueStats.filter(s => s.status === 'pending').length;
        const processing = queueStats.filter(s => s.status === 'processing').length;
        const sent = queueStats.filter(s => s.status === 'sent').length;
        const failed = queueStats.filter(s => s.status === 'failed').length;
        
        console.log('📋 قائمة انتظار الإشعارات:');
        console.log(`  معلقة: ${pending}`);
        console.log(`  قيد المعالجة: ${processing}`);
        console.log(`  مرسلة: ${sent}`);
        console.log(`  فاشلة: ${failed}`);
        console.log(`  المجموع: ${queueStats.length}`);
      }

      // إحصائيات FCM Tokens
      const { data: tokenStats } = await this.supabase
        .from('user_fcm_tokens')
        .select('is_active');

      if (tokenStats) {
        const activeTokens = tokenStats.filter(t => t.is_active).length;
        console.log(`\n📱 FCM Tokens نشطة: ${activeTokens}/${tokenStats.length}`);
      }

      console.log('═══════════════════════════════');

    } catch (error) {
      console.error('❌ خطأ في عرض الإحصائيات:', error.message);
    }
  }
}

// ===================================
// تشغيل النظام
// ===================================
if (require.main === module) {
  const system = new FinalNotificationSystem();
  const command = process.argv[2];

  switch (command) {
    case 'start':
      system.startSystem();
      break;
      
    case 'stats':
      system.showStats()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      console.log('📋 الأوامر المتاحة:');
      console.log('  node start_notification_system_final.js start  - تشغيل النظام');
      console.log('  node start_notification_system_final.js stats  - عرض الإحصائيات');
      process.exit(1);
  }
}

module.exports = FinalNotificationSystem;
