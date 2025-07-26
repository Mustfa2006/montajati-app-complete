const axios = require('axios');

async function comprehensiveSystemAnalysis() {
  console.log('🔍 === تحليل شامل ومفصل لنظام إرسال الطلبات للوسيط ===\n');
  console.log('🎯 الهدف: فهم المشروع بالكامل وتحديد المشكلة الحقيقية\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. تحليل تدفق العمل الكامل
    console.log('1️⃣ === تحليل تدفق العمل الكامل ===');
    await analyzeWorkflow();
    
    // 2. فحص نظام تحديث الحالات
    console.log('\n2️⃣ === فحص نظام تحديث الحالات ===');
    await analyzeStatusUpdateSystem(baseURL);
    
    // 3. فحص خدمة المزامنة
    console.log('\n3️⃣ === فحص خدمة المزامنة ===');
    await analyzeSyncService(baseURL);
    
    // 4. فحص عميل الوسيط
    console.log('\n4️⃣ === فحص عميل الوسيط ===');
    await analyzeWaseetClient(baseURL);
    
    // 5. اختبار التدفق الكامل خطوة بخطوة
    console.log('\n5️⃣ === اختبار التدفق الكامل خطوة بخطوة ===');
    await testCompleteFlow(baseURL);
    
    // 6. تحليل المشكلة المحتملة
    console.log('\n6️⃣ === تحليل المشكلة المحتملة ===');
    await analyzePotentialIssues(baseURL);
    
  } catch (error) {
    console.error('❌ خطأ في التحليل الشامل:', error.message);
  }
}

async function analyzeWorkflow() {
  console.log('📋 تحليل تدفق العمل المتوقع:');
  console.log('');
  
  console.log('🔄 === التدفق المتوقع ===');
  console.log('1. المستخدم ينشئ طلب جديد في التطبيق');
  console.log('2. المستخدم يغير حالة الطلب إلى "قيد التوصيل"');
  console.log('3. التطبيق يرسل طلب تحديث الحالة للخادم');
  console.log('4. الخادم يستلم الطلب ويحدث قاعدة البيانات');
  console.log('5. الخادم يفحص إذا كانت الحالة الجديدة تتطلب إرسال للوسيط');
  console.log('6. إذا كانت كذلك، يستدعي خدمة المزامنة');
  console.log('7. خدمة المزامنة تجهز بيانات الطلب');
  console.log('8. خدمة المزامنة ترسل الطلب لعميل الوسيط');
  console.log('9. عميل الوسيط يرسل الطلب لـ API الوسيط');
  console.log('10. الوسيط يرد بـ QR ID');
  console.log('11. الخادم يحدث قاعدة البيانات بمعرف الوسيط');
  console.log('');
  
  console.log('🔍 === النقاط الحرجة المحتملة ===');
  console.log('❓ هل التطبيق يرسل الحالة الصحيحة؟');
  console.log('❓ هل الخادم يتعرف على الحالة كحالة توصيل؟');
  console.log('❓ هل خدمة المزامنة مهيأة بشكل صحيح؟');
  console.log('❓ هل عميل الوسيط يعمل؟');
  console.log('❓ هل بيانات المصادقة مع الوسيط صحيحة؟');
  console.log('❓ هل بيانات الطلب كاملة ومناسبة للوسيط؟');
}

async function analyzeStatusUpdateSystem(baseURL) {
  try {
    console.log('📊 تحليل نظام تحديث الحالات...');
    
    // فحص الحالات المدعومة في الخادم
    console.log('\n🔍 الحالات المدعومة للإرسال للوسيط (من الكود):');
    const supportedStatuses = [
      'قيد التوصيل',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'قيد التوصيل الى الزبون',
      'في عهدة المندوب',
      'قيد التوصيل للزبون',
      'shipping',
      'shipped'
    ];
    
    supportedStatuses.forEach((status, index) => {
      console.log(`   ${index + 1}. "${status}"`);
    });
    
    // فحص الطلبات الحالية لمعرفة الحالات المستخدمة فعلياً
    console.log('\n📋 فحص الحالات المستخدمة فعلياً في قاعدة البيانات...');
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const orders = ordersResponse.data.data;
    
    const actualStatuses = new Set();
    orders.forEach(order => {
      if (order.status) {
        actualStatuses.add(order.status);
      }
    });
    
    console.log('\n📊 الحالات الموجودة فعلياً في قاعدة البيانات:');
    Array.from(actualStatuses).forEach((status, index) => {
      const isSupported = supportedStatuses.includes(status);
      console.log(`   ${index + 1}. "${status}" ${isSupported ? '✅' : '❌'}`);
    });
    
    // تحليل الطلبات في حالة توصيل
    const deliveryOrders = orders.filter(order => 
      supportedStatuses.includes(order.status)
    );
    
    console.log(`\n📦 طلبات في حالة توصيل: ${deliveryOrders.length}`);
    
    const withWaseetId = deliveryOrders.filter(order => 
      order.waseet_order_id && order.waseet_order_id !== 'null'
    );
    
    const withoutWaseetId = deliveryOrders.filter(order => 
      !order.waseet_order_id || order.waseet_order_id === 'null'
    );
    
    console.log(`✅ مع معرف وسيط: ${withWaseetId.length}`);
    console.log(`❌ بدون معرف وسيط: ${withoutWaseetId.length}`);
    console.log(`📈 معدل النجاح: ${((withWaseetId.length / deliveryOrders.length) * 100).toFixed(1)}%`);
    
    if (withoutWaseetId.length > 0) {
      console.log('\n⚠️ طلبات في حالة توصيل لكن بدون معرف وسيط:');
      withoutWaseetId.slice(0, 5).forEach(order => {
        console.log(`   📦 ${order.id} - ${order.customer_name}`);
        console.log(`      📊 الحالة: ${order.status}`);
        console.log(`      📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        console.log(`      🕐 آخر تحديث: ${order.updated_at}`);
      });
    }
    
  } catch (error) {
    console.log(`❌ خطأ في تحليل نظام تحديث الحالات: ${error.message}`);
  }
}

async function analyzeSyncService(baseURL) {
  try {
    console.log('🔄 تحليل خدمة المزامنة...');
    
    // فحص حالة خدمة المزامنة
    console.log('\n🔍 فحص حالة خدمة المزامنة:');
    
    try {
      const syncResponse = await axios.get(`${baseURL}/api/sync/status`, { 
        timeout: 10000,
        validateStatus: () => true 
      });
      
      if (syncResponse.status === 200) {
        console.log('✅ خدمة المزامنة متاحة');
        console.log('📋 حالة الخدمة:', syncResponse.data);
      } else if (syncResponse.status === 404) {
        console.log('⚠️ endpoint خدمة المزامنة غير موجود');
      } else {
        console.log(`❌ خدمة المزامنة تعطي status: ${syncResponse.status}`);
      }
    } catch (error) {
      console.log(`❌ خطأ في الوصول لخدمة المزامنة: ${error.message}`);
    }
    
    // اختبار إرسال طلب للوسيط يدوياً
    console.log('\n🧪 اختبار إرسال طلب للوسيط يدوياً...');
    
    // البحث عن طلب مناسب للاختبار
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const orders = ordersResponse.data.data;
    
    const testOrder = orders.find(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      (!order.waseet_order_id || order.waseet_order_id === 'null')
    );
    
    if (testOrder) {
      console.log(`📦 طلب الاختبار: ${testOrder.id}`);
      
      try {
        const manualSendResponse = await axios.post(`${baseURL}/api/orders/${testOrder.id}/send-to-waseet`, {}, {
          timeout: 30000,
          validateStatus: () => true
        });
        
        console.log(`📊 نتيجة الإرسال اليدوي:`);
        console.log(`   Status: ${manualSendResponse.status}`);
        console.log(`   Success: ${manualSendResponse.data?.success}`);
        
        if (manualSendResponse.data?.success) {
          console.log(`   🆔 QR ID: ${manualSendResponse.data.data?.qrId}`);
          console.log('✅ الإرسال اليدوي يعمل - المشكلة في التشغيل التلقائي');
        } else {
          console.log(`   ❌ الإرسال اليدوي فشل: ${manualSendResponse.data?.error}`);
          console.log('🔍 المشكلة في خدمة المزامنة أو عميل الوسيط');
        }
        
      } catch (error) {
        console.log(`❌ خطأ في الإرسال اليدوي: ${error.message}`);
      }
    } else {
      console.log('⚠️ لم أجد طلب مناسب لاختبار الإرسال اليدوي');
    }
    
  } catch (error) {
    console.log(`❌ خطأ في تحليل خدمة المزامنة: ${error.message}`);
  }
}

async function analyzeWaseetClient(baseURL) {
  try {
    console.log('🔌 تحليل عميل الوسيط...');
    
    // فحص اتصال الوسيط
    console.log('\n🔍 فحص اتصال الوسيط:');
    
    try {
      const waseetResponse = await axios.post(`${baseURL}/api/waseet/test-connection`, {}, { 
        timeout: 15000,
        validateStatus: () => true 
      });
      
      console.log(`📊 نتيجة اختبار الاتصال:`);
      console.log(`   Status: ${waseetResponse.status}`);
      
      if (waseetResponse.status === 200) {
        console.log(`   Success: ${waseetResponse.data?.success}`);
        if (waseetResponse.data?.success) {
          console.log('✅ اتصال الوسيط يعمل بشكل صحيح');
        } else {
          console.log(`   ❌ فشل الاتصال: ${waseetResponse.data?.error}`);
        }
      } else if (waseetResponse.status === 404) {
        console.log('⚠️ endpoint اختبار الوسيط غير موجود');
      } else {
        console.log(`❌ مشكلة في اختبار الوسيط - Status: ${waseetResponse.status}`);
      }
      
    } catch (error) {
      console.log(`❌ خطأ في اختبار اتصال الوسيط: ${error.message}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في تحليل عميل الوسيط: ${error.message}`);
  }
}

async function testCompleteFlow(baseURL) {
  try {
    console.log('🧪 اختبار التدفق الكامل خطوة بخطوة...');
    
    // إنشاء طلب جديد
    console.log('\n📝 الخطوة 1: إنشاء طلب جديد...');
    
    const newOrderData = {
      customer_name: 'اختبار التدفق الكامل',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - اختبار التدفق',
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
      order_number: `ORD-FLOW-${Date.now()}`,
      notes: 'اختبار التدفق الكامل'
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
    
    // انتظار قصير
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // الخطوة 2: تحديث حالة الطلب
    console.log('\n🔄 الخطوة 2: تحديث حالة الطلب إلى "قيد التوصيل"...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار التدفق الكامل - تحديث الحالة',
      changedBy: 'complete_flow_test'
    };
    
    console.log('📤 إرسال طلب تحديث الحالة...');
    console.log('📋 البيانات المرسلة:', JSON.stringify(updateData, null, 2));
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${orderId}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 60000
      }
    );
    
    console.log(`📥 استجابة تحديث الحالة:`);
    console.log(`   Status: ${updateResponse.status}`);
    console.log(`   Success: ${updateResponse.data.success}`);
    console.log(`   Message: ${updateResponse.data.message}`);
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      
      // الخطوة 3: مراقبة إرسال الطلب للوسيط
      console.log('\n👀 الخطوة 3: مراقبة إرسال الطلب للوسيط...');
      
      const checkIntervals = [5, 15, 30, 60];
      let waseetSuccess = false;
      
      for (const seconds of checkIntervals) {
        console.log(`\n⏳ فحص بعد ${seconds} ثانية...`);
        await new Promise(resolve => setTimeout(resolve, seconds * 1000));
        
        const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
        const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
        
        if (updatedOrder) {
          console.log(`📋 حالة الطلب:`);
          console.log(`   📊 الحالة: ${updatedOrder.status}`);
          console.log(`   🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`   📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
          
          if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
            console.log(`🎉 نجح! تم إرسال الطلب للوسيط - QR ID: ${updatedOrder.waseet_order_id}`);
            waseetSuccess = true;
            break;
          } else if (updatedOrder.waseet_status === 'pending') {
            console.log('⏳ الطلب في حالة pending - لا يزال قيد المعالجة');
          } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('❌ فشل في إرسال الطلب للوسيط');
            break;
          } else if (!updatedOrder.waseet_status) {
            console.log('❓ لم يتم محاولة إرسال الطلب أصلاً');
          }
        }
      }
      
      // تحليل النتيجة
      console.log('\n📊 === تحليل نتيجة التدفق الكامل ===');
      
      if (waseetSuccess) {
        console.log('🎉 التدفق الكامل نجح 100%');
        console.log('✅ النظام يعمل بشكل صحيح');
        console.log('🔍 المشكلة قد تكون في التطبيق أو في طلبات محددة');
      } else {
        console.log('❌ التدفق الكامل فشل');
        console.log('🔍 هناك مشكلة في النظام نفسه');
        
        // تحليل أعمق للمشكلة
        const finalOrdersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
        const finalOrder = finalOrdersResponse.data.data.find(o => o.id === orderId);
        
        if (finalOrder && finalOrder.waseet_data) {
          try {
            const waseetData = JSON.parse(finalOrder.waseet_data);
            console.log('📋 بيانات الوسيط:', waseetData);
            
            if (waseetData.error) {
              console.log(`🔍 خطأ محدد: ${waseetData.error}`);
            }
            
            if (waseetData.needsConfiguration) {
              console.log('🔍 المشكلة: النظام يحتاج إعداد');
            }
          } catch (e) {
            console.log('📋 بيانات الوسيط (خام):', finalOrder.waseet_data);
          }
        }
      }
      
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('🔍 المشكلة في نظام تحديث الحالات');
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار التدفق الكامل: ${error.message}`);
  }
}

async function analyzePotentialIssues(baseURL) {
  console.log('🔍 تحليل المشاكل المحتملة...');
  
  console.log('\n📋 === المشاكل المحتملة ===');
  
  console.log('\n1️⃣ مشكلة في التطبيق (Frontend):');
  console.log('   - التطبيق لا يرسل الحالة الصحيحة');
  console.log('   - مشكلة في تحويل الحالات');
  console.log('   - مشكلة في استدعاء API');
  
  console.log('\n2️⃣ مشكلة في الخادم (Backend):');
  console.log('   - الخادم لا يتعرف على الحالة كحالة توصيل');
  console.log('   - مشكلة في قائمة deliveryStatuses');
  console.log('   - مشكلة في استدعاء خدمة المزامنة');
  
  console.log('\n3️⃣ مشكلة في خدمة المزامنة:');
  console.log('   - الخدمة غير مهيأة بشكل صحيح');
  console.log('   - مشكلة في global.orderSyncService');
  console.log('   - مشكلة في معالجة البيانات');
  
  console.log('\n4️⃣ مشكلة في عميل الوسيط:');
  console.log('   - بيانات المصادقة مفقودة أو خاطئة');
  console.log('   - مشكلة في API الوسيط');
  console.log('   - مشكلة في تنسيق البيانات');
  
  console.log('\n5️⃣ مشكلة في البيانات:');
  console.log('   - بيانات الطلب ناقصة');
  console.log('   - تنسيق البيانات غير صحيح');
  console.log('   - مشكلة في قاعدة البيانات');
  
  console.log('\n🎯 === التوصيات للحل ===');
  console.log('1. فحص logs الخادم بالتفصيل');
  console.log('2. اختبار كل خطوة منفصلة');
  console.log('3. التحقق من بيانات المصادقة');
  console.log('4. فحص تنسيق البيانات المرسلة');
  console.log('5. اختبار الإرسال اليدوي');
}

comprehensiveSystemAnalysis();
