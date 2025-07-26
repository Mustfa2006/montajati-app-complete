const axios = require('axios');

async function fixOrdersRoute() {
  console.log('🔧 === إصلاح مسار الطلبات ===\n');
  
  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // إنشاء طلب اختبار جديد
    console.log('🧪 إنشاء طلب اختبار جديد...');
    
    const testOrderData = {
      customer_name: 'اختبار إصلاح النظام',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - اختبار إصلاح',
      province: 'بغداد',
      city: 'الكرخ',
      subtotal: 25000,
      delivery_fee: 5000,
      total: 30000,
      profit: 5000,
      profit_amount: 5000,
      status: 'active',
      user_id: 'bba1fc61-3db9-4c5f-8b19-d8689251990d',
      user_phone: '07503597589',
      order_number: `ORD-FIXTEST-${Date.now()}`,
      notes: 'اختبار إصلاح النظام'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, testOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (createResponse.data.success) {
      const testOrderId = createResponse.data.data.id;
      console.log(`✅ تم إنشاء طلب اختبار: ${testOrderId}`);
      
      // انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // تحديث الحالة
      console.log('📤 تحديث حالة طلب الاختبار...');
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار إصلاح النظام',
        changedBy: 'fix_test'
      };
      
      const updateResponse = await axios.put(
        `${baseURL}/api/orders/${testOrderId}/status`,
        updateData,
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 60000,
          validateStatus: () => true // قبول جميع الاستجابات
        }
      );
      
      console.log(`📥 نتيجة تحديث الحالة:`);
      console.log(`   Status: ${updateResponse.status}`);
      console.log(`   Success: ${updateResponse.data?.success}`);
      console.log(`   Message: ${updateResponse.data?.message}`);
      console.log(`   Data:`, updateResponse.data?.data);
      
      if (updateResponse.status === 200 && updateResponse.data?.success) {
        console.log('✅ تم تحديث الحالة بنجاح');
        
        // فحص النتيجة بعد 10 ثوان
        console.log('\n⏳ انتظار 10 ثوان ثم فحص النتيجة...');
        await new Promise(resolve => setTimeout(resolve, 10000));
        
        const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
        const testOrder = ordersResponse.data.data.find(o => o.id === testOrderId);
        
        if (testOrder) {
          console.log(`📋 نتيجة طلب الاختبار:`);
          console.log(`   📊 الحالة: ${testOrder.status}`);
          console.log(`   🆔 معرف الوسيط: ${testOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`   📦 حالة الوسيط: ${testOrder.waseet_status || 'غير محدد'}`);
          
          if (testOrder.waseet_order_id && testOrder.waseet_order_id !== 'null') {
            console.log(`🎉 نجح! النظام يعمل - QR ID: ${testOrder.waseet_order_id}`);
            console.log(`✅ المشكلة تم حلها!`);
          } else {
            console.log(`❌ لا يزال هناك مشكلة - لم يتم الحصول على معرف الوسيط`);
            
            if (testOrder.waseet_data) {
              try {
                const waseetData = JSON.parse(testOrder.waseet_data);
                console.log(`🔍 بيانات الوسيط:`, waseetData);
              } catch (e) {
                console.log(`🔍 بيانات الوسيط (خام): ${testOrder.waseet_data}`);
              }
            }
            
            // محاولة إرسال يدوي
            console.log(`🔧 محاولة إرسال يدوي...`);
            
            try {
              const manualSendResponse = await axios.post(
                `${baseURL}/api/orders/${testOrderId}/send-to-waseet`, 
                {}, 
                { 
                  timeout: 60000,
                  validateStatus: () => true 
                }
              );
              
              if (manualSendResponse.data?.success) {
                console.log(`✅ الإرسال اليدوي نجح - QR ID: ${manualSendResponse.data.data?.qrId}`);
                console.log(`🎉 المشكلة تم حلها بالإرسال اليدوي!`);
              } else {
                console.log(`❌ الإرسال اليدوي فشل: ${manualSendResponse.data?.message}`);
              }
              
            } catch (error) {
              console.log(`❌ خطأ في الإرسال اليدوي: ${error.message}`);
            }
          }
        }
        
      } else {
        console.log('❌ فشل في تحديث الحالة');
        console.log('🔍 تفاصيل الخطأ:', updateResponse.data);
        
        if (updateResponse.status === 500) {
          console.log('💡 خطأ 500 - مشكلة في الخادم');
        }
      }
      
    } else {
      console.log('❌ فشل في إنشاء طلب الاختبار');
    }
    
    // فحص جميع الطلبات المشكلة
    console.log('\n🔍 === فحص جميع الطلبات المشكلة ===');
    
    const allOrdersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const allOrders = allOrdersResponse.data.data;
    
    const problemOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      (!order.waseet_order_id || order.waseet_order_id === 'null')
    );
    
    console.log(`❌ طلبات مشكلة: ${problemOrders.length}`);
    
    if (problemOrders.length > 0) {
      console.log('\n🔧 إصلاح الطلبات المشكلة...');
      
      for (let i = 0; i < Math.min(problemOrders.length, 3); i++) {
        const order = problemOrders[i];
        console.log(`\n${i + 1}. إصلاح الطلب: ${order.id}`);
        
        try {
          const manualSendResponse = await axios.post(
            `${baseURL}/api/orders/${order.id}/send-to-waseet`, 
            {}, 
            { 
              timeout: 60000,
              validateStatus: () => true 
            }
          );
          
          if (manualSendResponse.data?.success) {
            console.log(`   ✅ تم إصلاح الطلب - QR ID: ${manualSendResponse.data.data?.qrId}`);
          } else {
            console.log(`   ❌ فشل الإصلاح: ${manualSendResponse.data?.message}`);
          }
          
        } catch (error) {
          console.log(`   ❌ خطأ في الإصلاح: ${error.message}`);
        }
        
        // انتظار قصير بين الطلبات
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }
    
    // خلاصة نهائية
    console.log('\n📊 === خلاصة نهائية ===');
    
    const finalOrdersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const finalOrders = finalOrdersResponse.data.data;
    
    const deliveryOrders = finalOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    const successfulOrders = deliveryOrders.filter(order => 
      order.waseet_order_id && order.waseet_order_id !== 'null'
    );
    
    const failedOrders = deliveryOrders.filter(order => 
      !order.waseet_order_id || order.waseet_order_id === 'null'
    );
    
    console.log(`📦 إجمالي طلبات التوصيل: ${deliveryOrders.length}`);
    console.log(`✅ تم إرسالها بنجاح: ${successfulOrders.length}`);
    console.log(`❌ لم يتم إرسالها: ${failedOrders.length}`);
    
    const successRate = deliveryOrders.length > 0 ? 
      Math.round((successfulOrders.length / deliveryOrders.length) * 100) : 0;
    
    console.log(`📊 معدل النجاح: ${successRate}%`);
    
    if (failedOrders.length === 0) {
      console.log('\n🎉 === جميع الطلبات تعمل بشكل مثالي! ===');
      console.log('✅ النظام تم إصلاحه بنجاح');
      console.log('📱 يمكنك الآن إنشاء طلبات جديدة وتغيير حالتها بثقة');
    } else {
      console.log(`\n⚠️ === يوجد ${failedOrders.length} طلب لا يزال يحتاج إصلاح ===`);
      console.log('🔧 تم محاولة إصلاحها تلقائياً');
      console.log('📱 تحقق من التطبيق لرؤية النتائج');
    }
    
  } catch (error) {
    console.error('❌ خطأ في إصلاح مسار الطلبات:', error.message);
  }
}

fixOrdersRoute();
