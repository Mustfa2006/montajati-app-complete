const axios = require('axios');

// إعدادات الاختبار
const baseURL = 'https://montajati-backend.onrender.com';
const timeout = 60000; // دقيقة واحدة

// دالة مساعدة لإرسال الطلبات
async function makeRequest(method, url, data = null) {
  try {
    const config = {
      method,
      url,
      timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      validateStatus: () => true // قبول جميع status codes
    };
    
    if (data) {
      config.data = data;
    }
    
    const response = await axios(config);
    
    return {
      success: response.status >= 200 && response.status < 300,
      status: response.status,
      data: response.data,
      headers: response.headers,
      error: response.status >= 400 ? response.data : null
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      details: error.response?.data || null
    };
  }
}

// دالة لطباعة النتائج بشكل منظم
function printResult(title, result) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`📋 ${title}`);
  console.log(`${'='.repeat(60)}`);
  console.log(`✅ نجح: ${result.success}`);
  console.log(`📊 Status: ${result.status || 'N/A'}`);
  
  if (result.data) {
    console.log(`📄 البيانات:`);
    console.log(JSON.stringify(result.data, null, 2));
  }
  
  if (result.error) {
    console.log(`❌ الخطأ:`);
    console.log(JSON.stringify(result.error, null, 2));
  }
}

async function diagnoseOrderStatusUpdateIssue() {
  console.log('🔍 ===== تشخيص مشكلة تحديث حالة الطلب =====');
  console.log(`⏰ الوقت: ${new Date().toISOString()}`);
  console.log(`🌐 Backend URL: ${baseURL}`);
  
  try {
    // 1. اختبار الاتصال بالـ Backend
    console.log('\n1️⃣ === اختبار الاتصال بالـ Backend ===');
    const healthCheck = await makeRequest('GET', `${baseURL}/health`);
    printResult('فحص صحة الخادم', healthCheck);
    
    if (!healthCheck.success) {
      console.log('❌ فشل في الاتصال بالـ Backend - توقف التشخيص');
      return;
    }
    
    // 2. جلب طلب للاختبار
    console.log('\n2️⃣ === جلب طلب للاختبار ===');
    const ordersResult = await makeRequest('GET', `${baseURL}/api/orders?limit=1`);
    printResult('جلب الطلبات', ordersResult);
    
    if (!ordersResult.success || !ordersResult.data?.data?.length) {
      console.log('❌ لا توجد طلبات للاختبار - إنشاء طلب جديد...');
      
      // إنشاء طلب جديد للاختبار
      const testOrderData = {
        customer_name: 'اختبار تشخيص',
        customer_phone: '07700000000',
        customer_address: 'عنوان اختبار',
        customer_city: 'بغداد',
        items: [
          {
            product_id: 'test_product',
            product_name: 'منتج اختبار',
            quantity: 1,
            price: 1000
          }
        ],
        total_amount: 1000,
        delivery_fee: 5000,
        final_total: 6000,
        payment_method: 'نقداً عند الاستلام',
        notes: 'طلب اختبار لتشخيص مشكلة تحديث الحالة'
      };
      
      const createResult = await makeRequest('POST', `${baseURL}/api/orders`, testOrderData);
      printResult('إنشاء طلب اختبار', createResult);
      
      if (!createResult.success) {
        console.log('❌ فشل في إنشاء طلب اختبار - توقف التشخيص');
        return;
      }
      
      var testOrder = createResult.data.data;
    } else {
      var testOrder = ordersResult.data.data[0];
    }
    
    console.log(`📦 طلب الاختبار: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    
    // 3. اختبار تحديث حالة الطلب
    console.log('\n3️⃣ === اختبار تحديث حالة الطلب ===');
    
    const testStatuses = [
      'نشط',
      'قيد التحضير',
      'جاهز للتوصيل',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'تم التسليم للزبون'
    ];
    
    // اختيار حالة مختلفة عن الحالة الحالية
    const newStatus = testStatuses.find(status => status !== testOrder.status) || testStatuses[0];
    
    const updateData = {
      status: newStatus,
      notes: 'اختبار تشخيص مشكلة تحديث الحالة',
      changedBy: 'diagnosis_script'
    };
    
    console.log(`🔄 تحديث الحالة من "${testOrder.status}" إلى "${newStatus}"`);
    console.log(`📋 بيانات التحديث:`, JSON.stringify(updateData, null, 2));
    
    const updateResult = await makeRequest('PUT', `${baseURL}/api/orders/${testOrder.id}/status`, updateData);
    printResult('تحديث حالة الطلب', updateResult);
    
    // 4. التحقق من التحديث
    console.log('\n4️⃣ === التحقق من التحديث ===');
    
    await new Promise(resolve => setTimeout(resolve, 3000)); // انتظار 3 ثوان
    
    const verifyResult = await makeRequest('GET', `${baseURL}/api/orders/${testOrder.id}`);
    printResult('التحقق من الطلب المحدث', verifyResult);
    
    if (verifyResult.success && verifyResult.data?.data) {
      const updatedOrder = verifyResult.data.data;
      console.log(`\n📊 مقارنة الحالات:`);
      console.log(`   الحالة القديمة: "${testOrder.status}"`);
      console.log(`   الحالة المطلوبة: "${newStatus}"`);
      console.log(`   الحالة الحالية: "${updatedOrder.status}"`);
      console.log(`   تم التحديث: ${updatedOrder.status === newStatus ? '✅ نعم' : '❌ لا'}`);
    }
    
    // 5. اختبار حالات مختلفة
    console.log('\n5️⃣ === اختبار حالات مختلفة ===');
    
    const additionalTests = [
      { status: '1', description: 'حالة برقم' },
      { status: 'مغلق', description: 'حالة إغلاق' },
      { status: 'ملغي', description: 'حالة إلغاء' }
    ];
    
    for (const test of additionalTests) {
      console.log(`\n🧪 اختبار: ${test.description}`);
      
      const testUpdateData = {
        status: test.status,
        notes: `اختبار ${test.description}`,
        changedBy: 'diagnosis_script'
      };
      
      const testResult = await makeRequest('PUT', `${baseURL}/api/orders/${testOrder.id}/status`, testUpdateData);
      console.log(`   النتيجة: ${testResult.success ? '✅ نجح' : '❌ فشل'}`);
      
      if (!testResult.success) {
        console.log(`   الخطأ: ${JSON.stringify(testResult.error, null, 2)}`);
      }
      
      await new Promise(resolve => setTimeout(resolve, 2000)); // انتظار ثانيتين
    }
    
    // 6. تحليل الأخطاء الشائعة
    console.log('\n6️⃣ === تحليل الأخطاء الشائعة ===');
    
    // اختبار طلب غير موجود
    const nonExistentTest = await makeRequest('PUT', `${baseURL}/api/orders/non_existent_order/status`, updateData);
    console.log(`🔍 اختبار طلب غير موجود: ${nonExistentTest.success ? '❌ نجح (مشكلة!)' : '✅ فشل (طبيعي)'}`);
    
    // اختبار بيانات ناقصة
    const incompleteTest = await makeRequest('PUT', `${baseURL}/api/orders/${testOrder.id}/status`, {});
    console.log(`🔍 اختبار بيانات ناقصة: ${incompleteTest.success ? '❌ نجح (مشكلة!)' : '✅ فشل (طبيعي)'}`);
    
    console.log('\n🎯 ===== انتهاء التشخيص =====');
    console.log('📋 تحقق من النتائج أعلاه لتحديد سبب المشكلة');
    
  } catch (error) {
    console.error('❌ خطأ في التشخيص:', error.message);
    console.error('📋 تفاصيل الخطأ:', error);
  }
}

// تشغيل التشخيص
diagnoseOrderStatusUpdateIssue();
