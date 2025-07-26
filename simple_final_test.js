const axios = require('axios');

async function simpleFinalTest() {
  console.log('🎯 === اختبار بسيط نهائي ===\n');
  console.log('🔧 اختبار الحالة الوحيدة المؤهلة للوسيط\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    console.log('⏰ انتظار 30 ثانية للتأكد من تطبيق التغييرات على Render...\n');
    await new Promise(resolve => setTimeout(resolve, 30000));
    
    // اختبار واحد فقط - الحالة المؤهلة
    console.log('🧪 اختبار الحالة المؤهلة: الرقم "3"');
    console.log('   📝 يجب أن يتحول إلى: "قيد التوصيل الى الزبون (في عهدة المندوب)"');
    console.log('   📦 يجب أن يرسل للوسيط: ✅ نعم\n');
    
    // إنشاء طلب جديد
    const newOrderData = {
      customer_name: 'اختبار نهائي بسيط',
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
      order_number: `ORD-FINAL-${Date.now()}`,
      notes: 'اختبار نهائي بسيط'
    };
    
    console.log('📦 إنشاء طلب جديد...');
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (createResponse.data.success) {
      const orderId = createResponse.data.data.id;
      console.log(`✅ تم إنشاء الطلب: ${orderId}\n`);
      
      // تحديث الحالة إلى "3"
      const updateData = {
        status: '3',
        notes: 'اختبار نهائي - تحويل الرقم 3',
        changedBy: 'final_test'
      };
      
      console.log('📤 تحديث حالة الطلب إلى "3"...');
      
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
      
      console.log(`📥 نتيجة التحديث:`);
      console.log(`   Status: ${updateResponse.status}`);
      console.log(`   Success: ${updateResponse.data.success}`);
      console.log(`   Message: ${updateResponse.data.message}\n`);
      
      if (updateResponse.data.success) {
        console.log('✅ تم تحديث الحالة بنجاح!\n');
        
        // انتظار قصير ثم فحص النتيجة
        console.log('⏰ انتظار 15 ثانية لمعالجة الطلب...\n');
        await new Promise(resolve => setTimeout(resolve, 15000));
        
        console.log('🔍 فحص النتيجة النهائية...');
        const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
        const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
        
        if (updatedOrder) {
          console.log(`📋 النتيجة النهائية:`);
          console.log(`   📊 الحالة في قاعدة البيانات: "${updatedOrder.status}"`);
          console.log(`   🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`   📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}\n`);
          
          // فحص النتيجة
          const expectedStatus = 'قيد التوصيل الى الزبون (في عهدة المندوب)';
          const statusCorrect = updatedOrder.status === expectedStatus;
          const hasWaseetId = updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null';
          
          console.log('🧪 تحليل النتائج:');
          console.log(`   🔄 تحويل الحالة: ${statusCorrect ? '✅ صحيح' : '❌ خاطئ'}`);
          console.log(`   📦 إرسال للوسيط: ${hasWaseetId ? '✅ تم' : '❌ لم يتم'}\n`);
          
          if (statusCorrect && hasWaseetId) {
            console.log('🎉 === النجاح الكامل! ===');
            console.log('✅ الرقم "3" تم تحويله بنجاح');
            console.log('✅ تم إرسال الطلب للوسيط');
            console.log(`✅ QR ID: ${updatedOrder.waseet_order_id}`);
            
            // فحص رابط الوسيط
            if (updatedOrder.waseet_data) {
              try {
                const waseetData = JSON.parse(updatedOrder.waseet_data);
                if (waseetData.waseetResponse && waseetData.waseetResponse.data && waseetData.waseetResponse.data.qr_link) {
                  console.log(`✅ رابط الوسيط: ${waseetData.waseetResponse.data.qr_link}`);
                }
              } catch (e) {
                // تجاهل أخطاء التحليل
              }
            }
            
            console.log('\n🎊 تهانينا! المشكلة محلولة بالكامل!');
            console.log('📱 يمكنك الآن استخدام التطبيق بثقة');
            console.log('🔹 غير حالة أي طلب إلى الرقم "3"');
            console.log('🔹 ستظهر معرف الوسيط تلقائياً');
            console.log('🔹 يمكنك فتح رابط الوسيط للطباعة');
            
          } else {
            console.log('❌ === هناك مشكلة ===');
            if (!statusCorrect) {
              console.log(`❌ الحالة خاطئة: متوقع "${expectedStatus}" لكن حصلت على "${updatedOrder.status}"`);
            }
            if (!hasWaseetId) {
              console.log('❌ لم يتم إرسال الطلب للوسيط');
            }
            console.log('🔍 قد تحتاج لانتظار المزيد أو مراجعة الكود');
          }
        } else {
          console.log('❌ لم يتم العثور على الطلب المحدث');
        }
      } else {
        console.log(`❌ فشل في تحديث الحالة: ${updateResponse.data.error}`);
      }
    } else {
      console.log('❌ فشل في إنشاء الطلب');
    }
    
  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
    
    if (error.code === 'ECONNABORTED') {
      console.log('⏰ انتهت مهلة الاتصال - قد يكون الخادم بطيء');
      console.log('💡 جرب الاختبار مرة أخرى بعد دقائق قليلة');
    }
  }
}

simpleFinalTest();
