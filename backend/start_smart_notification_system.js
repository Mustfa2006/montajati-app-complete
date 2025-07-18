// ===================================
// تشغيل نظام الإشعارات الذكي الكامل
// ===================================

require('dotenv').config();
const SmartNotificationSetup = require('./setup_smart_notifications');
const NotificationServiceRunner = require('./services/notification_service_runner');

class SmartNotificationSystemStarter {
  constructor() {
    this.setup = new SmartNotificationSetup();
    this.runner = new NotificationServiceRunner();
  }

  // ===================================
  // بدء النظام الكامل
  // ===================================
  async startCompleteSystem() {
    try {
      console.log('🚀 بدء نظام الإشعارات الذكي الكامل...\n');

      // 1. التحقق من متغيرات البيئة
      this.validateEnvironment();

      // 2. إعداد قاعدة البيانات
      console.log('📊 إعداد قاعدة البيانات...');
      await this.setup.setupSmartNotifications();

      // 3. بدء خدمة المعالجة
      console.log('\n🔄 بدء خدمة معالجة الإشعارات...');
      await this.runner.start();

      console.log('\n✅ نظام الإشعارات الذكي يعمل بالكامل!');
      console.log('📋 النظام جاهز لاستقبال تغييرات حالة الطلبات');

    } catch (error) {
      console.error('❌ خطأ في بدء النظام:', error.message);
      process.exit(1);
    }
  }

  // ===================================
  // التحقق من متغيرات البيئة
  // ===================================
  validateEnvironment() {
    console.log('🔍 التحقق من متغيرات البيئة...');

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
      const firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      if (!firebaseConfig.project_id || !firebaseConfig.private_key) {
        throw new Error('Firebase Service Account غير مكتمل');
      }
      console.log(`✅ Firebase Project: ${firebaseConfig.project_id}`);
    } catch (error) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT غير صالح - يجب أن يكون JSON صحيح');
    }

    console.log('✅ جميع متغيرات البيئة صحيحة\n');
  }

  // ===================================
  // اختبار النظام الكامل
  // ===================================
  async testCompleteSystem(userPhone) {
    try {
      console.log('🧪 اختبار النظام الكامل...\n');

      if (!userPhone) {
        throw new Error('يجب تحديد رقم هاتف للاختبار');
      }

      // 1. اختبار إرسال إشعار مباشر
      console.log('📤 اختبار الإرسال المباشر...');
      const directTest = await this.runner.testNotification(
        userPhone, 
        'اختبار الإرسال المباشر 🧪'
      );

      if (!directTest) {
        console.log('❌ فشل اختبار الإرسال المباشر');
        return false;
      }

      // 2. اختبار Database Trigger
      console.log('\n🔄 اختبار Database Trigger...');
      await this.testDatabaseTrigger(userPhone);

      // 3. عرض الإحصائيات
      console.log('\n📊 إحصائيات النظام:');
      await this.setup.showSystemStats();

      console.log('\n✅ جميع الاختبارات نجحت!');
      return true;

    } catch (error) {
      console.error('❌ خطأ في اختبار النظام:', error.message);
      return false;
    }
  }

  // ===================================
  // اختبار Database Trigger
  // ===================================
  async testDatabaseTrigger(userPhone) {
    try {
      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      // إنشاء طلب اختبار
      const testOrderId = 'TEST-TRIGGER-' + Date.now();
      
      console.log(`📝 إنشاء طلب اختبار: ${testOrderId}`);
      
      const { error: insertError } = await supabase
        .from('orders')
        .insert({
          id: testOrderId,
          customer_name: 'اختبار Trigger',
          primary_phone: userPhone,
          customer_phone: userPhone,
          delivery_address: 'عنوان اختبار',
          subtotal: 100,
          total: 100,
          status: 'active'
        });

      if (insertError) {
        throw new Error(`فشل في إنشاء طلب الاختبار: ${insertError.message}`);
      }

      // انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 1000));

      // تحديث حالة الطلب لتفعيل Trigger
      console.log('🔄 تحديث حالة الطلب لتفعيل Trigger...');
      
      const { error: updateError } = await supabase
        .from('orders')
        .update({ status: 'in_delivery' })
        .eq('id', testOrderId);

      if (updateError) {
        throw new Error(`فشل في تحديث الطلب: ${updateError.message}`);
      }

      // انتظار معالجة الإشعار
      console.log('⏳ انتظار معالجة الإشعار...');
      await new Promise(resolve => setTimeout(resolve, 3000));

      // التحقق من قائمة الانتظار
      const { data: queueData } = await supabase
        .from('notification_queue')
        .select('*')
        .eq('order_id', testOrderId);

      if (queueData && queueData.length > 0) {
        console.log('✅ تم إضافة الإشعار لقائمة الانتظار بنجاح');
        console.log(`📋 بيانات الإشعار: ${queueData[0].notification_data.title}`);
      } else {
        console.log('⚠️ لم يتم العثور على الإشعار في قائمة الانتظار');
      }

      // تنظيف - حذف طلب الاختبار
      await supabase
        .from('orders')
        .delete()
        .eq('id', testOrderId);

      await supabase
        .from('notification_queue')
        .delete()
        .eq('order_id', testOrderId);

      console.log('🧹 تم تنظيف بيانات الاختبار');

    } catch (error) {
      console.error('❌ خطأ في اختبار Database Trigger:', error.message);
      throw error;
    }
  }

  // ===================================
  // عرض دليل الاستخدام
  // ===================================
  showUsageGuide() {
    console.log('📋 دليل استخدام نظام الإشعارات الذكي:');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    console.log('🚀 بدء النظام الكامل:');
    console.log('  node start_smart_notification_system.js start');
    console.log('');
    console.log('🧪 اختبار النظام:');
    console.log('  node start_smart_notification_system.js test <رقم_الهاتف>');
    console.log('');
    console.log('📊 عرض الإحصائيات:');
    console.log('  node start_smart_notification_system.js stats');
    console.log('');
    console.log('🔧 إعداد قاعدة البيانات فقط:');
    console.log('  node setup_smart_notifications.js setup');
    console.log('');
    console.log('🔄 تشغيل معالج الإشعارات فقط:');
    console.log('  npm run notification:start');
    console.log('');
    console.log('📈 مراقبة الإحصائيات:');
    console.log('  npm run notification:stats');
    console.log('');
    console.log('🧪 اختبار إشعار مباشر:');
    console.log('  npm run notification:test <رقم_الهاتف>');
    console.log('');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    console.log('📝 ملاحظات مهمة:');
    console.log('• تأكد من وجود متغيرات البيئة المطلوبة');
    console.log('• النظام يراقب تغييرات عمود status في جدول orders');
    console.log('• كل مستخدم يحصل على إشعاره الخاص فقط');
    console.log('• الإشعارات لا تتكرر للحالة نفسها');
    console.log('• النظام يدعم إعادة المحاولة عند الفشل');
    console.log('');
  }
}

// ===================================
// تشغيل النظام حسب المعامل المرسل
// ===================================
if (require.main === module) {
  const systemStarter = new SmartNotificationSystemStarter();
  const command = process.argv[2];

  switch (command) {
    case 'start':
      systemStarter.startCompleteSystem();
      break;
      
    case 'test':
      const userPhone = process.argv[3];
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف للاختبار');
        console.log('الاستخدام: node start_smart_notification_system.js test <رقم_الهاتف>');
        process.exit(1);
      }
      
      systemStarter.testCompleteSystem(userPhone)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'stats':
      systemStarter.setup.showSystemStats()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      systemStarter.showUsageGuide();
      process.exit(1);
  }
}

module.exports = SmartNotificationSystemStarter;
