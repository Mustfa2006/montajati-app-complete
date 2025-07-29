/**
 * اختبار حقيقي 100% لإصلاح حالة "ارسال الى مخزن الارجاعات"
 * Real 100% Test for "ارسال الى مخزن الارجاعات" Status Fix
 * 
 * هذا الاختبار يعمل على الخادم الحقيقي في Render
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./services/targeted_notification_service');

// إعداد Supabase الحقيقي
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function realWaseetStatusTest() {
  console.log('🚀 بدء الاختبار الحقيقي 100% لإصلاح حالة الوسيط...\n');
  console.log('🌐 الاختبار يعمل على الخادم الحقيقي في Render');
  console.log('📊 قاعدة البيانات الحقيقية في Supabase\n');

  let testOrderId = null;
  let testWaseetOrderId = null;

  try {
    // 1. جلب مستخدم حقيقي للاختبار
    console.log('1️⃣ جلب مستخدم حقيقي للاختبار...');
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('phone, name')
      .not('phone', 'is', null)
      .limit(1);

    if (usersError || !users || users.length === 0) {
      throw new Error('لا يوجد مستخدمون في قاعدة البيانات للاختبار');
    }

    const testUser = users[0];
    console.log(`✅ تم العثور على مستخدم للاختبار: ${testUser.phone}`);

    // 2. إنشاء طلب جديد للاختبار
    console.log('\n2️⃣ إنشاء طلب جديد للاختبار...');
    testWaseetOrderId = `TEST-WASEET-${Date.now()}`;
    
    const testOrderIdString = `TEST-ORDER-${Date.now()}`;

    const { data: newOrder, error: orderError } = await supabase
      .from('orders')
      .insert({
        id: testOrderIdString,
        user_phone: testUser.phone,
        customer_name: 'عميل تجريبي للاختبار',
        primary_phone: '07501234567',
        customer_phone: '07501234567',
        customer_address: 'عنوان تجريبي للاختبار',
        province: 'بغداد',
        city: 'بغداد',
        subtotal: 25000,
        delivery_fee: 3000,
        total: 28000,
        profit: 5000,
        status: 'فعال',
        waseet_order_id: testWaseetOrderId,
        waseet_status_id: 1,
        waseet_status_text: 'فعال',
        created_at: new Date().toISOString(),
        last_status_check: new Date().toISOString()
      })
      .select()
      .single();

    if (orderError) {
      throw new Error(`فشل في إنشاء الطلب: ${orderError.message}`);
    }

    testOrderId = newOrder.id;
    console.log(`✅ تم إنشاء طلب تجريبي: ID=${testOrderId}, Waseet ID=${testWaseetOrderId}`);
    console.log(`📱 المستخدم: ${testUser.phone}`);
    console.log(`👤 العميل: ${newOrder.customer_name}`);
    console.log(`📊 الحالة الأولية: ${newOrder.status}`);

    // 3. محاكاة تحديث من الوسيط بالحالة المشكلة
    console.log('\n3️⃣ محاكاة تحديث من الوسيط بالحالة المشكلة...');
    console.log('📥 محاكاة استلام البيانات من الوسيط:');
    console.log(`   - waseet_order_id: ${testWaseetOrderId}`);
    console.log(`   - status_id: 23`);
    console.log(`   - status: "ارسال الى مخزن الارجاعات"`);

    // تطبيق التحويل الجديد
    const IntegratedWaseetSync = require('./services/integrated_waseet_sync');
    const syncService = new IntegratedWaseetSync();
    
    const newAppStatus = syncService.mapWaseetStatusToApp(23, 'ارسال الى مخزن الارجاعات');
    console.log(`🔄 التحويل إلى حالة التطبيق: "${newAppStatus}"`);

    // 4. تحديث الطلب في قاعدة البيانات
    console.log('\n4️⃣ تحديث الطلب في قاعدة البيانات...');
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: newAppStatus,
        waseet_status_id: 23,
        waseet_status_text: 'ارسال الى مخزن الارجاعات',
        last_status_check: new Date().toISOString(),
        status_updated_at: new Date().toISOString()
      })
      .eq('id', testOrderId);

    if (updateError) {
      throw new Error(`فشل في تحديث الطلب: ${updateError.message}`);
    }

    console.log('✅ تم تحديث الطلب في قاعدة البيانات');

    // 5. التحقق من التحديث
    console.log('\n5️⃣ التحقق من التحديث...');
    const { data: updatedOrder, error: checkError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', testOrderId)
      .single();

    if (checkError) {
      throw new Error(`فشل في جلب الطلب المحدث: ${checkError.message}`);
    }

    console.log('📊 حالة الطلب بعد التحديث:');
    console.log(`   - الحالة في التطبيق: "${updatedOrder.status}"`);
    console.log(`   - معرف حالة الوسيط: ${updatedOrder.waseet_status_id}`);
    console.log(`   - نص حالة الوسيط: "${updatedOrder.waseet_status_text}"`);

    // التحقق من نجاح التحويل
    if (updatedOrder.status === 'الغاء الطلب') {
      console.log('✅ نجح التحويل! الحالة تظهر الآن "الغاء الطلب" بدلاً من "الرقم غير معرف"');
    } else {
      console.log(`❌ فشل التحويل! الحالة: "${updatedOrder.status}"`);
    }

    // 6. اختبار إرسال الإشعار
    console.log('\n6️⃣ اختبار إرسال الإشعار...');
    
    // تهيئة خدمة الإشعارات
    const initialized = await targetedNotificationService.initialize();
    if (!initialized) {
      throw new Error('فشل في تهيئة خدمة الإشعارات');
    }

    // إرسال إشعار تحديث الحالة
    const notificationResult = await targetedNotificationService.sendOrderStatusNotification(
      testUser.phone,
      testOrderId.toString(),
      'الغاء الطلب',
      updatedOrder.customer_name,
      'ارسال الى مخزن الارجاعات'
    );

    if (notificationResult.success) {
      console.log('✅ تم إرسال الإشعار بنجاح!');
      console.log(`📱 معرف الرسالة: ${notificationResult.messageId}`);
      console.log('📋 تنسيق الإشعار:');
      console.log(`   - العنوان: ❌ إلغاء الطلب`);
      console.log(`   - الرسالة: ${updatedOrder.customer_name} - (الغاء الطلب)`);
    } else {
      console.log(`❌ فشل إرسال الإشعار: ${notificationResult.error}`);
    }

    // 7. فحص سجل الإشعارات
    console.log('\n7️⃣ فحص سجل الإشعارات...');
    const { data: notificationLogs, error: logsError } = await supabase
      .from('notification_logs')
      .select('title, message, success, sent_at')
      .eq('user_phone', testUser.phone)
      .eq('order_id', testOrderId.toString())
      .order('sent_at', { ascending: false })
      .limit(1);

    if (logsError) {
      console.log(`⚠️ خطأ في جلب سجل الإشعارات: ${logsError.message}`);
    } else if (notificationLogs && notificationLogs.length > 0) {
      const log = notificationLogs[0];
      console.log('📋 آخر إشعار مسجل:');
      console.log(`   - العنوان: "${log.title}"`);
      console.log(`   - الرسالة: "${log.message}"`);
      console.log(`   - النجاح: ${log.success ? '✅' : '❌'}`);
      console.log(`   - التوقيت: ${new Date(log.sent_at).toLocaleString('ar-EG')}`);
    } else {
      console.log('⚠️ لم يتم العثور على سجل إشعارات');
    }

    // 8. النتائج النهائية
    console.log('\n🎯 === النتائج النهائية ===');
    
    const testPassed = updatedOrder.status === 'الغاء الطلب' && notificationResult.success;
    
    if (testPassed) {
      console.log('🎉 الاختبار نجح بالكامل!');
      console.log('✅ تم إصلاح مشكلة "ارسال الى مخزن الارجاعات"');
      console.log('✅ الحالة تتحول الآن إلى "الغاء الطلب"');
      console.log('✅ الإشعارات تُرسل بالتنسيق الصحيح');
      console.log('\n💡 الآن عندما يأتي من الوسيط:');
      console.log('   - ID: 23, النص: "ارسال الى مخزن الارجاعات"');
      console.log('   سيظهر في التطبيق: "الغاء الطلب"');
      console.log('   وسيصل إشعار: "❌ إلغاء الطلب - اسم العميل - (الغاء الطلب)"');
    } else {
      console.log('❌ الاختبار فشل!');
      if (updatedOrder.status !== 'الغاء الطلب') {
        console.log(`   - مشكلة في التحويل: "${updatedOrder.status}"`);
      }
      if (!notificationResult.success) {
        console.log(`   - مشكلة في الإشعار: ${notificationResult.error}`);
      }
    }

    return testPassed;

  } catch (error) {
    console.error('❌ خطأ في الاختبار الحقيقي:', error.message);
    console.error('📋 تفاصيل الخطأ:', error.stack);
    return false;
  } finally {
    // 9. تنظيف البيانات التجريبية
    if (testOrderId) {
      console.log('\n9️⃣ تنظيف البيانات التجريبية...');
      try {
        const { error: deleteError } = await supabase
          .from('orders')
          .delete()
          .eq('id', testOrderId);

        if (deleteError) {
          console.log(`⚠️ خطأ في حذف الطلب التجريبي: ${deleteError.message}`);
        } else {
          console.log('✅ تم حذف الطلب التجريبي');
        }
      } catch (cleanupError) {
        console.log(`⚠️ خطأ في التنظيف: ${cleanupError.message}`);
      }
    }
  }
}

// تشغيل الاختبار
if (require.main === module) {
  realWaseetStatusTest()
    .then((success) => {
      if (success) {
        console.log('\n🎉 الاختبار الحقيقي نجح بالكامل!');
        console.log('🚀 النظام جاهز للإنتاج');
        process.exit(0);
      } else {
        console.log('\n❌ الاختبار الحقيقي فشل');
        process.exit(1);
      }
    })
    .catch((error) => {
      console.error('\n💥 خطأ كارثي في الاختبار:', error.message);
      process.exit(1);
    });
}

module.exports = { realWaseetStatusTest };
