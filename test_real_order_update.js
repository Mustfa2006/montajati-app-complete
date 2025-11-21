const axios = require('axios');

async function testRealOrderUpdate() {
  console.log('🧪 === اختبار تحديث حالة طلب حقيقي ===\n');

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    // 1. جلب قائمة الطلبات
    console.log('1️⃣ جلب قائمة الطلبات...');
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });
    
    console.log(`✅ تم جلب ${ordersResponse.data.data.length} طلب`);
    
    // البحث عن طلب مناسب للاختبار
    const testOrder = ordersResponse.data.data.find(order => 
      order.status !== 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      order.status !== 'تم التسليم للزبون'
    );
    
    if (!testOrder) {
      console.log('⚠️ لم يتم العثور على طلب مناسب للاختبار');
      console.log('📋 جميع الطلبات إما قيد التوصيل أو تم تسليمها');
      
      // استخدام أول طلب متاح
      const firstOrder = ordersResponse.data.data[0];
      console.log(`📦 سنستخدم الطلب: ${firstOrder.id}`);
      console.log(`📊 الحالة الحالية: ${firstOrder.status}`);
      
      await testOrderStatusUpdate(firstOrder);
      return;
    }
    
    console.log(`📦 طلب الاختبار: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🆔 معرف الوسيط الحالي: ${testOrder.waseet_order_id || 'غير محدد'}`);
    
    await testOrderStatusUpdate(testOrder);
    
  } catch (error) {
    console.error('❌ خطأ في جلب الطلبات:', error.message);
    if (error.response) {
      console.error('📋 Status:', error.response.status);
      console.error('📋 Response:', error.response.data);
    }
  }
}

async function testOrderStatusUpdate(order) {
  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    console.log('\n2️⃣ تحديث حالة الطلب إلى "قيد التوصيل"...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار مباشر لحل مشكلة إرسال الطلبات للوسيط',
      changedBy: 'test_real_order_update'
    };
    
    console.log('📤 إرسال طلب التحديث...');
    console.log('📋 البيانات:', JSON.stringify(updateData, null, 2));
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${order.id}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 60000
      }
    );
    
    console.log('\n📥 استجابة الخادم:');
    console.log('📊 Status:', updateResponse.status);
    console.log('📊 نجح:', updateResponse.data.success);
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      console.log('📋 البيانات:', JSON.stringify(updateResponse.data, null, 2));
      
      // انتظار قليل للمعالجة
      console.log('\n⏳ انتظار 10 ثوان للمعالجة...');
      await new Promise(resolve => setTimeout(resolve, 10000));
      
      // فحص الطلب مرة أخرى
      await checkOrderAfterUpdate(order.id);
      
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('📋 الخطأ:', updateResponse.data.error);
    }
    
  } catch (error) {
    console.error('❌ خطأ في تحديث الحالة:', error.message);
    if (error.response) {
      console.error('📋 Status:', error.response.status);
      console.error('📋 Response:', error.response.data);
    }
  }
}

async function checkOrderAfterUpdate(orderId) {
  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    console.log('\n3️⃣ فحص الطلب بعد التحديث...');
    
    const orderResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });
    
    const updatedOrder = orderResponse.data.data.find(o => o.id === orderId);
    
    if (!updatedOrder) {
      console.log('❌ لم يتم العثور على الطلب بعد التحديث');
      return;
    }
    
    console.log('📋 حالة الطلب بعد التحديث:');
    console.log(`   📊 الحالة: ${updatedOrder.status}`);
    console.log(`   🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`   📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
    console.log(`   📋 بيانات الوسيط: ${updatedOrder.waseet_data ? 'موجودة' : 'غير موجودة'}`);
    
    // تحليل النتيجة
    const expectedStatus = 'قيد التوصيل الى الزبون (في عهدة المندوب)';
    
    if (updatedOrder.status === expectedStatus) {
      console.log('\n✅ تم تحديث الحالة بنجاح');
      
      if (updatedOrder.waseet_order_id) {
        console.log('🎉 تم إرسال الطلب للوسيط بنجاح!');
        console.log(`🆔 QR ID: ${updatedOrder.waseet_order_id}`);
        console.log('✅ المشكلة محلولة - النظام يعمل بشكل صحيح');
      } else {
        console.log('⚠️ تم تحديث الحالة لكن لم يتم إرسال الطلب للوسيط');
        console.log('🔍 هذا يعني أن هناك مشكلة في خدمة إرسال الطلبات للوسيط');
        console.log('💡 قد تكون المشكلة في:');
        console.log('   - إعدادات الوسيط');
        console.log('   - خدمة المزامنة');
        console.log('   - اتصال الوسيط');
      }
    } else {
      console.log('❌ لم يتم تحديث الحالة كما متوقع');
      console.log(`📊 متوقع: ${expectedStatus}`);
      console.log(`📊 فعلي: ${updatedOrder.status}`);
    }
    
  } catch (error) {
    console.error('❌ خطأ في فحص الطلب:', error.message);
  }
}

testRealOrderUpdate();
