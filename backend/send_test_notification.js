// ===================================
// إرسال إشعار تجريبي للمستخدم المحدد
// ===================================

require('dotenv').config({ path: '../.env' });
const { createClient } = require('@supabase/supabase-js');

const TEST_USER_PHONE = '07866241788';

async function sendTestNotification() {
  console.log('🔔 إرسال إشعار تجريبي للمستخدم...');
  console.log(`📱 المستخدم: ${TEST_USER_PHONE}`);
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

    // 2. الحصول على طلب للمستخدم
    console.log('\n2️⃣ البحث عن طلب للمستخدم...');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    const { data: orders, error } = await supabase
      .from('orders')
      .select('id, customer_name, status')
      .or(`customer_phone.eq.${TEST_USER_PHONE},user_phone.eq.${TEST_USER_PHONE}`)
      .limit(1);

    if (error || !orders || orders.length === 0) {
      console.log('❌ لا توجد طلبات للمستخدم');
      return;
    }

    const testOrder = orders[0];
    console.log(`✅ تم العثور على الطلب: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`🔄 الحالة الحالية: ${testOrder.status}`);

    // 3. إرسال إشعار تحديث حالة الطلب
    console.log('\n3️⃣ إرسال إشعار تحديث حالة الطلب...');
    
    const result = await targetedNotificationService.sendOrderStatusNotification(
      TEST_USER_PHONE,
      testOrder.id,
      'shipped', // الحالة الجديدة
      testOrder.customer_name || 'عميل',
      'تم شحن طلبك بنجاح - إشعار تجريبي'
    );

    if (result.success) {
      console.log('🎉 تم إرسال الإشعار بنجاح!');
      console.log(`📊 النتائج:`);
      console.log(`   ✅ تم الإرسال لـ ${result.sentCount || 1} جهاز`);
      console.log(`   📱 عدد الرموز المستخدمة: ${result.totalTokens || 1}`);
      console.log(`   ⏰ وقت الإرسال: ${new Date().toLocaleString('ar-SA')}`);
      
      console.log('\n📱 يجب أن يصل الإشعار الآن للهاتف!');
      console.log('🔍 تحقق من الهاتف للتأكد من وصول الإشعار');
      
    } else {
      console.log('❌ فشل في إرسال الإشعار');
      console.log(`🔍 السبب: ${result.error}`);
      
      if (result.error && result.error.includes('No FCM tokens found')) {
        console.log('\n💡 الحلول المقترحة:');
        console.log('1. تأكد من تسجيل الدخول في التطبيق');
        console.log('2. تأكد من قبول أذونات الإشعارات');
        console.log('3. جرب إعادة تسجيل الدخول');
      }
    }

  } catch (error) {
    console.error('❌ خطأ في إرسال الإشعار التجريبي:', error.message);
  }

  console.log('\n=====================================');
  console.log('🏁 انتهى اختبار الإشعار التجريبي');
  console.log('=====================================');
}

// تشغيل الاختبار
sendTestNotification().catch(error => {
  console.error('❌ خطأ في تشغيل الاختبار:', error);
  process.exit(1);
});
