const axios = require('axios');

async function correctStatusTest() {
  console.log('🎯 === اختبار بالحالة الصحيحة ===\n');
  console.log('✅ استخدام الحالة الصحيحة: "قيد التوصيل الى الزبون (في عهدة المندوب)"\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. إنشاء طلب جديد
    console.log('1️⃣ === إنشاء طلب جديد ===');
    
    const newOrderData = {
      customer_name: 'اختبار الحالة الصحيحة',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - اختبار الحالة الصحيحة',
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
      order_number: `ORD-CORRECT-${Date.now()}`,
      notes: 'اختبار الحالة الصحيحة'
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
    
    // 2. تحديث الحالة بالحالة الصحيحة
    console.log('\n2️⃣ === تحديث الحالة بالحالة الصحيحة ===');
    
    const correctStatus = 'قيد التوصيل الى الزبون (في عهدة المندوب)';
    
    const updateData = {
      status: correctStatus,
      notes: 'اختبار بالحالة الصحيحة',
      changedBy: 'correct_status_test'
    };
    
    console.log(`📤 إرسال طلب تحديث الحالة إلى: "${correctStatus}"`);
    
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
      
      // 3. مراقبة إرسال الطلب للوسيط
      console.log('\n3️⃣ === مراقبة إرسال الطلب للوسيط ===');
      
      const checkIntervals = [5, 15, 30, 60];
      let waseetSuccess = false;
      let finalQrId = null;
      
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
            finalQrId = updatedOrder.waseet_order_id;
            waseetSuccess = true;
            break;
          } else if (updatedOrder.waseet_status === 'pending') {
            console.log('⏳ الطلب في حالة pending - لا يزال قيد المعالجة');
          } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('❌ فشل في إرسال الطلب للوسيط');
            
            // محاولة إرسال يدوي
            console.log('🔧 محاولة إرسال يدوي...');
            try {
              const manualSendResponse = await axios.post(`${baseURL}/api/orders/${orderId}/send-to-waseet`, {}, {
                timeout: 30000,
                validateStatus: () => true
              });
              
              if (manualSendResponse.data?.success) {
                console.log(`✅ نجح الإرسال اليدوي - QR ID: ${manualSendResponse.data.data?.qrId}`);
                finalQrId = manualSendResponse.data.data?.qrId;
                waseetSuccess = true;
                break;
              } else {
                console.log(`❌ فشل الإرسال اليدوي: ${manualSendResponse.data?.error}`);
              }
            } catch (error) {
              console.log(`❌ خطأ في الإرسال اليدوي: ${error.message}`);
            }
          } else if (!updatedOrder.waseet_status) {
            console.log('❓ لم يتم محاولة إرسال الطلب للوسيط أصلاً');
          }
        }
      }
      
      // 4. النتيجة النهائية
      console.log('\n4️⃣ === النتيجة النهائية ===');
      
      if (waseetSuccess && finalQrId) {
        console.log('🎉 === النظام يعمل بشكل مثالي! ===');
        console.log(`✅ تم إنشاء الطلب: ${orderId}`);
        console.log(`✅ تم تحديث الحالة إلى: "${correctStatus}"`);
        console.log(`✅ تم إرسال الطلب للوسيط: ${finalQrId}`);
        console.log(`✅ رابط الوسيط: https://alwaseet-iq.net/merchant/print-single-tcpdf?id=${finalQrId}`);
        console.log('');
        console.log('📱 === للمستخدم ===');
        console.log('1. غير حالة الطلب إلى "قيد التوصيل الى الزبون (في عهدة المندوب)"');
        console.log('2. انتظر 30 ثانية');
        console.log('3. ادخل على تفاصيل الطلب');
        console.log('4. ستجد معرف الوسيط معروض بوضوح');
        console.log('5. اضغط على الأيقونة لفتح رابط الوسيط');
        
      } else {
        console.log('❌ === هناك مشكلة في النظام ===');
        console.log('🔍 الطلب لم يصل للوسيط رغم استخدام الحالة الصحيحة');
        
        // تحليل المشكلة
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
    console.error('❌ خطأ في اختبار الحالة الصحيحة:', error.message);
  }
}

correctStatusTest();
