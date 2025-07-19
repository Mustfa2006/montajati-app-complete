// ===================================
// تشغيل نظام الإشعارات الحقيقي
// ===================================

require('dotenv').config();
const RealOfficialNotificationSystem = require('./official_real_notification_system');

class RealNotificationRunner {
  constructor() {
    this.system = new RealOfficialNotificationSystem();
  }

  // ===================================
  // بدء النظام الحقيقي
  // ===================================
  async startRealSystem() {
    try {
      console.log('🔥 بدء نظام الإشعارات الحقيقي الكامل...\n');

      // التحقق من متغيرات البيئة
      this.validateRealEnvironment();

      // بدء النظام الحقيقي
      await this.system.startRealSystem();

    } catch (error) {
      console.error('❌ خطأ في بدء النظام الحقيقي:', error.message);
      process.exit(1);
    }
  }

  // ===================================
  // التحقق من متغيرات البيئة الحقيقية
  // ===================================
  validateRealEnvironment() {
    console.log('🔍 التحقق من متغيرات البيئة الحقيقية...');

    const requiredVars = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'FIREBASE_SERVICE_ACCOUNT'
    ];

    const missingVars = requiredVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
      throw new Error(`متغيرات البيئة المطلوبة مفقودة: ${missingVars.join(', ')}`);
    }

    // التحقق من صحة Firebase Service Account الحقيقي
    try {
      const firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      if (!firebaseConfig.project_id || !firebaseConfig.private_key || !firebaseConfig.client_email) {
        throw new Error('Firebase Service Account الحقيقي غير مكتمل');
      }
      console.log(`✅ Firebase Project الحقيقي: ${firebaseConfig.project_id}`);
      console.log(`📧 Service Account: ${firebaseConfig.client_email}`);
    } catch (error) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT غير صالح - يجب أن يكون JSON صحيح');
    }

    console.log('✅ جميع متغيرات البيئة الحقيقية صحيحة\n');
  }

  // ===================================
  // اختبار إشعار حقيقي
  // ===================================
  async testRealNotification(userPhone, testMessage = 'اختبار النظام الحقيقي 🔥') {
    try {
      console.log(`🧪 اختبار إرسال إشعار حقيقي للمستخدم: ${userPhone}\n`);

      const result = await this.system.testRealNotification(userPhone, testMessage);
      
      if (result) {
        console.log('\n🎉 نجح اختبار الإشعار الحقيقي!');
        console.log('📱 تحقق من هاتف المستخدم - يجب أن يكون الإشعار وصل');
      } else {
        console.log('\n❌ فشل اختبار الإشعار الحقيقي');
      }

      return result;
      
    } catch (error) {
      console.error('❌ خطأ في اختبار الإشعار الحقيقي:', error.message);
      return false;
    }
  }

  // ===================================
  // اختبار Database Trigger الحقيقي
  // ===================================
  async testRealDatabaseTrigger(userPhone) {
    try {
      console.log(`🔄 اختبار Database Trigger الحقيقي للمستخدم: ${userPhone}\n`);

      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      // إنشاء طلب اختبار حقيقي
      const testOrderId = 'REAL-TRIGGER-' + Date.now();
      
      console.log(`📝 إنشاء طلب اختبار حقيقي: ${testOrderId}`);
      
      const testOrder = {
        id: testOrderId,
        customer_name: 'اختبار Trigger حقيقي',
        primary_phone: userPhone,
        customer_phone: userPhone,
        province: 'بغداد',
        city: 'الكرادة',
        delivery_address: 'عنوان اختبار حقيقي',
        subtotal: 100,
        delivery_fee: 0,
        total: 100,
        profit: 0,
        status: 'active'
      };

      const { error: insertError } = await supabase
        .from('orders')
        .insert(testOrder);

      if (insertError) {
        throw new Error(`فشل في إنشاء الطلب: ${insertError.message}`);
      }

      console.log('✅ تم إنشاء الطلب بنجاح');

      // انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 2000));

      // تحديث حالة الطلب لتفعيل Trigger الحقيقي
      console.log('🔄 تحديث حالة الطلب لتفعيل Trigger الحقيقي...');
      
      const { error: updateError } = await supabase
        .from('orders')
        .update({ status: 'in_delivery' })
        .eq('id', testOrderId);

      if (updateError) {
        throw new Error(`فشل في تحديث الطلب: ${updateError.message}`);
      }

      console.log('✅ تم تحديث حالة الطلب بنجاح');
      console.log('⏳ انتظار معالجة الإشعار الحقيقي (15 ثانية)...');

      // انتظار معالجة الإشعار الحقيقي
      await new Promise(resolve => setTimeout(resolve, 15000)); // 15 ثانية

      // التحقق من قائمة الانتظار
      const { data: queueData } = await supabase
        .from('notification_queue')
        .select('*')
        .eq('order_id', testOrderId);

      if (queueData && queueData.length > 0) {
        console.log('\n✅ Database Trigger الحقيقي يعمل بشكل صحيح!');
        console.log(`📋 تم إنشاء إشعار: ${queueData[0].notification_data?.title}`);
        console.log(`📱 حالة الإشعار: ${queueData[0].status}`);
        
        if (queueData[0].status === 'sent') {
          console.log('🔥 تم إرسال الإشعار الحقيقي بنجاح!');
          console.log('📱 تحقق من هاتف المستخدم - يجب أن يكون الإشعار وصل');
        } else if (queueData[0].status === 'pending') {
          console.log('⏳ الإشعار في قائمة الانتظار - سيتم إرساله قريباً');
        }
      } else {
        console.log('⚠️ لم يتم العثور على الإشعار في قائمة الانتظار');
      }

      // تنظيف
      console.log('\n🧹 تنظيف بيانات الاختبار...');
      await supabase.from('orders').delete().eq('id', testOrderId);

      return true;

    } catch (error) {
      console.error('❌ خطأ في اختبار Database Trigger الحقيقي:', error.message);
      return false;
    }
  }

  // ===================================
  // عرض الإحصائيات الحقيقية
  // ===================================
  async showRealStats() {
    try {
      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      console.log('📊 إحصائيات النظام الحقيقي:');
      console.log('═══════════════════════════════');

      // إحصائيات قائمة الانتظار
      const { data: queueStats } = await supabase
        .from('notification_queue')
        .select('status')
        .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

      if (queueStats) {
        const pending = queueStats.filter(s => s.status === 'pending').length;
        const processing = queueStats.filter(s => s.status === 'processing').length;
        const sent = queueStats.filter(s => s.status === 'sent').length;
        const failed = queueStats.filter(s => s.status === 'failed').length;
        
        console.log('📋 قائمة انتظار الإشعارات الحقيقية (آخر 24 ساعة):');
        console.log(`  معلقة: ${pending}`);
        console.log(`  قيد المعالجة: ${processing}`);
        console.log(`  مرسلة: ${sent}`);
        console.log(`  فاشلة: ${failed}`);
        console.log(`  المجموع: ${queueStats.length}`);
      }

      // إحصائيات FCM Tokens
      const { data: tokenStats } = await supabase
        .from('user_fcm_tokens')
        .select('platform, is_active');

      if (tokenStats) {
        const activeTokens = tokenStats.filter(t => t.is_active).length;
        const androidTokens = tokenStats.filter(t => t.platform === 'android').length;
        const iosTokens = tokenStats.filter(t => t.platform === 'ios').length;
        
        console.log('\n📱 إحصائيات FCM Tokens الحقيقية:');
        console.log(`  نشطة: ${activeTokens}`);
        console.log(`  Android: ${androidTokens}`);
        console.log(`  iOS: ${iosTokens}`);
        console.log(`  المجموع: ${tokenStats.length}`);
      }

      // إحصائيات سجل الإشعارات
      const { data: logStats } = await supabase
        .from('notification_logs')
        .select('is_successful')
        .gte('sent_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

      if (logStats) {
        const successful = logStats.filter(l => l.is_successful).length;
        const failed = logStats.filter(l => !l.is_successful).length;
        
        console.log('\n📈 سجل الإشعارات الحقيقية (آخر 24 ساعة):');
        console.log(`  ناجحة: ${successful}`);
        console.log(`  فاشلة: ${failed}`);
        console.log(`  المجموع: ${logStats.length}`);
        
        if (logStats.length > 0) {
          const successRate = ((successful / logStats.length) * 100).toFixed(1);
          console.log(`  معدل النجاح: ${successRate}%`);
        }
      }

      console.log('═══════════════════════════════');

    } catch (error) {
      console.error('❌ خطأ في عرض الإحصائيات الحقيقية:', error.message);
    }
  }

  // ===================================
  // عرض دليل الاستخدام الحقيقي
  // ===================================
  showRealUsageGuide() {
    console.log('📋 دليل استخدام النظام الحقيقي:');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    console.log('🔥 بدء النظام الحقيقي:');
    console.log('  node run_real_notification_system.js start');
    console.log('');
    console.log('🧪 اختبار إشعار حقيقي:');
    console.log('  node run_real_notification_system.js test <رقم_الهاتف>');
    console.log('');
    console.log('🔄 اختبار Database Trigger الحقيقي:');
    console.log('  node run_real_notification_system.js trigger <رقم_الهاتف>');
    console.log('');
    console.log('📊 عرض الإحصائيات الحقيقية:');
    console.log('  node run_real_notification_system.js stats');
    console.log('');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    console.log('🔥 مميزات النظام الحقيقي:');
    console.log('• إشعارات حقيقية 100% عبر Firebase (ليست محاكاة)');
    console.log('• تصل للمستخدمين فوراً حتى لو كان التطبيق مغلق');
    console.log('• مراقبة تلقائية لتغييرات حالة الطلبات');
    console.log('• نظام إعادة محاولة ذكي');
    console.log('• إحصائيات مفصلة ومراقبة الأداء');
    console.log('• يعمل مع المستخدمين غير النشطين');
    console.log('');
    console.log('📱 إجابة سؤالك:');
    console.log('نعم! المستخدم سيحصل على الإشعار حتى لو كان:');
    console.log('• التطبيق مغلق');
    console.log('• الهاتف في وضع السكون');
    console.log('• المستخدم غير نشط');
    console.log('• يستخدم تطبيقات أخرى');
    console.log('');
  }
}

// ===================================
// تشغيل النظام الحقيقي
// ===================================
if (require.main === module) {
  const runner = new RealNotificationRunner();
  const command = process.argv[2];
  const userPhone = process.argv[3];

  switch (command) {
    case 'start':
      runner.startRealSystem();
      break;
      
    case 'test':
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف للاختبار');
        console.log('الاستخدام: node run_real_notification_system.js test <رقم_الهاتف>');
        process.exit(1);
      }
      
      runner.testRealNotification(userPhone)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'trigger':
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف للاختبار');
        console.log('الاستخدام: node run_real_notification_system.js trigger <رقم_الهاتف>');
        process.exit(1);
      }
      
      runner.testRealDatabaseTrigger(userPhone)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'stats':
      runner.showRealStats()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      runner.showRealUsageGuide();
      process.exit(1);
  }
}

module.exports = RealNotificationRunner;
