// ===================================
// اختبار شامل لنظام الإشعارات
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = 'https://fqdhskaolzfavapmqodl.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNzE5NzI2NiwiZXhwIjoyMDUyNzU3MjY2fQ.tRHMAogrSzjRwSIJ9-m0YMoPhlHeR6U8kfob0wyvf_I';
const supabase = createClient(supabaseUrl, supabaseKey);

// رابط الخادم
const serverUrl = 'https://montajati-backend.onrender.com';

async function testNotificationSystem() {
  console.log('🧪 === اختبار شامل لنظام الإشعارات ===\n');

  try {
    // 1. اختبار صحة الخادم
    console.log('1️⃣ فحص صحة الخادم...');
    const healthResponse = await axios.get(`${serverUrl}/health`, { timeout: 10000 });
    console.log(`✅ الخادم يعمل: ${healthResponse.status}`);
    console.log(`📊 البيانات: ${JSON.stringify(healthResponse.data, null, 2)}\n`);

    // 2. اختبار route الإشعارات
    console.log('2️⃣ اختبار route الإشعارات...');
    
    const testNotificationData = {
      userPhone: '07801234567', // رقم تجريبي
      title: '🧪 اختبار الإشعارات',
      message: 'هذا إشعار تجريبي للتأكد من عمل النظام',
      data: {
        type: 'test',
        timestamp: new Date().toISOString()
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
      console.error(`📝 رسالة الخطأ: ${notificationError.response?.data?.error || notificationError.message}`);
      console.error(`🔗 الرابط: ${serverUrl}/api/notifications/send\n`);
    }

    // 3. اختبار إشعار تغيير حالة الطلب
    console.log('3️⃣ اختبار إشعار تغيير حالة الطلب...');
    
    // البحث عن طلب للاختبار
    const { data: orders, error: fetchError } = await supabase
      .from('orders')
      .select('id, order_number, status, customer_name, primary_phone')
      .limit(1);

    if (fetchError || !orders || orders.length === 0) {
      console.log('⚠️ لا توجد طلبات للاختبار');
    } else {
      const testOrder = orders[0];
      console.log(`📦 طلب الاختبار: ${testOrder.order_number}`);
      console.log(`👤 العميل: ${testOrder.customer_name}`);
      console.log(`📱 الهاتف: ${testOrder.primary_phone}`);

      const orderStatusNotificationData = {
        userPhone: testOrder.primary_phone,
        title: '🔄 تحديث حالة الطلب',
        message: `تم تحديث حالة طلبك رقم ${testOrder.order_number} إلى: قيد التوصيل`,
        data: {
          type: 'order_status_update',
          orderId: testOrder.id,
          orderNumber: testOrder.order_number,
          newStatus: 'in_delivery',
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

    // 4. فحص خدمات الإشعارات
    console.log('4️⃣ فحص حالة خدمات الإشعارات...');
    
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

    // 5. فحص Firebase في الخادم
    console.log('5️⃣ فحص إعدادات Firebase...');
    
    const firebaseVars = [
      'FIREBASE_PROJECT_ID',
      'FIREBASE_PRIVATE_KEY',
      'FIREBASE_CLIENT_EMAIL'
    ];

    firebaseVars.forEach(varName => {
      const value = process.env[varName];
      if (value) {
        console.log(`✅ ${varName}: موجود`);
      } else {
        console.log(`❌ ${varName}: مفقود`);
      }
    });

    // 6. فحص جدول المستخدمين
    console.log('\n6️⃣ فحص جدول المستخدمين...');
    
    try {
      const { data: users, error: usersError } = await supabase
        .from('users')
        .select('id, phone, fcm_token')
        .limit(3);

      if (usersError) {
        console.error(`❌ خطأ في جلب المستخدمين: ${usersError.message}`);
      } else {
        console.log(`✅ تم العثور على ${users.length} مستخدم`);
        users.forEach(user => {
          console.log(`👤 المستخدم: ${user.phone} - FCM Token: ${user.fcm_token ? 'موجود' : 'مفقود'}`);
        });
      }
    } catch (usersError) {
      console.error(`❌ خطأ في فحص المستخدمين: ${usersError.message}`);
    }

  } catch (error) {
    console.error('❌ خطأ عام في الاختبار:', error.message);
  }

  console.log('\n🏁 انتهى الاختبار الشامل');
}

// تشغيل الاختبار
if (require.main === module) {
  testNotificationSystem();
}

module.exports = testNotificationSystem;
