const axios = require('axios');

async function testExactStatusSync() {
  console.log('🎯 اختبار المزامنة الدقيقة للحالات');
  console.log('الهدف: التأكد من عرض نفس الحالة من الوسيط في التطبيق');
  console.log('='.repeat(70));

  const baseURL = 'https://clownfish-app-krnk9.ondigitalocean.app';
  const testOrderId = 'order_1754573207829_6456';
  const waseetOrderId = '97458931';

  try {
    // 1. فحص الحالة الحالية
    console.log('\n1️⃣ فحص الحالة الحالية في قاعدة البيانات...');
    
    const currentResponse = await axios.get(`${baseURL}/api/orders/${testOrderId}`, {
      timeout: 15000
    });

    const currentOrder = currentResponse.data.data;
    console.log(`📊 الحالة في قاعدة البيانات: "${currentOrder.status}"`);
    console.log(`🚛 معرف الوسيط: ${currentOrder.waseet_order_id}`);
    console.log(`📋 حالة الوسيط المحفوظة: "${currentOrder.waseet_status_text || 'غير محدد'}"`);
    console.log(`🆔 معرف حالة الوسيط: ${currentOrder.waseet_status_id || 'غير محدد'}`);

    // 2. تشغيل المزامنة الفورية
    console.log('\n2️⃣ تشغيل المزامنة الفورية...');
    
    try {
      const syncResponse = await axios.post(`${baseURL}/api/orders/force-waseet-sync`, {}, {
        timeout: 60000
      });

      if (syncResponse.data.success) {
        console.log('✅ تم تشغيل المزامنة الفورية بنجاح');
        console.log(`⏱️ وقت التنفيذ: ${syncResponse.data.duration || 0}ms`);
        
        if (syncResponse.data.stats) {
          console.log(`📊 الطلبات المحدثة: ${syncResponse.data.stats.ordersUpdated}`);
        }
      } else {
        console.log('❌ فشل في تشغيل المزامنة الفورية');
        console.log('📋 الخطأ:', syncResponse.data.error);
      }
    } catch (syncError) {
      console.log('⚠️ خطأ في تشغيل المزامنة الفورية:', syncError.message);
    }

    // 3. فحص النتائج بعد المزامنة
    console.log('\n3️⃣ فحص النتائج بعد المزامنة...');
    console.log('⏳ انتظار 5 ثواني...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    const finalResponse = await axios.get(`${baseURL}/api/orders/${testOrderId}`, {
      timeout: 15000
    });

    const finalOrder = finalResponse.data.data;
    
    console.log('\n📊 حالة الطلب بعد المزامنة:');
    console.log(`   📈 الحالة في قاعدة البيانات: "${finalOrder.status}"`);
    console.log(`   🚛 معرف الوسيط: ${finalOrder.waseet_order_id}`);
    console.log(`   📋 حالة الوسيط: "${finalOrder.waseet_status_text || 'غير محدد'}"`);
    console.log(`   🆔 معرف حالة الوسيط: ${finalOrder.waseet_status_id || 'غير محدد'}`);
    console.log(`   🕐 آخر تحديث: ${new Date(finalOrder.updated_at).toLocaleString('ar-IQ')}`);

    // 4. تحليل دقة المزامنة
    console.log('\n4️⃣ تحليل دقة المزامنة:');
    
    const statusChanged = currentOrder.status !== finalOrder.status;
    const waseetStatusChanged = currentOrder.waseet_status_text !== finalOrder.waseet_status_text;

    if (statusChanged) {
      console.log(`🔄 تغيرت الحالة: "${currentOrder.status}" → "${finalOrder.status}"`);
      
      // التحقق من أن الحالة الجديدة هي نفس حالة الوسيط
      if (finalOrder.status === finalOrder.waseet_status_text) {
        console.log('✅ ممتاز! الحالة في قاعدة البيانات تطابق حالة الوسيط بالضبط');
        console.log(`   الحالة الموحدة: "${finalOrder.status}"`);
      } else {
        console.log('⚠️ تحذير: الحالة في قاعدة البيانات لا تطابق حالة الوسيط');
        console.log(`   حالة قاعدة البيانات: "${finalOrder.status}"`);
        console.log(`   حالة الوسيط: "${finalOrder.waseet_status_text}"`);
      }
    } else {
      console.log('📝 لم تتغير الحالة');
    }

    if (waseetStatusChanged) {
      console.log(`📋 تغيرت حالة الوسيط: "${currentOrder.waseet_status_text}" → "${finalOrder.waseet_status_text}"`);
    }

    // 5. اختبار الحالات المختلفة
    console.log('\n5️⃣ اختبار الحالات المدعومة:');
    console.log('📋 الحالات التي يجب أن تظهر بالضبط كما هي من الوسيط:');
    
    const exactStatuses = [
      'تم التسليم للزبون',
      'لا يرد',
      'مغلق',
      'الغاء الطلب',
      'رفض الطلب',
      'تم الارجاع الى التاجر',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'تم تغيير محافظة الزبون',
      'لا يرد بعد الاتفاق',
      'مغلق بعد الاتفاق',
      'مؤجل',
      'مؤجل لحين اعادة الطلب لاحقا',
      'مستلم مسبقا',
      'الرقم غير معرف',
      'الرقم غير داخل في الخدمة',
      'العنوان غير دقيق',
      'لم يطلب',
      'حظر المندوب',
      'لا يمكن الاتصال بالرقم',
      'تغيير المندوب'
    ];

    exactStatuses.forEach((status, index) => {
      console.log(`   ${index + 1}. "${status}"`);
    });

    // 6. التحقق من الإصلاح
    console.log('\n6️⃣ التحقق من نجاح الإصلاح:');
    
    if (finalOrder.status && finalOrder.waseet_status_text) {
      if (finalOrder.status === finalOrder.waseet_status_text) {
        console.log('🎉 نجح الإصلاح! الحالة في التطبيق تطابق حالة الوسيط بالضبط');
        console.log(`✅ الحالة الموحدة: "${finalOrder.status}"`);
      } else {
        console.log('⚠️ الإصلاح يحتاج مراجعة');
        console.log(`   التطبيق يعرض: "${finalOrder.status}"`);
        console.log(`   الوسيط يعرض: "${finalOrder.waseet_status_text}"`);
      }
    } else {
      console.log('📝 لا توجد بيانات كافية للمقارنة');
    }

    // 7. التوصيات
    console.log('\n7️⃣ التوصيات للاختبار الكامل:');
    console.log('💡 لاختبار الإصلاح بشكل كامل:');
    console.log(`1. اذهب لموقع الوسيط: https://alwaseet-iq.net`);
    console.log(`2. ابحث عن الطلب: ${waseetOrderId}`);
    console.log('3. غير حالة الطلب إلى "تم التسليم للزبون"');
    console.log('4. انتظر 5 دقائق للمزامنة التلقائية');
    console.log('5. تحقق من أن التطبيق يعرض "تم التسليم للزبون" بالضبط');
    console.log('6. جرب حالات أخرى مثل "لا يرد" أو "مغلق"');

    console.log('\n🎯 خلاصة الاختبار:');
    console.log(`   الطلب: ${testOrderId}`);
    console.log(`   معرف الوسيط: ${waseetOrderId}`);
    console.log(`   الحالة في التطبيق: "${finalOrder.status}"`);
    console.log(`   الحالة في الوسيط: "${finalOrder.waseet_status_text || 'غير محدد'}"`);
    console.log(`   التطابق: ${finalOrder.status === finalOrder.waseet_status_text ? 'نعم ✅' : 'لا ❌'}`);
    
    console.log('\n✅ انتهى اختبار المزامنة الدقيقة!');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
    if (error.response) {
      console.error('📋 تفاصيل الخطأ:', error.response.data);
    }
  }
}

testExactStatusSync();
