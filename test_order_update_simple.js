const axios = require('axios');

// اختبار مبسط لتحديث حالة الطلب
async function testOrderStatusUpdate() {
  const baseURL = 'https://clownfish-app-krnk9.ondigitalocean.app';
  const testOrderId = 'order_17';
  
  console.log('🧪 === اختبار تحديث حالة الطلب ===');
  console.log(`🌐 الخادم: ${baseURL}`);
  console.log(`📦 طلب الاختبار: ${testOrderId}`);
  console.log(`⏰ الوقت: ${new Date().toISOString()}\n`);

  // اختبار 1: فحص الخادم على الـ root path
  console.log('1️⃣ فحص الخادم الأساسي...');
  try {
    const response = await axios.get(baseURL, {
      timeout: 10000,
      validateStatus: () => true
    });
    
    console.log(`   📊 Status: ${response.status}`);
    if (response.status === 200) {
      console.log('   ✅ الخادم يعمل بشكل طبيعي');
      if (response.data && response.data.status) {
        console.log(`   📄 حالة النظام: ${response.data.status}`);
      }
    } else {
      console.log('   ⚠️ الخادم يستجيب لكن بحالة غير طبيعية');
    }
  } catch (error) {
    console.log(`   ❌ خطأ في الاتصال: ${error.message}`);
    return;
  }

  // اختبار 2: فحص وجود الطلب
  console.log('\n2️⃣ فحص وجود الطلب...');
  try {
    const response = await axios.get(`${baseURL}/api/orders/${testOrderId}`, {
      timeout: 10000,
      validateStatus: () => true
    });
    
    console.log(`   📊 Status: ${response.status}`);
    if (response.status === 200 && response.data?.data) {
      const order = response.data.data;
      console.log('   ✅ الطلب موجود');
      console.log(`   🆔 ID: ${order.id}`);
      console.log(`   📊 الحالة الحالية: "${order.status}"`);
      console.log(`   👤 العميل: ${order.customer_name}`);
    } else if (response.status === 404) {
      console.log('   ⚠️ الطلب غير موجود - سنختبر بطلب وهمي');
    } else {
      console.log(`   ❌ خطأ في جلب الطلب: ${response.status}`);
      if (response.data) {
        console.log(`   📄 التفاصيل: ${JSON.stringify(response.data).substring(0, 100)}...`);
      }
    }
  } catch (error) {
    console.log(`   ❌ خطأ في فحص الطلب: ${error.message}`);
  }

  // اختبار 3: تحديث حالة الطلب - الطريقة الأولى
  console.log('\n3️⃣ اختبار تحديث الحالة - API الرئيسي...');
  try {
    const updateData = {
      status: 'قيد التحضير',
      notes: 'اختبار تحديث من أداة التشخيص',
      changedBy: 'test_tool'
    };
    
    console.log(`   📋 البيانات: ${JSON.stringify(updateData)}`);
    
    const startTime = Date.now();
    const response = await axios.put(`${baseURL}/api/orders/${testOrderId}/status`, updateData, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 15000,
      validateStatus: () => true
    });
    const duration = Date.now() - startTime;
    
    console.log(`   📊 Status: ${response.status}`);
    console.log(`   ⏱️ المدة: ${duration}ms`);
    
    if (response.status >= 200 && response.status < 300) {
      console.log('   🎉 نجح تحديث الحالة!');
      console.log(`   📄 النتيجة: ${JSON.stringify(response.data, null, 2)}`);
    } else {
      console.log('   ❌ فشل تحديث الحالة');
      console.log(`   📄 تفاصيل الخطأ: ${JSON.stringify(response.data, null, 2)}`);
    }
    
  } catch (error) {
    console.log(`   ❌ خطأ في الطلب: ${error.message}`);
    if (error.code) {
      console.log(`   🔍 كود الخطأ: ${error.code}`);
    }
  }

  // اختبار 4: تحديث حالة الطلب - طريقة Waseet
  console.log('\n4️⃣ اختبار تحديث الحالة - Waseet API...');
  try {
    const waseetData = {
      orderId: testOrderId,
      waseetStatusId: 1,
      waseetStatusText: 'نشط'
    };
    
    console.log(`   📋 البيانات: ${JSON.stringify(waseetData)}`);
    
    const startTime = Date.now();
    const response = await axios.post(`${baseURL}/api/waseet-statuses/update-order-status`, waseetData, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 15000,
      validateStatus: () => true
    });
    const duration = Date.now() - startTime;
    
    console.log(`   📊 Status: ${response.status}`);
    console.log(`   ⏱️ المدة: ${duration}ms`);
    
    if (response.status >= 200 && response.status < 300) {
      console.log('   🎉 نجح تحديث الحالة عبر Waseet!');
      console.log(`   📄 النتيجة: ${JSON.stringify(response.data, null, 2)}`);
    } else {
      console.log('   ❌ فشل تحديث الحالة عبر Waseet');
      console.log(`   📄 تفاصيل الخطأ: ${JSON.stringify(response.data, null, 2)}`);
    }
    
  } catch (error) {
    console.log(`   ❌ خطأ في الطلب: ${error.message}`);
    if (error.code) {
      console.log(`   🔍 كود الخطأ: ${error.code}`);
    }
  }

  // النتيجة النهائية
  console.log('\n🏁 === النتيجة النهائية ===');
  console.log('إذا نجح أي من الاختبارين 3 أو 4، فهذا يعني أن:');
  console.log('✅ المشكلة الأصلية تم حلها');
  console.log('✅ تحديث حالة الطلب يعمل الآن');
  console.log('✅ يمكن استخدام التطبيق بشكل طبيعي');
  console.log('\nإذا فشل كلا الاختبارين، فهناك مشكلة أخرى تحتاج فحص إضافي.');
}

// تشغيل الاختبار
testOrderStatusUpdate().catch(console.error);
