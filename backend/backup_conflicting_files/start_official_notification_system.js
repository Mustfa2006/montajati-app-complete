// ===================================
// تشغيل نظام الإشعارات الرسمي
// ===================================

require('dotenv').config();
const OfficialFirebaseNotificationService = require('./services/official_firebase_notification_service');

class OfficialNotificationSystemRunner {
  constructor() {
    this.service = new OfficialFirebaseNotificationService();
  }

  // ===================================
  // بدء النظام الرسمي
  // ===================================
  async startOfficialSystem() {
    try {
      console.log('🔥 بدء نظام الإشعارات الرسمي الكامل...\n');

      // التحقق من متغيرات البيئة
      this.validateEnvironment();

      // بدء النظام الرسمي
      await this.service.startOfficialSystem();

    } catch (error) {
      console.error('❌ خطأ في بدء النظام الرسمي:', error.message);
      process.exit(1);
    }
  }

  // ===================================
  // التحقق من متغيرات البيئة
  // ===================================
  validateEnvironment() {
    console.log('🔍 التحقق من متغيرات البيئة الرسمية...');

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

    console.log('✅ جميع متغيرات البيئة الرسمية صحيحة\n');
  }

  // ===================================
  // اختبار إشعار رسمي
  // ===================================
  async testOfficialNotification(userPhone, testMessage = 'اختبار النظام الرسمي 🔥') {
    try {
      console.log(`🧪 اختبار إرسال إشعار رسمي للمستخدم: ${userPhone}`);

      // الحصول على FCM Token
      const fcmToken = await this.service.getFCMToken(userPhone);
      
      if (!fcmToken) {
        console.log(`❌ لا يوجد FCM Token للمستخدم ${userPhone}`);
        console.log('💡 تأكد من أن المستخدم سجل دخول في التطبيق وحفظ FCM Token');
        return false;
      }

      // إنشاء إشعار اختبار رسمي
      const testNotification = {
        id: 'official-test-' + Date.now(),
        order_id: 'OFFICIAL-TEST-ORDER',
        user_phone: userPhone,
        customer_name: 'اختبار رسمي',
        old_status: 'active',
        new_status: 'in_delivery',
        notification_data: {
          title: 'اختبار النظام الرسمي 🔥',
          message: testMessage,
          type: 'test',
          emoji: '🔥',
          priority: 1,
          timestamp: Date.now()
        }
      };

      // إرسال الإشعار الرسمي
      const result = await this.service.sendOfficialFirebaseNotification(fcmToken, testNotification);
      
      if (result.success) {
        console.log(`✅ تم إرسال الإشعار الرسمي بنجاح!`);
        console.log(`📱 Message ID: ${result.messageId}`);
        console.log('🔔 يجب أن يصل الإشعار للمستخدم الآن (حتى لو كان التطبيق مغلق)');
        return true;
      } else {
        console.log(`❌ فشل في إرسال الإشعار الرسمي: ${result.error}`);
        return false;
      }
      
    } catch (error) {
      console.error('❌ خطأ في اختبار الإشعار الرسمي:', error.message);
      return false;
    }
  }

  // ===================================
  // اختبار Database Trigger الرسمي
  // ===================================
  async testOfficialDatabaseTrigger(userPhone) {
    try {
      console.log(`🔄 اختبار Database Trigger الرسمي للمستخدم: ${userPhone}`);

      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      // إنشاء طلب اختبار رسمي
      const testOrderId = 'OFFICIAL-TRIGGER-' + Date.now();
      
      console.log(`📝 إنشاء طلب اختبار رسمي: ${testOrderId}`);
      
      const testOrder = {
        id: testOrderId,
        customer_name: 'اختبار Trigger رسمي',
        primary_phone: userPhone,
        customer_phone: userPhone,
        province: 'بغداد',
        city: 'الكرادة',
        delivery_address: 'عنوان اختبار رسمي',
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

      // انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 1000));

      // تحديث حالة الطلب لتفعيل Trigger الرسمي
      console.log('🔄 تحديث حالة الطلب لتفعيل Trigger الرسمي...');
      
      const { error: updateError } = await supabase
        .from('orders')
        .update({ status: 'in_delivery' })
        .eq('id', testOrderId);

      if (updateError) {
        throw new Error(`فشل في تحديث الطلب: ${updateError.message}`);
      }

      console.log('✅ تم تحديث حالة الطلب بنجاح');

      // انتظار معالجة الإشعار الرسمي
      console.log('⏳ انتظار معالجة الإشعار الرسمي...');
      await new Promise(resolve => setTimeout(resolve, 10000)); // 10 ثواني

      // التحقق من قائمة الانتظار
      const { data: queueData } = await supabase
        .from('notification_queue')
        .select('*')
        .eq('order_id', testOrderId);

      if (queueData && queueData.length > 0) {
        console.log('✅ Database Trigger الرسمي يعمل بشكل صحيح!');
        console.log(`📋 تم إنشاء إشعار: ${queueData[0].notification_data?.title}`);
        console.log(`📱 حالة الإشعار: ${queueData[0].status}`);
        
        if (queueData[0].status === 'sent') {
          console.log('🔥 تم إرسال الإشعار الرسمي بنجاح!');
        }
      } else {
        console.log('⚠️ لم يتم العثور على الإشعار في قائمة الانتظار');
      }

      // تنظيف
      console.log('🧹 تنظيف بيانات الاختبار...');
      await supabase.from('orders').delete().eq('id', testOrderId);

      return true;

    } catch (error) {
      console.error('❌ خطأ في اختبار Database Trigger الرسمي:', error.message);
      return false;
    }
  }

  // ===================================
  // عرض الإحصائيات الرسمية
  // ===================================
  async showOfficialStats() {
    try {
      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      console.log('📊 إحصائيات النظام الرسمي:');
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
        
        console.log('📋 قائمة انتظار الإشعارات (آخر 24 ساعة):');
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
        
        console.log('\n📱 إحصائيات FCM Tokens:');
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
        
        console.log('\n📈 سجل الإشعارات الرسمية (آخر 24 ساعة):');
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
      console.error('❌ خطأ في عرض الإحصائيات الرسمية:', error.message);
    }
  }

  // ===================================
  // عرض دليل الاستخدام الرسمي
  // ===================================
  showOfficialUsageGuide() {
    console.log('📋 دليل استخدام النظام الرسمي:');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    console.log('🔥 بدء النظام الرسمي:');
    console.log('  node start_official_notification_system.js start');
    console.log('');
    console.log('🧪 اختبار إشعار رسمي:');
    console.log('  node start_official_notification_system.js test <رقم_الهاتف>');
    console.log('');
    console.log('🔄 اختبار Database Trigger الرسمي:');
    console.log('  node start_official_notification_system.js trigger <رقم_الهاتف>');
    console.log('');
    console.log('📊 عرض الإحصائيات الرسمية:');
    console.log('  node start_official_notification_system.js stats');
    console.log('');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    console.log('🔥 مميزات النظام الرسمي:');
    console.log('• إشعارات حقيقية عبر Firebase (ليست محاكاة)');
    console.log('• تصل للمستخدمين حتى لو كان التطبيق مغلق');
    console.log('• مراقبة تلقائية لتغييرات حالة الطلبات');
    console.log('• نظام إعادة محاولة ذكي');
    console.log('• إحصائيات مفصلة ومراقبة الأداء');
    console.log('');
  }
}

// ===================================
// تشغيل النظام الرسمي
// ===================================
if (require.main === module) {
  const runner = new OfficialNotificationSystemRunner();
  const command = process.argv[2];
  const userPhone = process.argv[3];

  switch (command) {
    case 'start':
      runner.startOfficialSystem();
      break;
      
    case 'test':
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف للاختبار');
        console.log('الاستخدام: node start_official_notification_system.js test <رقم_الهاتف>');
        process.exit(1);
      }
      
      runner.testOfficialNotification(userPhone)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'trigger':
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف للاختبار');
        console.log('الاستخدام: node start_official_notification_system.js trigger <رقم_الهاتف>');
        process.exit(1);
      }
      
      runner.testOfficialDatabaseTrigger(userPhone)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'stats':
      runner.showOfficialStats()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      runner.showOfficialUsageGuide();
      process.exit(1);
  }
}

module.exports = OfficialNotificationSystemRunner;
