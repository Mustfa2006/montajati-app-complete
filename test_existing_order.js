const axios = require('axios');

async function testExistingOrder() {
  console.log('🔍 === اختبار طلب موجود فعلاً ===\n');
  console.log('🎯 الهدف: اختبار النظام مع طلب موجود مسبقاً\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. جلب آخر الطلبات
    console.log('1️⃣ === جلب آخر الطلبات ===');
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const allOrders = ordersResponse.data.data;
    
    console.log(`📊 إجمالي الطلبات: ${allOrders.length}`);
    
    // البحث عن طلب مناسب للاختبار
    const testableOrder = allOrders.find(order => 
      order.status !== 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      order.status !== 'تم التسليم للزبون' &&
      order.status !== 'ملغي' &&
      (!order.waseet_order_id || order.waseet_order_id === 'null')
    );
    
    if (!testableOrder) {
      console.log('⚠️ لم أجد طلب مناسب للاختبار');
      console.log('📋 جميع الطلبات إما في حالة توصيل أو تم إرسالها للوسيط مسبقاً');
      
      // عرض آخر 5 طلبات
      console.log('\n📋 آخر 5 طلبات:');
      allOrders.slice(0, 5).forEach((order, index) => {
        console.log(`${index + 1}. 📦 ${order.id}`);
        console.log(`   👤 العميل: ${order.customer_name}`);
        console.log(`   📊 الحالة: ${order.status}`);
        console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        console.log('');
      });
      
      return;
    }
    
    console.log(`📦 طلب الاختبار: ${testableOrder.id}`);
    console.log(`👤 العميل: ${testableOrder.customer_name}`);
    console.log(`📊 الحالة الحالية: ${testableOrder.status}`);
    console.log(`🆔 معرف الوسيط الحالي: ${testableOrder.waseet_order_id || 'غير محدد'}`);
    
    // 2. تحديث حالة الطلب الموجود
    console.log('\n2️⃣ === تحديث حالة الطلب الموجود ===');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار طلب موجود مسبقاً',
      changedBy: 'existing_order_test'
    };
    
    console.log('📤 إرسال طلب تحديث الحالة...');
    
    const updateStartTime = Date.now();
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${testableOrder.id}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 120000
      }
    );
    
    const updateTime = Date.now() - updateStartTime;
    
    console.log(`📥 استجابة تحديث الحالة (خلال ${updateTime}ms):`);
    console.log(`   Status: ${updateResponse.status}`);
    console.log(`   Success: ${updateResponse.data.success}`);
    console.log(`   Message: ${updateResponse.data.message}`);
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      
      // 3. مراقبة الطلب
      console.log('\n3️⃣ === مراقبة الطلب ===');
      
      const checkIntervals = [2, 5, 10, 15, 30];
      
      for (const seconds of checkIntervals) {
        console.log(`\n⏳ فحص بعد ${seconds} ثانية...`);
        await new Promise(resolve => setTimeout(resolve, seconds * 1000));
        
        try {
          const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
          const currentOrder = ordersResponse.data.data.find(o => o.id === testableOrder.id);
          
          if (currentOrder) {
            console.log(`📋 حالة الطلب:`);
            console.log(`   📊 الحالة: ${currentOrder.status}`);
            console.log(`   🆔 معرف الوسيط: ${currentOrder.waseet_order_id || 'غير محدد'}`);
            console.log(`   📦 حالة الوسيط: ${currentOrder.waseet_status || 'غير محدد'}`);
            
            if (currentOrder.waseet_order_id && currentOrder.waseet_order_id !== 'null') {
              console.log(`🎉 نجح! تم إرسال الطلب للوسيط - QR ID: ${currentOrder.waseet_order_id}`);
              break;
            } else if (currentOrder.waseet_status === 'pending') {
              console.log(`⏳ الطلب في حالة pending - لا يزال قيد المعالجة`);
            } else if (currentOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
              console.log(`❌ فشل في إرسال الطلب للوسيط`);
              
              // فحص سبب الفشل
              if (currentOrder.waseet_data) {
                try {
                  const waseetData = JSON.parse(currentOrder.waseet_data);
                  console.log(`🔍 سبب الفشل:`, waseetData.error);
                } catch (e) {
                  console.log(`🔍 بيانات الفشل:`, currentOrder.waseet_data);
                }
              }
              break;
            } else if (!currentOrder.waseet_status) {
              console.log(`❓ لم يتم محاولة إرسال الطلب للوسيط أصلاً`);
            }
          }
          
        } catch (error) {
          console.log(`❌ خطأ في فحص الطلب: ${error.message}`);
        }
      }
      
    } else {
      console.log('❌ فشل في تحديث الحالة');
    }
    
    // 4. فحص الطلبات التي لم تصل للوسيط
    console.log('\n4️⃣ === فحص الطلبات التي لم تصل للوسيط ===');
    
    const deliveryOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    const withoutWaseet = deliveryOrders.filter(order => 
      !order.waseet_order_id || order.waseet_order_id === 'null'
    );
    
    console.log(`📊 طلبات في حالة توصيل: ${deliveryOrders.length}`);
    console.log(`❌ طلبات بدون معرف وسيط: ${withoutWaseet.length}`);
    
    if (withoutWaseet.length > 0) {
      console.log('\n⚠️ طلبات لم تصل للوسيط:');
      withoutWaseet.slice(0, 5).forEach(order => {
        console.log(`   📦 ${order.id} - ${order.customer_name}`);
        console.log(`      📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        console.log(`      🕐 آخر تحديث: ${order.updated_at}`);
        
        // فحص سبب عدم الوصول
        if (order.waseet_data) {
          try {
            const waseetData = JSON.parse(order.waseet_data);
            if (waseetData.error) {
              console.log(`      🔍 سبب الفشل: ${waseetData.error}`);
            }
          } catch (e) {
            // تجاهل أخطاء التحليل
          }
        }
      });
      
      // محاولة إصلاح الطلبات العالقة
      console.log('\n🔧 محاولة إصلاح الطلبات العالقة...');
      
      for (const order of withoutWaseet.slice(0, 3)) {
        console.log(`\n🔧 إصلاح الطلب: ${order.id}`);
        
        try {
          const fixResponse = await axios.post(`${baseURL}/api/orders/${order.id}/send-to-waseet`, {}, {
            timeout: 30000,
            validateStatus: () => true
          });
          
          if (fixResponse.data?.success) {
            console.log(`   ✅ تم إصلاح الطلب - QR ID: ${fixResponse.data.data?.qrId}`);
          } else {
            console.log(`   ❌ فشل في إصلاح الطلب: ${fixResponse.data?.error}`);
          }
        } catch (error) {
          console.log(`   ❌ خطأ في إصلاح الطلب: ${error.message}`);
        }
      }
    } else {
      console.log('✅ جميع الطلبات في حالة التوصيل تم إرسالها للوسيط بنجاح');
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار الطلب الموجود:', error.message);
  }
}

testExistingOrder();
