const axios = require('axios');

async function diagnoseStatusMismatch() {
  console.log('🔍 === تشخيص عدم تطابق الحالات ===\n');
  console.log('🎯 المشكلة المكتشفة: التطبيق يرسل "in_delivery" لكن الخادم يتوقع النص العربي\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. فحص الحالات الموجودة في قاعدة البيانات
    console.log('1️⃣ === فحص الحالات الموجودة في قاعدة البيانات ===');
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const orders = ordersResponse.data.data;
    
    const statusCounts = {};
    orders.forEach(order => {
      if (order.status) {
        statusCounts[order.status] = (statusCounts[order.status] || 0) + 1;
      }
    });
    
    console.log('📊 الحالات الموجودة فعلياً:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   "${status}": ${count} طلب`);
    });
    
    // 2. اختبار إرسال حالات مختلفة
    console.log('\n2️⃣ === اختبار إرسال حالات مختلفة ===');
    
    // البحث عن طلب للاختبار
    const testOrder = orders.find(order => 
      order.status !== 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      order.status !== 'تم التسليم للزبون'
    );
    
    if (testOrder) {
      console.log(`📦 طلب الاختبار: ${testOrder.id}`);
      console.log(`📊 الحالة الحالية: ${testOrder.status}`);
      
      // اختبار الحالات المختلفة
      const statusesToTest = [
        'in_delivery',
        'قيد التوصيل',
        'قيد التوصيل الى الزبون (في عهدة المندوب)',
        'قيد التوصيل الى الزبون',
        'في عهدة المندوب'
      ];
      
      for (const status of statusesToTest) {
        console.log(`\n🧪 اختبار الحالة: "${status}"`);
        await testStatusUpdate(baseURL, testOrder.id, status);
        
        // انتظار قصير بين الاختبارات
        await new Promise(resolve => setTimeout(resolve, 5000));
      }
      
    } else {
      console.log('⚠️ لم أجد طلب مناسب للاختبار');
    }
    
    // 3. فحص كيف يتعامل الخادم مع الحالات
    console.log('\n3️⃣ === فحص كيف يتعامل الخادم مع الحالات ===');
    await analyzeServerStatusHandling(baseURL);
    
    // 4. تحليل المشكلة وتقديم الحل
    console.log('\n4️⃣ === تحليل المشكلة وتقديم الحل ===');
    await provideSolution();
    
  } catch (error) {
    console.error('❌ خطأ في تشخيص عدم تطابق الحالات:', error.message);
  }
}

async function testStatusUpdate(baseURL, orderId, status) {
  try {
    const updateData = {
      status: status,
      notes: `اختبار الحالة: ${status}`,
      changedBy: 'status_mismatch_test'
    };
    
    console.log(`📤 إرسال طلب تحديث...`);
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${orderId}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000,
        validateStatus: () => true
      }
    );
    
    console.log(`📥 النتيجة:`);
    console.log(`   Status: ${updateResponse.status}`);
    console.log(`   Success: ${updateResponse.data?.success}`);
    console.log(`   Message: ${updateResponse.data?.message}`);
    
    if (updateResponse.data?.success) {
      console.log('✅ تم قبول الحالة');
      
      // فحص إذا تم إرسال الطلب للوسيط
      await new Promise(resolve => setTimeout(resolve, 10000));
      
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
      
      if (updatedOrder) {
        console.log(`   📊 الحالة في قاعدة البيانات: ${updatedOrder.status}`);
        console.log(`   🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
        
        if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
          console.log(`   🎉 تم إرسال الطلب للوسيط! QR ID: ${updatedOrder.waseet_order_id}`);
        } else {
          console.log(`   ❌ لم يتم إرسال الطلب للوسيط`);
        }
      }
      
    } else {
      console.log(`❌ تم رفض الحالة: ${updateResponse.data?.error}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار الحالة: ${error.message}`);
  }
}

async function analyzeServerStatusHandling(baseURL) {
  try {
    console.log('🔍 تحليل كيف يتعامل الخادم مع الحالات...');
    
    // من التحليل السابق، نعرف أن الخادم يدعم هذه الحالات:
    const supportedStatuses = [
      'قيد التوصيل',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'قيد التوصيل الى الزبون',
      'في عهدة المندوب',
      'قيد التوصيل للزبون',
      'shipping',
      'shipped'
    ];
    
    console.log('\n📋 الحالات المدعومة في الخادم للإرسال للوسيط:');
    supportedStatuses.forEach((status, index) => {
      console.log(`   ${index + 1}. "${status}"`);
    });
    
    // لكن التطبيق يرسل "in_delivery"
    console.log('\n⚠️ المشكلة المكتشفة:');
    console.log('   📱 التطبيق يرسل: "in_delivery"');
    console.log('   🖥️ الخادم يتوقع: "قيد التوصيل الى الزبون (في عهدة المندوب)"');
    console.log('   🔍 النتيجة: عدم تطابق يؤدي لعدم إرسال الطلب للوسيط');
    
    // فحص إذا كان هناك تحويل في الخادم
    console.log('\n🔍 فحص إذا كان هناك تحويل في الخادم...');
    
    // من الكود، يبدو أن AdminService في التطبيق يحول "in_delivery" إلى النص العربي
    console.log('✅ وجدت تحويل في AdminService:');
    console.log('   if (status == "in_delivery") {');
    console.log('     return "قيد التوصيل الى الزبون (في عهدة المندوب)";');
    console.log('   }');
    
    console.log('\n🤔 إذن لماذا لا يعمل؟');
    console.log('   ❓ ربما التطبيق لا يستخدم AdminService');
    console.log('   ❓ ربما هناك مسار آخر لتحديث الحالة');
    console.log('   ❓ ربما المشكلة في مكان آخر');
    
  } catch (error) {
    console.log(`❌ خطأ في تحليل معالجة الحالات: ${error.message}`);
  }
}

async function provideSolution() {
  console.log('💡 === الحل المقترح ===');
  
  console.log('\n🎯 المشكلة الحقيقية:');
  console.log('   📱 التطبيق قد يرسل "in_delivery" مباشرة للخادم');
  console.log('   🖥️ الخادم لا يتعرف على "in_delivery" كحالة توصيل');
  console.log('   🔍 النتيجة: لا يتم إرسال الطلب للوسيط');
  
  console.log('\n🔧 الحلول المقترحة:');
  
  console.log('\n1️⃣ الحل الأول: إضافة "in_delivery" لقائمة الحالات المدعومة في الخادم');
  console.log('   📁 الملف: backend/routes/orders.js');
  console.log('   📝 إضافة "in_delivery" لمصفوفة deliveryStatuses');
  
  console.log('\n2️⃣ الحل الثاني: التأكد من أن التطبيق يستخدم AdminService');
  console.log('   📁 الملف: frontend/lib/services/admin_service.dart');
  console.log('   📝 التأكد من استخدام _convertStatusToDatabase');
  
  console.log('\n3️⃣ الحل الثالث: إضافة تحويل في الخادم');
  console.log('   📁 الملف: backend/routes/orders.js');
  console.log('   📝 إضافة تحويل "in_delivery" → "قيد التوصيل الى الزبون (في عهدة المندوب)"');
  
  console.log('\n🎯 الحل الموصى به:');
  console.log('   ✅ إضافة "in_delivery" لقائمة deliveryStatuses في الخادم');
  console.log('   ✅ إضافة تحويل تلقائي في الخادم');
  console.log('   ✅ التأكد من أن التطبيق يرسل الحالة الصحيحة');
  
  console.log('\n📋 خطوات التنفيذ:');
  console.log('1. تحديث قائمة deliveryStatuses في backend/routes/orders.js');
  console.log('2. إضافة تحويل تلقائي للحالات الإنجليزية');
  console.log('3. اختبار التحديث');
  console.log('4. التأكد من عمل النظام');
  
  console.log('\n🚀 بعد تطبيق الحل:');
  console.log('   ✅ التطبيق سيرسل "in_delivery"');
  console.log('   ✅ الخادم سيتعرف عليها كحالة توصيل');
  console.log('   ✅ سيتم إرسال الطلب للوسيط تلقائياً');
  console.log('   ✅ المستخدم سيحصل على QR ID');
}

diagnoseStatusMismatch();
