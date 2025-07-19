#!/usr/bin/env node

// ===================================
// اختبار تدفق الإشعارات الكامل
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testNotificationFlow() {
  console.log('🧪 اختبار تدفق الإشعارات الكامل...\n');

  // 1. إنشاء طلب تجريبي
  console.log('📦 إنشاء طلب تجريبي...');
  const testOrderId = `TEST_ORDER_${Date.now()}`;
  const testUserPhone = '07503597589'; // رقم هاتف تجريبي

  try {
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        id: testOrderId,
        customer_name: 'عميل تجريبي',
        primary_phone: '07701234567',
        user_phone: testUserPhone, // هاتف المستخدم صاحب الطلب
        province: 'بغداد',
        city: 'الكرادة',
        subtotal: 50000,
        total: 55000,
        profit: 5000,
        status: 'pending'
      })
      .select()
      .single();

    if (orderError) {
      console.log(`❌ فشل في إنشاء الطلب: ${orderError.message}`);
      return;
    }

    console.log(`✅ تم إنشاء الطلب: ${testOrderId}`);

    // 2. إضافة FCM Token للمستخدم
    console.log('\n🔑 إضافة FCM Token للمستخدم...');
    const testFCMToken = `test_fcm_token_${Date.now()}`;

    const { error: tokenError } = await supabase
      .from('fcm_tokens')
      .upsert({
        user_phone: testUserPhone,
        token: testFCMToken,
        platform: 'android',
        is_active: true,
        device_info: { test: true }
      });

    if (tokenError) {
      console.log(`❌ فشل في إضافة FCM Token: ${tokenError.message}`);
    } else {
      console.log(`✅ تم إضافة FCM Token للمستخدم: ${testUserPhone}`);
    }

    // 3. تحديث حالة الطلب لتفعيل الـ trigger
    console.log('\n🔄 تحديث حالة الطلب لتفعيل الإشعار...');
    
    const { error: updateError } = await supabase
      .from('orders')
      .update({ status: 'confirmed' })
      .eq('id', testOrderId);

    if (updateError) {
      console.log(`❌ فشل في تحديث الطلب: ${updateError.message}`);
      return;
    }

    console.log(`✅ تم تحديث حالة الطلب إلى: confirmed`);

    // 4. انتظار قليل ثم فحص قائمة الانتظار
    console.log('\n⏳ انتظار 3 ثواني ثم فحص قائمة الانتظار...');
    await new Promise(resolve => setTimeout(resolve, 3000));

    const { data: notifications, error: queueError } = await supabase
      .from('notification_queue')
      .select('*')
      .eq('order_id', testOrderId);

    if (queueError) {
      console.log(`❌ فشل في فحص قائمة الانتظار: ${queueError.message}`);
    } else if (notifications && notifications.length > 0) {
      console.log(`✅ تم إنشاء ${notifications.length} إشعار في قائمة الانتظار`);
      notifications.forEach(notification => {
        console.log(`   - ID: ${notification.id}`);
        console.log(`   - المستخدم: ${notification.user_phone}`);
        console.log(`   - الحالة: ${notification.status}`);
        console.log(`   - العنوان: ${notification.notification_data?.title}`);
      });
    } else {
      console.log(`❌ لم يتم إنشاء أي إشعار في قائمة الانتظار`);
      console.log('🔍 فحص الأسباب المحتملة:');
      
      // فحص وجود الـ trigger
      const { data: triggers, error: triggerError } = await supabase
        .rpc('exec_sql', {
          sql: `
            SELECT trigger_name, event_manipulation, action_statement 
            FROM information_schema.triggers 
            WHERE trigger_name = 'smart_notification_trigger';
          `
        });

      if (triggerError) {
        console.log(`❌ فشل في فحص الـ triggers: ${triggerError.message}`);
      } else if (triggers && triggers.length > 0) {
        console.log(`✅ الـ trigger موجود`);
      } else {
        console.log(`❌ الـ trigger غير موجود - يجب تطبيق smart_notification_trigger.sql`);
      }
    }

    // 5. تنظيف البيانات التجريبية
    console.log('\n🧹 تنظيف البيانات التجريبية...');
    
    await supabase.from('notification_queue').delete().eq('order_id', testOrderId);
    await supabase.from('orders').delete().eq('id', testOrderId);
    await supabase.from('fcm_tokens').delete().eq('token', testFCMToken);
    
    console.log('✅ تم تنظيف البيانات التجريبية');

  } catch (error) {
    console.error('❌ خطأ في اختبار تدفق الإشعارات:', error.message);
  }
}

// تشغيل الاختبار
testNotificationFlow().catch(console.error);
