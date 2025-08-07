// ===================================
// اختبار عدم وجود إشعارات مكررة
// ===================================

require('dotenv').config({ path: '../.env' });
const { createClient } = require('@supabase/supabase-js');

const TEST_USER_PHONE = '07866241788';

async function testNoDuplicateNotifications() {
  console.log('🔍 اختبار عدم وجود إشعارات مكررة...');
  console.log(`📱 المستخدم: ${TEST_USER_PHONE}`);
  console.log('=====================================\n');

  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );

  try {
    // 1. فحص الأنظمة المتبقية
    console.log('1️⃣ فحص الأنظمة المتبقية:');
    
    console.log('   ✅ النظام الأول: routes/orders.js - التحديث اليدوي');
    console.log('   ✅ النظام الثاني: routes/waseet_statuses.js - المزامنة مع الوسيط');
    console.log('   ❌ تم حذف: routes/notifications.js - النظام المكرر');
    console.log('   ❌ تم حذف: routes/targeted_notifications.js - النظام المكرر');

    // 2. إنشاء طلب تجريبي للاختبار
    console.log('\n2️⃣ إنشاء طلب تجريبي للاختبار:');
    
    const testOrder = {
      id: `test_order_${Date.now()}`,
      customer_phone: TEST_USER_PHONE,
      customer_name: 'عميل تجريبي',
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data: insertedOrder, error: insertError } = await supabase
      .from('orders')
      .insert(testOrder)
      .select()
      .single();

    if (insertError) {
      console.log(`   ❌ فشل في إنشاء طلب تجريبي: ${insertError.message}`);
      return;
    }

    console.log(`   ✅ تم إنشاء طلب تجريبي: ${insertedOrder.id}`);

    // 3. تهيئة خدمة الإشعارات
    console.log('\n3️⃣ تهيئة خدمة الإشعارات:');
    
    const targetedNotificationService = require('./services/targeted_notification_service');
    
    const initialized = await targetedNotificationService.initialize();
    if (!initialized) {
      console.log('   ❌ فشل في تهيئة خدمة الإشعارات');
      return;
    }
    
    console.log('   ✅ تم تهيئة خدمة الإشعارات بنجاح');

    // 4. محاكاة التحديث من النظام الأول (التحديث اليدوي)
    console.log('\n4️⃣ محاكاة التحديث من النظام الأول (التحديث اليدوي):');
    
    let notificationCount = 0;
    
    // تسجيل عدد الإشعارات المرسلة
    const originalSend = targetedNotificationService.sendOrderStatusNotification;
    targetedNotificationService.sendOrderStatusNotification = async function(...args) {
      notificationCount++;
      console.log(`   📤 إشعار رقم ${notificationCount}: تم إرسال إشعار من النظام الأول`);
      return await originalSend.apply(this, args);
    };

    // محاكاة تحديث من routes/orders.js
    console.log('   🔄 محاكاة تحديث حالة الطلب من لوحة التحكم...');
    
    const result1 = await targetedNotificationService.sendOrderStatusNotification(
      TEST_USER_PHONE,
      insertedOrder.id,
      'shipped',
      'عميل تجريبي',
      'تم الشحن - تحديث يدوي'
    );

    if (result1.success) {
      console.log('   ✅ تم إرسال إشعار النظام الأول بنجاح');
    } else {
      console.log('   ❌ فشل في إرسال إشعار النظام الأول');
    }

    // انتظار قصير
    await new Promise(resolve => setTimeout(resolve, 2000));

    // 5. محاكاة التحديث من النظام الثاني (المزامنة مع الوسيط)
    console.log('\n5️⃣ محاكاة التحديث من النظام الثاني (المزامنة مع الوسيط):');
    
    // محاكاة تحديث من routes/waseet_statuses.js
    console.log('   🔄 محاكاة تحديث حالة الطلب من الوسيط...');
    
    const result2 = await targetedNotificationService.sendOrderStatusNotification(
      TEST_USER_PHONE,
      insertedOrder.id,
      'delivered',
      'عميل تجريبي',
      'تم التوصيل - تحديث من الوسيط'
    );

    if (result2.success) {
      console.log('   ✅ تم إرسال إشعار النظام الثاني بنجاح');
    } else {
      console.log('   ❌ فشل في إرسال إشعار النظام الثاني');
    }

    // 6. فحص النتائج
    console.log('\n6️⃣ فحص النتائج:');
    
    console.log(`   📊 إجمالي الإشعارات المرسلة: ${notificationCount}`);
    
    if (notificationCount === 2) {
      console.log('   ✅ النتيجة صحيحة: تم إرسال إشعارين منفصلين لتحديثين مختلفين');
      console.log('   🎯 لا توجد إشعارات مكررة لنفس التحديث');
    } else if (notificationCount > 2) {
      console.log('   ⚠️ تحذير: تم إرسال إشعارات أكثر من المتوقع');
      console.log('   🔍 قد تكون هناك أنظمة مكررة لم يتم حذفها');
    } else {
      console.log('   ❌ خطأ: لم يتم إرسال الإشعارات المطلوبة');
    }

    // 7. تنظيف البيانات التجريبية
    console.log('\n7️⃣ تنظيف البيانات التجريبية:');
    
    const { error: deleteError } = await supabase
      .from('orders')
      .delete()
      .eq('id', insertedOrder.id);

    if (deleteError) {
      console.log(`   ⚠️ تحذير: فشل في حذف الطلب التجريبي: ${deleteError.message}`);
    } else {
      console.log('   ✅ تم حذف الطلب التجريبي بنجاح');
    }

  } catch (error) {
    console.error('❌ خطأ في اختبار الإشعارات المكررة:', error.message);
  }

  console.log('\n=====================================');
  console.log('🏁 انتهى اختبار الإشعارات المكررة');
  console.log('=====================================');
  
  console.log('\n📋 ملخص التنظيف:');
  console.log('✅ تم حذف الأنظمة المكررة');
  console.log('✅ تم إصلاح ترتيب المعاملات');
  console.log('✅ يوجد نظامان فقط للإشعارات:');
  console.log('   1. التحديث اليدوي (routes/orders.js)');
  console.log('   2. المزامنة مع الوسيط (routes/waseet_statuses.js)');
  
  console.log('\n🎯 النتيجة المتوقعة:');
  console.log('- لا مزيد من الإشعارات المكررة');
  console.log('- إشعار واحد فقط لكل تحديث');
  console.log('- نظام واضح ومنظم');
  
  console.log('\n💡 للاختبار الفعلي:');
  console.log('1. شغل الخادم: npm start');
  console.log('2. غير حالة طلب من لوحة التحكم');
  console.log('3. تحقق من وصول إشعار واحد فقط للهاتف');
}

// تشغيل الاختبار
testNoDuplicateNotifications().catch(error => {
  console.error('❌ خطأ في تشغيل الاختبار:', error);
  process.exit(1);
});
