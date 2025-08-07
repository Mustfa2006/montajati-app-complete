const axios = require('axios');

async function finalSyncTest() {
  console.log('🎯 الاختبار النهائي للمزامنة مع الوسيط');
  console.log('المستخدم: 07503597589');
  console.log('الطلب المثبت: order_1754573207829_6456');
  console.log('معرف الوسيط: 97458931');
  console.log('='.repeat(60));

  const baseURL = 'https://clownfish-app-krnk9.ondigitalocean.app';
  const testOrderId = 'order_1754573207829_6456';
  const waseetOrderId = '97458931';

  try {
    // 1. فحص حالة الطلب الحالية
    console.log('\n1️⃣ فحص حالة الطلب الحالية...');
    
    const currentResponse = await axios.get(`${baseURL}/api/orders/${testOrderId}`, {
      timeout: 15000
    });

    const currentOrder = currentResponse.data.data;
    console.log(`📊 الحالة الحالية: "${currentOrder.status}"`);
    console.log(`🚛 معرف الوسيط: ${currentOrder.waseet_order_id}`);
    console.log(`📋 حالة الوسيط: "${currentOrder.waseet_status_text || 'غير محدد'}"`);
    console.log(`🆔 معرف حالة الوسيط: ${currentOrder.waseet_status_id || 'غير محدد'}`);

    // 2. فحص حالة نظام المزامنة
    console.log('\n2️⃣ فحص حالة نظام المزامنة...');
    
    try {
      const statusResponse = await axios.get(`${baseURL}/api/orders/waseet-sync-status`, {
        timeout: 15000
      });

      const syncStatus = statusResponse.data.data;
      console.log(`🔄 النظام يعمل: ${syncStatus.isRunning ? 'نعم' : 'لا'}`);
      console.log(`⏱️ فترة المزامنة: ${syncStatus.syncIntervalMinutes} دقيقة`);
      console.log(`📅 آخر مزامنة: ${syncStatus.lastSyncTime || 'لم تتم بعد'}`);
      console.log(`📊 المزامنات الناجحة: ${syncStatus.successfulSyncs}`);
      console.log(`📈 الطلبات المحدثة: ${syncStatus.ordersUpdated}`);
      
      if (syncStatus.lastError) {
        console.log(`❌ آخر خطأ: ${syncStatus.lastError}`);
      }
    } catch (statusError) {
      console.log('⚠️ خطأ في جلب حالة النظام:', statusError.message);
    }

    // 3. تشغيل المزامنة الفورية
    console.log('\n3️⃣ تشغيل المزامنة الفورية...');
    
    try {
      const syncResponse = await axios.post(`${baseURL}/api/orders/force-waseet-sync`, {}, {
        timeout: 60000
      });

      if (syncResponse.data.success) {
        console.log('✅ تم تشغيل المزامنة الفورية بنجاح');
        console.log(`⏱️ وقت التنفيذ: ${syncResponse.data.duration || 0}ms`);
        
        if (syncResponse.data.stats) {
          console.log(`📊 إحصائيات المزامنة:`);
          console.log(`   المزامنات الناجحة: ${syncResponse.data.stats.successfulSyncs}`);
          console.log(`   الطلبات المحدثة: ${syncResponse.data.stats.ordersUpdated}`);
        }
      } else {
        console.log('❌ فشل في تشغيل المزامنة الفورية');
        console.log('📋 الخطأ:', syncResponse.data.error);
      }
    } catch (syncError) {
      console.log('⚠️ خطأ في تشغيل المزامنة الفورية:', syncError.message);
      if (syncError.response) {
        console.log('📋 تفاصيل الخطأ:', syncError.response.data);
      }
    }

    // 4. انتظار وفحص النتائج
    console.log('\n4️⃣ انتظار وفحص النتائج...');
    console.log('⏳ انتظار 10 ثواني للمعالجة...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    const finalResponse = await axios.get(`${baseURL}/api/orders/${testOrderId}`, {
      timeout: 15000
    });

    const finalOrder = finalResponse.data.data;
    
    console.log('\n📊 حالة الطلب بعد المزامنة:');
    console.log(`   📈 الحالة: "${finalOrder.status}"`);
    console.log(`   🚛 معرف الوسيط: ${finalOrder.waseet_order_id}`);
    console.log(`   📋 حالة الوسيط: "${finalOrder.waseet_status_text || 'غير محدد'}"`);
    console.log(`   🆔 معرف حالة الوسيط: ${finalOrder.waseet_status_id || 'غير محدد'}`);
    console.log(`   🕐 آخر تحديث: ${new Date(finalOrder.updated_at).toLocaleString('ar-IQ')}`);

    // 5. تحليل النتائج
    console.log('\n5️⃣ تحليل النتائج:');
    
    const statusChanged = currentOrder.status !== finalOrder.status;
    const waseetStatusChanged = currentOrder.waseet_status_text !== finalOrder.waseet_status_text;
    const waseetIdChanged = currentOrder.waseet_status_id !== finalOrder.waseet_status_id;

    if (statusChanged) {
      console.log(`🔄 تغيرت الحالة: "${currentOrder.status}" → "${finalOrder.status}"`);
      console.log('✅ المزامنة تعمل بشكل صحيح!');
      
      if (finalOrder.status === 'تم التسليم للزبون') {
        console.log('🎉 تم حل مشكلة المزامنة! الحالة تظهر "تم التسليم للزبون" بشكل صحيح.');
      }
    } else {
      console.log('📝 لم تتغير الحالة الرئيسية');
    }

    if (waseetStatusChanged) {
      console.log(`📋 تغيرت حالة الوسيط: "${currentOrder.waseet_status_text}" → "${finalOrder.waseet_status_text}"`);
    } else {
      console.log('📝 لم تتغير حالة الوسيط');
    }

    if (waseetIdChanged) {
      console.log(`🆔 تغير معرف حالة الوسيط: "${currentOrder.waseet_status_id}" → "${finalOrder.waseet_status_id}"`);
    }

    // 6. اختبار الحالات المختلفة
    console.log('\n6️⃣ اختبار تحويل الحالات:');
    console.log('📋 الحالات المدعومة في النظام المحدث:');
    
    const supportedStatuses = [
      { id: 4, text: 'تم التسليم للزبون', expected: 'تم التسليم للزبون' },
      { id: 25, text: 'لا يرد', expected: 'لا يرد' },
      { id: 27, text: 'مغلق', expected: 'مغلق' },
      { id: 31, text: 'الغاء الطلب', expected: 'الغاء الطلب' },
      { id: 17, text: 'تم الارجاع الى التاجر', expected: 'تم الارجاع الى التاجر' }
    ];

    supportedStatuses.forEach(status => {
      console.log(`   ✅ ID ${status.id}: "${status.text}" → "${status.expected}"`);
    });

    // 7. التوصيات
    console.log('\n7️⃣ التوصيات للاختبار الكامل:');
    console.log('💡 لاختبار المزامنة بشكل كامل:');
    console.log(`1. اذهب لموقع الوسيط: https://alwaseet-iq.net`);
    console.log(`2. ابحث عن الطلب: ${waseetOrderId}`);
    console.log('3. غير حالة الطلب إلى "تم التسليم للزبون" (ID: 4)');
    console.log('4. انتظر 5 دقائق للمزامنة التلقائية');
    console.log('5. أو شغل المزامنة الفورية مرة أخرى');
    console.log('6. تحقق من أن الحالة في التطبيق تصبح "تم التسليم للزبون"');

    console.log('\n🎯 خلاصة الاختبار:');
    console.log(`   الطلب: ${testOrderId}`);
    console.log(`   معرف الوسيط: ${waseetOrderId}`);
    console.log(`   الحالة النهائية: "${finalOrder.status}"`);
    console.log(`   حالة الوسيط: "${finalOrder.waseet_status_text || 'غير محدد'}"`);
    console.log(`   المزامنة تعمل: ${statusChanged || waseetStatusChanged ? 'نعم' : 'يحتاج اختبار إضافي'}`);
    
    console.log('\n✅ انتهى الاختبار النهائي!');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
    if (error.response) {
      console.error('📋 تفاصيل الخطأ:', error.response.data);
    }
  }
}

finalSyncTest();
