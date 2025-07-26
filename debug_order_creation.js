const axios = require('axios');

async function debugOrderCreation() {
  console.log('🔍 === تشخيص مشكلة إنشاء الطلبات ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. فحص endpoint إنشاء الطلبات
    console.log('1️⃣ فحص endpoint إنشاء الطلبات...');
    
    try {
      const testResponse = await axios.get(`${baseURL}/api/orders`, { 
        timeout: 10000,
        validateStatus: () => true 
      });
      console.log(`✅ GET /api/orders يعمل - Status: ${testResponse.status}`);
    } catch (error) {
      console.log(`❌ مشكلة في GET /api/orders: ${error.message}`);
    }
    
    // 2. محاولة إنشاء طلب بسيط جداً
    console.log('\n2️⃣ محاولة إنشاء طلب بسيط جداً...');
    
    const simpleOrderData = {
      customer_name: 'اختبار بسيط',
      primary_phone: '07901234567',
      total: 25000,
      status: 'active'
    };
    
    console.log('📤 إرسال طلب بسيط...');
    console.log('📋 البيانات:', JSON.stringify(simpleOrderData, null, 2));
    
    try {
      const simpleResponse = await axios.post(`${baseURL}/api/orders`, simpleOrderData, {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 30000,
        validateStatus: () => true
      });
      
      console.log(`📥 استجابة الطلب البسيط:`);
      console.log(`📊 Status: ${simpleResponse.status}`);
      console.log(`📋 Response:`, JSON.stringify(simpleResponse.data, null, 2));
      
      if (simpleResponse.data.success) {
        console.log('✅ نجح إنشاء الطلب البسيط');
        const orderId = simpleResponse.data.data.id;
        
        // محاولة تحديث حالة الطلب البسيط
        console.log('\n3️⃣ محاولة تحديث حالة الطلب البسيط...');
        await testOrderUpdate(baseURL, orderId);
        
      } else {
        console.log('❌ فشل إنشاء الطلب البسيط');
        console.log('📋 الخطأ:', simpleResponse.data.error);
      }
      
    } catch (error) {
      console.log(`❌ خطأ في إنشاء الطلب البسيط: ${error.message}`);
      if (error.response) {
        console.log(`📋 Response Status: ${error.response.status}`);
        console.log(`📋 Response Data:`, error.response.data);
      }
    }
    
    // 3. فحص طلب موجود وتحديث حالته
    console.log('\n4️⃣ فحص طلب موجود وتحديث حالته...');
    
    try {
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const existingOrders = ordersResponse.data.data;
      
      // البحث عن طلب ليس في حالة توصيل
      const testOrder = existingOrders.find(order => 
        order.status !== 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
        order.status !== 'تم التسليم للزبون'
      );
      
      if (testOrder) {
        console.log(`📦 وجدت طلب موجود للاختبار: ${testOrder.id}`);
        console.log(`📊 الحالة الحالية: ${testOrder.status}`);
        
        await testOrderUpdate(baseURL, testOrder.id);
        
      } else {
        console.log('⚠️ لم أجد طلب مناسب للاختبار');
        
        // استخدام أي طلب متاح
        if (existingOrders.length > 0) {
          const anyOrder = existingOrders[0];
          console.log(`📦 سأستخدم أي طلب متاح: ${anyOrder.id}`);
          await testOrderUpdate(baseURL, anyOrder.id);
        }
      }
      
    } catch (error) {
      console.log(`❌ خطأ في فحص الطلبات الموجودة: ${error.message}`);
    }
    
  } catch (error) {
    console.error('❌ خطأ عام في التشخيص:', error.message);
  }
}

async function testOrderUpdate(baseURL, orderId) {
  try {
    console.log(`\n🔄 اختبار تحديث الطلب: ${orderId}`);
    
    // فحص الطلب قبل التحديث
    console.log('📋 فحص الطلب قبل التحديث...');
    const beforeUpdate = await getOrderDetails(baseURL, orderId);
    
    if (beforeUpdate) {
      console.log(`   📊 الحالة قبل: ${beforeUpdate.status}`);
      console.log(`   🆔 معرف الوسيط قبل: ${beforeUpdate.waseet_order_id || 'غير محدد'}`);
      console.log(`   📦 حالة الوسيط قبل: ${beforeUpdate.waseet_status || 'غير محدد'}`);
    }
    
    // تحديث الحالة
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار تشخيص مشكلة الطلبات الجديدة',
      changedBy: 'debug_order_creation'
    };
    
    console.log('\n📤 إرسال طلب تحديث الحالة...');
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${orderId}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 60000,
        validateStatus: () => true
      }
    );
    
    console.log(`📥 استجابة تحديث الحالة:`);
    console.log(`📊 Status: ${updateResponse.status}`);
    console.log(`📋 Response:`, JSON.stringify(updateResponse.data, null, 2));
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      
      // فحص النتيجة بعد فترات مختلفة
      const checkIntervals = [5, 15, 30];
      
      for (const seconds of checkIntervals) {
        console.log(`\n⏳ انتظار ${seconds} ثانية...`);
        await new Promise(resolve => setTimeout(resolve, seconds * 1000));
        
        console.log(`🔍 فحص بعد ${seconds} ثانية:`);
        const afterUpdate = await getOrderDetails(baseURL, orderId);
        
        if (afterUpdate) {
          console.log(`   📊 الحالة بعد: ${afterUpdate.status}`);
          console.log(`   🆔 معرف الوسيط بعد: ${afterUpdate.waseet_order_id || 'غير محدد'}`);
          console.log(`   📦 حالة الوسيط بعد: ${afterUpdate.waseet_status || 'غير محدد'}`);
          
          if (afterUpdate.waseet_order_id && afterUpdate.waseet_order_id !== 'null') {
            console.log(`🎉 نجح! تم إرسال الطلب للوسيط - QR ID: ${afterUpdate.waseet_order_id}`);
            break;
          } else if (afterUpdate.waseet_status === 'pending') {
            console.log('⚠️ الطلب في حالة pending - لا يزال قيد المعالجة');
          } else if (afterUpdate.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('❌ فشل في إرسال الطلب للوسيط');
            break;
          } else if (!afterUpdate.waseet_status) {
            console.log('❓ لم يتم محاولة إرسال الطلب أصلاً');
          }
        }
      }
      
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('📋 الخطأ:', updateResponse.data.error);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار تحديث الطلب: ${error.message}`);
    if (error.response) {
      console.log(`📋 Response:`, error.response.data);
    }
  }
}

async function getOrderDetails(baseURL, orderId) {
  try {
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const order = ordersResponse.data.data.find(o => o.id === orderId);
    return order || null;
  } catch (error) {
    console.log(`❌ خطأ في جلب تفاصيل الطلب: ${error.message}`);
    return null;
  }
}

debugOrderCreation();
