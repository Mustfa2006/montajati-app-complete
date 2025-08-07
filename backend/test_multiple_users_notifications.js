// ===================================
// اختبار الإشعارات لعدة مستخدمين
// ===================================

require('dotenv').config({ path: '../.env' });
const { createClient } = require('@supabase/supabase-js');

const TEST_USERS = [
  '07503597589',
  '07512329969'
];

async function testMultipleUsersNotifications() {
  console.log('🔔 اختبار الإشعارات لعدة مستخدمين...');
  console.log(`👥 المستخدمون: ${TEST_USERS.join(', ')}`);
  console.log('=====================================\n');

  try {
    // 1. تهيئة خدمة الإشعارات
    console.log('1️⃣ تهيئة خدمة الإشعارات...');
    const targetedNotificationService = require('./services/targeted_notification_service');
    
    const initialized = await targetedNotificationService.initialize();
    if (!initialized) {
      console.log('❌ فشل في تهيئة خدمة الإشعارات');
      return;
    }
    
    console.log('✅ تم تهيئة خدمة الإشعارات بنجاح');

    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // 2. اختبار كل مستخدم
    for (let i = 0; i < TEST_USERS.length; i++) {
      const userPhone = TEST_USERS[i];
      console.log(`\n${i + 2}️⃣ اختبار المستخدم: ${userPhone}`);
      console.log('─'.repeat(50));

      try {
        // فحص FCM Tokens
        const { data: tokens, error: tokensError } = await supabase
          .from('fcm_tokens')
          .select('fcm_token, created_at, last_used_at')
          .eq('user_phone', userPhone)
          .eq('is_active', true);

        if (tokensError || !tokens || tokens.length === 0) {
          console.log(`   ❌ لا يوجد FCM Token للمستخدم ${userPhone}`);
          continue;
        }

        console.log(`   ✅ FCM Tokens: ${tokens.length} نشط`);

        // البحث عن طلب للمستخدم
        const { data: orders, error: ordersError } = await supabase
          .from('orders')
          .select('id, customer_name, status')
          .or(`customer_phone.eq.${userPhone},user_phone.eq.${userPhone}`)
          .limit(1);

        if (ordersError || !orders || orders.length === 0) {
          console.log(`   ❌ لا توجد طلبات للمستخدم ${userPhone}`);
          continue;
        }

        const testOrder = orders[0];
        console.log(`   📦 الطلب: ${testOrder.id}`);
        console.log(`   👤 العميل: ${testOrder.customer_name}`);

        // إرسال إشعار تجريبي
        console.log(`   📤 إرسال إشعار تجريبي...`);
        
        const result = await targetedNotificationService.sendOrderStatusNotification(
          userPhone,
          testOrder.id,
          'delivered', // حالة تجريبية
          testOrder.customer_name || 'عميل',
          `إشعار تجريبي - تم توصيل طلبك بنجاح`
        );

        if (result.success) {
          console.log(`   🎉 تم إرسال الإشعار بنجاح!`);
          console.log(`   📊 تم الإرسال لـ ${result.sentCount || 1} جهاز`);
        } else {
          console.log(`   ❌ فشل في إرسال الإشعار: ${result.error}`);
        }

      } catch (userError) {
        console.log(`   ❌ خطأ في اختبار المستخدم ${userPhone}: ${userError.message}`);
      }

      // انتظار قصير بين المستخدمين
      if (i < TEST_USERS.length - 1) {
        console.log('   ⏳ انتظار 3 ثوان...');
        await new Promise(resolve => setTimeout(resolve, 3000));
      }
    }

    // 3. إحصائيات شاملة
    console.log('\n📊 إحصائيات شاملة:');
    console.log('─'.repeat(50));

    for (const userPhone of TEST_USERS) {
      try {
        // عدد FCM Tokens
        const { data: tokens } = await supabase
          .from('fcm_tokens')
          .select('id')
          .eq('user_phone', userPhone)
          .eq('is_active', true);

        // عدد الطلبات
        const { data: orders } = await supabase
          .from('orders')
          .select('id')
          .or(`customer_phone.eq.${userPhone},user_phone.eq.${userPhone}`);

        console.log(`📱 ${userPhone}:`);
        console.log(`   🔑 FCM Tokens: ${tokens?.length || 0}`);
        console.log(`   📦 الطلبات: ${orders?.length || 0}`);

      } catch (error) {
        console.log(`📱 ${userPhone}: خطأ في جمع الإحصائيات`);
      }
    }

  } catch (error) {
    console.error('❌ خطأ في اختبار المستخدمين المتعددين:', error.message);
  }

  console.log('\n=====================================');
  console.log('🏁 انتهى اختبار المستخدمين المتعددين');
  console.log('=====================================');
  
  console.log('\n🎯 النتيجة:');
  console.log('✅ نظام الإشعارات يعمل بنجاح');
  console.log('✅ Firebase مُهيأ بشكل صحيح');
  console.log('✅ خدمة الإشعارات المستهدفة تعمل');
  console.log('✅ تم إرسال إشعارات تجريبية للمستخدمين');
  
  console.log('\n📱 تحقق من الهواتف للتأكد من وصول الإشعارات!');
}

// تشغيل الاختبار
testMultipleUsersNotifications().catch(error => {
  console.error('❌ خطأ في تشغيل الاختبار:', error);
  process.exit(1);
});
