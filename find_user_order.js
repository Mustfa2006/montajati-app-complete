const axios = require('axios');

async function findUserOrder() {
  console.log('🔍 === البحث عن طلب المستخدم ===\n');
  console.log('🎯 البحث عن الطلب الذي أنشأه المستخدم وغير حالته\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // جلب جميع الطلبات
    const response = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const allOrders = response.data.data;
    
    console.log(`📊 إجمالي الطلبات: ${allOrders.length}`);
    
    // ترتيب الطلبات حسب تاريخ الإنشاء (الأحدث أولاً)
    const sortedOrders = allOrders.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    
    // البحث عن الطلبات الحديثة جداً (آخر ساعة)
    const veryRecentOrders = sortedOrders.filter(order => {
      const orderTime = new Date(order.created_at);
      const now = new Date();
      const diffMinutes = (now - orderTime) / (1000 * 60);
      return diffMinutes <= 60; // آخر ساعة
    });
    
    console.log(`📦 طلبات آخر ساعة: ${veryRecentOrders.length}`);
    
    if (veryRecentOrders.length > 0) {
      console.log('\n📋 === طلبات آخر ساعة ===');
      
      veryRecentOrders.forEach((order, index) => {
        const createdTime = new Date(order.created_at);
        const updatedTime = new Date(order.updated_at);
        const diffMinutes = Math.floor((new Date() - createdTime) / (1000 * 60));
        const updateDiffMinutes = Math.floor((new Date() - updatedTime) / (1000 * 60));
        
        console.log(`\n${index + 1}. طلب: ${order.id}`);
        console.log(`   📋 رقم الطلب: ${order.order_number || 'غير محدد'}`);
        console.log(`   👤 العميل: ${order.customer_name}`);
        console.log(`   📊 الحالة: ${order.status}`);
        console.log(`   📅 تاريخ الإنشاء: ${createdTime.toLocaleString('ar-IQ')}`);
        console.log(`   📅 آخر تحديث: ${updatedTime.toLocaleString('ar-IQ')}`);
        console.log(`   ⏰ منذ الإنشاء: ${diffMinutes} دقيقة`);
        console.log(`   ⏰ منذ آخر تحديث: ${updateDiffMinutes} دقيقة`);
        
        if (order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
          console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
          console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
          
          if (order.waseet_order_id && order.waseet_order_id !== 'null') {
            console.log(`   ✅ تم الإرسال للوسيط بنجاح - QR ID: ${order.waseet_order_id}`);
          } else {
            console.log(`   ❌ لم يتم الإرسال للوسيط - هذا قد يكون طلب المستخدم!`);
            
            if (order.waseet_data) {
              try {
                const waseetData = JSON.parse(order.waseet_data);
                console.log(`   📋 بيانات الوسيط:`, waseetData);
              } catch (e) {
                console.log(`   📋 بيانات الوسيط (خام): ${order.waseet_data.substring(0, 100)}...`);
              }
            }
            
            // محاولة إرسال يدوي فوري
            console.log(`   🔧 محاولة إرسال يدوي فوري...`);
            
            try {
              const manualSendResponse = await axios.post(
                `${baseURL}/api/orders/${order.id}/send-to-waseet`, 
                {}, 
                { 
                  timeout: 60000,
                  validateStatus: () => true 
                }
              );
              
              console.log(`   📊 نتيجة الإرسال اليدوي:`);
              console.log(`      Status: ${manualSendResponse.status}`);
              console.log(`      Success: ${manualSendResponse.data?.success}`);
              console.log(`      Message: ${manualSendResponse.data?.message}`);
              
              if (manualSendResponse.data?.success) {
                console.log(`   ✅ تم إصلاح الطلب!`);
                console.log(`   🆔 QR ID: ${manualSendResponse.data.data?.qrId}`);
                console.log(`   🔗 رابط الوسيط: ${manualSendResponse.data.data?.qr_link || 'غير متوفر'}`);
                console.log(`\n   🎉 الطلب الآن في الوسيط ويمكن طباعته!`);
              } else {
                console.log(`   ❌ فشل الإرسال اليدوي`);
                console.log(`   🔍 تفاصيل الخطأ:`, manualSendResponse.data);
              }
              
            } catch (error) {
              console.log(`   ❌ خطأ في الإرسال اليدوي: ${error.message}`);
              if (error.response) {
                console.log(`   📊 Status: ${error.response.status}`);
                console.log(`   📋 Data:`, error.response.data);
              }
            }
          }
        } else if (order.status === 'active' || order.status === 'نشط') {
          console.log(`   📝 الطلب لا يزال نشط - لم يتم تغيير الحالة بعد`);
        }
      });
    }
    
    // البحث عن جميع الطلبات في حالة التوصيل بدون معرف وسيط
    const problemOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      (!order.waseet_order_id || order.waseet_order_id === 'null')
    );
    
    console.log(`\n❌ === طلبات في حالة التوصيل بدون معرف وسيط: ${problemOrders.length} ===`);
    
    if (problemOrders.length > 0) {
      console.log('\n📋 تفاصيل الطلبات المشكلة:');
      
      for (let i = 0; i < Math.min(problemOrders.length, 5); i++) {
        const order = problemOrders[i];
        const createdTime = new Date(order.created_at);
        const updatedTime = new Date(order.updated_at);
        const diffMinutes = Math.floor((new Date() - updatedTime) / (1000 * 60));
        
        console.log(`\n${i + 1}. طلب: ${order.id}`);
        console.log(`   📋 رقم الطلب: ${order.order_number || 'غير محدد'}`);
        console.log(`   👤 العميل: ${order.customer_name}`);
        console.log(`   📅 تاريخ الإنشاء: ${createdTime.toLocaleString('ar-IQ')}`);
        console.log(`   📅 آخر تحديث: ${updatedTime.toLocaleString('ar-IQ')}`);
        console.log(`   ⏰ منذ آخر تحديث: ${diffMinutes} دقيقة`);
        console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        
        // محاولة إرسال يدوي
        console.log(`   🔧 محاولة إرسال يدوي...`);
        
        try {
          const manualSendResponse = await axios.post(
            `${baseURL}/api/orders/${order.id}/send-to-waseet`, 
            {}, 
            { 
              timeout: 60000,
              validateStatus: () => true 
            }
          );
          
          if (manualSendResponse.data?.success) {
            console.log(`   ✅ تم إصلاح الطلب - QR ID: ${manualSendResponse.data.data?.qrId}`);
          } else {
            console.log(`   ❌ فشل الإصلاح: ${manualSendResponse.data?.message}`);
          }
          
        } catch (error) {
          console.log(`   ❌ خطأ في الإصلاح: ${error.message}`);
        }
        
        // انتظار قصير بين الطلبات
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }
    
    // إنشاء طلب اختبار جديد للتأكد من النظام
    console.log('\n🧪 === إنشاء طلب اختبار جديد للتأكد ===');
    
    const testOrderData = {
      customer_name: 'اختبار نهائي للمستخدم',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - اختبار نهائي',
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
      order_number: `ORD-FINALTEST-${Date.now()}`,
      notes: 'اختبار نهائي للمستخدم'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, testOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (createResponse.data.success) {
      const testOrderId = createResponse.data.data.id;
      console.log(`✅ تم إنشاء طلب اختبار: ${testOrderId}`);
      
      // تحديث الحالة
      console.log('📤 تحديث حالة طلب الاختبار إلى حالة التوصيل...');
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار نهائي للمستخدم - تحديث تلقائي',
        changedBy: 'final_user_test'
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
        console.log('\n👀 === مراقبة مكثفة لطلب الاختبار ===');
        
        const checkIntervals = [5, 15, 30, 60, 120]; // ثوان
        
        for (const seconds of checkIntervals) {
          console.log(`\n⏳ فحص بعد ${seconds} ثانية...`);
          await new Promise(resolve => setTimeout(resolve, seconds * 1000));
          
          const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
          const currentOrder = ordersResponse.data.data.find(o => o.id === testOrderId);
          
          if (currentOrder) {
            console.log(`📋 حالة طلب الاختبار:`);
            console.log(`   📊 الحالة: ${currentOrder.status}`);
            console.log(`   🆔 معرف الوسيط: ${currentOrder.waseet_order_id || 'غير محدد'}`);
            console.log(`   📦 حالة الوسيط: ${currentOrder.waseet_status || 'غير محدد'}`);
            
            if (currentOrder.waseet_order_id && currentOrder.waseet_order_id !== 'null') {
              console.log(`🎉 نجح! طلب الاختبار تم إرساله للوسيط`);
              console.log(`🆔 QR ID: ${currentOrder.waseet_order_id}`);
              console.log(`✅ النظام يعمل بشكل صحيح!`);
              
              if (currentOrder.waseet_data) {
                try {
                  const waseetData = JSON.parse(currentOrder.waseet_data);
                  if (waseetData.waseetResponse && waseetData.waseetResponse.data && waseetData.waseetResponse.data.qr_link) {
                    console.log(`🔗 رابط الوسيط: ${waseetData.waseetResponse.data.qr_link}`);
                  }
                } catch (e) {
                  // تجاهل أخطاء التحليل
                }
              }
              break;
            } else if (currentOrder.waseet_status === 'pending') {
              console.log(`⏳ لا يزال قيد المعالجة...`);
            } else if (currentOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
              console.log(`❌ فشل في الإرسال`);
              
              if (currentOrder.waseet_data) {
                try {
                  const waseetData = JSON.parse(currentOrder.waseet_data);
                  console.log(`🔍 سبب الفشل:`, waseetData);
                } catch (e) {
                  console.log(`🔍 بيانات الفشل: ${currentOrder.waseet_data}`);
                }
              }
              
              // محاولة إرسال يدوي
              console.log(`   🔧 محاولة إرسال يدوي...`);
              
              try {
                const manualSendResponse = await axios.post(
                  `${baseURL}/api/orders/${testOrderId}/send-to-waseet`, 
                  {}, 
                  { 
                    timeout: 60000,
                    validateStatus: () => true 
                  }
                );
                
                if (manualSendResponse.data?.success) {
                  console.log(`   ✅ الإرسال اليدوي نجح - QR ID: ${manualSendResponse.data.data?.qrId}`);
                } else {
                  console.log(`   ❌ الإرسال اليدوي فشل: ${manualSendResponse.data?.message}`);
                }
                
              } catch (error) {
                console.log(`   ❌ خطأ في الإرسال اليدوي: ${error.message}`);
              }
              break;
            } else if (!currentOrder.waseet_status) {
              console.log(`❓ لم يتم محاولة الإرسال أصلاً`);
              console.log(`🔍 مشكلة في الكود - النظام لم يحاول الإرسال`);
            }
          }
        }
      }
    }
    
    // خلاصة نهائية
    console.log('\n📊 === خلاصة نهائية ===');
    
    const deliveryOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    const successfulOrders = deliveryOrders.filter(order => 
      order.waseet_order_id && order.waseet_order_id !== 'null'
    );
    
    const failedOrders = deliveryOrders.filter(order => 
      !order.waseet_order_id || order.waseet_order_id === 'null'
    );
    
    console.log(`📦 إجمالي طلبات التوصيل: ${deliveryOrders.length}`);
    console.log(`✅ تم إرسالها بنجاح: ${successfulOrders.length}`);
    console.log(`❌ لم يتم إرسالها: ${failedOrders.length}`);
    
    if (failedOrders.length === 0) {
      console.log('\n🎉 === جميع الطلبات تعمل بشكل مثالي! ===');
      console.log('✅ جميع الطلبات في حالة التوصيل تم إرسالها للوسيط');
      console.log('📱 النظام يعمل بشكل صحيح 100%');
    } else {
      console.log(`\n⚠️ === يوجد ${failedOrders.length} طلب لم يتم إرساله ===`);
      console.log('🔧 تم محاولة إصلاحها تلقائياً');
      console.log('📱 تحقق من التطبيق لرؤية النتائج');
    }
    
  } catch (error) {
    console.error('❌ خطأ في البحث عن طلب المستخدم:', error.message);
  }
}

findUserOrder();
