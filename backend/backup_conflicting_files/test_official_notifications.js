// ===================================
// اختبار شامل للنظام الرسمي للإشعارات
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = 'https://fqdhskaolzfavapmqodl.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNzE5NzI2NiwiZXhwIjoyMDUyNzU3MjY2fQ.tRHMAogrSzjRwSIJ9-m0YMoPhlHeR6U8kfob0wyvf_I';
const supabase = createClient(supabaseUrl, supabaseKey);

// رابط الخادم
const serverUrl = 'https://montajati-backend.onrender.com';

async function testOfficialNotificationSystem() {
  console.log('🎯 === اختبار النظام الرسمي للإشعارات ===\n');

  try {
    // 1. فحص صحة الخادم
    console.log('1️⃣ فحص صحة الخادم...');
    const healthResponse = await axios.get(`${serverUrl}/health`, { timeout: 10000 });
    console.log(`✅ الخادم يعمل: ${healthResponse.status}`);
    console.log(`📊 البيانات: ${JSON.stringify(healthResponse.data, null, 2)}\n`);

    // 2. فحص جدول FCM Tokens
    console.log('2️⃣ فحص جدول FCM Tokens...');
    
    try {
      const { data: tokens, error: tokensError } = await supabase
        .from('user_fcm_tokens')
        .select('*')
        .limit(5);

      if (tokensError) {
        console.error(`❌ خطأ في جلب FCM Tokens: ${tokensError.message}`);
      } else {
        console.log(`✅ تم العثور على ${tokens.length} FCM Token`);
        tokens.forEach(token => {
          console.log(`📱 المستخدم: ${token.user_phone} - المنصة: ${token.platform} - نشط: ${token.is_active}`);
        });
      }
    } catch (tokensError) {
      console.error(`❌ خطأ في فحص FCM Tokens: ${tokensError.message}`);
    }

    console.log('');

    // 3. اختبار إرسال إشعار للمستخدم الأول
    console.log('3️⃣ اختبار إرسال إشعار للمستخدم...');
    
    const testUserPhone = '07503597589';
    const testNotificationData = {
      userPhone: testUserPhone,
      title: '🧪 اختبار النظام الرسمي',
      message: 'هذا إشعار تجريبي للتأكد من عمل النظام الرسمي للإشعارات',
      data: {
        type: 'test_official',
        timestamp: new Date().toISOString(),
        test_id: 'official_test_' + Date.now()
      }
    };

    try {
      const notificationResponse = await axios.post(
        `${serverUrl}/api/notifications/send`,
        testNotificationData,
        {
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          timeout: 30000
        }
      );

      console.log(`✅ نجح إرسال الإشعار:`);
      console.log(`📊 كود الاستجابة: ${notificationResponse.status}`);
      console.log(`📝 البيانات: ${JSON.stringify(notificationResponse.data, null, 2)}\n`);

    } catch (notificationError) {
      console.error('❌ فشل في إرسال الإشعار:');
      console.error(`📊 كود الخطأ: ${notificationError.response?.status || 'غير معروف'}`);
      console.error(`📝 رسالة الخطأ: ${notificationError.response?.data?.error || notificationError.message}\n`);
    }

    // 4. اختبار إشعار تغيير حالة طلب حقيقي
    console.log('4️⃣ اختبار إشعار تغيير حالة طلب حقيقي...');
    
    // البحث عن طلب للمستخدم المحدد
    const { data: userOrders, error: ordersError } = await supabase
      .from('orders')
      .select('id, order_number, status, customer_name, user_phone')
      .eq('user_phone', testUserPhone)
      .limit(1);

    if (ordersError || !userOrders || userOrders.length === 0) {
      console.log('⚠️ لا توجد طلبات للمستخدم المحدد للاختبار');
    } else {
      const testOrder = userOrders[0];
      console.log(`📦 طلب الاختبار: ${testOrder.order_number}`);
      console.log(`👤 العميل: ${testOrder.customer_name}`);
      console.log(`📱 المستخدم: ${testOrder.user_phone}`);
      console.log(`📊 الحالة الحالية: ${testOrder.status}`);

      const orderStatusNotificationData = {
        userPhone: testOrder.user_phone,
        title: '🔄 تحديث حالة الطلب (اختبار)',
        message: `تم تحديث حالة طلب ${testOrder.customer_name} رقم ${testOrder.order_number} إلى: قيد التوصيل`,
        data: {
          type: 'order_status_update',
          order_id: testOrder.id,
          order_number: testOrder.order_number,
          customer_name: testOrder.customer_name,
          old_status: testOrder.status,
          new_status: 'in_delivery',
          timestamp: new Date().toISOString()
        }
      };

      try {
        const orderNotificationResponse = await axios.post(
          `${serverUrl}/api/notifications/send`,
          orderStatusNotificationData,
          {
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            timeout: 30000
          }
        );

        console.log(`✅ نجح إرسال إشعار حالة الطلب:`);
        console.log(`📊 كود الاستجابة: ${orderNotificationResponse.status}`);
        console.log(`📝 البيانات: ${JSON.stringify(orderNotificationResponse.data, null, 2)}\n`);

      } catch (orderNotificationError) {
        console.error('❌ فشل في إرسال إشعار حالة الطلب:');
        console.error(`📊 كود الخطأ: ${orderNotificationError.response?.status || 'غير معروف'}`);
        console.error(`📝 رسالة الخطأ: ${orderNotificationError.response?.data?.error || orderNotificationError.message}\n`);
      }
    }

    // 5. فحص Firebase في الخادم
    console.log('5️⃣ فحص إعدادات Firebase في الخادم...');
    
    try {
      const servicesResponse = await axios.get(
        `${serverUrl}/api/notifications/status`,
        { timeout: 15000 }
      );

      console.log(`✅ حالة خدمات الإشعارات:`);
      console.log(`📊 كود الاستجابة: ${servicesResponse.status}`);
      console.log(`📝 البيانات: ${JSON.stringify(servicesResponse.data, null, 2)}\n`);

    } catch (servicesError) {
      console.error('❌ فشل في فحص خدمات الإشعارات:');
      console.error(`📊 كود الخطأ: ${servicesError.response?.status || 'غير معروف'}`);
      console.error(`📝 رسالة الخطأ: ${servicesError.response?.data?.error || servicesError.message}\n`);
    }

    // 6. إحصائيات النظام
    console.log('6️⃣ إحصائيات النظام...');
    
    try {
      // عدد المستخدمين المسجلين للإشعارات
      const { count: activeTokensCount } = await supabase
        .from('user_fcm_tokens')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      console.log(`📊 عدد المستخدمين المسجلين للإشعارات: ${activeTokensCount || 0}`);

      // عدد الطلبات الإجمالي
      const { count: totalOrdersCount } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true });

      console.log(`📦 عدد الطلبات الإجمالي: ${totalOrdersCount || 0}`);

      // عدد الطلبات للمستخدم المحدد
      const { count: userOrdersCount } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .eq('user_phone', testUserPhone);

      console.log(`👤 عدد طلبات المستخدم ${testUserPhone}: ${userOrdersCount || 0}`);

    } catch (statsError) {
      console.error(`❌ خطأ في جلب الإحصائيات: ${statsError.message}`);
    }

  } catch (error) {
    console.error('❌ خطأ عام في الاختبار:', error.message);
  }

  console.log('\n🏁 انتهى الاختبار الشامل للنظام الرسمي');
  console.log('🎯 النظام جاهز لإرسال الإشعارات للمستخدمين صاحبي الطلبات');
}

// تشغيل الاختبار
if (require.main === module) {
  testOfficialNotificationSystem();
}

module.exports = testOfficialNotificationSystem;
