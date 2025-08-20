const axios = require('axios');

// إعدادات الاختبار
const CONFIG = {
  baseURL: 'https://montajati-official-backend-production.up.railway.app',
  timeout: 60000,
  testOrderId: null, // سيتم تحديده أثناء الاختبار
  adminCredentials: {
    email: 'admin@montajati.com',
    password: 'admin123'
  }
};

// دالة مساعدة لإرسال الطلبات
async function makeRequest(method, endpoint, data = null, headers = {}) {
  try {
    const config = {
      method,
      url: `${CONFIG.baseURL}${endpoint}`,
      timeout: CONFIG.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers
      },
      validateStatus: () => true // قبول جميع status codes
    };
    
    if (data) {
      config.data = data;
    }
    
    console.log(`📤 ${method} ${endpoint}`);
    if (data) {
      console.log(`📋 البيانات المرسلة:`, JSON.stringify(data, null, 2));
    }
    
    const response = await axios(config);
    
    console.log(`📥 الاستجابة: ${response.status}`);
    console.log(`📄 المحتوى:`, JSON.stringify(response.data, null, 2));
    
    return {
      success: response.status >= 200 && response.status < 300,
      status: response.status,
      data: response.data,
      headers: response.headers,
      error: response.status >= 400 ? response.data : null
    };
  } catch (error) {
    console.log(`❌ خطأ في الطلب:`, error.message);
    return {
      success: false,
      error: error.message,
      details: error.response?.data || null,
      timeout: error.code === 'ECONNABORTED'
    };
  }
}

// دالة لطباعة النتائج
function printTestResult(testName, result, details = null) {
  console.log(`\n${'='.repeat(80)}`);
  console.log(`🧪 اختبار: ${testName}`);
  console.log(`${'='.repeat(80)}`);
  console.log(`✅ النتيجة: ${result.success ? 'نجح' : 'فشل'}`);
  console.log(`📊 Status Code: ${result.status || 'N/A'}`);
  
  if (result.data) {
    console.log(`📋 البيانات:`);
    console.log(JSON.stringify(result.data, null, 2));
  }
  
  if (result.error) {
    console.log(`❌ الخطأ:`);
    console.log(JSON.stringify(result.error, null, 2));
  }
  
  if (details) {
    console.log(`📝 تفاصيل إضافية:`);
    console.log(details);
  }
  
  if (result.timeout) {
    console.log(`⏰ انتهت مهلة الطلب (Timeout)`);
  }
}

async function comprehensiveOrderStatusTest() {
  console.log('🔍 ===== اختبار شامل لمشكلة تحديث حالة الطلب =====');
  console.log(`⏰ بدء الاختبار: ${new Date().toISOString()}`);
  console.log(`🌐 Backend URL: ${CONFIG.baseURL}`);
  
  try {
    // 1. اختبار الاتصال بالـ Backend
    console.log('\n1️⃣ === اختبار الاتصال بالـ Backend ===');
    const healthCheck = await makeRequest('GET', '/health');
    printTestResult('فحص صحة الخادم', healthCheck);
    
    if (!healthCheck.success) {
      console.log('❌ فشل في الاتصال بالـ Backend - توقف الاختبار');
      return;
    }
    
    // 2. اختبار API الطلبات
    console.log('\n2️⃣ === اختبار API الطلبات ===');
    const ordersAPI = await makeRequest('GET', '/api/orders?limit=5');
    printTestResult('جلب الطلبات', ordersAPI);
    
    // تحديد طلب للاختبار
    let testOrder = null;
    if (ordersAPI.success && ordersAPI.data?.data?.length > 0) {
      testOrder = ordersAPI.data.data[0];
      CONFIG.testOrderId = testOrder.id;
      console.log(`📦 طلب الاختبار المحدد: ${testOrder.id}`);
      console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    } else {
      console.log('⚠️ لا توجد طلبات للاختبار - سيتم إنشاء طلب جديد');
      
      // إنشاء طلب جديد للاختبار
      const newOrderData = {
        customer_name: 'اختبار شامل',
        customer_phone: '07700000001',
        customer_address: 'عنوان اختبار شامل',
        customer_city: 'بغداد',
        items: [
          {
            product_id: 'test_comprehensive',
            product_name: 'منتج اختبار شامل',
            quantity: 1,
            price: 2000
          }
        ],
        total_amount: 2000,
        delivery_fee: 5000,
        final_total: 7000,
        payment_method: 'نقداً عند الاستلام',
        notes: 'طلب اختبار شامل لتشخيص مشكلة تحديث الحالة'
      };
      
      const createResult = await makeRequest('POST', '/api/orders', newOrderData);
      printTestResult('إنشاء طلب اختبار', createResult);
      
      if (createResult.success) {
        testOrder = createResult.data.data;
        CONFIG.testOrderId = testOrder.id;
        console.log(`📦 تم إنشاء طلب اختبار: ${testOrder.id}`);
      } else {
        console.log('❌ فشل في إنشاء طلب اختبار - توقف الاختبار');
        return;
      }
    }
    
    // 3. اختبار تحديث حالة الطلب - الحالات المختلفة
    console.log('\n3️⃣ === اختبار تحديث حالة الطلب ===');
    
    const testStatuses = [
      { status: 'نشط', description: 'حالة نشط' },
      { status: 'قيد التحضير', description: 'حالة قيد التحضير' },
      { status: 'جاهز للتوصيل', description: 'حالة جاهز للتوصيل' },
      { status: '3', description: 'حالة برقم 3' },
      { status: 'قيد التوصيل الى الزبون (في عهدة المندوب)', description: 'حالة التوصيل الكاملة' },
      { status: 'تم التسليم للزبون', description: 'حالة التسليم' }
    ];
    
    for (const testStatus of testStatuses) {
      console.log(`\n🧪 اختبار: ${testStatus.description}`);
      
      const updateData = {
        status: testStatus.status,
        notes: `اختبار شامل - ${testStatus.description}`,
        changedBy: 'comprehensive_test'
      };
      
      const updateResult = await makeRequest('PUT', `/api/orders/${CONFIG.testOrderId}/status`, updateData);
      printTestResult(`تحديث الحالة إلى: ${testStatus.status}`, updateResult);
      
      // انتظار قصير بين الاختبارات
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // التحقق من التحديث
      const verifyResult = await makeRequest('GET', `/api/orders/${CONFIG.testOrderId}`);
      if (verifyResult.success) {
        const currentStatus = verifyResult.data.data?.status;
        console.log(`📊 الحالة بعد التحديث: "${currentStatus}"`);
        console.log(`✅ تم التحديث: ${currentStatus === testStatus.status ? 'نعم' : 'لا'}`);
      }
    }
    
    // 4. اختبار الحالات الخاطئة
    console.log('\n4️⃣ === اختبار الحالات الخاطئة ===');
    
    const invalidTests = [
      { data: {}, description: 'بيانات فارغة' },
      { data: { status: '' }, description: 'حالة فارغة' },
      { data: { status: null }, description: 'حالة null' },
      { data: { status: 'حالة_غير_موجودة' }, description: 'حالة غير صحيحة' }
    ];
    
    for (const invalidTest of invalidTests) {
      console.log(`\n🧪 اختبار خطأ: ${invalidTest.description}`);
      const result = await makeRequest('PUT', `/api/orders/${CONFIG.testOrderId}/status`, invalidTest.data);
      printTestResult(`اختبار ${invalidTest.description}`, result);
    }
    
    // 5. اختبار طلب غير موجود
    console.log('\n5️⃣ === اختبار طلب غير موجود ===');
    const nonExistentResult = await makeRequest('PUT', '/api/orders/non_existent_order_123/status', {
      status: 'نشط',
      notes: 'اختبار طلب غير موجود'
    });
    printTestResult('اختبار طلب غير موجود', nonExistentResult);
    
    // 6. اختبار الأداء والـ Timeout
    console.log('\n6️⃣ === اختبار الأداء والـ Timeout ===');
    
    const startTime = Date.now();
    const performanceResult = await makeRequest('PUT', `/api/orders/${CONFIG.testOrderId}/status`, {
      status: 'نشط',
      notes: 'اختبار الأداء',
      changedBy: 'performance_test'
    });
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    
    printTestResult('اختبار الأداء', performanceResult, `وقت الاستجابة: ${responseTime}ms`);
    
    if (responseTime > 30000) {
      console.log('⚠️ تحذير: وقت الاستجابة طويل جداً (أكثر من 30 ثانية)');
    }
    
    // 7. تحليل النتائج النهائية
    console.log('\n7️⃣ === تحليل النتائج النهائية ===');
    console.log('📋 ملخص الاختبارات:');
    console.log('   ✅ اختبار الاتصال: ' + (healthCheck.success ? 'نجح' : 'فشل'));
    console.log('   ✅ اختبار جلب الطلبات: ' + (ordersAPI.success ? 'نجح' : 'فشل'));
    console.log('   ✅ اختبار تحديث الحالة: راجع النتائج أعلاه');
    console.log(`   ⏱️ متوسط وقت الاستجابة: ${responseTime}ms`);
    
    console.log('\n🎯 === التوصيات ===');
    if (!healthCheck.success) {
      console.log('❌ مشكلة في الاتصال بالـ Backend');
    }
    if (responseTime > 10000) {
      console.log('⚠️ وقت الاستجابة بطيء - قد تحتاج لزيادة timeout');
    }
    
    console.log('\n🏁 === انتهاء الاختبار الشامل ===');
    console.log(`⏰ وقت الانتهاء: ${new Date().toISOString()}`);
    
  } catch (error) {
    console.error('❌ خطأ عام في الاختبار:', error.message);
    console.error('📋 تفاصيل الخطأ:', error);
  }
}

// تشغيل الاختبار الشامل
if (require.main === module) {
  comprehensiveOrderStatusTest();
}

module.exports = { comprehensiveOrderStatusTest, makeRequest, CONFIG };
