const axios = require('axios');

async function debugRealIssue() {
  console.log('🔍 === تشخيص المشكلة الحقيقية ===\n');
  console.log('🎯 الهدف: معرفة لماذا الطلبات لا تصل للوسيط رغم كل الإصلاحات\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. إنشاء طلب جديد للاختبار
    console.log('1️⃣ === إنشاء طلب جديد للاختبار ===');
    
    const newOrderData = {
      customer_name: 'اختبار المشكلة الحقيقية',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - اختبار المشكلة الحقيقية',
      province: 'بغداد',
      city: 'الكرخ',
      subtotal: 25000,
      delivery_fee: 5000,
      total: 30000,
      profit: 5000,
      profit_amount: 5000,
      status: 'active',
      user_id: 'bba1fc61-3db9-4c5f-8b19-d8689251990d',
      user_phone: '07503597589',
      order_number: `ORD-DEBUG-${Date.now()}`,
      notes: 'اختبار تشخيص المشكلة الحقيقية'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (!createResponse.data.success) {
      console.log('❌ فشل في إنشاء الطلب');
      return;
    }
    
    const orderId = createResponse.data.data.id;
    console.log(`✅ تم إنشاء الطلب: ${orderId}`);
    
    // 2. تحديث الحالة مع مراقبة مفصلة
    console.log('\n2️⃣ === تحديث الحالة مع مراقبة مفصلة ===');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار تشخيص المشكلة الحقيقية',
      changedBy: 'debug_test'
    };
    
    console.log('📤 إرسال طلب تحديث الحالة...');
    console.log('📋 البيانات المرسلة:', JSON.stringify(updateData, null, 2));
    
    const updateStartTime = Date.now();
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${orderId}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 120000 // دقيقتين
      }
    );
    
    const updateTime = Date.now() - updateStartTime;
    
    console.log(`📥 استجابة تحديث الحالة (خلال ${updateTime}ms):`);
    console.log(`   Status: ${updateResponse.status}`);
    console.log(`   Success: ${updateResponse.data.success}`);
    console.log(`   Message: ${updateResponse.data.message}`);
    console.log(`   Full Response:`, JSON.stringify(updateResponse.data, null, 2));
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      
      // 3. مراقبة مكثفة للطلب
      console.log('\n3️⃣ === مراقبة مكثفة للطلب ===');
      
      const checkIntervals = [2, 5, 10, 15, 30, 60, 120];
      
      for (const seconds of checkIntervals) {
        console.log(`\n⏳ فحص بعد ${seconds} ثانية...`);
        await new Promise(resolve => setTimeout(resolve, seconds * 1000));
        
        try {
          const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
          const currentOrder = ordersResponse.data.data.find(o => o.id === orderId);
          
          if (currentOrder) {
            console.log(`📋 حالة الطلب بعد ${seconds} ثانية:`);
            console.log(`   📊 الحالة: ${currentOrder.status}`);
            console.log(`   🆔 معرف الوسيط: ${currentOrder.waseet_order_id || 'غير محدد'}`);
            console.log(`   📦 حالة الوسيط: ${currentOrder.waseet_status || 'غير محدد'}`);
            console.log(`   🔄 آخر تحديث: ${currentOrder.updated_at}`);
            
            // فحص بيانات الوسيط
            if (currentOrder.waseet_data) {
              try {
                const waseetData = typeof currentOrder.waseet_data === 'string' 
                  ? JSON.parse(currentOrder.waseet_data) 
                  : currentOrder.waseet_data;
                console.log(`   📋 بيانات الوسيط:`, JSON.stringify(waseetData, null, 2));
              } catch (e) {
                console.log(`   📋 بيانات الوسيط (خام): ${currentOrder.waseet_data}`);
              }
            }
            
            // تحليل الحالة
            if (currentOrder.waseet_order_id && currentOrder.waseet_order_id !== 'null') {
              console.log(`🎉 نجح! تم إرسال الطلب للوسيط - QR ID: ${currentOrder.waseet_order_id}`);
              break;
            } else if (currentOrder.waseet_status === 'pending') {
              console.log(`⏳ الطلب في حالة pending - لا يزال قيد المعالجة`);
            } else if (currentOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
              console.log(`❌ فشل في إرسال الطلب للوسيط`);
              
              // محاولة إرسال يدوي
              console.log(`🔧 محاولة إرسال يدوي...`);
              await tryManualSend(baseURL, orderId);
              break;
            } else if (!currentOrder.waseet_status) {
              console.log(`❓ لم يتم محاولة إرسال الطلب للوسيط أصلاً`);
              console.log(`🔍 هذا يعني أن هناك مشكلة في الكود - النظام لم يحاول الإرسال`);
              
              // فحص أعمق للمشكلة
              await deepDiagnosis(baseURL, orderId);
              break;
            }
          } else {
            console.log(`❌ لم يتم العثور على الطلب ${orderId}`);
          }
          
        } catch (error) {
          console.log(`❌ خطأ في فحص الطلب: ${error.message}`);
        }
      }
      
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('🔍 المشكلة في نظام تحديث الحالات نفسه');
    }
    
  } catch (error) {
    console.error('❌ خطأ في تشخيص المشكلة:', error.message);
    if (error.response) {
      console.error('📋 Response Status:', error.response.status);
      console.error('📋 Response Data:', error.response.data);
    }
  }
}

async function tryManualSend(baseURL, orderId) {
  try {
    console.log(`🔧 محاولة إرسال يدوي للطلب ${orderId}...`);
    
    const manualSendResponse = await axios.post(`${baseURL}/api/orders/${orderId}/send-to-waseet`, {}, {
      timeout: 60000,
      validateStatus: () => true
    });
    
    console.log(`📊 نتيجة الإرسال اليدوي:`);
    console.log(`   Status: ${manualSendResponse.status}`);
    console.log(`   Success: ${manualSendResponse.data?.success}`);
    console.log(`   Response:`, JSON.stringify(manualSendResponse.data, null, 2));
    
    if (manualSendResponse.data?.success) {
      console.log(`✅ نجح الإرسال اليدوي - QR ID: ${manualSendResponse.data.data?.qrId}`);
      console.log(`🔍 المشكلة: النظام التلقائي لا يعمل، لكن الإرسال اليدوي يعمل`);
    } else {
      console.log(`❌ فشل الإرسال اليدوي أيضاً`);
      console.log(`🔍 المشكلة: مشكلة أساسية في نظام الوسيط`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في الإرسال اليدوي: ${error.message}`);
  }
}

async function deepDiagnosis(baseURL, orderId) {
  console.log('\n🔍 === تشخيص عميق للمشكلة ===');
  
  try {
    // فحص خدمة المزامنة
    console.log('1. فحص خدمة المزامنة...');
    
    try {
      const syncResponse = await axios.get(`${baseURL}/api/sync/status`, { 
        timeout: 10000,
        validateStatus: () => true 
      });
      
      if (syncResponse.status === 200) {
        console.log('   ✅ خدمة المزامنة متاحة');
        console.log('   📋 حالة الخدمة:', syncResponse.data);
      } else {
        console.log(`   ❌ خدمة المزامنة تعطي status: ${syncResponse.status}`);
        console.log(`   🔍 هذا قد يكون سبب المشكلة`);
      }
    } catch (error) {
      console.log(`   ❌ خطأ في خدمة المزامنة: ${error.message}`);
      console.log(`   🔍 هذا قد يكون سبب المشكلة`);
    }
    
    // فحص اتصال الوسيط
    console.log('\n2. فحص اتصال الوسيط...');
    
    try {
      const waseetResponse = await axios.post(`${baseURL}/api/waseet/test-connection`, {}, { 
        timeout: 15000,
        validateStatus: () => true 
      });
      
      console.log(`   📊 Status: ${waseetResponse.status}`);
      console.log(`   📋 Response:`, JSON.stringify(waseetResponse.data, null, 2));
      
      if (waseetResponse.status === 200 && waseetResponse.data?.success) {
        console.log('   ✅ اتصال الوسيط يعمل');
      } else {
        console.log(`   ❌ مشكلة في اتصال الوسيط`);
        console.log(`   🔍 هذا قد يكون سبب المشكلة`);
      }
    } catch (error) {
      console.log(`   ❌ خطأ في اتصال الوسيط: ${error.message}`);
      console.log(`   🔍 هذا قد يكون سبب المشكلة`);
    }
    
    // فحص متغيرات البيئة
    console.log('\n3. فحص متغيرات البيئة...');
    
    try {
      const envResponse = await axios.get(`${baseURL}/api/debug/env`, { 
        timeout: 10000,
        validateStatus: () => true 
      });
      
      if (envResponse.status === 200) {
        console.log('   ✅ متغيرات البيئة متاحة');
        console.log('   📋 المتغيرات:', envResponse.data);
      } else {
        console.log(`   ❌ مشكلة في متغيرات البيئة - Status: ${envResponse.status}`);
      }
    } catch (error) {
      console.log(`   ❌ خطأ في فحص متغيرات البيئة: ${error.message}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في التشخيص العميق: ${error.message}`);
  }
}

debugRealIssue();
