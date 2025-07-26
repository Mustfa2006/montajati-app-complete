const axios = require('axios');

async function testRealUserFlow() {
  console.log('🧪 === محاكاة تدفق المستخدم الحقيقي ===\n');
  console.log('📝 سأقوم بنفس العملية التي تقوم بها:');
  console.log('1. إنشاء طلب جديد');
  console.log('2. تغيير حالته إلى "قيد التوصيل"');
  console.log('3. فحص ما إذا وصل للوسيط\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. إنشاء طلب جديد تماماً كما يفعل المستخدم
    console.log('1️⃣ === إنشاء طلب جديد ===');
    
    const timestamp = Date.now();
    const newOrderData = {
      customer_name: 'عميل اختبار حقيقي',
      primary_phone: '07901234567',
      secondary_phone: '07709876543',
      province: 'بغداد',
      city: 'الكرخ',
      customer_address: 'بغداد - الكرخ - شارع الاختبار الحقيقي',
      delivery_address: 'بغداد - الكرخ - شارع الاختبار الحقيقي',
      notes: 'طلب اختبار حقيقي لمحاكاة تدفق المستخدم',
      items: [
        {
          name: 'منتج اختبار حقيقي',
          quantity: 1,
          price: 25000,
          sku: 'REAL_TEST_001'
        }
      ],
      subtotal: 25000,
      delivery_fee: 5000,
      total: 30000,
      status: 'active'
    };
    
    console.log('📤 إرسال طلب إنشاء الطلب...');
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    console.log(`📥 استجابة إنشاء الطلب:`);
    console.log(`📊 Status: ${createResponse.status}`);
    console.log(`📊 Success: ${createResponse.data.success}`);
    
    if (!createResponse.data.success) {
      console.log('❌ فشل في إنشاء الطلب');
      console.log('📋 الخطأ:', createResponse.data.error);
      return;
    }
    
    const newOrderId = createResponse.data.data.id;
    console.log(`✅ تم إنشاء طلب جديد بنجاح: ${newOrderId}`);
    
    // 2. انتظار قصير (كما يفعل المستخدم)
    console.log('\n⏳ انتظار 3 ثوان (كما يفعل المستخدم عادة)...');
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // 3. فحص الطلب الجديد قبل تغيير الحالة
    console.log('\n2️⃣ === فحص الطلب الجديد قبل تغيير الحالة ===');
    await checkOrderStatus(baseURL, newOrderId, 'قبل تغيير الحالة');
    
    // 4. تغيير حالة الطلب إلى "قيد التوصيل" (كما يفعل المستخدم)
    console.log('\n3️⃣ === تغيير حالة الطلب إلى "قيد التوصيل" ===');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'تغيير حالة طلب جديد - اختبار حقيقي',
      changedBy: 'real_user_test'
    };
    
    console.log('📤 إرسال طلب تغيير الحالة...');
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
    
    console.log('\n📥 استجابة تغيير الحالة:');
    console.log(`📊 Status: ${updateResponse.status}`);
    console.log(`📊 Success: ${updateResponse.data.success}`);
    console.log(`📋 Message: ${updateResponse.data.message}`);
    
    if (updateResponse.data.success) {
      console.log('✅ تم تغيير الحالة بنجاح');
      
      // 5. مراقبة مفصلة كما يفعل المستخدم
      console.log('\n4️⃣ === مراقبة الطلب بعد تغيير الحالة ===');
      
      // فحص فوري
      console.log('\n🔍 فحص فوري (بعد ثانيتين):');
      await new Promise(resolve => setTimeout(resolve, 2000));
      const status1 = await checkOrderStatus(baseURL, newOrderId, 'بعد ثانيتين');
      
      // فحص بعد 10 ثوان
      console.log('\n🔍 فحص بعد 10 ثوان:');
      await new Promise(resolve => setTimeout(resolve, 8000));
      const status2 = await checkOrderStatus(baseURL, newOrderId, 'بعد 10 ثوان');
      
      // فحص بعد 30 ثانية
      console.log('\n🔍 فحص بعد 30 ثانية:');
      await new Promise(resolve => setTimeout(resolve, 20000));
      const status3 = await checkOrderStatus(baseURL, newOrderId, 'بعد 30 ثانية');
      
      // فحص بعد دقيقة
      console.log('\n🔍 فحص بعد دقيقة:');
      await new Promise(resolve => setTimeout(resolve, 30000));
      const status4 = await checkOrderStatus(baseURL, newOrderId, 'بعد دقيقة');
      
      // تحليل النتائج
      console.log('\n📊 === تحليل النتائج ===');
      
      const finalStatus = status4 || status3 || status2 || status1;
      
      if (finalStatus && finalStatus.waseet_order_id && finalStatus.waseet_order_id !== 'null') {
        console.log('🎉 نجح! تم إرسال الطلب للوسيط');
        console.log(`🆔 QR ID: ${finalStatus.waseet_order_id}`);
        console.log('✅ النظام يعمل بشكل صحيح');
      } else {
        console.log('❌ فشل! لم يتم إرسال الطلب للوسيط');
        console.log('🔍 هذا يؤكد وجود مشكلة في النظام');
        
        if (finalStatus) {
          console.log(`📦 حالة الوسيط النهائية: ${finalStatus.waseet_status || 'غير محدد'}`);
          
          if (finalStatus.waseet_status === 'pending') {
            console.log('⚠️ الطلب عالق في حالة pending');
          } else if (finalStatus.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('⚠️ فشل في إرسال الطلب للوسيط');
          } else if (!finalStatus.waseet_status) {
            console.log('⚠️ لم يتم محاولة إرسال الطلب أصلاً');
          }
        }
        
        // محاولة تشخيص المشكلة
        console.log('\n🔧 === محاولة تشخيص المشكلة ===');
        await diagnoseProblem(baseURL, newOrderId);
      }
      
    } else {
      console.log('❌ فشل في تغيير الحالة');
      console.log('📋 الخطأ:', updateResponse.data.error);
    }
    
  } catch (error) {
    console.error('❌ خطأ في محاكاة تدفق المستخدم:', error.message);
    if (error.response) {
      console.error('📋 Response Status:', error.response.status);
      console.error('📋 Response Data:', error.response.data);
    }
  }
}

async function checkOrderStatus(baseURL, orderId, stage) {
  try {
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const order = ordersResponse.data.data.find(o => o.id === orderId);
    
    if (!order) {
      console.log('❌ لم يتم العثور على الطلب');
      return null;
    }
    
    console.log(`📋 ${stage}:`);
    console.log(`   📊 الحالة: ${order.status}`);
    console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
    console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
    console.log(`   📋 بيانات الوسيط: ${order.waseet_data ? 'موجودة' : 'غير موجودة'}`);
    console.log(`   🕐 آخر تحديث: ${order.updated_at}`);
    
    return {
      status: order.status,
      waseet_order_id: order.waseet_order_id,
      waseet_status: order.waseet_status,
      waseet_data: order.waseet_data,
      updated_at: order.updated_at
    };
    
  } catch (error) {
    console.log(`❌ خطأ في فحص الطلب: ${error.message}`);
    return null;
  }
}

async function diagnoseProblem(baseURL, orderId) {
  try {
    console.log('🔍 فحص تفصيلي للمشكلة...');
    
    // فحص حالة الخادم
    console.log('\n1. فحص حالة الخادم:');
    try {
      const healthResponse = await axios.get(`${baseURL}/`, { timeout: 10000 });
      console.log(`   ✅ الخادم يعمل - Status: ${healthResponse.status}`);
    } catch (error) {
      console.log(`   ❌ مشكلة في الخادم: ${error.message}`);
    }
    
    // فحص خدمة المزامنة
    console.log('\n2. فحص خدمة المزامنة:');
    try {
      const syncResponse = await axios.get(`${baseURL}/api/sync/status`, { 
        timeout: 10000,
        validateStatus: () => true 
      });
      console.log(`   📊 Status: ${syncResponse.status}`);
      if (syncResponse.status === 200) {
        console.log('   ✅ خدمة المزامنة تعمل');
      } else {
        console.log('   ⚠️ خدمة المزامنة قد تكون معطلة');
      }
    } catch (error) {
      console.log(`   ❌ خطأ في خدمة المزامنة: ${error.message}`);
    }
    
    // فحص اتصال الوسيط
    console.log('\n3. فحص اتصال الوسيط:');
    try {
      const waseetResponse = await axios.post(`${baseURL}/api/waseet/test-connection`, {}, { 
        timeout: 15000,
        validateStatus: () => true 
      });
      console.log(`   📊 Status: ${waseetResponse.status}`);
      if (waseetResponse.status === 200) {
        console.log('   ✅ اتصال الوسيط يعمل');
      } else {
        console.log('   ❌ مشكلة في اتصال الوسيط');
      }
    } catch (error) {
      console.log(`   ❌ خطأ في اتصال الوسيط: ${error.message}`);
    }
    
    // محاولة إعادة إرسال الطلب يدوياً
    console.log('\n4. محاولة إعادة إرسال الطلب يدوياً:');
    try {
      const retryResponse = await axios.post(`${baseURL}/api/orders/${orderId}/send-to-waseet`, {}, {
        timeout: 30000,
        validateStatus: () => true
      });
      console.log(`   📊 Status: ${retryResponse.status}`);
      if (retryResponse.status === 200 && retryResponse.data.success) {
        console.log('   ✅ نجح الإرسال اليدوي');
        console.log(`   🆔 QR ID: ${retryResponse.data.data.qrId}`);
      } else {
        console.log('   ❌ فشل الإرسال اليدوي');
        console.log(`   📋 الخطأ: ${retryResponse.data?.error || 'غير محدد'}`);
      }
    } catch (error) {
      console.log(`   ❌ خطأ في الإرسال اليدوي: ${error.message}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في التشخيص: ${error.message}`);
  }
}

testRealUserFlow();
