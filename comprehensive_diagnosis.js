const axios = require('axios');

async function comprehensiveDiagnosis() {
  console.log('🔍 === تشخيص شامل للمشكلة ===\n');
  console.log('🎯 تحليل مفصل لمعرفة سبب عدم إضافة الطلبات للوسيط\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. فحص آخر الطلبات
    console.log('1️⃣ === فحص آخر الطلبات ===');
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const allOrders = ordersResponse.data.data;
    
    console.log(`📊 إجمالي الطلبات: ${allOrders.length}`);
    
    // البحث عن الطلبات في حالة التوصيل
    const deliveryOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    console.log(`📦 طلبات في حالة التوصيل: ${deliveryOrders.length}`);
    
    if (deliveryOrders.length > 0) {
      console.log('\n📋 تفاصيل طلبات التوصيل:');
      
      deliveryOrders.slice(0, 5).forEach((order, index) => {
        console.log(`\n   ${index + 1}. طلب: ${order.id}`);
        console.log(`      👤 العميل: ${order.customer_name}`);
        console.log(`      📅 تاريخ الإنشاء: ${order.created_at}`);
        console.log(`      📅 آخر تحديث: ${order.updated_at}`);
        console.log(`      🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
        console.log(`      📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        
        if (order.waseet_data) {
          try {
            const waseetData = JSON.parse(order.waseet_data);
            if (waseetData.error) {
              console.log(`      ❌ خطأ الوسيط: ${waseetData.error}`);
            }
            if (waseetData.lastAttempt) {
              console.log(`      🕐 آخر محاولة: ${waseetData.lastAttempt}`);
            }
          } catch (e) {
            console.log(`      📋 بيانات الوسيط (خام): ${order.waseet_data.substring(0, 100)}...`);
          }
        }
      });
      
      // فحص الطلبات بدون معرف وسيط
      const ordersWithoutWaseet = deliveryOrders.filter(order => 
        !order.waseet_order_id || order.waseet_order_id === 'null'
      );
      
      console.log(`\n❌ طلبات بدون معرف وسيط: ${ordersWithoutWaseet.length}`);
      
      if (ordersWithoutWaseet.length > 0) {
        console.log('\n🔍 === تحليل الطلبات المشكلة ===');
        
        const latestProblemOrder = ordersWithoutWaseet[0];
        console.log(`\n📦 آخر طلب مشكلة: ${latestProblemOrder.id}`);
        console.log(`   👤 العميل: ${latestProblemOrder.customer_name}`);
        console.log(`   📅 آخر تحديث: ${latestProblemOrder.updated_at}`);
        console.log(`   📦 حالة الوسيط: ${latestProblemOrder.waseet_status || 'غير محدد'}`);
        
        // محاولة إرسال يدوي للطلب المشكلة
        console.log('\n🔧 === محاولة إرسال يدوي ===');
        
        try {
          const manualSendResponse = await axios.post(
            `${baseURL}/api/orders/${latestProblemOrder.id}/send-to-waseet`, 
            {}, 
            { 
              timeout: 60000,
              validateStatus: () => true 
            }
          );
          
          console.log(`📊 نتيجة الإرسال اليدوي:`);
          console.log(`   Status: ${manualSendResponse.status}`);
          console.log(`   Success: ${manualSendResponse.data?.success}`);
          console.log(`   Message: ${manualSendResponse.data?.message}`);
          console.log(`   Data:`, JSON.stringify(manualSendResponse.data, null, 2));
          
          if (manualSendResponse.data?.success) {
            console.log(`✅ الإرسال اليدوي نجح - QR ID: ${manualSendResponse.data.data?.qrId}`);
            console.log(`🔍 المشكلة: النظام التلقائي لا يعمل، لكن الإرسال اليدوي يعمل`);
          } else {
            console.log(`❌ الإرسال اليدوي فشل أيضاً`);
            console.log(`🔍 المشكلة: مشكلة أساسية في نظام الوسيط`);
          }
          
        } catch (error) {
          console.log(`❌ خطأ في الإرسال اليدوي: ${error.message}`);
        }
      }
    } else {
      console.log('⚠️ لا توجد طلبات في حالة التوصيل');
    }
    
    // 2. فحص خدمة المزامنة
    console.log('\n2️⃣ === فحص خدمة المزامنة ===');
    
    try {
      const syncResponse = await axios.get(`${baseURL}/api/sync/status`, { 
        timeout: 10000,
        validateStatus: () => true 
      });
      
      console.log(`📊 حالة خدمة المزامنة:`);
      console.log(`   Status: ${syncResponse.status}`);
      console.log(`   Data:`, JSON.stringify(syncResponse.data, null, 2));
      
      if (syncResponse.status === 200) {
        console.log('✅ خدمة المزامنة متاحة');
      } else {
        console.log('❌ مشكلة في خدمة المزامنة');
      }
      
    } catch (error) {
      console.log(`❌ خطأ في فحص خدمة المزامنة: ${error.message}`);
      console.log(`🔍 هذا قد يكون سبب المشكلة - خدمة المزامنة لا تعمل`);
    }
    
    // 3. فحص اتصال الوسيط
    console.log('\n3️⃣ === فحص اتصال الوسيط ===');
    
    try {
      const waseetResponse = await axios.post(`${baseURL}/api/waseet/test-connection`, {}, { 
        timeout: 15000,
        validateStatus: () => true 
      });
      
      console.log(`📊 اختبار اتصال الوسيط:`);
      console.log(`   Status: ${waseetResponse.status}`);
      console.log(`   Data:`, JSON.stringify(waseetResponse.data, null, 2));
      
      if (waseetResponse.status === 200 && waseetResponse.data?.success) {
        console.log('✅ اتصال الوسيط يعمل');
      } else {
        console.log('❌ مشكلة في اتصال الوسيط');
      }
      
    } catch (error) {
      console.log(`❌ خطأ في اختبار اتصال الوسيط: ${error.message}`);
    }
    
    // 4. إنشاء طلب اختبار جديد
    console.log('\n4️⃣ === إنشاء طلب اختبار جديد ===');
    
    const testOrderData = {
      customer_name: 'تشخيص شامل للمشكلة',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - تشخيص شامل',
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
      order_number: `ORD-DIAGNOSIS-${Date.now()}`,
      notes: 'تشخيص شامل للمشكلة'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, testOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (createResponse.data.success) {
      const testOrderId = createResponse.data.data.id;
      console.log(`✅ تم إنشاء طلب الاختبار: ${testOrderId}`);
      
      // تحديث الحالة مع مراقبة مفصلة
      console.log('\n📤 تحديث حالة طلب الاختبار...');
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'تشخيص شامل - اختبار النظام التلقائي',
        changedBy: 'comprehensive_diagnosis'
      };
      
      const updateResponse = await axios.put(
        `${baseURL}/api/orders/${testOrderId}/status`,
        updateData,
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 60000
        }
      );
      
      console.log(`📥 نتيجة تحديث الحالة:`);
      console.log(`   Status: ${updateResponse.status}`);
      console.log(`   Success: ${updateResponse.data.success}`);
      console.log(`   Message: ${updateResponse.data.message}`);
      
      if (updateResponse.data.success) {
        console.log('✅ تم تحديث الحالة بنجاح');
        
        // مراقبة مكثفة للطلب
        console.log('\n👀 === مراقبة مكثفة للطلب ===');
        
        const checkIntervals = [5, 10, 20, 30];
        
        for (const seconds of checkIntervals) {
          console.log(`\n⏳ فحص بعد ${seconds} ثانية...`);
          await new Promise(resolve => setTimeout(resolve, seconds * 1000));
          
          const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
          const currentOrder = ordersResponse.data.data.find(o => o.id === testOrderId);
          
          if (currentOrder) {
            console.log(`📋 حالة الطلب:`);
            console.log(`   📊 الحالة: ${currentOrder.status}`);
            console.log(`   🆔 معرف الوسيط: ${currentOrder.waseet_order_id || 'غير محدد'}`);
            console.log(`   📦 حالة الوسيط: ${currentOrder.waseet_status || 'غير محدد'}`);
            
            if (currentOrder.waseet_order_id && currentOrder.waseet_order_id !== 'null') {
              console.log(`🎉 نجح! تم إرسال الطلب للوسيط - QR ID: ${currentOrder.waseet_order_id}`);
              break;
            } else if (currentOrder.waseet_status === 'pending') {
              console.log(`⏳ الطلب في حالة pending - لا يزال قيد المعالجة`);
            } else if (currentOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
              console.log(`❌ فشل في إرسال الطلب للوسيط`);
              
              if (currentOrder.waseet_data) {
                try {
                  const waseetData = JSON.parse(currentOrder.waseet_data);
                  console.log(`🔍 تفاصيل الفشل:`, waseetData);
                } catch (e) {
                  console.log(`🔍 بيانات الفشل (خام): ${currentOrder.waseet_data}`);
                }
              }
              break;
            } else if (!currentOrder.waseet_status) {
              console.log(`❓ لم يتم محاولة إرسال الطلب للوسيط أصلاً`);
              console.log(`🔍 هذا يعني أن هناك مشكلة في الكود - النظام لم يحاول الإرسال`);
            }
          }
        }
      }
    }
    
    // 5. خلاصة التشخيص
    console.log('\n📊 === خلاصة التشخيص ===');
    
    const problemOrders = deliveryOrders.filter(order => 
      !order.waseet_order_id || order.waseet_order_id === 'null'
    );
    
    if (problemOrders.length === 0) {
      console.log('✅ جميع الطلبات في حالة التوصيل تم إرسالها للوسيط');
      console.log('🎯 لا توجد مشكلة في النظام');
    } else {
      console.log(`❌ يوجد ${problemOrders.length} طلب لم يتم إرساله للوسيط`);
      console.log('\n🔍 الأسباب المحتملة:');
      console.log('   1. خدمة المزامنة لا تعمل');
      console.log('   2. مشكلة في اتصال الوسيط');
      console.log('   3. خطأ في البيانات المرسلة');
      console.log('   4. مشكلة في تهيئة الخدمات');
      console.log('   5. خطأ في الكود');
    }
    
  } catch (error) {
    console.error('❌ خطأ في التشخيص الشامل:', error.message);
  }
}

comprehensiveDiagnosis();
