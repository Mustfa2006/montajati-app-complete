const axios = require('axios');

async function fixOrderCreation() {
  console.log('🔧 === إصلاح مشكلة إنشاء الطلبات ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  // محاولة إنشاء طلب بالحقول المطلوبة بالضبط
  console.log('1️⃣ محاولة إنشاء طلب بالحقول المطلوبة...');
  
  const correctOrderData = {
    customer_name: 'عميل اختبار صحيح',
    primary_phone: '07901234567',
    secondary_phone: '07709876543',
    customer_address: 'بغداد - الكرخ - شارع الاختبار',
    delivery_address: 'بغداد - الكرخ - شارع الاختبار',
    province: 'بغداد',
    city: 'الكرخ',
    subtotal: 25000,
    delivery_fee: 5000,
    total: 30000,
    status: 'active',
    notes: 'طلب اختبار لإصلاح مشكلة الإنشاء',
    items: JSON.stringify([
      {
        name: 'منتج اختبار',
        quantity: 1,
        price: 25000,
        sku: 'TEST_001'
      }
    ])
  };
  
  try {
    console.log('📤 إرسال طلب إنشاء مع الحقول الصحيحة...');
    console.log('📋 البيانات:', JSON.stringify(correctOrderData, null, 2));
    
    const response = await axios.post(`${baseURL}/api/orders`, correctOrderData, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      timeout: 30000,
      validateStatus: () => true
    });
    
    console.log(`\n📥 استجابة إنشاء الطلب:`);
    console.log(`📊 Status: ${response.status}`);
    console.log(`📋 Response:`, JSON.stringify(response.data, null, 2));
    
    if (response.data.success) {
      console.log('✅ نجح إنشاء الطلب!');
      const orderId = response.data.data.id;
      
      // اختبار تحديث حالة الطلب الجديد
      console.log('\n2️⃣ اختبار تحديث حالة الطلب الجديد...');
      await testNewOrderUpdate(baseURL, orderId);
      
    } else {
      console.log('❌ فشل إنشاء الطلب');
      console.log('📋 الخطأ:', response.data.error);
      
      // محاولة مع حقول أقل
      console.log('\n🔄 محاولة مع حقول أساسية فقط...');
      await tryMinimalOrder(baseURL);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في إنشاء الطلب: ${error.message}`);
    if (error.response) {
      console.log(`📋 Response Status: ${error.response.status}`);
      console.log(`📋 Response Data:`, error.response.data);
    }
    
    // محاولة مع حقول أقل
    console.log('\n🔄 محاولة مع حقول أساسية فقط...');
    await tryMinimalOrder(baseURL);
  }
}

async function tryMinimalOrder(baseURL) {
  try {
    console.log('📝 محاولة إنشاء طلب بحقول أساسية فقط...');
    
    const minimalOrderData = {
      customer_name: 'عميل بسيط',
      primary_phone: '07901234567',
      total: 25000,
      status: 'active'
    };
    
    console.log('📤 إرسال طلب بسيط...');
    console.log('📋 البيانات:', JSON.stringify(minimalOrderData, null, 2));
    
    const response = await axios.post(`${baseURL}/api/orders`, minimalOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000,
      validateStatus: () => true
    });
    
    console.log(`\n📥 استجابة الطلب البسيط:`);
    console.log(`📊 Status: ${response.status}`);
    console.log(`📋 Response:`, JSON.stringify(response.data, null, 2));
    
    if (response.data.success) {
      console.log('✅ نجح إنشاء الطلب البسيط!');
      const orderId = response.data.data.id;
      
      // اختبار تحديث حالة الطلب البسيط
      console.log('\n3️⃣ اختبار تحديث حالة الطلب البسيط...');
      await testNewOrderUpdate(baseURL, orderId);
      
    } else {
      console.log('❌ فشل إنشاء الطلب البسيط أيضاً');
      console.log('📋 الخطأ:', response.data.error);
      
      // فحص schema قاعدة البيانات
      console.log('\n🔍 فحص schema قاعدة البيانات...');
      await checkDatabaseSchema(baseURL);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في إنشاء الطلب البسيط: ${error.message}`);
    
    // فحص schema قاعدة البيانات
    console.log('\n🔍 فحص schema قاعدة البيانات...');
    await checkDatabaseSchema(baseURL);
  }
}

async function testNewOrderUpdate(baseURL, orderId) {
  try {
    console.log(`🔄 اختبار تحديث حالة الطلب الجديد: ${orderId}`);
    
    // فحص الطلب قبل التحديث
    const beforeUpdate = await getOrderDetails(baseURL, orderId);
    if (beforeUpdate) {
      console.log(`📋 الطلب الجديد قبل التحديث:`);
      console.log(`   📊 الحالة: ${beforeUpdate.status}`);
      console.log(`   🆔 معرف الوسيط: ${beforeUpdate.waseet_order_id || 'غير محدد'}`);
      console.log(`   📦 حالة الوسيط: ${beforeUpdate.waseet_status || 'غير محدد'}`);
    }
    
    // تحديث الحالة إلى قيد التوصيل
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار طلب جديد - إصلاح مشكلة الإنشاء',
      changedBy: 'fix_order_creation'
    };
    
    console.log('\n📤 تحديث حالة الطلب الجديد...');
    
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
      
      // مراقبة النتيجة
      const checkIntervals = [5, 15, 30];
      
      for (const seconds of checkIntervals) {
        console.log(`\n⏳ انتظار ${seconds} ثانية...`);
        await new Promise(resolve => setTimeout(resolve, seconds * 1000));
        
        const afterUpdate = await getOrderDetails(baseURL, orderId);
        if (afterUpdate) {
          console.log(`🔍 فحص بعد ${seconds} ثانية:`);
          console.log(`   📊 الحالة: ${afterUpdate.status}`);
          console.log(`   🆔 معرف الوسيط: ${afterUpdate.waseet_order_id || 'غير محدد'}`);
          console.log(`   📦 حالة الوسيط: ${afterUpdate.waseet_status || 'غير محدد'}`);
          
          if (afterUpdate.waseet_order_id && afterUpdate.waseet_order_id !== 'null') {
            console.log(`🎉 نجح! الطلب الجديد تم إرساله للوسيط - QR ID: ${afterUpdate.waseet_order_id}`);
            console.log('✅ مشكلة إنشاء الطلبات محلولة!');
            break;
          } else if (afterUpdate.waseet_status === 'pending') {
            console.log('⚠️ الطلب في حالة pending - لا يزال قيد المعالجة');
          } else if (!afterUpdate.waseet_status) {
            console.log('❓ لم يتم محاولة إرسال الطلب أصلاً');
          }
        }
      }
      
    } else {
      console.log('❌ فشل في تحديث حالة الطلب الجديد');
      console.log('📋 الخطأ:', updateResponse.data.error);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار تحديث الطلب الجديد: ${error.message}`);
  }
}

async function getOrderDetails(baseURL, orderId) {
  try {
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const order = ordersResponse.data.data.find(o => o.id === orderId);
    return order || null;
  } catch (error) {
    console.log(`❌ خطأ في جلب تفاصيل الطلب: ${error.message}`);
    return null;
  }
}

async function checkDatabaseSchema(baseURL) {
  try {
    console.log('🔍 فحص schema قاعدة البيانات...');
    
    // محاولة الوصول لمعلومات schema
    const schemaResponse = await axios.get(`${baseURL}/api/schema/orders`, {
      timeout: 10000,
      validateStatus: () => true
    });
    
    if (schemaResponse.status === 200) {
      console.log('✅ تم الوصول لمعلومات schema');
      console.log('📋 Schema:', JSON.stringify(schemaResponse.data, null, 2));
    } else if (schemaResponse.status === 404) {
      console.log('ℹ️ endpoint schema غير متاح');
    } else {
      console.log(`⚠️ schema endpoint يعطي status: ${schemaResponse.status}`);
    }
    
    // فحص الطلبات الموجودة لفهم البنية
    console.log('\n📊 فحص بنية الطلبات الموجودة...');
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const orders = ordersResponse.data.data;
    
    if (orders.length > 0) {
      const sampleOrder = orders[0];
      console.log('📋 مثال على بنية الطلب الموجود:');
      console.log('📝 الحقول المتاحة:');
      
      Object.keys(sampleOrder).forEach(key => {
        const value = sampleOrder[key];
        const type = typeof value;
        console.log(`   ${key}: ${type} = ${value !== null ? String(value).substring(0, 50) : 'null'}`);
      });
      
      // تحليل الحقول المطلوبة
      console.log('\n🔍 تحليل الحقول المطلوبة:');
      
      const requiredFields = [
        'customer_name',
        'primary_phone', 
        'total',
        'status'
      ];
      
      const optionalFields = [
        'secondary_phone',
        'customer_address',
        'delivery_address',
        'province',
        'city',
        'subtotal',
        'delivery_fee',
        'notes',
        'items'
      ];
      
      console.log('📋 الحقول المطلوبة:');
      requiredFields.forEach(field => {
        const exists = sampleOrder.hasOwnProperty(field);
        console.log(`   ${field}: ${exists ? '✅ موجود' : '❌ مفقود'}`);
      });
      
      console.log('📋 الحقول الاختيارية:');
      optionalFields.forEach(field => {
        const exists = sampleOrder.hasOwnProperty(field);
        console.log(`   ${field}: ${exists ? '✅ موجود' : '⚠️ مفقود'}`);
      });
    }
    
  } catch (error) {
    console.log(`❌ خطأ في فحص schema: ${error.message}`);
  }
}

fixOrderCreation();
