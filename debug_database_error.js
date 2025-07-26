const axios = require('axios');

async function debugDatabaseError() {
  console.log('🔍 === تشخيص خطأ قاعدة البيانات ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  // إنشاء endpoint خاص للتشخيص
  console.log('1️⃣ محاولة إنشاء طلب مع تفاصيل الخطأ...');
  
  try {
    // محاولة إنشاء طلب بسيط جداً
    const testOrderData = {
      customer_name: 'اختبار تشخيص',
      primary_phone: '07901234567',
      total: 25000
    };
    
    console.log('📤 إرسال طلب تشخيص...');
    console.log('📋 البيانات:', JSON.stringify(testOrderData, null, 2));
    
    const response = await axios.post(`${baseURL}/api/orders`, testOrderData, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      timeout: 30000,
      validateStatus: () => true
    });
    
    console.log(`\n📥 استجابة التشخيص:`);
    console.log(`📊 Status: ${response.status}`);
    console.log(`📋 Response:`, JSON.stringify(response.data, null, 2));
    
    if (!response.data.success) {
      console.log('\n🔍 تحليل سبب الفشل...');
      
      // محاولة فهم المشكلة من خلال فحص الطلبات الموجودة
      console.log('\n2️⃣ فحص الطلبات الموجودة لفهم البنية...');
      
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const orders = ordersResponse.data.data;
      
      if (orders.length > 0) {
        const sampleOrder = orders[0];
        
        console.log('📋 تحليل بنية الطلب الموجود:');
        
        // الحقول المطلوبة التي قد تكون مفقودة
        const possibleRequiredFields = [
          'user_id',
          'user_phone', 
          'order_number',
          'profit',
          'profit_amount'
        ];
        
        console.log('\n🔍 الحقول التي قد تكون مطلوبة:');
        possibleRequiredFields.forEach(field => {
          const value = sampleOrder[field];
          console.log(`   ${field}: ${value !== null && value !== undefined ? value : 'null/undefined'}`);
        });
        
        // محاولة إنشاء طلب مع الحقول المطلوبة
        console.log('\n3️⃣ محاولة إنشاء طلب مع الحقول المطلوبة...');
        
        const completeOrderData = {
          customer_name: 'اختبار كامل',
          primary_phone: '07901234567',
          total: 25000,
          status: 'active',
          user_id: sampleOrder.user_id,
          user_phone: sampleOrder.user_phone,
          order_number: `ORD-${Date.now()}`,
          profit: 5000,
          profit_amount: 5000,
          subtotal: 20000,
          delivery_fee: 5000,
          province: 'بغداد',
          city: 'الكرخ',
          customer_address: 'بغداد - الكرخ - اختبار'
        };
        
        console.log('📤 إرسال طلب كامل...');
        console.log('📋 البيانات الكاملة:', JSON.stringify(completeOrderData, null, 2));
        
        const completeResponse = await axios.post(`${baseURL}/api/orders`, completeOrderData, {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 30000,
          validateStatus: () => true
        });
        
        console.log(`\n📥 استجابة الطلب الكامل:`);
        console.log(`📊 Status: ${completeResponse.status}`);
        console.log(`📋 Response:`, JSON.stringify(completeResponse.data, null, 2));
        
        if (completeResponse.data.success) {
          console.log('🎉 نجح إنشاء الطلب الكامل!');
          const orderId = completeResponse.data.data.id;
          
          // اختبار تحديث حالة الطلب الجديد
          console.log('\n4️⃣ اختبار تحديث حالة الطلب الجديد...');
          await testOrderUpdate(baseURL, orderId);
          
        } else {
          console.log('❌ فشل إنشاء الطلب الكامل أيضاً');
          
          // محاولة أخيرة مع نسخ بيانات طلب موجود
          console.log('\n5️⃣ محاولة أخيرة مع نسخ بيانات طلب موجود...');
          await tryCloneExistingOrder(baseURL, sampleOrder);
        }
        
      } else {
        console.log('❌ لا توجد طلبات موجودة للمقارنة');
      }
    }
    
  } catch (error) {
    console.error('❌ خطأ في التشخيص:', error.message);
    if (error.response) {
      console.error('📋 Response:', error.response.data);
    }
  }
}

async function tryCloneExistingOrder(baseURL, sampleOrder) {
  try {
    console.log('📋 محاولة نسخ بيانات طلب موجود...');
    
    // نسخ جميع الحقول من طلب موجود مع تغيير المعرف
    const clonedOrder = {
      ...sampleOrder,
      id: `cloned_order_${Date.now()}`,
      customer_name: 'عميل منسوخ',
      primary_phone: '07901234567',
      order_number: `CLONED-${Date.now()}`,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      status: 'active',
      waseet_order_id: null,
      waseet_status: null,
      waseet_data: null
    };
    
    // إزالة الحقول التي قد تسبب تضارب
    delete clonedOrder.waseet_qr_id;
    delete clonedOrder.last_status_check;
    delete clonedOrder.status_updated_at;
    
    console.log('📤 إرسال طلب منسوخ...');
    
    const cloneResponse = await axios.post(`${baseURL}/api/orders`, clonedOrder, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000,
      validateStatus: () => true
    });
    
    console.log(`\n📥 استجابة الطلب المنسوخ:`);
    console.log(`📊 Status: ${cloneResponse.status}`);
    console.log(`📋 Response:`, JSON.stringify(cloneResponse.data, null, 2));
    
    if (cloneResponse.data.success) {
      console.log('🎉 نجح إنشاء الطلب المنسوخ!');
      const orderId = cloneResponse.data.data.id;
      
      // اختبار تحديث حالة الطلب المنسوخ
      console.log('\n6️⃣ اختبار تحديث حالة الطلب المنسوخ...');
      await testOrderUpdate(baseURL, orderId);
      
    } else {
      console.log('❌ فشل إنشاء الطلب المنسوخ أيضاً');
      console.log('🔍 هذا يشير إلى مشكلة في قاعدة البيانات أو الخادم');
    }
    
  } catch (error) {
    console.log(`❌ خطأ في نسخ الطلب: ${error.message}`);
  }
}

async function testOrderUpdate(baseURL, orderId) {
  try {
    console.log(`🔄 اختبار تحديث حالة الطلب: ${orderId}`);
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار طلب جديد تم إنشاؤه بنجاح',
      changedBy: 'debug_database_error'
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
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث حالة الطلب الجديد بنجاح');
      
      // فحص النتيجة بعد 30 ثانية
      console.log('\n⏳ انتظار 30 ثانية لفحص النتيجة...');
      await new Promise(resolve => setTimeout(resolve, 30000));
      
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
      
      if (updatedOrder) {
        console.log('🔍 نتيجة الطلب الجديد:');
        console.log(`   📊 الحالة: ${updatedOrder.status}`);
        console.log(`   🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
        
        if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
          console.log(`🎉 مثالي! الطلب الجديد تم إرساله للوسيط - QR ID: ${updatedOrder.waseet_order_id}`);
          console.log('✅ مشكلة إنشاء الطلبات محلولة تماماً!');
          
          // تقديم الحل النهائي
          console.log('\n🎯 === الحل النهائي ===');
          console.log('📋 لإنشاء طلب جديد بنجاح، استخدم هذه البيانات:');
          
          const solutionData = {
            customer_name: 'اسم العميل',
            primary_phone: '07xxxxxxxxx',
            total: 'المبلغ الإجمالي',
            status: 'active',
            user_id: updatedOrder.user_id,
            user_phone: updatedOrder.user_phone,
            order_number: 'ORD-' + Date.now(),
            profit: 'مبلغ الربح',
            profit_amount: 'مبلغ الربح',
            subtotal: 'المبلغ الفرعي',
            delivery_fee: 'رسوم التوصيل',
            province: 'المحافظة',
            city: 'المدينة',
            customer_address: 'عنوان العميل'
          };
          
          console.log(JSON.stringify(solutionData, null, 2));
          
        } else {
          console.log('⚠️ الطلب الجديد لم يصل للوسيط بعد');
        }
      }
      
    } else {
      console.log('❌ فشل في تحديث حالة الطلب الجديد');
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار تحديث الطلب: ${error.message}`);
  }
}

debugDatabaseError();
