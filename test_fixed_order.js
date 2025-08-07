const axios = require('axios');

async function testFixedOrder() {
  console.log('🧪 اختبار المزامنة على الطلب المثبت');
  console.log('المستخدم: 07503597589');
  console.log('='.repeat(50));

  const baseURL = 'https://clownfish-app-krnk9.ondigitalocean.app';
  const testUserPhone = '07503597589';

  try {
    // 1. البحث عن طلبات المستخدم
    console.log('\n1️⃣ البحث عن طلبات المستخدم...');
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });

    const allOrders = ordersResponse.data.data || [];
    console.log(`📊 إجمالي الطلبات: ${allOrders.length}`);

    // البحث عن طلبات المستخدم
    const userOrders = allOrders.filter(order => 
      order.user_phone === testUserPhone || 
      order.primary_phone === testUserPhone ||
      order.customer_phone === testUserPhone
    );

    console.log(`👤 طلبات المستخدم: ${userOrders.length}`);

    if (userOrders.length === 0) {
      console.log('❌ لا توجد طلبات لهذا المستخدم');
      return;
    }

    // 2. عرض آخر طلب (الطلب المثبت)
    const latestOrder = userOrders.sort((a, b) => 
      new Date(b.created_at) - new Date(a.created_at)
    )[0];

    console.log('\n2️⃣ الطلب المثبت (الأحدث):');
    console.log(`🆔 ID: ${latestOrder.id}`);
    console.log(`📋 رقم الطلب: ${latestOrder.order_number || 'غير محدد'}`);
    console.log(`👤 اسم العميل: ${latestOrder.customer_name}`);
    console.log(`📞 رقم الهاتف: ${latestOrder.primary_phone || latestOrder.customer_phone}`);
    console.log(`📊 الحالة الحالية: "${latestOrder.status}"`);
    console.log(`🚛 معرف الوسيط: ${latestOrder.waseet_order_id || 'لم يرسل بعد'}`);
    console.log(`📈 حالة الوسيط: "${latestOrder.waseet_status_text || 'غير محدد'}"`);
    console.log(`🆔 معرف حالة الوسيط: ${latestOrder.waseet_status_id || 'غير محدد'}`);
    console.log(`🕐 تاريخ الإنشاء: ${new Date(latestOrder.created_at).toLocaleString('ar-IQ')}`);

    // 3. إذا لم يرسل للوسيط، أرسله أولاً
    let testOrder = latestOrder;
    
    if (!testOrder.waseet_order_id) {
      console.log('\n3️⃣ الطلب لم يرسل للوسيط - سأرسله الآن...');
      
      const updateResult = await axios.put(`${baseURL}/api/orders/${testOrder.id}/status`, {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار المزامنة - إرسال للوسيط'
      }, {
        timeout: 30000
      });

      if (updateResult.data.success) {
        console.log('✅ تم تحديث الحالة وإرسال الطلب للوسيط');
        
        // انتظار 10 ثواني للمعالجة
        console.log('⏳ انتظار 10 ثواني للمعالجة...');
        await new Promise(resolve => setTimeout(resolve, 10000));
        
        // جلب البيانات المحدثة
        const updatedResponse = await axios.get(`${baseURL}/api/orders/${testOrder.id}`, {
          timeout: 15000
        });
        
        testOrder = updatedResponse.data.data;
        console.log(`🆔 معرف الوسيط الجديد: ${testOrder.waseet_order_id || 'لم يتم الإرسال بعد'}`);
      } else {
        console.log('❌ فشل في إرسال الطلب للوسيط');
        console.log('📋 الخطأ:', updateResult.data.error);
      }
    }

    // 4. محاكاة تغيير حالة في الوسيط
    console.log('\n4️⃣ اختبار المزامنة...');
    console.log('📝 ملاحظة: في الوسيط الحقيقي، يجب تغيير حالة الطلب يدوياً');
    console.log(`🔍 الطلب الحالي في الوسيط: ${testOrder.waseet_order_id || 'غير مرسل'}`);

    if (testOrder.waseet_order_id) {
      console.log('\n📋 الحالات المتوقعة في الوسيط:');
      console.log('   ID: 4 = "تم التسليم للزبون"');
      console.log('   ID: 25 = "لا يرد"');
      console.log('   ID: 27 = "مغلق"');
      console.log('   ID: 31 = "الغاء الطلب"');
      
      console.log('\n💡 لاختبار المزامنة:');
      console.log('1. اذهب لموقع الوسيط');
      console.log(`2. ابحث عن الطلب: ${testOrder.waseet_order_id}`);
      console.log('3. غير حالة الطلب إلى "تم التسليم للزبون"');
      console.log('4. انتظر 5 دقائق للمزامنة التلقائية');
      console.log('5. أو شغل المزامنة الفورية أدناه');
    }

    // 5. تشغيل المزامنة الفورية
    console.log('\n5️⃣ تشغيل المزامنة الفورية...');
    
    try {
      const syncResponse = await axios.post(`${baseURL}/api/orders/force-waseet-sync`, {}, {
        timeout: 60000
      });

      if (syncResponse.data.success) {
        console.log('✅ تم تشغيل المزامنة الفورية بنجاح');
        console.log('📊 إحصائيات المزامنة:');
        console.log(`   المزامنات الناجحة: ${syncResponse.data.data?.successfulSyncs || 0}`);
        console.log(`   الطلبات المحدثة: ${syncResponse.data.data?.ordersUpdated || 0}`);
        console.log(`   وقت التنفيذ: ${syncResponse.data.duration || 0}ms`);
      } else {
        console.log('❌ فشل في تشغيل المزامنة الفورية');
        console.log('📋 الخطأ:', syncResponse.data.error);
      }
    } catch (syncError) {
      console.log('⚠️ خطأ في تشغيل المزامنة الفورية:', syncError.message);
    }

    // 6. فحص النتائج بعد المزامنة
    console.log('\n6️⃣ فحص النتائج بعد المزامنة...');
    console.log('⏳ انتظار 5 ثواني...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    const finalResponse = await axios.get(`${baseURL}/api/orders/${testOrder.id}`, {
      timeout: 15000
    });

    const finalOrder = finalResponse.data.data;
    
    console.log('\n📊 حالة الطلب بعد المزامنة:');
    console.log(`   📈 الحالة: "${finalOrder.status}"`);
    console.log(`   🚛 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`   📋 حالة الوسيط: "${finalOrder.waseet_status_text || 'غير محدد'}"`);
    console.log(`   🆔 معرف حالة الوسيط: ${finalOrder.waseet_status_id || 'غير محدد'}`);
    console.log(`   🕐 آخر تحديث: ${new Date(finalOrder.updated_at).toLocaleString('ar-IQ')}`);

    // 7. مقارنة النتائج
    console.log('\n7️⃣ مقارنة النتائج:');
    
    if (testOrder.status !== finalOrder.status) {
      console.log(`🔄 تغيرت الحالة: "${testOrder.status}" → "${finalOrder.status}"`);
      console.log('✅ المزامنة تعمل بشكل صحيح!');
      
      if (finalOrder.status === 'تم التسليم للزبون') {
        console.log('🎉 تم حل مشكلة المزامنة! الحالة تظهر بشكل صحيح.');
      }
    } else {
      console.log('📝 لم تتغير الحالة');
      console.log('💡 هذا طبيعي إذا لم تتغير الحالة في الوسيط');
    }

    if (testOrder.waseet_status_text !== finalOrder.waseet_status_text) {
      console.log(`📋 تغيرت حالة الوسيط: "${testOrder.waseet_status_text}" → "${finalOrder.waseet_status_text}"`);
    }

    console.log('\n🎯 خلاصة الاختبار:');
    console.log(`   الطلب المختبر: ${finalOrder.id}`);
    console.log(`   المستخدم: ${testUserPhone}`);
    console.log(`   معرف الوسيط: ${finalOrder.waseet_order_id || 'غير مرسل'}`);
    console.log(`   الحالة النهائية: "${finalOrder.status}"`);
    
    console.log('\n✅ انتهى الاختبار!');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
    if (error.response) {
      console.error('📋 تفاصيل الخطأ:', error.response.data);
    }
  }
}

testFixedOrder();
