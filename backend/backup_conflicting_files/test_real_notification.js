// ===================================
// اختبار حقيقي لنظام الإشعارات
// Real Notification System Test
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = 'https://fqdhskaolzfavapmqodl.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNzE5NzI2NiwiZXhwIjoyMDUyNzU3MjY2fQ.tRHMAogrSzjRwSIJ9-m0YMoPhlHeR6U8kfob0wyvf_I';
const supabase = createClient(supabaseUrl, supabaseKey);

// رابط الخادم
const serverUrl = 'https://montajati-backend.onrender.com';

async function testRealNotificationSystem() {
  console.log('🎯 === اختبار حقيقي لنظام الإشعارات ===\n');

  try {
    // 1. فحص الطلب الأخير الذي تم تغيير حالته
    console.log('1️⃣ فحص الطلب الأخير الذي تم تغيير حالته...');
    
    const { data: recentOrder, error: orderError } = await supabase
      .from('orders')
      .select('*')
      .order('updated_at', { ascending: false })
      .limit(1)
      .single();

    if (orderError || !recentOrder) {
      console.log('❌ لا يوجد أي طلب للاختبار');
      return;
    }

    console.log(`✅ تم العثور على الطلب:`);
    console.log(`📦 معرف الطلب: ${recentOrder.id}`);
    console.log(`🔢 رقم الطلب: ${recentOrder.order_number}`);
    console.log(`👤 اسم العميل: ${recentOrder.customer_name}`);
    console.log(`📱 رقم المستخدم: ${recentOrder.user_phone}`);
    console.log(`📊 الحالة: ${recentOrder.status}`);
    console.log(`⏰ آخر تحديث: ${recentOrder.updated_at}\n`);

    // 2. فحص FCM Token للمستخدم
    console.log('2️⃣ فحص FCM Token للمستخدم...');
    
    const { data: fcmTokens, error: tokenError } = await supabase
      .from('user_fcm_tokens')
      .select('*')
      .eq('user_phone', recentOrder.user_phone);

    if (tokenError) {
      console.error(`❌ خطأ في جلب FCM Token: ${tokenError.message}`);
    } else if (!fcmTokens || fcmTokens.length === 0) {
      console.log(`⚠️ لا يوجد FCM Token للمستخدم ${recentOrder.user_phone}`);
      console.log('💡 هذا هو السبب في عدم وصول الإشعارات!');
      
      // إضافة FCM Token تجريبي للاختبار
      console.log('🔧 إضافة FCM Token تجريبي للاختبار...');
      
      const { error: insertError } = await supabase
        .from('user_fcm_tokens')
        .upsert({
          user_phone: recentOrder.user_phone,
          fcm_token: `real_test_token_${Date.now()}`,
          platform: 'android',
          is_active: true,
          updated_at: new Date().toISOString(),
        });

      if (insertError) {
        console.error(`❌ فشل في إضافة FCM Token: ${insertError.message}`);
      } else {
        console.log('✅ تم إضافة FCM Token تجريبي');
      }
    } else {
      console.log(`✅ تم العثور على ${fcmTokens.length} FCM Token للمستخدم:`);
      fcmTokens.forEach((token, index) => {
        console.log(`   ${index + 1}. Token: ${token.fcm_token.substring(0, 20)}...`);
        console.log(`      المنصة: ${token.platform}`);
        console.log(`      نشط: ${token.is_active}`);
        console.log(`      آخر تحديث: ${token.updated_at}`);
      });
    }

    console.log('');

    // 3. اختبار إرسال إشعار حقيقي
    console.log('3️⃣ اختبار إرسال إشعار حقيقي...');
    
    const notificationData = {
      userPhone: recentOrder.user_phone,
      title: '🧪 اختبار إشعار حقيقي',
      message: `تم تحديث حالة طلب ${recentOrder.customer_name} رقم ${recentOrder.order_number} إلى: قيد التوصيل`,
      data: {
        type: 'order_status_update',
        order_id: recentOrder.id,
        order_number: recentOrder.order_number,
        customer_name: recentOrder.customer_name,
        new_status: 'in_delivery',
        timestamp: new Date().toISOString(),
        test: true
      }
    };

    console.log(`📤 إرسال إشعار إلى: ${recentOrder.user_phone}`);
    console.log(`📋 العنوان: ${notificationData.title}`);
    console.log(`💬 الرسالة: ${notificationData.message}`);

    try {
      const response = await axios.post(
        `${serverUrl}/api/notifications/send`,
        notificationData,
        {
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          timeout: 30000
        }
      );

      console.log(`✅ نجح إرسال الإشعار:`);
      console.log(`📊 كود الاستجابة: ${response.status}`);
      console.log(`📝 البيانات: ${JSON.stringify(response.data, null, 2)}\n`);

      // 4. فحص سجل الإشعارات
      console.log('4️⃣ فحص سجل الإشعارات...');
      
      // انتظار قصير للسماح بحفظ السجل
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const { data: notificationLogs, error: logError } = await supabase
        .from('notification_logs')
        .select('*')
        .eq('user_id', recentOrder.user_phone)
        .order('created_at', { ascending: false })
        .limit(3);

      if (logError) {
        console.log(`⚠️ لا يمكن فحص سجل الإشعارات: ${logError.message}`);
      } else if (notificationLogs && notificationLogs.length > 0) {
        console.log(`✅ تم العثور على ${notificationLogs.length} سجل إشعار:`);
        notificationLogs.forEach((log, index) => {
          console.log(`   ${index + 1}. العنوان: ${log.title}`);
          console.log(`      الحالة: ${log.status}`);
          console.log(`      الوقت: ${log.created_at}`);
          if (log.error_message) {
            console.log(`      خطأ: ${log.error_message}`);
          }
        });
      } else {
        console.log('⚠️ لا توجد سجلات إشعارات');
      }

    } catch (notificationError) {
      console.error('❌ فشل في إرسال الإشعار:');
      console.error(`📊 كود الخطأ: ${notificationError.response?.status || 'غير معروف'}`);
      console.error(`📝 رسالة الخطأ: ${notificationError.response?.data?.error || notificationError.message}`);
      
      if (notificationError.response?.data) {
        console.error(`📋 تفاصيل الخطأ: ${JSON.stringify(notificationError.response.data, null, 2)}`);
      }
    }

    // 5. تحليل المشكلة
    console.log('\n5️⃣ تحليل المشكلة...');
    
    console.log('🔍 الأسباب المحتملة لعدم وصول الإشعارات:');
    
    if (!fcmTokens || fcmTokens.length === 0) {
      console.log('❌ السبب الرئيسي: لا يوجد FCM Token للمستخدم');
      console.log('💡 الحل: التطبيق يجب أن يحفظ FCM Token عند تسجيل الدخول');
    } else {
      const hasValidToken = fcmTokens.some(token => 
        token.is_active && 
        token.fcm_token && 
        !token.fcm_token.startsWith('test_')
      );
      
      if (!hasValidToken) {
        console.log('❌ السبب: FCM Token تجريبي وليس حقيقي');
        console.log('💡 الحل: التطبيق يجب أن يحصل على FCM Token حقيقي من Firebase');
      } else {
        console.log('✅ FCM Token موجود وصحيح');
        console.log('🔍 المشكلة قد تكون في:');
        console.log('   - إعدادات Firebase في الخادم');
        console.log('   - صلاحيات الإشعارات في التطبيق');
        console.log('   - اتصال الشبكة');
      }
    }

    // 6. خطوات الحل
    console.log('\n6️⃣ خطوات الحل المطلوبة:');
    console.log('1. تأكد من تهيئة Firebase في التطبيق');
    console.log('2. احصل على FCM Token حقيقي وليس تجريبي');
    console.log('3. احفظ FCM Token في قاعدة البيانات عند تسجيل الدخول');
    console.log('4. تأكد من صلاحيات الإشعارات في التطبيق');
    console.log('5. اختبر الإرسال من واجهة الإعدادات في التطبيق');

  } catch (error) {
    console.error('❌ خطأ عام في الاختبار:', error.message);
  }

  console.log('\n🏁 انتهى الاختبار الحقيقي');
}

// تشغيل الاختبار
if (require.main === module) {
  testRealNotificationSystem();
}

module.exports = testRealNotificationSystem;
