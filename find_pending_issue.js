const axios = require('axios');

async function findPendingIssue() {
  console.log('🔍 === البحث عن مصدر مشكلة pending ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. إنشاء طلب جديد للاختبار
    console.log('1️⃣ إنشاء طلب جديد للاختبار...');
    
    const newOrderData = {
      customer_name: 'اختبار مشكلة pending',
      primary_phone: '07901234567',
      secondary_phone: '07709876543',
      province: 'بغداد',
      city: 'الكرخ',
      customer_address: 'بغداد - الكرخ - شارع الاختبار',
      delivery_address: 'بغداد - الكرخ - شارع الاختبار',
      notes: 'طلب اختبار لفحص مشكلة pending',
      items: [
        {
          name: 'منتج اختبار pending',
          quantity: 1,
          price: 25000,
          sku: 'PENDING_TEST_001'
        }
      ],
      subtotal: 25000,
      delivery_fee: 5000,
      total: 30000,
      status: 'active'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (!createResponse.data.success) {
      console.log('❌ فشل في إنشاء طلب جديد');
      return;
    }
    
    const newOrderId = createResponse.data.data.id;
    console.log(`✅ تم إنشاء طلب جديد: ${newOrderId}`);
    
    // 2. فحص الطلب قبل تحديث الحالة
    console.log('\n2️⃣ فحص الطلب قبل تحديث الحالة...');
    await checkOrderStatus(baseURL, newOrderId, 'قبل التحديث');
    
    // 3. تحديث الحالة مع مراقبة مفصلة
    console.log('\n3️⃣ تحديث الحالة مع مراقبة مفصلة...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار مشكلة pending - مراقبة مفصلة',
      changedBy: 'pending_issue_test'
    };
    
    console.log('📤 إرسال طلب تحديث الحالة...');
    console.log('📋 البيانات:', JSON.stringify(updateData, null, 2));
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${newOrderId}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 60000
      }
    );
    
    console.log('\n📥 استجابة تحديث الحالة:');
    console.log(`📊 Status: ${updateResponse.status}`);
    console.log(`📊 Success: ${updateResponse.data.success}`);
    console.log(`📋 Response:`, JSON.stringify(updateResponse.data, null, 2));
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      
      // 4. فحص فوري بعد التحديث
      console.log('\n4️⃣ فحص فوري بعد التحديث (5 ثوان)...');
      await new Promise(resolve => setTimeout(resolve, 5000));
      await checkOrderStatus(baseURL, newOrderId, 'بعد 5 ثوان');
      
      // 5. فحص بعد 15 ثانية
      console.log('\n5️⃣ فحص بعد 15 ثانية...');
      await new Promise(resolve => setTimeout(resolve, 10000));
      await checkOrderStatus(baseURL, newOrderId, 'بعد 15 ثانية');
      
      // 6. فحص بعد 30 ثانية
      console.log('\n6️⃣ فحص بعد 30 ثانية...');
      await new Promise(resolve => setTimeout(resolve, 15000));
      await checkOrderStatus(baseURL, newOrderId, 'بعد 30 ثانية');
      
      // 7. فحص نهائي بعد دقيقة
      console.log('\n7️⃣ فحص نهائي بعد دقيقة...');
      await new Promise(resolve => setTimeout(resolve, 30000));
      await checkOrderStatus(baseURL, newOrderId, 'بعد دقيقة');
      
    } else {
      console.log('❌ فشل في تحديث الحالة');
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار مشكلة pending:', error.message);
    if (error.response) {
      console.error('📋 Response:', error.response.data);
    }
  }
}

async function checkOrderStatus(baseURL, orderId, stage) {
  try {
    console.log(`🔍 فحص الطلب ${orderId} - ${stage}:`);
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const order = ordersResponse.data.data.find(o => o.id === orderId);
    
    if (!order) {
      console.log('❌ لم يتم العثور على الطلب');
      return;
    }
    
    console.log(`   📊 الحالة: ${order.status}`);
    console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
    console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
    console.log(`   📋 بيانات الوسيط: ${order.waseet_data ? 'موجودة' : 'غير موجودة'}`);
    console.log(`   🕐 آخر تحديث: ${order.updated_at}`);
    
    // تحليل حالة الوسيط
    if (order.waseet_status === 'pending') {
      console.log('   ⚠️ الطلب في حالة pending - هذا هو مصدر المشكلة!');
      
      if (order.waseet_data) {
        try {
          const waseetData = typeof order.waseet_data === 'string' 
            ? JSON.parse(order.waseet_data) 
            : order.waseet_data;
          console.log('   📊 تفاصيل بيانات الوسيط:', JSON.stringify(waseetData, null, 2));
        } catch (e) {
          console.log(`   📊 بيانات الوسيط (خام): ${order.waseet_data}`);
        }
      }
    } else if (order.waseet_status === 'في انتظار الإرسال للوسيط') {
      console.log('   ⚠️ الطلب في انتظار الإرسال - فشل في الإرسال');
    } else if (order.waseet_status === 'sent' || order.waseet_status === 'تم الإرسال للوسيط') {
      console.log('   ✅ تم إرسال الطلب للوسيط بنجاح');
    } else if (!order.waseet_status) {
      console.log('   ❓ لا توجد حالة وسيط - لم يتم محاولة الإرسال');
    }
    
    // فحص إضافي للطلبات في حالة pending
    if (order.waseet_status === 'pending') {
      console.log('\n   🔍 === تحليل عميق لحالة pending ===');
      
      // فحص متى تم تعيين pending
      const timeDiff = new Date() - new Date(order.updated_at);
      const minutesAgo = Math.floor(timeDiff / (1000 * 60));
      console.log(`   ⏰ تم تعيين pending منذ: ${minutesAgo} دقيقة`);
      
      // فحص إذا كان هناك خطأ في البيانات
      if (order.waseet_data) {
        try {
          const data = JSON.parse(order.waseet_data);
          if (data.error) {
            console.log(`   ❌ خطأ في البيانات: ${data.error}`);
          }
          if (data.retry_needed) {
            console.log(`   🔄 يحتاج إعادة محاولة: ${data.retry_needed}`);
          }
          if (data.last_attempt) {
            console.log(`   🕐 آخر محاولة: ${data.last_attempt}`);
          }
        } catch (e) {
          console.log('   ⚠️ خطأ في تحليل بيانات الوسيط');
        }
      }
    }
    
  } catch (error) {
    console.log(`❌ خطأ في فحص الطلب: ${error.message}`);
  }
}

findPendingIssue();
