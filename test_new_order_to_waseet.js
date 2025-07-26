const axios = require('axios');

async function testNewOrderToWaseet() {
  console.log('🧪 === اختبار إرسال طلب جديد للوسيط ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. جلب قائمة الطلبات
    console.log('1️⃣ البحث عن طلب جديد لم يرسل للوسيط...');
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });
    
    console.log(`✅ تم جلب ${ordersResponse.data.data.length} طلب`);
    
    // البحث عن طلب ليس له معرف وسيط
    const newOrder = ordersResponse.data.data.find(order => 
      !order.waseet_order_id && 
      order.status !== 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      order.status !== 'تم التسليم للزبون'
    );
    
    if (!newOrder) {
      console.log('⚠️ لم يتم العثور على طلب جديد مناسب للاختبار');
      console.log('📋 جميع الطلبات إما مرسلة للوسيط أو في حالة نهائية');
      
      // إنشاء طلب اختبار جديد
      console.log('\n🆕 إنشاء طلب اختبار جديد...');
      const testOrder = await createTestOrder();
      if (testOrder) {
        await testOrderToWaseetFlow(testOrder);
      }
      return;
    }
    
    console.log(`📦 طلب جديد للاختبار: ${newOrder.id}`);
    console.log(`👤 العميل: ${newOrder.customer_name}`);
    console.log(`📊 الحالة الحالية: ${newOrder.status}`);
    console.log(`🆔 معرف الوسيط: ${newOrder.waseet_order_id || 'غير موجود ✅'}`);
    console.log(`📋 بيانات الوسيط: ${newOrder.waseet_data ? 'موجودة' : 'غير موجودة ✅'}`);
    
    await testOrderToWaseetFlow(newOrder);
    
  } catch (error) {
    console.error('❌ خطأ في جلب الطلبات:', error.message);
    if (error.response) {
      console.error('📋 Status:', error.response.status);
      console.error('📋 Response:', error.response.data);
    }
  }
}

async function createTestOrder() {
  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    console.log('📝 إنشاء طلب اختبار جديد...');
    
    const newOrderData = {
      customer_name: 'عميل اختبار الوسيط',
      primary_phone: '07901234567',
      secondary_phone: '07709876543',
      delivery_address: 'بغداد - الكرادة - شارع الاختبار',
      notes: 'طلب اختبار لفحص إرسال الطلبات للوسيط',
      items: [
        {
          name: 'منتج اختبار',
          quantity: 1,
          price: 25000,
          sku: 'TEST_PRODUCT_001'
        }
      ],
      subtotal: 25000,
      delivery_fee: 5000,
      total: 30000,
      status: 'active'
    };
    
    const response = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (response.data.success) {
      console.log('✅ تم إنشاء طلب اختبار جديد');
      console.log(`📦 معرف الطلب: ${response.data.data.id}`);
      return response.data.data;
    } else {
      console.log('❌ فشل في إنشاء طلب اختبار');
      return null;
    }
    
  } catch (error) {
    console.error('❌ خطأ في إنشاء طلب اختبار:', error.message);
    return null;
  }
}

async function testOrderToWaseetFlow(order) {
  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    console.log('\n2️⃣ تحديث حالة الطلب إلى "قيد التوصيل" (يجب أن يرسل للوسيط)...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار إرسال طلب جديد للوسيط لأول مرة',
      changedBy: 'test_new_order_to_waseet'
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
    console.log('📋 الرسالة:', updateResponse.data.message);
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      
      // انتظار أطول للمعالجة (إنشاء طلب جديد يحتاج وقت أكثر)
      console.log('\n⏳ انتظار 20 ثانية للمعالجة (إنشاء طلب جديد في الوسيط)...');
      await new Promise(resolve => setTimeout(resolve, 20000));
      
      // فحص الطلب مرة أخرى
      await checkNewOrderAfterUpdate(order.id);
      
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

async function checkNewOrderAfterUpdate(orderId) {
  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    console.log('\n3️⃣ فحص الطلب الجديد بعد التحديث...');
    
    const orderResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });
    
    const updatedOrder = orderResponse.data.data.find(o => o.id === orderId);
    
    if (!updatedOrder) {
      console.log('❌ لم يتم العثور على الطلب بعد التحديث');
      return;
    }
    
    console.log('📋 حالة الطلب الجديد بعد التحديث:');
    console.log(`   📊 الحالة: ${updatedOrder.status}`);
    console.log(`   🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`   📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
    console.log(`   📋 بيانات الوسيط: ${updatedOrder.waseet_data ? 'موجودة' : 'غير موجودة'}`);
    
    // تحليل النتيجة
    const expectedStatus = 'قيد التوصيل الى الزبون (في عهدة المندوب)';
    
    if (updatedOrder.status === expectedStatus) {
      console.log('\n✅ تم تحديث الحالة بنجاح');
      
      if (updatedOrder.waseet_order_id) {
        console.log('🎉 تم إنشاء وإرسال الطلب للوسيط بنجاح!');
        console.log(`🆔 QR ID الجديد: ${updatedOrder.waseet_order_id}`);
        console.log('✅ المشكلة محلولة - النظام يعمل للطلبات الجديدة');
      } else {
        console.log('❌ تم تحديث الحالة لكن لم يتم إرسال الطلب للوسيط');
        console.log('🔍 هذا يؤكد وجود مشكلة في إرسال الطلبات الجديدة للوسيط');
        console.log('💡 المشكلة قد تكون في:');
        console.log('   - خدمة إنشاء طلبات جديدة في الوسيط');
        console.log('   - إعدادات الوسيط للطلبات الجديدة');
        console.log('   - عملية تحويل بيانات الطلب لتنسيق الوسيط');
        console.log('   - مصادقة الوسيط');
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

testNewOrderToWaseet();
