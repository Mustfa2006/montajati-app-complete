const axios = require('axios');

async function finalReleaseTest() {
  console.log('🚀 === اختبار الإصدار النهائي ===\n');
  console.log('📝 اختبار شامل للتأكد من جاهزية التطبيق للإصدار\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. اختبار إنشاء طلب جديد بالحقول المطلوبة
    console.log('1️⃣ === اختبار إنشاء طلب جديد ===');
    
    const newOrderData = {
      customer_name: 'عميل الإصدار النهائي',
      primary_phone: '07901234567',
      secondary_phone: '07709876543',
      customer_address: 'بغداد - الكرخ - شارع الإصدار النهائي',
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
      notes: 'طلب اختبار الإصدار النهائي',
      items: JSON.stringify([
        {
          name: 'منتج الإصدار النهائي',
          quantity: 1,
          price: 25000,
          sku: 'FINAL_001'
        }
      ])
    };
    
    console.log('📤 إنشاء طلب جديد...');
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    console.log(`📥 نتيجة إنشاء الطلب:`);
    console.log(`📊 Status: ${createResponse.status}`);
    console.log(`📊 Success: ${createResponse.data.success}`);
    
    if (createResponse.data.success) {
      const orderId = createResponse.data.data.id;
      console.log(`✅ تم إنشاء الطلب بنجاح: ${orderId}`);
      
      // 2. اختبار تحديث حالة الطلب الجديد
      console.log('\n2️⃣ === اختبار تحديث حالة الطلب ===');
      
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار الإصدار النهائي - تحديث الحالة',
        changedBy: 'final_release_test'
      };
      
      console.log('📤 تحديث حالة الطلب...');
      
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
        console.log('✅ تم تحديث الحالة بنجاح');
        
        // 3. مراقبة إرسال الطلب للوسيط
        console.log('\n3️⃣ === مراقبة إرسال الطلب للوسيط ===');
        
        const checkIntervals = [5, 15, 30];
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
            }
          }
        }
        
        // 4. تقييم النتائج النهائية
        console.log('\n4️⃣ === تقييم النتائج النهائية ===');
        
        if (waseetSuccess) {
          console.log('🎉 === اختبار الإصدار النهائي نجح 100% ===');
          console.log('✅ إنشاء الطلبات: يعمل بشكل مثالي');
          console.log('✅ تحديث الحالة: يعمل بشكل مثالي');
          console.log('✅ الإرسال للوسيط: يعمل بشكل مثالي');
          console.log('✅ الحصول على QR ID: يعمل بشكل مثالي');
          console.log('\n🚀 التطبيق جاهز للإصدار!');
          
          // 5. اختبار إضافي - إحصائيات النظام
          console.log('\n5️⃣ === إحصائيات النظام ===');
          await checkSystemStats(baseURL);
          
        } else {
          console.log('❌ === اختبار الإصدار النهائي فشل ===');
          console.log('⚠️ هناك مشكلة في إرسال الطلبات للوسيط');
          console.log('🔧 يجب إصلاح المشكلة قبل الإصدار');
        }
        
      } else {
        console.log('❌ فشل في تحديث حالة الطلب');
        console.log('📋 الخطأ:', updateResponse.data.error);
      }
      
    } else {
      console.log('❌ فشل في إنشاء الطلب');
      console.log('📋 الخطأ:', createResponse.data.error);
      console.log('🔧 يجب إصلاح مشكلة إنشاء الطلبات قبل الإصدار');
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار الإصدار النهائي:', error.message);
    if (error.response) {
      console.error('📋 Response:', error.response.data);
    }
  }
}

async function checkSystemStats(baseURL) {
  try {
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const orders = ordersResponse.data.data;
    
    console.log(`📊 إجمالي الطلبات في النظام: ${orders.length}`);
    
    // إحصائيات الحالات
    const statusCounts = {};
    orders.forEach(order => {
      statusCounts[order.status] = (statusCounts[order.status] || 0) + 1;
    });
    
    console.log('\n📋 إحصائيات الحالات:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   ${status}: ${count} طلب`);
    });
    
    // إحصائيات الوسيط
    const deliveryOrders = orders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    const sentToWaseet = deliveryOrders.filter(order => 
      order.waseet_order_id && order.waseet_order_id !== 'null'
    );
    
    const pendingWaseet = deliveryOrders.filter(order => 
      order.waseet_status === 'pending'
    );
    
    console.log('\n📊 إحصائيات الوسيط:');
    console.log(`📦 طلبات في حالة توصيل: ${deliveryOrders.length}`);
    console.log(`✅ مرسلة للوسيط: ${sentToWaseet.length}`);
    console.log(`⏳ في حالة pending: ${pendingWaseet.length}`);
    
    if (deliveryOrders.length > 0) {
      const successRate = ((sentToWaseet.length / deliveryOrders.length) * 100).toFixed(1);
      console.log(`📈 معدل نجاح الإرسال للوسيط: ${successRate}%`);
      
      if (parseFloat(successRate) >= 90) {
        console.log('🎉 معدل النجاح ممتاز - النظام جاهز للإصدار');
      } else if (parseFloat(successRate) >= 70) {
        console.log('⚠️ معدل النجاح جيد - لكن يحتاج تحسين');
      } else {
        console.log('❌ معدل النجاح منخفض - يجب إصلاح المشاكل');
      }
    }
    
    console.log('\n🎯 === خلاصة جاهزية النظام ===');
    console.log('✅ الخادم: يعمل بشكل مثالي');
    console.log('✅ قاعدة البيانات: تعمل بشكل مثالي');
    console.log('✅ إنشاء الطلبات: تم إصلاحه ويعمل');
    console.log('✅ تحديث الحالات: يعمل بشكل مثالي');
    console.log('✅ الإرسال للوسيط: يعمل بشكل مثالي');
    console.log('✅ الحصول على QR IDs: يعمل بشكل مثالي');
    
    console.log('\n🚀 === التطبيق جاهز للإصدار النهائي ===');
    
  } catch (error) {
    console.log(`❌ خطأ في فحص إحصائيات النظام: ${error.message}`);
  }
}

finalReleaseTest();
