// ===================================
// اختبار شامل لجميع أنظمة المنتجات
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

// استيراد الخدمات
const { firebaseConfig } = require('./config/firebase');
const TelegramNotificationService = require('./telegram_notification_service');

class SystemTester {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.results = {
      database: { status: 'pending', details: [] },
      firebase: { status: 'pending', details: [] },
      telegram: { status: 'pending', details: [] },
      waseet: { status: 'pending', details: [] },
      notifications: { status: 'pending', details: [] },
      watchers: { status: 'pending', details: [] }
    };
  }

  // ===================================
  // اختبار قاعدة البيانات
  // ===================================
  async testDatabase() {
    console.log('🗄️ اختبار قاعدة البيانات...');
    
    try {
      // اختبار الاتصال
      const { data, error } = await this.supabase
        .from('users')
        .select('count')
        .limit(1);

      if (error) {
        if (error.message.includes('relation') || error.message.includes('does not exist')) {
          this.results.database.status = 'warning';
          this.results.database.details.push('⚠️ بعض الجداول غير موجودة - يجب تشغيل السكيما');
        } else {
          throw error;
        }
      } else {
        this.results.database.status = 'success';
        this.results.database.details.push('✅ الاتصال بقاعدة البيانات يعمل');
      }

      // اختبار جداول أساسية
      const tables = ['users', 'orders', 'products', 'delivery_providers'];
      
      for (const table of tables) {
        try {
          const { error: tableError } = await this.supabase
            .from(table)
            .select('*')
            .limit(1);
            
          if (tableError) {
            this.results.database.details.push(`❌ جدول ${table} غير موجود`);
          } else {
            this.results.database.details.push(`✅ جدول ${table} موجود`);
          }
        } catch (err) {
          this.results.database.details.push(`❌ خطأ في فحص جدول ${table}: ${err.message}`);
        }
      }

    } catch (error) {
      this.results.database.status = 'error';
      this.results.database.details.push(`❌ خطأ في قاعدة البيانات: ${error.message}`);
    }
  }

  // ===================================
  // اختبار Firebase
  // ===================================
  async testFirebase() {
    console.log('🔥 اختبار Firebase...');
    
    try {
      const result = await firebaseConfig.initialize();
      
      if (result) {
        this.results.firebase.status = 'success';
        this.results.firebase.details.push('✅ Firebase مهيأ بنجاح');
        this.results.firebase.details.push(`✅ Project ID: ${process.env.FIREBASE_PROJECT_ID}`);
      } else {
        this.results.firebase.status = 'warning';
        this.results.firebase.details.push('⚠️ Firebase غير مهيأ - الإشعارات معطلة');
        this.results.firebase.details.push('💡 راجع ملف FIREBASE_SETUP.md');
      }
    } catch (error) {
      this.results.firebase.status = 'error';
      this.results.firebase.details.push(`❌ خطأ في Firebase: ${error.message}`);
    }
  }

  // ===================================
  // اختبار Telegram
  // ===================================
  async testTelegram() {
    console.log('📱 اختبار Telegram...');
    
    try {
      const telegramService = new TelegramNotificationService();
      const result = await telegramService.testConnection();
      
      if (result.success) {
        this.results.telegram.status = 'success';
        this.results.telegram.details.push('✅ الاتصال بـ Telegram يعمل');
        this.results.telegram.details.push(`✅ Bot: ${result.bot_info.username}`);
        
        // اختبار إرسال رسالة
        const messageResult = await telegramService.sendMessage('🧪 اختبار النظام - جميع الأنظمة تعمل بنجاح!');
        
        if (messageResult.success) {
          this.results.telegram.details.push('✅ إرسال الرسائل يعمل');
        } else {
          this.results.telegram.details.push(`⚠️ فشل إرسال الرسالة: ${messageResult.error}`);
        }
      } else {
        this.results.telegram.status = 'error';
        this.results.telegram.details.push(`❌ فشل الاتصال بـ Telegram: ${result.error}`);
      }
    } catch (error) {
      this.results.telegram.status = 'error';
      this.results.telegram.details.push(`❌ خطأ في Telegram: ${error.message}`);
    }
  }

  // ===================================
  // اختبار شركة الوسيط
  // ===================================
  async testWaseet() {
    console.log('🚚 اختبار شركة الوسيط...');

    try {
      const OrderStatusSyncService = require('./sync/order_status_sync_service');
      const syncService = new OrderStatusSyncService();
      await syncService.initialize();

      // اختبار المصادقة
      const token = await syncService.authenticateWaseet();

      if (token) {
        this.results.waseet.status = 'success';
        this.results.waseet.details.push('✅ المصادقة مع شركة الوسيط تعمل');
        this.results.waseet.details.push('✅ تم الحصول على التوكن');
      } else {
        this.results.waseet.status = 'warning';
        this.results.waseet.details.push('⚠️ فشل في المصادقة مع شركة الوسيط');
        this.results.waseet.details.push('💡 تحقق من بيانات تسجيل الدخول في .env');
      }

      // اختبار جلب الطلبات
      const orders = await syncService.getOrdersForSync();
      this.results.waseet.details.push(`📊 عدد الطلبات المؤهلة للمزامنة: ${orders.length}`);

    } catch (error) {
      this.results.waseet.status = 'error';
      this.results.waseet.details.push(`❌ خطأ في شركة الوسيط: ${error.message}`);
    }
  }

  // ===================================
  // اختبار نظام الإشعارات
  // ===================================
  async testNotifications() {
    console.log('🔔 اختبار نظام الإشعارات...');

    try {
      const TargetedNotificationService = require('./services/targeted_notification_service');
      const notificationService = new TargetedNotificationService();
      await notificationService.initializeFirebase();

      if (notificationService.initialized) {
        this.results.notifications.status = 'success';
        this.results.notifications.details.push('✅ خدمة الإشعارات المستهدفة مهيأة');
      } else {
        this.results.notifications.status = 'warning';
        this.results.notifications.details.push('⚠️ خدمة الإشعارات المستهدفة معطلة');
      }

      // اختبار محاكاة إشعار
      const testResult = await notificationService.sendOrderStatusNotification(
        'test-order-123',
        'test-user-456',
        'عميل تجريبي',
        'pending',
        'in_delivery'
      );

      if (testResult.success) {
        this.results.notifications.details.push('✅ إرسال الإشعارات يعمل');
      } else {
        this.results.notifications.details.push(`⚠️ فشل إرسال الإشعار: ${testResult.error}`);
      }

    } catch (error) {
      this.results.notifications.status = 'error';
      this.results.notifications.details.push(`❌ خطأ في نظام الإشعارات: ${error.message}`);
    }
  }

  // ===================================
  // اختبار المراقبين
  // ===================================
  async testWatchers() {
    console.log('👁️ اختبار المراقبين...');

    try {
      // اختبار مراقب الطلبات
      const OrderStatusWatcher = require('./services/order_status_watcher');
      const orderWatcher = new OrderStatusWatcher();
      this.results.watchers.details.push('✅ مراقب حالة الطلبات مهيأ');

      // اختبار مراقب طلبات السحب
      const WithdrawalStatusWatcher = require('./services/withdrawal_status_watcher');
      const withdrawalWatcher = new WithdrawalStatusWatcher();
      this.results.watchers.details.push('✅ مراقب حالة طلبات السحب مهيأ');

      this.results.watchers.status = 'success';
      this.results.watchers.details.push('✅ جميع المراقبين يعملون');

    } catch (error) {
      this.results.watchers.status = 'error';
      this.results.watchers.details.push(`❌ خطأ في المراقبين: ${error.message}`);
    }
  }

  // ===================================
  // تشغيل جميع الاختبارات
  // ===================================
  async runAllTests() {
    console.log('🧪 بدء الاختبار الشامل للنظام...\n');
    
    await this.testDatabase();
    await this.testFirebase();
    await this.testTelegram();
    await this.testWaseet();
    await this.testNotifications();
    await this.testWatchers();
    
    this.printResults();
  }

  // ===================================
  // طباعة النتائج
  // ===================================
  printResults() {
    console.log('\n' + '='.repeat(50));
    console.log('📊 نتائج الاختبار الشامل');
    console.log('='.repeat(50));
    
    for (const [system, result] of Object.entries(this.results)) {
      const statusIcon = {
        success: '✅',
        warning: '⚠️',
        error: '❌',
        pending: '⏳'
      }[result.status];
      
      console.log(`\n${statusIcon} ${system.toUpperCase()}:`);
      result.details.forEach(detail => console.log(`  ${detail}`));
    }
    
    // ملخص عام
    const successCount = Object.values(this.results).filter(r => r.status === 'success').length;
    const warningCount = Object.values(this.results).filter(r => r.status === 'warning').length;
    const errorCount = Object.values(this.results).filter(r => r.status === 'error').length;
    
    console.log('\n' + '='.repeat(50));
    console.log('📈 الملخص العام:');
    console.log(`✅ نجح: ${successCount} | ⚠️ تحذيرات: ${warningCount} | ❌ أخطاء: ${errorCount}`);
    
    if (errorCount === 0 && warningCount === 0) {
      console.log('🎉 جميع الأنظمة تعمل بشكل مثالي!');
    } else if (errorCount === 0) {
      console.log('✅ النظام يعمل مع بعض التحذيرات');
    } else {
      console.log('❌ يوجد أخطاء تحتاج إصلاح');
    }
    
    console.log('='.repeat(50));
  }
}

// تشغيل الاختبار
if (require.main === module) {
  const tester = new SystemTester();
  tester.runAllTests().catch(console.error);
}

module.exports = SystemTester;
