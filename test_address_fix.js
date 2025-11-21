const axios = require('axios');

async function testAddressFix() {
  console.log('🧪 === اختبار إصلاح مشكلة العنوان ===\n');

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  // استخدام أحد الطلبات المشكوك فيها
  const problematicOrderId = 'order_1753477070545_6565';
  
  try {
    console.log(`📦 اختبار الطلب: ${problematicOrderId}`);
    
    // 1. فحص الطلب قبل الإصلاح
    console.log('1️⃣ فحص الطلب قبل الإصلاح...');
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });
    
    const order = ordersResponse.data.data.find(o => o.id === problematicOrderId);
    
    if (!order) {
      console.log('❌ لم يتم العثور على الطلب');
      return;
    }
    
    console.log('📋 حالة الطلب قبل الإصلاح:');
    console.log(`   👤 العميل: ${order.customer_name}`);
    console.log(`   📊 الحالة: ${order.status}`);
    console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
    console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
    console.log(`   📍 العنوان الحالي: ${order.customer_address || order.delivery_address || order.notes || 'غير محدد'}`);
    console.log(`   📞 الهاتف: ${order.primary_phone || order.customer_phone}`);
    
    // 2. محاولة إعادة إرسال الطلب مع الإصلاح الجديد
    console.log('\n2️⃣ محاولة إعادة إرسال الطلب مع إصلاح العنوان...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار إصلاح مشكلة العنوان - إعادة إرسال للوسيط',
      changedBy: 'test_address_fix'
    };
    
    console.log('📤 إرسال طلب إعادة المحاولة...');
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${problematicOrderId}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 60000
      }
    );
    
    if (updateResponse.data.success) {
      console.log('✅ تم إرسال طلب إعادة المحاولة بنجاح');
      
      // انتظار للمعالجة
      console.log('\n⏳ انتظار 30 ثانية للمعالجة مع الإصلاح الجديد...');
      await new Promise(resolve => setTimeout(resolve, 30000));
      
      // 3. فحص النتيجة
      console.log('\n3️⃣ فحص النتيجة بعد الإصلاح...');
      
      const updatedOrdersResponse = await axios.get(`${baseURL}/api/orders`, {
        timeout: 30000
      });
      
      const updatedOrder = updatedOrdersResponse.data.data.find(o => o.id === problematicOrderId);
      
      if (updatedOrder) {
        console.log('📋 حالة الطلب بعد الإصلاح:');
        console.log(`   📊 الحالة: ${updatedOrder.status}`);
        console.log(`   🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
        console.log(`   📋 بيانات الوسيط: ${updatedOrder.waseet_data ? 'موجودة' : 'غير موجودة'}`);
        
        if (updatedOrder.waseet_data) {
          try {
            const waseetData = typeof updatedOrder.waseet_data === 'string' 
              ? JSON.parse(updatedOrder.waseet_data) 
              : updatedOrder.waseet_data;
            console.log(`   📊 تفاصيل الوسيط:`, JSON.stringify(waseetData, null, 2));
          } catch (e) {
            console.log(`   📊 بيانات الوسيط (خام): ${updatedOrder.waseet_data}`);
          }
        }
        
        // تحليل النتيجة
        if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
          console.log('\n🎉 نجح الإصلاح! تم إرسال الطلب للوسيط');
          console.log(`🆔 QR ID الجديد: ${updatedOrder.waseet_order_id}`);
          console.log('✅ مشكلة العنوان تم حلها');
        } else {
          console.log('\n❌ لم ينجح الإصلاح - المشكلة أعمق من العنوان');
          
          if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('🔍 النظام يحاول لكن يفشل - قد تكون مشكلة في:');
            console.log('   - إعدادات الوسيط');
            console.log('   - مصادقة الوسيط');
            console.log('   - خدمة الوسيط نفسها');
          } else {
            console.log('🔍 النظام لم يحاول الإرسال - قد تكون مشكلة في:');
            console.log('   - منطق تحديد حالات التوصيل');
            console.log('   - خدمة المزامنة');
          }
        }
        
      } else {
        console.log('❌ لم يتم العثور على الطلب بعد التحديث');
      }
      
    } else {
      console.log('❌ فشل في إرسال طلب إعادة المحاولة');
      console.log('📋 الخطأ:', updateResponse.data.error);
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار إصلاح العنوان:', error.message);
    if (error.response) {
      console.error('📋 Status:', error.response.status);
      console.error('📋 Response:', error.response.data);
    }
  }
}

// اختبار طلبات متعددة
async function testMultipleOrders() {
  console.log('\n🔄 === اختبار طلبات متعددة ===');
  
  const problematicOrders = [
    'order_1753477070545_6565',
    'order_1753473073199_6564',
    'order_1753465511829_2222'
  ];
  
  for (const orderId of problematicOrders) {
    console.log(`\n📦 اختبار الطلب: ${orderId}`);
    
    try {
  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: `اختبار إصلاح العنوان - ${new Date().toISOString()}`,
        changedBy: 'batch_address_fix'
      };
      
      const updateResponse = await axios.put(
        `${baseURL}/api/orders/${orderId}/status`,
        updateData,
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );
      
      if (updateResponse.data.success) {
        console.log(`✅ تم إرسال طلب إعادة المحاولة للطلب ${orderId}`);
      } else {
        console.log(`❌ فشل في إرسال طلب إعادة المحاولة للطلب ${orderId}`);
      }
      
      // انتظار قصير بين الطلبات
      await new Promise(resolve => setTimeout(resolve, 5000));
      
    } catch (error) {
      console.error(`❌ خطأ في الطلب ${orderId}:`, error.message);
    }
  }
  
  console.log('\n⏳ انتظار 60 ثانية لمعالجة جميع الطلبات...');
  await new Promise(resolve => setTimeout(resolve, 60000));
  
  // فحص النتائج
  console.log('\n📊 فحص نتائج جميع الطلبات...');
  await checkAllResults(problematicOrders);
}

async function checkAllResults(orderIds) {
  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });
    
    let successCount = 0;
    let failCount = 0;
    
    for (const orderId of orderIds) {
      const order = ordersResponse.data.data.find(o => o.id === orderId);
      
      if (order) {
        if (order.waseet_order_id && order.waseet_order_id !== 'null') {
          console.log(`✅ ${orderId}: نجح - QR ID: ${order.waseet_order_id}`);
          successCount++;
        } else {
          console.log(`❌ ${orderId}: فشل - لا يوجد معرف وسيط`);
          failCount++;
        }
      } else {
        console.log(`❓ ${orderId}: لم يتم العثور على الطلب`);
        failCount++;
      }
    }
    
    console.log(`\n📊 النتائج النهائية:`);
    console.log(`✅ نجح: ${successCount} طلب`);
    console.log(`❌ فشل: ${failCount} طلب`);
    console.log(`📈 معدل النجاح: ${((successCount / orderIds.length) * 100).toFixed(1)}%`);
    
  } catch (error) {
    console.error('❌ خطأ في فحص النتائج:', error.message);
  }
}

// تشغيل الاختبار
console.log('💡 اختر نوع الاختبار:');
console.log('1. اختبار طلب واحد: node test_address_fix.js');
console.log('2. اختبار طلبات متعددة: node test_address_fix.js multiple\n');

if (process.argv[2] === 'multiple') {
  testMultipleOrders();
} else {
  testAddressFix();
}
