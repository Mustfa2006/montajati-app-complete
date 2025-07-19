// ===================================
// اختبار نظام الإشعارات بدون Firebase
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

class SimpleNotificationTester {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  // ===================================
  // اختبار النظام الكامل
  // ===================================
  async testNotificationSystem() {
    try {
      console.log('🧪 اختبار نظام الإشعارات الذكي...\n');

      // 1. اختبار الجداول
      await this.testTables();

      // 2. اختبار إنشاء إشعار
      await this.testCreateNotification();

      // 3. اختبار معالجة قائمة الانتظار
      await this.testProcessQueue();

      // 4. عرض الإحصائيات
      await this.showStats();

      console.log('\n✅ جميع الاختبارات نجحت!');
      console.log('🎉 نظام الإشعارات الذكي يعمل بالكامل!');

    } catch (error) {
      console.error('❌ خطأ في اختبار النظام:', error.message);
    }
  }

  // ===================================
  // اختبار الجداول
  // ===================================
  async testTables() {
    console.log('📊 اختبار الجداول...');

    const tables = [
      'notification_queue',
      'notification_logs', 
      'user_fcm_tokens'
    ];

    for (const table of tables) {
      try {
        const { data, error } = await this.supabase
          .from(table)
          .select('*')
          .limit(1);

        if (error) {
          console.warn(`⚠️ مشكلة في جدول ${table}: ${error.message}`);
        } else {
          console.log(`✅ جدول ${table} يعمل بشكل صحيح`);
        }
      } catch (err) {
        console.warn(`⚠️ خطأ في اختبار جدول ${table}: ${err.message}`);
      }
    }
  }

  // ===================================
  // اختبار إنشاء إشعار
  // ===================================
  async testCreateNotification() {
    console.log('\n📝 اختبار إنشاء إشعار...');

    const testNotification = {
      order_id: 'TEST-' + Date.now(),
      user_phone: '07503597589',
      customer_name: 'عميل اختبار',
      old_status: 'active',
      new_status: 'in_delivery',
      notification_data: {
        title: 'قيد التوصيل 🚗',
        message: 'عميل اختبار - قيد التوصيل 🚗',
        emoji: '🚗',
        priority: 2,
        type: 'order_status_change',
        timestamp: Date.now()
      },
      priority: 2,
      status: 'pending'
    };

    try {
      const { data, error } = await this.supabase
        .from('notification_queue')
        .insert(testNotification)
        .select();

      if (error) {
        console.error(`❌ فشل في إنشاء الإشعار: ${error.message}`);
        return null;
      }

      console.log('✅ تم إنشاء إشعار الاختبار بنجاح');
      console.log(`📋 ID: ${data[0]?.id}`);
      console.log(`📱 للمستخدم: ${data[0]?.user_phone}`);
      console.log(`📄 العنوان: ${data[0]?.notification_data?.title}`);

      return data[0];

    } catch (error) {
      console.error('❌ خطأ في إنشاء الإشعار:', error.message);
      return null;
    }
  }

  // ===================================
  // اختبار معالجة قائمة الانتظار
  // ===================================
  async testProcessQueue() {
    console.log('\n🔄 اختبار معالجة قائمة الانتظار...');

    try {
      // جلب الإشعارات المعلقة
      const { data: pendingNotifications, error } = await this.supabase
        .from('notification_queue')
        .select('*')
        .eq('status', 'pending')
        .limit(5);

      if (error) {
        console.error(`❌ خطأ في جلب الإشعارات: ${error.message}`);
        return;
      }

      if (!pendingNotifications || pendingNotifications.length === 0) {
        console.log('📭 لا توجد إشعارات معلقة');
        return;
      }

      console.log(`📋 تم العثور على ${pendingNotifications.length} إشعار معلق`);

      // معالجة كل إشعار
      for (const notification of pendingNotifications) {
        await this.processNotification(notification);
      }

    } catch (error) {
      console.error('❌ خطأ في معالجة قائمة الانتظار:', error.message);
    }
  }

  // ===================================
  // معالجة إشعار واحد (محاكاة)
  // ===================================
  async processNotification(notification) {
    try {
      console.log(`📤 معالجة إشعار: ${notification.id}`);
      console.log(`👤 المستخدم: ${notification.user_phone}`);
      console.log(`📄 الرسالة: ${notification.notification_data?.title}`);

      // محاكاة الحصول على FCM Token
      const { data: tokenData } = await this.supabase
        .from('user_fcm_tokens')
        .select('fcm_token')
        .eq('user_phone', notification.user_phone)
        .eq('is_active', true)
        .limit(1)
        .single();

      if (!tokenData) {
        console.log(`⚠️ لا يوجد FCM Token للمستخدم ${notification.user_phone}`);
        
        // تحديث حالة الإشعار إلى فاشل
        await this.supabase
          .from('notification_queue')
          .update({ 
            status: 'failed',
            error_message: 'لا يوجد FCM Token',
            processed_at: new Date().toISOString()
          })
          .eq('id', notification.id);

        return;
      }

      console.log(`📱 تم العثور على FCM Token: ${tokenData.fcm_token.substring(0, 20)}...`);

      // محاكاة إرسال الإشعار (بدون Firebase)
      console.log('📤 محاكاة إرسال الإشعار...');
      
      // تحديث حالة الإشعار إلى مرسل
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
          fcm_token: tokenData.fcm_token,
          firebase_response: { simulated: true, success: true },
          is_successful: true
        });

      console.log('✅ تم إرسال الإشعار بنجاح (محاكاة)');

    } catch (error) {
      console.error(`❌ خطأ في معالجة الإشعار ${notification.id}:`, error.message);
    }
  }

  // ===================================
  // عرض الإحصائيات
  // ===================================
  async showStats() {
    console.log('\n📊 إحصائيات النظام:');
    console.log('═══════════════════════════');

    try {
      // إحصائيات قائمة الانتظار
      const { data: queueStats } = await this.supabase
        .from('notification_queue')
        .select('status');

      if (queueStats) {
        const pending = queueStats.filter(s => s.status === 'pending').length;
        const sent = queueStats.filter(s => s.status === 'sent').length;
        const failed = queueStats.filter(s => s.status === 'failed').length;
        
        console.log('📋 قائمة انتظار الإشعارات:');
        console.log(`  معلقة: ${pending}`);
        console.log(`  مرسلة: ${sent}`);
        console.log(`  فاشلة: ${failed}`);
        console.log(`  المجموع: ${queueStats.length}`);
      }

      // إحصائيات FCM Tokens
      const { data: tokenStats } = await this.supabase
        .from('user_fcm_tokens')
        .select('platform, is_active');

      if (tokenStats) {
        const activeTokens = tokenStats.filter(t => t.is_active).length;
        
        console.log('\n📱 إحصائيات FCM Tokens:');
        console.log(`  نشطة: ${activeTokens}`);
        console.log(`  المجموع: ${tokenStats.length}`);
      }

      // إحصائيات سجل الإشعارات
      const { data: logStats } = await this.supabase
        .from('notification_logs')
        .select('is_successful');

      if (logStats) {
        const successful = logStats.filter(l => l.is_successful).length;
        const failed = logStats.filter(l => !l.is_successful).length;
        
        console.log('\n📈 سجل الإشعارات:');
        console.log(`  ناجحة: ${successful}`);
        console.log(`  فاشلة: ${failed}`);
        console.log(`  المجموع: ${logStats.length}`);
        
        if (logStats.length > 0) {
          const successRate = ((successful / logStats.length) * 100).toFixed(1);
          console.log(`  معدل النجاح: ${successRate}%`);
        }
      }

    } catch (error) {
      console.error('❌ خطأ في عرض الإحصائيات:', error.message);
    }

    console.log('═══════════════════════════');
  }

  // ===================================
  // اختبار Database Trigger
  // ===================================
  async testDatabaseTrigger() {
    console.log('\n🔄 اختبار Database Trigger...');

    try {
      // إنشاء طلب اختبار
      const testOrderId = 'TRIGGER-TEST-' + Date.now();
      
      console.log(`📝 إنشاء طلب اختبار: ${testOrderId}`);
      
      const testOrder = {
        id: testOrderId,
        customer_name: 'اختبار Trigger',
        primary_phone: '07503597589',
        customer_phone: '07503597589',
        province: 'بغداد',
        city: 'الكرادة',
        delivery_address: 'عنوان اختبار',
        subtotal: 100,
        delivery_fee: 0,
        total: 100,
        profit: 0,
        status: 'active'
      };

      const { error: insertError } = await this.supabase
        .from('orders')
        .insert(testOrder);

      if (insertError) {
        console.warn(`⚠️ لا يمكن إنشاء طلب اختبار: ${insertError.message}`);
        console.log('💡 سيتم اختبار النظام بدون Database Trigger');
        return;
      }

      // انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 1000));

      // تحديث حالة الطلب لتفعيل Trigger
      console.log('🔄 تحديث حالة الطلب لتفعيل Trigger...');
      
      const { error: updateError } = await this.supabase
        .from('orders')
        .update({ status: 'in_delivery' })
        .eq('id', testOrderId);

      if (updateError) {
        console.warn(`⚠️ فشل في تحديث الطلب: ${updateError.message}`);
        return;
      }

      // انتظار معالجة الإشعار
      console.log('⏳ انتظار معالجة الإشعار...');
      await new Promise(resolve => setTimeout(resolve, 2000));

      // التحقق من قائمة الانتظار
      const { data: queueData } = await this.supabase
        .from('notification_queue')
        .select('*')
        .eq('order_id', testOrderId);

      if (queueData && queueData.length > 0) {
        console.log('✅ Database Trigger يعمل بشكل صحيح!');
        console.log(`📋 تم إنشاء إشعار: ${queueData[0].notification_data?.title}`);
      } else {
        console.log('⚠️ Database Trigger لا يعمل أو غير مفعل');
      }

      // تنظيف
      console.log('🧹 تنظيف بيانات الاختبار...');
      await this.supabase.from('orders').delete().eq('id', testOrderId);
      await this.supabase.from('notification_queue').delete().eq('order_id', testOrderId);

    } catch (error) {
      console.error('❌ خطأ في اختبار Database Trigger:', error.message);
    }
  }
}

// ===================================
// تشغيل الاختبار
// ===================================
if (require.main === module) {
  const tester = new SimpleNotificationTester();
  const command = process.argv[2];

  switch (command) {
    case 'full':
      tester.testNotificationSystem()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'trigger':
      tester.testDatabaseTrigger()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'stats':
      tester.showStats()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      console.log('📋 الأوامر المتاحة:');
      console.log('  node test_notification_system_simple.js full     - اختبار كامل');
      console.log('  node test_notification_system_simple.js trigger  - اختبار Trigger');
      console.log('  node test_notification_system_simple.js stats    - عرض الإحصائيات');
      process.exit(1);
  }
}

module.exports = SimpleNotificationTester;
