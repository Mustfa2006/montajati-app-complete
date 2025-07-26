const axios = require('axios');

async function checkPendingOrdersNow() {
  console.log('🔍 === فحص الطلبات التي كانت في حالة pending ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  // الطلبات التي كانت في حالة pending في التحليل السابق
  const previouslyPendingOrders = [
    'order_1753478889109_1111',
    'order_1753473073199_6564', 
    'order_1753465511829_2222',
    'order_1753451944028_5555',
    'order_1753450297027_5555'
  ];
  
  try {
    // جلب جميع الطلبات
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 30000 });
    const allOrders = ordersResponse.data.data;
    
    console.log('📊 فحص الطلبات التي كانت في حالة pending سابقاً:\n');
    
    let stillPendingCount = 0;
    let nowSuccessfulCount = 0;
    
    for (const orderId of previouslyPendingOrders) {
      const order = allOrders.find(o => o.id === orderId);
      
      if (!order) {
        console.log(`❌ لم يتم العثور على الطلب: ${orderId}\n`);
        continue;
      }
      
      console.log(`📦 === ${orderId} ===`);
      console.log(`👤 العميل: ${order.customer_name}`);
      console.log(`📊 الحالة: ${order.status}`);
      console.log(`🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
      console.log(`📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
      console.log(`🕐 آخر تحديث: ${order.updated_at}`);
      
      // تحليل التغيير
      if (order.waseet_status === 'pending') {
        console.log(`⚠️ لا يزال في حالة pending`);
        stillPendingCount++;
      } else if (order.waseet_order_id && order.waseet_order_id !== 'null') {
        console.log(`✅ تم إرساله للوسيط بنجاح - QR ID: ${order.waseet_order_id}`);
        nowSuccessfulCount++;
      } else {
        console.log(`❓ حالة غير واضحة`);
      }
      
      console.log('');
    }
    
    console.log('📊 === ملخص النتائج ===');
    console.log(`✅ تم إرسالها للوسيط بنجاح: ${nowSuccessfulCount}`);
    console.log(`⚠️ لا تزال في حالة pending: ${stillPendingCount}`);
    console.log(`📈 معدل النجاح: ${((nowSuccessfulCount / previouslyPendingOrders.length) * 100).toFixed(1)}%`);
    
    // فحص جميع الطلبات الحالية في حالة pending
    console.log('\n🔍 === فحص جميع الطلبات الحالية في حالة pending ===');
    
    const currentPendingOrders = allOrders.filter(order => 
      order.waseet_status === 'pending'
    );
    
    console.log(`📦 عدد الطلبات في حالة pending حالياً: ${currentPendingOrders.length}`);
    
    if (currentPendingOrders.length > 0) {
      console.log('\n📋 الطلبات في حالة pending:');
      
      currentPendingOrders.forEach(order => {
        const timeDiff = new Date() - new Date(order.updated_at);
        const minutesAgo = Math.floor(timeDiff / (1000 * 60));
        
        console.log(`   📦 ${order.id} - ${order.customer_name}`);
        console.log(`      📊 الحالة: ${order.status}`);
        console.log(`      ⏰ منذ: ${minutesAgo} دقيقة`);
        console.log(`      📞 الهاتف: ${order.primary_phone || 'غير محدد'}`);
        console.log(`      📍 العنوان: ${order.customer_address || order.delivery_address || 'غير محدد'}`);
        
        if (minutesAgo > 5) {
          console.log(`      🚨 تحذير: في حالة pending لفترة طويلة!`);
        }
        
        console.log('');
      });
      
      // محاولة إصلاح الطلبات في حالة pending لفترة طويلة
      const oldPendingOrders = currentPendingOrders.filter(order => {
        const timeDiff = new Date() - new Date(order.updated_at);
        const minutesAgo = Math.floor(timeDiff / (1000 * 60));
        return minutesAgo > 5;
      });
      
      if (oldPendingOrders.length > 0) {
        console.log(`🔧 === محاولة إصلاح ${oldPendingOrders.length} طلب في حالة pending لفترة طويلة ===`);
        
        for (const order of oldPendingOrders.slice(0, 3)) { // أول 3 طلبات فقط
          console.log(`\n🔄 محاولة إصلاح الطلب: ${order.id}`);
          
          try {
            const updateData = {
              status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
              notes: `إصلاح طلب pending - ${new Date().toISOString()}`,
              changedBy: 'pending_fix_script'
            };
            
            const updateResponse = await axios.put(
              `${baseURL}/api/orders/${order.id}/status`,
              updateData,
              {
                headers: {
                  'Content-Type': 'application/json'
                },
                timeout: 30000
              }
            );
            
            if (updateResponse.data.success) {
              console.log(`✅ تم إرسال طلب إصلاح للطلب ${order.id}`);
              
              // انتظار قصير
              await new Promise(resolve => setTimeout(resolve, 10000));
              
              // فحص النتيجة
              const ordersResponse2 = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
              const updatedOrder = ordersResponse2.data.data.find(o => o.id === order.id);
              
              if (updatedOrder && updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
                console.log(`🎉 نجح الإصلاح! QR ID: ${updatedOrder.waseet_order_id}`);
              } else {
                console.log(`❌ لم ينجح الإصلاح - لا يزال بدون QR ID`);
                console.log(`📦 حالة الوسيط: ${updatedOrder?.waseet_status || 'غير محدد'}`);
              }
              
            } else {
              console.log(`❌ فشل في إرسال طلب الإصلاح للطلب ${order.id}`);
            }
            
          } catch (error) {
            console.log(`❌ خطأ في إصلاح الطلب ${order.id}: ${error.message}`);
          }
        }
      }
      
    } else {
      console.log('✅ لا توجد طلبات في حالة pending حالياً');
    }
    
    // فحص إحصائيات عامة
    console.log('\n📊 === إحصائيات عامة ===');
    
    const deliveryOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    const sentToWaseet = deliveryOrders.filter(order => 
      order.waseet_order_id && order.waseet_order_id !== 'null'
    );
    
    const pendingWaseet = deliveryOrders.filter(order => 
      order.waseet_status === 'pending'
    );
    
    const failedWaseet = deliveryOrders.filter(order => 
      order.waseet_status === 'في انتظار الإرسال للوسيط'
    );
    
    console.log(`📦 إجمالي الطلبات في حالة توصيل: ${deliveryOrders.length}`);
    console.log(`✅ مرسلة للوسيط بنجاح: ${sentToWaseet.length}`);
    console.log(`⚠️ في حالة pending: ${pendingWaseet.length}`);
    console.log(`❌ فشلت في الإرسال: ${failedWaseet.length}`);
    console.log(`📈 معدل النجاح الحالي: ${((sentToWaseet.length / deliveryOrders.length) * 100).toFixed(1)}%`);
    
  } catch (error) {
    console.error('❌ خطأ في فحص الطلبات:', error.message);
  }
}

checkPendingOrdersNow();
