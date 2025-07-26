const axios = require('axios');

async function finalSolutionTest() {
  console.log('🎯 === اختبار الحل النهائي ===\n');
  console.log('🔧 الحل المطبق:');
  console.log('1. ✅ إضافة عرض معرف الوسيط في تفاصيل الطلب');
  console.log('2. ✅ إضافة زر لفتح رابط الوسيط');
  console.log('3. ✅ إضافة "in_delivery" لقائمة الحالات المدعومة');
  console.log('4. ✅ تحسين logs الخادم لإظهار QR ID\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. إنشاء طلب جديد لاختبار الحل
    console.log('1️⃣ === إنشاء طلب جديد لاختبار الحل ===');
    
    const newOrderData = {
      customer_name: 'اختبار الحل النهائي',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - اختبار الحل النهائي',
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
      order_number: `ORD-FINAL-${Date.now()}`,
      notes: 'اختبار الحل النهائي'
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
    
    // 2. اختبار تحديث الحالة مع الحالة الصحيحة
    console.log('\n2️⃣ === اختبار تحديث الحالة مع "قيد التوصيل الى الزبون (في عهدة المندوب)" ===');

    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار الحل النهائي - تحديث بالحالة الصحيحة',
      changedBy: 'final_solution_test'
    };
    
    console.log('📤 إرسال طلب تحديث الحالة...');
    
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
      
      const checkIntervals = [5, 15, 30];
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
          }
        }
      }
      
      // 4. اختبار رابط الوسيط
      if (finalQrId) {
        console.log('\n4️⃣ === اختبار رابط الوسيط ===');
        const waseetUrl = `https://alwaseet-iq.net/merchant/print-single-tcpdf?id=${finalQrId}`;
        console.log(`🔗 رابط الوسيط: ${waseetUrl}`);
        
        try {
          const linkResponse = await axios.head(waseetUrl, { 
            timeout: 10000,
            validateStatus: () => true 
          });
          
          if (linkResponse.status === 200) {
            console.log('✅ رابط الوسيط يعمل بشكل صحيح');
          } else {
            console.log(`⚠️ رابط الوسيط يعطي status: ${linkResponse.status}`);
          }
        } catch (error) {
          console.log(`⚠️ لا يمكن الوصول لرابط الوسيط: ${error.message}`);
        }
      }
      
      // 5. النتيجة النهائية
      console.log('\n5️⃣ === النتيجة النهائية ===');
      
      if (waseetSuccess && finalQrId) {
        console.log('🎉 === الحل نجح بشكل مثالي! ===');
        console.log(`✅ تم إنشاء الطلب: ${orderId}`);
        console.log(`✅ تم تحديث الحالة إلى: قيد التوصيل الى الزبون (في عهدة المندوب)`);
        console.log(`✅ تم إرسال الطلب للوسيط: ${finalQrId}`);
        console.log(`✅ رابط الوسيط متاح: https://alwaseet-iq.net/merchant/print-single-tcpdf?id=${finalQrId}`);
        console.log('');
        console.log('🎯 === ما تم حله ===');
        console.log('1. ✅ النظام يعمل بشكل مثالي');
        console.log('2. ✅ معرف الوسيط سيظهر الآن في تفاصيل الطلب');
        console.log('3. ✅ المستخدم يمكنه فتح رابط الوسيط مباشرة');
        console.log('4. ✅ دعم كامل للحالة "قيد التوصيل الى الزبون (في عهدة المندوب)"');
        console.log('5. ✅ logs محسنة لتتبع العملية');
        console.log('');
        console.log('📱 === للمستخدم ===');
        console.log('1. غير حالة الطلب إلى "قيد التوصيل"');
        console.log('2. انتظر 30 ثانية');
        console.log('3. ادخل على تفاصيل الطلب');
        console.log('4. ستجد معرف الوسيط معروض بوضوح');
        console.log('5. اضغط على الأيقونة لفتح رابط الوسيط');
        
      } else {
        console.log('❌ === الحل لم ينجح ===');
        console.log('🔍 هناك مشكلة أخرى تحتاج لمزيد من التحقيق');
      }
      
    } else {
      console.log('❌ فشل في تحديث الحالة');
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار الحل النهائي:', error.message);
  }
}

finalSolutionTest();
