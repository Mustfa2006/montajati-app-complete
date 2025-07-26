const axios = require('axios');

async function comprehensiveDeepDiagnosis() {
  console.log('🔍 === فحص شامل ومفصل للنظام ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. فحص حالة الخادم
    console.log('1️⃣ === فحص حالة الخادم ===');
    await checkServerHealth(baseURL);
    
    // 2. فحص خدمة المزامنة
    console.log('\n2️⃣ === فحص خدمة المزامنة ===');
    await checkSyncService(baseURL);
    
    // 3. فحص اتصال الوسيط
    console.log('\n3️⃣ === فحص اتصال الوسيط ===');
    await checkWaseetConnection(baseURL);
    
    // 4. فحص الطلبات الحالية
    console.log('\n4️⃣ === فحص الطلبات الحالية ===');
    await analyzeCurrentOrders(baseURL);
    
    // 5. اختبار تحديث حالة طلب
    console.log('\n5️⃣ === اختبار تحديث حالة طلب ===');
    await testOrderStatusUpdate(baseURL);
    
    // 6. فحص logs الخادم
    console.log('\n6️⃣ === فحص logs الخادم ===');
    await checkServerLogs(baseURL);
    
    // 7. اختبار إنشاء طلب جديد كامل
    console.log('\n7️⃣ === اختبار إنشاء طلب جديد كامل ===');
    await testCompleteNewOrder(baseURL);
    
  } catch (error) {
    console.error('❌ خطأ في الفحص الشامل:', error.message);
  }
}

async function checkServerHealth(baseURL) {
  try {
    const response = await axios.get(`${baseURL}/`, { timeout: 10000 });
    console.log(`✅ الخادم يعمل - Status: ${response.status}`);
    
    // فحص endpoints مهمة
    const endpoints = [
      '/api/orders',
      '/api/orders/test/status-update'
    ];
    
    for (const endpoint of endpoints) {
      try {
        const endpointResponse = await axios.get(`${baseURL}${endpoint}`, { 
          timeout: 10000,
          validateStatus: (status) => status < 500
        });
        console.log(`✅ ${endpoint} - Status: ${endpointResponse.status}`);
      } catch (error) {
        console.log(`❌ ${endpoint} - خطأ: ${error.message}`);
      }
    }
    
  } catch (error) {
    console.log(`❌ الخادم لا يستجيب: ${error.message}`);
  }
}

async function checkSyncService(baseURL) {
  try {
    // محاولة الوصول لخدمة المزامنة
    const response = await axios.get(`${baseURL}/api/sync/status`, { 
      timeout: 10000,
      validateStatus: () => true 
    });
    
    if (response.status === 200) {
      console.log('✅ خدمة المزامنة تعمل');
      console.log('📋 حالة الخدمة:', response.data);
    } else if (response.status === 404) {
      console.log('⚠️ endpoint خدمة المزامنة غير موجود - قد يكون طبيعي');
    } else {
      console.log(`⚠️ خدمة المزامنة تعطي status: ${response.status}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في فحص خدمة المزامنة: ${error.message}`);
  }
}

async function checkWaseetConnection(baseURL) {
  try {
    // محاولة اختبار اتصال الوسيط
    const response = await axios.post(`${baseURL}/api/waseet/test-connection`, {}, { 
      timeout: 15000,
      validateStatus: () => true 
    });
    
    if (response.status === 200) {
      console.log('✅ اتصال الوسيط يعمل');
      console.log('📋 نتيجة الاختبار:', response.data);
    } else if (response.status === 404) {
      console.log('⚠️ endpoint اختبار الوسيط غير موجود');
    } else {
      console.log(`⚠️ اختبار الوسيط يعطي status: ${response.status}`);
      console.log('📋 الاستجابة:', response.data);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في فحص اتصال الوسيط: ${error.message}`);
  }
}

async function analyzeCurrentOrders(baseURL) {
  try {
    const response = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const orders = response.data.data;
    
    console.log(`📊 إجمالي الطلبات: ${orders.length}`);
    
    // تحليل الحالات
    const statusCounts = {};
    const waseetStats = {
      withWaseetId: 0,
      withoutWaseetId: 0,
      deliveryStatusWithoutWaseet: 0
    };
    
    const deliveryStatuses = [
      'قيد التوصيل',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'قيد التوصيل الى الزبون',
      'في عهدة المندوب',
      'قيد التوصيل للزبون',
      'shipping',
      'shipped',
      'in_delivery'
    ];
    
    orders.forEach(order => {
      // إحصائيات الحالات
      statusCounts[order.status] = (statusCounts[order.status] || 0) + 1;
      
      // إحصائيات الوسيط
      if (order.waseet_order_id && order.waseet_order_id !== 'null') {
        waseetStats.withWaseetId++;
      } else {
        waseetStats.withoutWaseetId++;
        
        // فحص إذا كان في حالة توصيل لكن بدون وسيط
        if (deliveryStatuses.includes(order.status)) {
          waseetStats.deliveryStatusWithoutWaseet++;
        }
      }
    });
    
    console.log('\n📊 إحصائيات الحالات:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   ${status}: ${count} طلب`);
    });
    
    console.log('\n📊 إحصائيات الوسيط:');
    console.log(`   ✅ مع معرف وسيط: ${waseetStats.withWaseetId}`);
    console.log(`   ❌ بدون معرف وسيط: ${waseetStats.withoutWaseetId}`);
    console.log(`   ⚠️ في حالة توصيل لكن بدون وسيط: ${waseetStats.deliveryStatusWithoutWaseet}`);
    
    // عرض الطلبات المشكوك فيها
    if (waseetStats.deliveryStatusWithoutWaseet > 0) {
      console.log('\n⚠️ الطلبات المشكوك فيها:');
      orders
        .filter(order => deliveryStatuses.includes(order.status) && (!order.waseet_order_id || order.waseet_order_id === 'null'))
        .slice(0, 5) // أول 5 طلبات فقط
        .forEach(order => {
          console.log(`   📦 ${order.id} - ${order.customer_name} - ${order.status}`);
          console.log(`      📞 ${order.primary_phone || order.customer_phone || 'لا يوجد'}`);
          console.log(`      📍 ${order.customer_address || order.delivery_address || order.notes || 'لا يوجد عنوان'}`);
          console.log(`      🕐 آخر تحديث: ${order.updated_at}`);
        });
    }
    
  } catch (error) {
    console.log(`❌ خطأ في تحليل الطلبات: ${error.message}`);
  }
}

async function testOrderStatusUpdate(baseURL) {
  try {
    // جلب طلب للاختبار
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const orders = ordersResponse.data.data;
    
    // البحث عن طلب مناسب للاختبار
    const testOrder = orders.find(order => 
      order.status !== 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      order.status !== 'تم التسليم للزبون'
    ) || orders[0];
    
    if (!testOrder) {
      console.log('❌ لم يتم العثور على طلب للاختبار');
      return;
    }
    
    console.log(`📦 طلب الاختبار: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🆔 معرف الوسيط الحالي: ${testOrder.waseet_order_id || 'غير محدد'}`);
    
    // تحديث الحالة
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار فحص شامل - تحديث تشخيصي',
      changedBy: 'comprehensive_diagnosis'
    };
    
    console.log('\n📤 إرسال طلب تحديث الحالة...');
    console.log('📋 البيانات المرسلة:', JSON.stringify(updateData, null, 2));
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${testOrder.id}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 30000
      }
    );
    
    console.log('\n📥 استجابة الخادم:');
    console.log(`📊 Status Code: ${updateResponse.status}`);
    console.log(`📊 Success: ${updateResponse.data.success}`);
    console.log(`📋 Message: ${updateResponse.data.message}`);
    console.log(`📋 Full Response:`, JSON.stringify(updateResponse.data, null, 2));
    
    if (updateResponse.data.success) {
      console.log('\n⏳ انتظار 30 ثانية للمعالجة...');
      await new Promise(resolve => setTimeout(resolve, 30000));
      
      // فحص النتيجة
      await checkUpdateResult(baseURL, testOrder.id);
    } else {
      console.log('❌ فشل في تحديث الحالة');
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار تحديث الحالة: ${error.message}`);
    if (error.response) {
      console.log(`📋 Response Status: ${error.response.status}`);
      console.log(`📋 Response Data:`, error.response.data);
    }
  }
}

async function checkUpdateResult(baseURL, orderId) {
  try {
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
    
    if (!updatedOrder) {
      console.log('❌ لم يتم العثور على الطلب بعد التحديث');
      return;
    }
    
    console.log('\n📋 نتيجة التحديث:');
    console.log(`📊 الحالة: ${updatedOrder.status}`);
    console.log(`🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
    console.log(`📋 بيانات الوسيط: ${updatedOrder.waseet_data ? 'موجودة' : 'غير موجودة'}`);
    console.log(`🕐 آخر تحديث: ${updatedOrder.updated_at}`);
    
    if (updatedOrder.waseet_data) {
      try {
        const waseetData = typeof updatedOrder.waseet_data === 'string' 
          ? JSON.parse(updatedOrder.waseet_data) 
          : updatedOrder.waseet_data;
        console.log(`📊 تفاصيل بيانات الوسيط:`, JSON.stringify(waseetData, null, 2));
      } catch (e) {
        console.log(`📊 بيانات الوسيط (خام): ${updatedOrder.waseet_data}`);
      }
    }
    
    // تحليل النتيجة
    const expectedStatus = 'قيد التوصيل الى الزبون (في عهدة المندوب)';
    
    if (updatedOrder.status === expectedStatus) {
      if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
        console.log('\n🎉 نجح الاختبار! تم تحديث الحالة وإرسال الطلب للوسيط');
        console.log(`🆔 QR ID: ${updatedOrder.waseet_order_id}`);
      } else {
        console.log('\n⚠️ تم تحديث الحالة لكن لم يتم إرسال الطلب للوسيط');
        console.log('🔍 هذا يؤكد وجود مشكلة في عملية الإرسال للوسيط');
        
        // تحليل أعمق للمشكلة
        if (updatedOrder.waseet_status === 'pending') {
          console.log('📋 السبب المحتمل: النظام يحاول لكن لم ينجح بعد');
        } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
          console.log('📋 السبب المحتمل: النظام يحاول لكن يفشل');
        } else {
          console.log('📋 السبب المحتمل: النظام لم يحاول الإرسال أصلاً');
        }
      }
    } else {
      console.log('\n❌ فشل في تحديث الحالة');
      console.log(`📊 متوقع: ${expectedStatus}`);
      console.log(`📊 فعلي: ${updatedOrder.status}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في فحص نتيجة التحديث: ${error.message}`);
  }
}

async function checkServerLogs(baseURL) {
  try {
    // محاولة الوصول للـ logs إذا كان متاح
    const response = await axios.get(`${baseURL}/api/logs/recent`, { 
      timeout: 10000,
      validateStatus: () => true 
    });
    
    if (response.status === 200) {
      console.log('✅ تم الوصول للـ logs');
      console.log('📋 آخر logs:', response.data);
    } else if (response.status === 404) {
      console.log('ℹ️ endpoint الـ logs غير متاح - طبيعي للأمان');
    } else {
      console.log(`⚠️ logs endpoint يعطي status: ${response.status}`);
    }
    
  } catch (error) {
    console.log(`ℹ️ لا يمكن الوصول للـ logs: ${error.message}`);
  }
}

async function testCompleteNewOrder(baseURL) {
  try {
    console.log('📝 إنشاء طلب اختبار جديد كامل...');
    
    const newOrderData = {
      customer_name: 'عميل فحص شامل',
      primary_phone: '07901234567',
      secondary_phone: '07709876543',
      province: 'بغداد',
      city: 'الكرخ',
      customer_address: 'بغداد - الكرخ - شارع الرئيسي - بناية رقم 123',
      delivery_address: 'بغداد - الكرخ - شارع الرئيسي - بناية رقم 123',
      notes: 'طلب اختبار للفحص الشامل',
      items: [
        {
          name: 'منتج اختبار شامل',
          quantity: 1,
          price: 30000,
          sku: 'COMPREHENSIVE_TEST_001'
        }
      ],
      subtotal: 30000,
      delivery_fee: 5000,
      total: 35000,
      status: 'active'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (createResponse.data.success) {
      const newOrderId = createResponse.data.data.id;
      console.log(`✅ تم إنشاء طلب جديد: ${newOrderId}`);
      
      // انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      // تحديث الحالة إلى قيد التوصيل
      console.log('\n📤 تحديث الطلب الجديد إلى قيد التوصيل...');
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار طلب جديد كامل - فحص شامل',
        changedBy: 'comprehensive_new_order_test'
      };
      
      const updateResponse = await axios.put(
        `${baseURL}/api/orders/${newOrderId}/status`,
        updateData,
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );
      
      if (updateResponse.data.success) {
        console.log('✅ تم تحديث حالة الطلب الجديد');
        
        // انتظار للمعالجة
        console.log('⏳ انتظار 30 ثانية لمعالجة الطلب الجديد...');
        await new Promise(resolve => setTimeout(resolve, 30000));
        
        // فحص النتيجة النهائية
        await checkUpdateResult(baseURL, newOrderId);
        
      } else {
        console.log('❌ فشل في تحديث حالة الطلب الجديد');
      }
      
    } else {
      console.log('❌ فشل في إنشاء طلب جديد');
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار الطلب الجديد الكامل: ${error.message}`);
    if (error.response) {
      console.log(`📋 Response:`, error.response.data);
    }
  }
}

// تشغيل الفحص الشامل
comprehensiveDeepDiagnosis();
