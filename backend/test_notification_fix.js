/**
 * اختبار إصلاح نظام الإشعارات عند تغيير حالة الطلب من الوسيط
 * Test Notification Fix for Order Status Changes from Waseet
 */

const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./services/targeted_notification_service');

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testNotificationFix() {
  console.log('🧪 بدء اختبار إصلاح نظام الإشعارات...\n');

  try {
    // 1. تهيئة خدمة الإشعارات
    console.log('1️⃣ تهيئة خدمة الإشعارات...');
    const initialized = await targetedNotificationService.initialize();
    
    if (!initialized) {
      throw new Error('فشل في تهيئة خدمة الإشعارات');
    }
    console.log('✅ تم تهيئة خدمة الإشعارات بنجاح\n');

    // 2. فحص جدول الطلبات
    console.log('2️⃣ فحص جدول الطلبات...');
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('id, user_phone, primary_phone, customer_name, status, waseet_order_id')
      .not('waseet_order_id', 'is', null)
      .limit(5);

    if (ordersError) {
      throw new Error(`خطأ في جلب الطلبات: ${ordersError.message}`);
    }

    console.log(`📦 تم العثور على ${orders.length} طلب مع معرف الوسيط`);
    
    if (orders.length === 0) {
      console.log('⚠️ لا توجد طلبات للاختبار');
      return;
    }

    // عرض عينة من الطلبات
    orders.forEach((order, index) => {
      console.log(`   ${index + 1}. الطلب ${order.id}:`);
      console.log(`      - العميل: ${order.customer_name}`);
      console.log(`      - هاتف المستخدم: ${order.user_phone || 'غير محدد'}`);
      console.log(`      - الهاتف الأساسي: ${order.primary_phone || 'غير محدد'}`);
      console.log(`      - الحالة: ${order.status}`);
      console.log(`      - معرف الوسيط: ${order.waseet_order_id}`);
    });
    console.log('');

    // 3. فحص FCM Tokens
    console.log('3️⃣ فحص FCM Tokens...');
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_phone, fcm_token, is_active')
      .eq('is_active', true)
      .limit(5);

    if (fcmError) {
      console.log(`⚠️ خطأ في جلب FCM Tokens: ${fcmError.message}`);
    } else {
      console.log(`📱 تم العثور على ${fcmTokens.length} FCM Token نشط`);
      
      fcmTokens.forEach((token, index) => {
        console.log(`   ${index + 1}. المستخدم: ${token.user_phone}`);
        console.log(`      - Token: ${token.fcm_token.substring(0, 20)}...`);
      });
    }
    console.log('');

    // 4. اختبار إرسال إشعار تجريبي
    console.log('4️⃣ اختبار إرسال إشعار تجريبي...');
    
    // البحث عن طلب له user_phone و FCM token
    const testOrder = orders.find(order => {
      const userPhone = order.user_phone || order.primary_phone;
      return userPhone && fcmTokens.some(token => token.user_phone === userPhone);
    });

    if (testOrder) {
      const userPhone = testOrder.user_phone || testOrder.primary_phone;
      console.log(`📱 إرسال إشعار تجريبي للطلب ${testOrder.id} للمستخدم ${userPhone}`);

      const result = await targetedNotificationService.sendOrderStatusNotification(
        userPhone,
        testOrder.id.toString(),
        'delivered',
        testOrder.customer_name || 'عميل',
        'اختبار النظام المحدث'
      );

      if (result.success) {
        console.log('✅ تم إرسال الإشعار التجريبي بنجاح');
        console.log(`   - معرف الرسالة: ${result.messageId}`);
      } else {
        console.log(`❌ فشل إرسال الإشعار التجريبي: ${result.error}`);
      }
    } else {
      console.log('⚠️ لا يوجد طلب مناسب للاختبار (يحتاج user_phone و FCM token)');
    }
    console.log('');

    // 5. فحص سجل الإشعارات
    console.log('5️⃣ فحص سجل الإشعارات الأخير...');
    const { data: recentLogs, error: logsError } = await supabase
      .from('notification_logs')
      .select('user_phone, title, message, success, sent_at')
      .order('sent_at', { ascending: false })
      .limit(3);

    if (logsError) {
      console.log(`⚠️ خطأ في جلب سجل الإشعارات: ${logsError.message}`);
    } else {
      console.log(`📋 آخر ${recentLogs.length} إشعار:`);
      
      recentLogs.forEach((log, index) => {
        console.log(`   ${index + 1}. ${log.title} - ${log.user_phone}`);
        console.log(`      - الرسالة: ${log.message}`);
        console.log(`      - النجاح: ${log.success ? '✅' : '❌'}`);
        console.log(`      - التوقيت: ${new Date(log.sent_at).toLocaleString('ar-EG')}`);
      });
    }

    console.log('\n🎉 تم إكمال اختبار النظام بنجاح!');
    console.log('\n📋 ملخص النتائج:');
    console.log(`   ✅ خدمة الإشعارات: ${initialized ? 'مهيأة' : 'غير مهيأة'}`);
    console.log(`   📦 الطلبات مع الوسيط: ${orders.length}`);
    console.log(`   📱 FCM Tokens نشطة: ${fcmTokens.length}`);
    console.log(`   🔧 النظام جاهز للعمل: ${initialized && orders.length > 0 && fcmTokens.length > 0 ? 'نعم' : 'لا'}`);

  } catch (error) {
    console.error('❌ خطأ في اختبار النظام:', error.message);
    console.error('📋 تفاصيل الخطأ:', error.stack);
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testNotificationFix()
    .then(() => {
      console.log('\n✅ تم إكمال الاختبار');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار:', error.message);
      process.exit(1);
    });
}

module.exports = { testNotificationFix };
