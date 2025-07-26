const axios = require('axios');

async function checkProblemOrders() {
  console.log('🔍 === فحص الطلبات المشكلة ===\n');
  
  try {
    const response = await axios.get('https://montajati-backend.onrender.com/api/orders', { 
      timeout: 15000 
    });
    
    const allOrders = response.data.data;
    console.log(`📊 إجمالي الطلبات: ${allOrders.length}`);
    
    // البحث عن الطلبات في حالة التوصيل
    const deliveryOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    console.log(`📦 طلبات في حالة التوصيل: ${deliveryOrders.length}`);
    
    // الطلبات بدون معرف وسيط
    const ordersWithoutWaseet = deliveryOrders.filter(order => 
      !order.waseet_order_id || order.waseet_order_id === 'null' || order.waseet_order_id === null
    );
    
    console.log(`❌ طلبات بدون معرف وسيط: ${ordersWithoutWaseet.length}`);
    
    if (ordersWithoutWaseet.length > 0) {
      console.log('\n📋 تفاصيل الطلبات المشكلة:');
      
      ordersWithoutWaseet.slice(0, 10).forEach((order, index) => {
        console.log(`\n${index + 1}. طلب: ${order.id}`);
        console.log(`   👤 العميل: ${order.customer_name}`);
        console.log(`   📅 تاريخ الإنشاء: ${order.created_at}`);
        console.log(`   📅 آخر تحديث: ${order.updated_at}`);
        console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        
        // حساب الوقت منذ آخر تحديث
        const updatedTime = new Date(order.updated_at);
        const now = new Date();
        const diffMinutes = Math.floor((now - updatedTime) / (1000 * 60));
        console.log(`   ⏰ منذ آخر تحديث: ${diffMinutes} دقيقة`);
        
        if (order.waseet_data) {
          try {
            const waseetData = JSON.parse(order.waseet_data);
            if (waseetData.error) {
              console.log(`   ❌ خطأ الوسيط: ${waseetData.error}`);
            }
            if (waseetData.lastAttempt) {
              console.log(`   🕐 آخر محاولة: ${waseetData.lastAttempt}`);
            }
          } catch (e) {
            console.log(`   📋 بيانات الوسيط: ${order.waseet_data.substring(0, 50)}...`);
          }
        }
      });
      
      // اختبار إرسال يدوي لآخر طلب مشكلة
      const latestProblemOrder = ordersWithoutWaseet[0];
      console.log(`\n🔧 === محاولة إرسال يدوي لآخر طلب مشكلة ===`);
      console.log(`📦 الطلب: ${latestProblemOrder.id}`);
      
      try {
        const manualSendResponse = await axios.post(
          `https://montajati-backend.onrender.com/api/orders/${latestProblemOrder.id}/send-to-waseet`, 
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
        
        if (manualSendResponse.data?.success) {
          console.log(`✅ الإرسال اليدوي نجح!`);
          console.log(`🆔 QR ID: ${manualSendResponse.data.data?.qrId}`);
          console.log(`🔍 المشكلة: النظام التلقائي لا يعمل، لكن الإرسال اليدوي يعمل`);
        } else {
          console.log(`❌ الإرسال اليدوي فشل أيضاً`);
          console.log(`🔍 تفاصيل الخطأ:`, manualSendResponse.data);
        }
        
      } catch (error) {
        console.log(`❌ خطأ في الإرسال اليدوي: ${error.message}`);
        if (error.response) {
          console.log(`📊 Status: ${error.response.status}`);
          console.log(`📋 Data:`, error.response.data);
        }
      }
      
    } else {
      console.log('\n✅ جميع الطلبات في حالة التوصيل تم إرسالها للوسيط بنجاح!');
      console.log('🎯 النظام يعمل بشكل صحيح');
    }
    
    // فحص آخر 5 طلبات تم إرسالها بنجاح
    const successfulOrders = deliveryOrders.filter(order => 
      order.waseet_order_id && order.waseet_order_id !== 'null' && order.waseet_order_id !== null
    );
    
    console.log(`\n✅ طلبات تم إرسالها بنجاح: ${successfulOrders.length}`);
    
    if (successfulOrders.length > 0) {
      console.log('\n📋 آخر 3 طلبات ناجحة:');
      
      successfulOrders.slice(0, 3).forEach((order, index) => {
        console.log(`\n${index + 1}. طلب: ${order.id}`);
        console.log(`   👤 العميل: ${order.customer_name}`);
        console.log(`   📅 آخر تحديث: ${order.updated_at}`);
        console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id}`);
        console.log(`   📦 حالة الوسيط: ${order.waseet_status}`);
      });
    }
    
  } catch (error) {
    console.error('❌ خطأ في فحص الطلبات:', error.message);
  }
}

checkProblemOrders();
