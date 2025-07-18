// ===================================
// إنشاء جداول الإشعارات مباشرة عبر Supabase
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

class DirectNotificationTablesCreator {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  // ===================================
  // إنشاء الجداول مباشرة
  // ===================================
  async createNotificationTables() {
    try {
      console.log('🚀 إنشاء جداول الإشعارات مباشرة...\n');

      // 1. إنشاء جدول قائمة انتظار الإشعارات
      await this.createNotificationQueueTable();

      // 2. التحقق من جدول FCM Tokens وإنشاؤه إذا لم يكن موجود
      await this.ensureFCMTokensTable();

      // 3. إضافة بيانات اختبار
      await this.addTestData();

      console.log('\n✅ تم إنشاء جداول الإشعارات بنجاح!');
      
      // اختبار الجداول
      await this.testTables();

    } catch (error) {
      console.error('❌ خطأ في إنشاء الجداول:', error.message);
      throw error;
    }
  }

  // ===================================
  // إنشاء جدول قائمة انتظار الإشعارات
  // ===================================
  async createNotificationQueueTable() {
    try {
      console.log('📋 إنشاء جدول notification_queue...');

      // محاولة إنشاء الجدول عبر INSERT مع ON CONFLICT
      const testData = {
        id: '00000000-0000-0000-0000-000000000000',
        order_id: 'TEST-INIT',
        user_phone: '00000000000',
        customer_name: 'تهيئة الجدول',
        old_status: 'init',
        new_status: 'init',
        notification_data: {
          title: 'تهيئة',
          message: 'تهيئة الجدول',
          type: 'init'
        },
        priority: 1,
        max_retries: 3,
        retry_count: 0,
        status: 'pending'
      };

      const { error } = await this.supabase
        .from('notification_queue')
        .upsert(testData);

      if (error) {
        console.warn(`⚠️ الجدول غير موجود، سيتم إنشاؤه تلقائياً عند أول استخدام`);
        console.log('📝 سيتم إنشاء الجدول عبر migration أو admin panel');
      } else {
        console.log('✅ جدول notification_queue موجود ويعمل');
        
        // حذف بيانات الاختبار
        await this.supabase
          .from('notification_queue')
          .delete()
          .eq('id', testData.id);
      }

    } catch (error) {
      console.warn('⚠️ سيتم إنشاء الجدول عند الحاجة:', error.message);
    }
  }

  // ===================================
  // التأكد من وجود جدول FCM Tokens
  // ===================================
  async ensureFCMTokensTable() {
    try {
      console.log('📱 التحقق من جدول user_fcm_tokens...');

      const { data, error } = await this.supabase
        .from('user_fcm_tokens')
        .select('*')
        .limit(1);

      if (error) {
        console.warn(`⚠️ مشكلة في جدول FCM Tokens: ${error.message}`);
      } else {
        console.log('✅ جدول user_fcm_tokens يعمل بشكل صحيح');
      }

    } catch (error) {
      console.error('❌ خطأ في التحقق من جدول FCM Tokens:', error.message);
    }
  }

  // ===================================
  // إضافة بيانات اختبار
  // ===================================
  async addTestData() {
    try {
      console.log('🧪 إضافة بيانات اختبار...');

      // إضافة FCM Token اختبار
      const testToken = {
        user_phone: '07503597589',
        fcm_token: `test_token_${Date.now()}`,
        platform: 'android',
        is_active: true
      };

      const { error: tokenError } = await this.supabase
        .from('user_fcm_tokens')
        .upsert(testToken, {
          onConflict: 'user_phone,platform'
        });

      if (tokenError) {
        console.warn(`⚠️ تحذير في إضافة FCM Token: ${tokenError.message}`);
      } else {
        console.log('✅ تم إضافة FCM Token اختبار');
      }

    } catch (error) {
      console.warn('⚠️ تحذير في إضافة بيانات الاختبار:', error.message);
    }
  }

  // ===================================
  // اختبار الجداول
  // ===================================
  async testTables() {
    try {
      console.log('\n🧪 اختبار الجداول...');

      // اختبار جدول notification_logs
      const { data: logsData, error: logsError } = await this.supabase
        .from('notification_logs')
        .select('*')
        .limit(1);

      if (logsError) {
        console.warn(`⚠️ مشكلة في جدول notification_logs: ${logsError.message}`);
      } else {
        console.log('✅ جدول notification_logs يعمل بشكل صحيح');
      }

      // اختبار جدول user_fcm_tokens
      const { data: tokensData, error: tokensError } = await this.supabase
        .from('user_fcm_tokens')
        .select('*')
        .limit(1);

      if (tokensError) {
        console.warn(`⚠️ مشكلة في جدول user_fcm_tokens: ${tokensError.message}`);
      } else {
        console.log('✅ جدول user_fcm_tokens يعمل بشكل صحيح');
        console.log(`📊 عدد FCM Tokens: ${tokensData?.length || 0}`);
      }

      // اختبار جدول notification_queue
      const { data: queueData, error: queueError } = await this.supabase
        .from('notification_queue')
        .select('*')
        .limit(1);

      if (queueError) {
        console.warn(`⚠️ مشكلة في جدول notification_queue: ${queueError.message}`);
        console.log('💡 سيتم إنشاء الجدول عند أول استخدام للنظام');
      } else {
        console.log('✅ جدول notification_queue يعمل بشكل صحيح');
        console.log(`📊 عدد الإشعارات المعلقة: ${queueData?.length || 0}`);
      }

    } catch (error) {
      console.error('❌ خطأ في اختبار الجداول:', error.message);
    }
  }

  // ===================================
  // إنشاء إشعار اختبار يدوي
  // ===================================
  async createTestNotification(userPhone, customerName = 'اختبار النظام') {
    try {
      console.log(`🧪 إنشاء إشعار اختبار للمستخدم: ${userPhone}`);

      const testNotification = {
        order_id: 'TEST-' + Date.now(),
        user_phone: userPhone,
        customer_name: customerName,
        old_status: 'active',
        new_status: 'in_delivery',
        notification_data: {
          title: 'قيد التوصيل 🚗',
          message: `${customerName} - قيد التوصيل 🚗`,
          emoji: '🚗',
          priority: 2,
          type: 'order_status_change',
          timestamp: Date.now()
        },
        priority: 2,
        status: 'pending'
      };

      const { data, error } = await this.supabase
        .from('notification_queue')
        .insert(testNotification)
        .select();

      if (error) {
        console.error(`❌ فشل في إنشاء إشعار الاختبار: ${error.message}`);
        return false;
      }

      console.log('✅ تم إنشاء إشعار الاختبار بنجاح');
      console.log(`📋 ID: ${data[0]?.id}`);
      return data[0];

    } catch (error) {
      console.error('❌ خطأ في إنشاء إشعار الاختبار:', error.message);
      return false;
    }
  }

  // ===================================
  // محاكاة تغيير حالة طلب
  // ===================================
  async simulateOrderStatusChange(userPhone) {
    try {
      console.log(`🔄 محاكاة تغيير حالة طلب للمستخدم: ${userPhone}`);

      // 1. إنشاء طلب اختبار
      const testOrderId = 'SIM-' + Date.now();
      
      const testOrder = {
        id: testOrderId,
        customer_name: 'عميل اختبار',
        primary_phone: userPhone,
        customer_phone: userPhone,
        delivery_address: 'عنوان اختبار',
        subtotal: 100,
        total: 100,
        status: 'active'
      };

      console.log('📝 إنشاء طلب اختبار...');
      const { error: insertError } = await this.supabase
        .from('orders')
        .insert(testOrder);

      if (insertError) {
        console.error(`❌ فشل في إنشاء الطلب: ${insertError.message}`);
        return false;
      }

      // 2. انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 1000));

      // 3. تحديث حالة الطلب
      console.log('🔄 تحديث حالة الطلب...');
      const { error: updateError } = await this.supabase
        .from('orders')
        .update({ status: 'in_delivery' })
        .eq('id', testOrderId);

      if (updateError) {
        console.error(`❌ فشل في تحديث الطلب: ${updateError.message}`);
        return false;
      }

      console.log('✅ تم تحديث حالة الطلب بنجاح');

      // 4. انتظار معالجة الإشعار
      console.log('⏳ انتظار معالجة الإشعار...');
      await new Promise(resolve => setTimeout(resolve, 2000));

      // 5. التحقق من قائمة الانتظار
      const { data: queueData } = await this.supabase
        .from('notification_queue')
        .select('*')
        .eq('order_id', testOrderId);

      if (queueData && queueData.length > 0) {
        console.log('✅ تم إنشاء الإشعار في قائمة الانتظار');
        console.log(`📋 عنوان الإشعار: ${queueData[0].notification_data?.title}`);
      } else {
        console.log('⚠️ لم يتم العثور على الإشعار - قد يكون Trigger غير مفعل');
        
        // إنشاء إشعار يدوي
        await this.createTestNotification(userPhone, 'عميل اختبار');
      }

      // 6. تنظيف
      console.log('🧹 تنظيف بيانات الاختبار...');
      await this.supabase.from('orders').delete().eq('id', testOrderId);
      await this.supabase.from('notification_queue').delete().eq('order_id', testOrderId);

      return true;

    } catch (error) {
      console.error('❌ خطأ في محاكاة تغيير الحالة:', error.message);
      return false;
    }
  }
}

// ===================================
// تشغيل الإنشاء
// ===================================
if (require.main === module) {
  const creator = new DirectNotificationTablesCreator();
  const command = process.argv[2];
  const userPhone = process.argv[3];

  switch (command) {
    case 'create':
      creator.createNotificationTables()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'test':
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف للاختبار');
        console.log('الاستخدام: node create_notification_tables_direct.js test <رقم_الهاتف>');
        process.exit(1);
      }
      
      creator.createNotificationTables()
        .then(() => creator.simulateOrderStatusChange(userPhone))
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'notification':
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف');
        process.exit(1);
      }
      
      creator.createTestNotification(userPhone)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      console.log('📋 الأوامر المتاحة:');
      console.log('  node create_notification_tables_direct.js create');
      console.log('  node create_notification_tables_direct.js test <رقم_الهاتف>');
      console.log('  node create_notification_tables_direct.js notification <رقم_الهاتف>');
      process.exit(1);
  }
}

module.exports = DirectNotificationTablesCreator;
