const axios = require('axios');

async function testServerStatus() {
  console.log('🔍 === فحص حالة الخادم ===\n');
  console.log('🎯 التحقق من أن التغييرات وصلت للخادم\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // إنشاء طلب جديد
    const newOrderData = {
      customer_name: 'فحص حالة الخادم',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - فحص حالة الخادم',
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
      order_number: `ORD-SERVERTEST-${Date.now()}`,
      notes: 'فحص حالة الخادم'
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
      
      // اختبار تحديث الحالة مع مراقبة logs الخادم
      console.log('📤 تحديث حالة الطلب إلى "3" مع مراقبة logs...');
      
      const updateData = {
        status: '3',
        notes: 'فحص حالة الخادم - اختبار الرقم 3',
        changedBy: 'server_status_test'
      };
      
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
      
      console.log(`📥 استجابة الخادم:`);
      console.log(`   Status: ${updateResponse.status}`);
      console.log(`   Success: ${updateResponse.data.success}`);
      console.log(`   Message: ${updateResponse.data.message}`);
      console.log(`   Data:`, JSON.stringify(updateResponse.data, null, 2));
      
      if (updateResponse.data.success) {
        console.log('\n✅ تم تحديث الحالة بنجاح');
        
        // فحص النتيجة فوراً
        console.log('\n🔍 فحص النتيجة فوراً...');
        const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
        const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
        
        if (updatedOrder) {
          console.log(`📋 النتيجة الفورية:`);
          console.log(`   📊 الحالة في قاعدة البيانات: "${updatedOrder.status}"`);
          console.log(`   🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`   📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
          
          // تحليل النتيجة
          console.log('\n🧪 تحليل النتيجة:');
          
          if (updatedOrder.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
            console.log('✅ الخادم يحول الرقم "3" بشكل صحيح');
          } else if (updatedOrder.status === 'in_delivery') {
            console.log('❌ الخادم لا يزال يحول إلى "in_delivery"');
            console.log('🔍 التغييرات لم تصل للخادم بعد');
          } else {
            console.log(`⚠️ الخادم حول إلى حالة غير متوقعة: "${updatedOrder.status}"`);
          }
          
          const hasWaseetId = updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null';
          if (hasWaseetId) {
            console.log('✅ تم إرسال الطلب للوسيط');
            console.log(`🆔 QR ID: ${updatedOrder.waseet_order_id}`);
          } else {
            console.log('❌ لم يتم إرسال الطلب للوسيط');
          }
          
          // انتظار ثم فحص مرة أخرى
          console.log('\n⏰ انتظار 10 ثوان ثم فحص مرة أخرى...');
          await new Promise(resolve => setTimeout(resolve, 10000));
          
          const ordersResponse2 = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
          const updatedOrder2 = ordersResponse2.data.data.find(o => o.id === orderId);
          
          if (updatedOrder2) {
            console.log(`📋 النتيجة بعد 10 ثوان:`);
            console.log(`   📊 الحالة: "${updatedOrder2.status}"`);
            console.log(`   🆔 معرف الوسيط: ${updatedOrder2.waseet_order_id || 'غير محدد'}`);
            console.log(`   📦 حالة الوسيط: ${updatedOrder2.waseet_status || 'غير محدد'}`);
            
            const hasWaseetId2 = updatedOrder2.waseet_order_id && updatedOrder2.waseet_order_id !== 'null';
            
            if (updatedOrder2.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)' && hasWaseetId2) {
              console.log('\n🎉 === النجاح الكامل! ===');
              console.log('✅ الخادم يعمل بشكل صحيح');
              console.log('✅ التحويل صحيح');
              console.log('✅ الإرسال للوسيط يعمل');
              console.log('\n📱 يمكنك الآن استخدام التطبيق بثقة!');
              
            } else if (updatedOrder2.status === 'in_delivery') {
              console.log('\n❌ === المشكلة لا تزال موجودة ===');
              console.log('❌ الخادم لا يزال يحول إلى "in_delivery"');
              console.log('🔍 التغييرات لم تصل للخادم');
              console.log('💡 قد تحتاج لإعادة نشر الكود على Render');
              
            } else {
              console.log('\n⚠️ === حالة غير متوقعة ===');
              console.log(`⚠️ الحالة: "${updatedOrder2.status}"`);
              console.log(`⚠️ إرسال الوسيط: ${hasWaseetId2 ? 'تم' : 'لم يتم'}`);
            }
          }
        }
      } else {
        console.log(`❌ فشل في تحديث الحالة: ${updateResponse.data.error}`);
      }
    } else {
      console.log('❌ فشل في إنشاء الطلب');
    }
    
  } catch (error) {
    console.error('❌ خطأ في فحص حالة الخادم:', error.message);
  }
}

testServerStatus();
