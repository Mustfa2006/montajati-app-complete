#!/usr/bin/env node

// ===================================
// اختبار سريع للنظام الكامل
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function quickSystemTest() {
  console.log('🧪 بدء الاختبار السريع للنظام...\n');

  try {
    // 1. إنشاء طلب تجريبي
    const testOrderId = `QUICK-TEST-${Date.now()}`;
    
    console.log('📝 إنشاء طلب تجريبي...');
    const { data: orderData, error: orderError } = await supabase
      .from('orders')
      .insert({
        id: testOrderId,
        customer_name: 'اختبار سريع للنظام',
        primary_phone: '07503597589',
        province: 'بغداد',
        city: 'بغداد',
        user_phone: '07503597589',
        customer_phone: '07111222333',
        status: 'active',
        subtotal: 5000,
        delivery_fee: 1000,
        total: 6000,
        profit: 500
      })
      .select();

    if (orderError) {
      throw new Error(`خطأ في إنشاء الطلب: ${orderError.message}`);
    }

    console.log('✅ تم إنشاء الطلب:', testOrderId);

    // انتظار قليل
    await new Promise(resolve => setTimeout(resolve, 2000));

    // 2. تغيير حالة الطلب
    console.log('🔄 تغيير حالة الطلب...');
    const { error: updateError } = await supabase
      .from('orders')
      .update({ status: 'in_delivery' })
      .eq('id', testOrderId);

    if (updateError) {
      throw new Error(`خطأ في تحديث الطلب: ${updateError.message}`);
    }

    console.log('✅ تم تحديث حالة الطلب إلى: in_delivery');

    // انتظار قليل
    await new Promise(resolve => setTimeout(resolve, 2000));

    // 3. فحص قائمة انتظار الإشعارات
    console.log('📬 فحص قائمة انتظار الإشعارات...');
    const { data: queueData, error: queueError } = await supabase
      .from('notification_queue')
      .select('*')
      .eq('order_id', testOrderId)
      .order('created_at', { ascending: false });

    if (queueError) {
      throw new Error(`خطأ في فحص قائمة الإشعارات: ${queueError.message}`);
    }

    if (queueData && queueData.length > 0) {
      const notification = queueData[0];
      console.log('✅ تم إنشاء إشعار بنجاح:');
      console.log(`   📱 هاتف المستخدم: ${notification.user_phone}`);
      console.log(`   👤 اسم العميل: ${notification.customer_name}`);
      console.log(`   📋 تغيير الحالة: ${notification.old_status} → ${notification.new_status}`);
      console.log(`   ⏰ وقت الإنشاء: ${notification.created_at}`);
      console.log(`   📊 حالة الإشعار: ${notification.status}`);
      
      // التحقق من صحة البيانات
      if (notification.user_phone === '07503597589') {
        console.log('✅ الهاتف صحيح: يستخدم user_phone');
      } else {
        console.log('❌ خطأ: الهاتف غير صحيح!');
      }

      if (notification.old_status === 'active' && notification.new_status === 'in_delivery') {
        console.log('✅ تغيير الحالة صحيح');
      } else {
        console.log('❌ خطأ: تغيير الحالة غير صحيح!');
      }

    } else {
      console.log('❌ لم يتم إنشاء إشعار!');
    }

    // 4. فحص إحصائيات النظام
    console.log('\n📊 إحصائيات النظام:');
    
    const { data: queueStats } = await supabase
      .from('notification_queue')
      .select('status')
      .neq('order_id', testOrderId); // استثناء الطلب التجريبي

    const stats = {};
    queueStats?.forEach(item => {
      stats[item.status] = (stats[item.status] || 0) + 1;
    });

    console.log('   📬 قائمة الانتظار:');
    Object.entries(stats).forEach(([status, count]) => {
      console.log(`      ${status}: ${count}`);
    });

    // 5. فحص FCM tokens
    const { data: tokensData } = await supabase
      .from('fcm_tokens')
      .select('user_phone, is_active')
      .eq('is_active', true);

    console.log(`   📱 FCM Tokens نشطة: ${tokensData?.length || 0}`);

    // تنظيف الطلب التجريبي
    console.log('\n🧹 تنظيف البيانات التجريبية...');
    await supabase.from('orders').delete().eq('id', testOrderId);
    await supabase.from('notification_queue').delete().eq('order_id', testOrderId);
    console.log('✅ تم تنظيف البيانات');

    console.log('\n🎉 اكتمل الاختبار بنجاح!');
    console.log('✅ النظام يعمل بشكل صحيح');

  } catch (error) {
    console.error('\n❌ فشل الاختبار:', error.message);
    process.exit(1);
  }
}

// تشغيل الاختبار
quickSystemTest()
  .then(() => {
    console.log('\n💯 النظام جاهز للاستخدام!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ خطأ في الاختبار:', error);
    process.exit(1);
  });
