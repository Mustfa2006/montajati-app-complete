// ===================================
// خدمة تشغيل معالج الإشعارات الذكي
// ===================================

require('dotenv').config();
const SmartNotificationProcessor = require('./smart_notification_processor');

class NotificationServiceRunner {
  constructor() {
    this.processor = new SmartNotificationProcessor();
    this.isRunning = false;
    this.healthCheckInterval = null;
  }

  // ===================================
  // بدء الخدمة
  // ===================================
  async start() {
    try {
      console.log('🚀 بدء خدمة الإشعارات الذكية...');
      
      // التحقق من متغيرات البيئة المطلوبة
      this.validateEnvironment();
      
      // بدء معالج الإشعارات
      this.processor.startProcessing();
      this.isRunning = true;
      
      // بدء فحص الصحة الدوري
      this.startHealthCheck();
      
      console.log('✅ تم بدء خدمة الإشعارات بنجاح');
      console.log('📊 لعرض الإحصائيات: npm run notification:stats');
      console.log('⏹️ لإيقاف الخدمة: Ctrl+C');
      
      // معالجة إشارات الإيقاف
      this.setupGracefulShutdown();
      
    } catch (error) {
      console.error('❌ خطأ في بدء خدمة الإشعارات:', error.message);
      process.exit(1);
    }
  }

  // ===================================
  // التحقق من متغيرات البيئة
  // ===================================
  validateEnvironment() {
    const requiredVars = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'FIREBASE_SERVICE_ACCOUNT'
    ];

    const missingVars = requiredVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
      throw new Error(`متغيرات البيئة المطلوبة مفقودة: ${missingVars.join(', ')}`);
    }

    // التحقق من صحة Firebase Service Account
    try {
      JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (error) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT غير صالح - يجب أن يكون JSON صحيح');
    }

    console.log('✅ تم التحقق من متغيرات البيئة');
  }

  // ===================================
  // بدء فحص الصحة الدوري
  // ===================================
  startHealthCheck() {
    this.healthCheckInterval = setInterval(async () => {
      try {
        const stats = await this.processor.getProcessingStats();
        
        if (stats) {
          console.log(`📊 إحصائيات آخر 24 ساعة: المجموع=${stats.total}, معلق=${stats.pending}, مرسل=${stats.sent}, فاشل=${stats.failed}`);
          
          // تحذير إذا كان هناك إشعارات فاشلة كثيرة
          if (stats.failed > stats.sent * 0.1) { // أكثر من 10% فشل
            console.warn(`⚠️ تحذير: نسبة فشل عالية في الإشعارات (${stats.failed}/${stats.total})`);
          }
        }
        
      } catch (error) {
        console.error('❌ خطأ في فحص الصحة:', error.message);
      }
    }, 60000); // كل دقيقة
  }

  // ===================================
  // إعداد الإيقاف الآمن
  // ===================================
  setupGracefulShutdown() {
    const shutdown = async (signal) => {
      console.log(`\n📡 تم استلام إشارة ${signal}، بدء الإيقاف الآمن...`);
      
      try {
        // إيقاف معالج الإشعارات
        this.processor.stopProcessing();
        
        // إيقاف فحص الصحة
        if (this.healthCheckInterval) {
          clearInterval(this.healthCheckInterval);
        }
        
        this.isRunning = false;
        
        console.log('✅ تم إيقاف خدمة الإشعارات بأمان');
        process.exit(0);
        
      } catch (error) {
        console.error('❌ خطأ في الإيقاف الآمن:', error.message);
        process.exit(1);
      }
    };

    // معالجة إشارات النظام
    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
    
    // معالجة الأخطاء غير المتوقعة
    process.on('uncaughtException', (error) => {
      console.error('❌ خطأ غير متوقع:', error);
      shutdown('uncaughtException');
    });
    
    process.on('unhandledRejection', (reason, promise) => {
      console.error('❌ Promise مرفوض غير معالج:', reason);
      shutdown('unhandledRejection');
    });
  }

  // ===================================
  // إيقاف الخدمة
  // ===================================
  async stop() {
    if (!this.isRunning) {
      console.log('⚠️ الخدمة غير مشغلة');
      return;
    }

    console.log('⏹️ إيقاف خدمة الإشعارات...');
    
    this.processor.stopProcessing();
    
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }
    
    this.isRunning = false;
    console.log('✅ تم إيقاف الخدمة');
  }

  // ===================================
  // عرض الإحصائيات
  // ===================================
  async showStats() {
    try {
      console.log('📊 جاري جلب إحصائيات الإشعارات...\n');
      
      const stats = await this.processor.getProcessingStats();
      
      if (!stats) {
        console.log('❌ لا يمكن جلب الإحصائيات');
        return;
      }

      console.log('📈 إحصائيات آخر 24 ساعة:');
      console.log('═══════════════════════════════');
      console.log(`📋 إجمالي الإشعارات: ${stats.total}`);
      console.log(`⏳ معلقة: ${stats.pending}`);
      console.log(`🔄 قيد المعالجة: ${stats.processing}`);
      console.log(`✅ مرسلة: ${stats.sent}`);
      console.log(`❌ فاشلة: ${stats.failed}`);
      
      if (stats.total > 0) {
        const successRate = ((stats.sent / stats.total) * 100).toFixed(1);
        console.log(`📊 معدل النجاح: ${successRate}%`);
      }
      
      console.log('═══════════════════════════════\n');
      
    } catch (error) {
      console.error('❌ خطأ في عرض الإحصائيات:', error.message);
    }
  }

  // ===================================
  // اختبار الإشعارات
  // ===================================
  async testNotification(userPhone, testMessage = 'اختبار نظام الإشعارات 🧪') {
    try {
      console.log(`🧪 اختبار إرسال إشعار للمستخدم: ${userPhone}`);
      
      // الحصول على FCM Token
      const fcmToken = await this.processor.getFCMToken(userPhone);
      
      if (!fcmToken) {
        console.log(`❌ لا يوجد FCM Token للمستخدم ${userPhone}`);
        return false;
      }

      // إنشاء إشعار اختبار
      const testNotification = {
        id: 'test-' + Date.now(),
        order_id: 'TEST-ORDER',
        user_phone: userPhone,
        customer_name: 'اختبار',
        old_status: 'active',
        new_status: 'test',
        notification_data: {
          title: 'اختبار الإشعارات 🧪',
          message: testMessage,
          type: 'test',
          emoji: '🧪',
          priority: 1
        }
      };

      // إرسال الإشعار
      const result = await this.processor.sendFirebaseNotification(fcmToken, testNotification);
      
      if (result.success) {
        console.log(`✅ تم إرسال إشعار الاختبار بنجاح: ${result.messageId}`);
        return true;
      } else {
        console.log(`❌ فشل في إرسال إشعار الاختبار: ${result.error}`);
        return false;
      }
      
    } catch (error) {
      console.error('❌ خطأ في اختبار الإشعار:', error.message);
      return false;
    }
  }
}

// ===================================
// تشغيل الخدمة حسب المعامل المرسل
// ===================================
if (require.main === module) {
  const runner = new NotificationServiceRunner();
  const command = process.argv[2];

  switch (command) {
    case 'start':
      runner.start();
      break;
      
    case 'stats':
      runner.showStats().then(() => process.exit(0));
      break;
      
    case 'test':
      const userPhone = process.argv[3];
      const testMessage = process.argv[4];
      
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف للاختبار');
        console.log('الاستخدام: npm run notification:test <رقم_الهاتف> [رسالة_اختيارية]');
        process.exit(1);
      }
      
      runner.testNotification(userPhone, testMessage)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      console.log('📋 الأوامر المتاحة:');
      console.log('  npm run notification:start  - بدء خدمة الإشعارات');
      console.log('  npm run notification:stats  - عرض الإحصائيات');
      console.log('  npm run notification:test <phone> - اختبار إشعار');
      process.exit(1);
  }
}

module.exports = NotificationServiceRunner;
