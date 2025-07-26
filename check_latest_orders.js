const axios = require('axios');

async function checkLatestOrders() {
  console.log('🔍 === فحص آخر الطلبات المحدثة ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // جلب قائمة الطلبات
    console.log('📋 جلب قائمة الطلبات...');
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });
    
    console.log(`✅ تم جلب ${ordersResponse.data.data.length} طلب`);
    
    // ترتيب الطلبات حسب آخر تحديث
    const sortedOrders = ordersResponse.data.data.sort((a, b) => 
      new Date(b.updated_at) - new Date(a.updated_at)
    );
    
    console.log('\n📊 === آخر 10 طلبات محدثة ===');
    
    for (let i = 0; i < Math.min(10, sortedOrders.length); i++) {
      const order = sortedOrders[i];
      const updatedTime = new Date(order.updated_at);
      const now = new Date();
      const minutesAgo = Math.floor((now - updatedTime) / (1000 * 60));
      
      console.log(`\n${i + 1}. 📦 ${order.id}`);
      console.log(`   👤 العميل: ${order.customer_name}`);
      console.log(`   📊 الحالة: ${order.status}`);
      console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
      console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
      console.log(`   🕐 آخر تحديث: ${minutesAgo} دقيقة مضت`);
      
      // تحليل الحالة
      const isDeliveryStatus = [
        'قيد التوصيل',
        'قيد التوصيل الى الزبون (في عهدة المندوب)',
        'قيد التوصيل الى الزبون',
        'في عهدة المندوب',
        'قيد التوصيل للزبون',
        'shipping',
        'shipped'
      ].includes(order.status);
      
      if (isDeliveryStatus && !order.waseet_order_id) {
        console.log(`   ⚠️ مشكلة: في حالة توصيل لكن لم يرسل للوسيط`);
      } else if (isDeliveryStatus && order.waseet_order_id) {
        console.log(`   ✅ تم إرسال للوسيط بنجاح`);
      }
    }
    
    // البحث عن الطلبات التي في حالة توصيل لكن لم ترسل للوسيط
    console.log('\n🔍 === الطلبات المشكوك فيها ===');
    
    const problematicOrders = sortedOrders.filter(order => {
      const isDeliveryStatus = [
        'قيد التوصيل',
        'قيد التوصيل الى الزبون (في عهدة المندوب)',
        'قيد التوصيل الى الزبون',
        'في عهدة المندوب',
        'قيد التوصيل للزبون',
        'shipping',
        'shipped'
      ].includes(order.status);
      
      return isDeliveryStatus && !order.waseet_order_id;
    });
    
    if (problematicOrders.length > 0) {
      console.log(`⚠️ وجدت ${problematicOrders.length} طلب في حالة توصيل لكن لم يرسل للوسيط:`);
      
      for (const order of problematicOrders) {
        const updatedTime = new Date(order.updated_at);
        const now = new Date();
        const minutesAgo = Math.floor((now - updatedTime) / (1000 * 60));
        
        console.log(`\n📦 ${order.id}`);
        console.log(`   👤 ${order.customer_name}`);
        console.log(`   📊 ${order.status}`);
        console.log(`   🕐 ${minutesAgo} دقيقة مضت`);
        console.log(`   📞 ${order.primary_phone || order.customer_phone || 'لا يوجد رقم'}`);
        console.log(`   📍 ${order.delivery_address || order.notes || 'لا يوجد عنوان'}`);
        
        // فحص سبب عدم الإرسال
        if (!order.primary_phone && !order.customer_phone) {
          console.log(`   ❌ سبب محتمل: لا يوجد رقم هاتف`);
        }
        if (!order.delivery_address && !order.notes) {
          console.log(`   ❌ سبب محتمل: لا يوجد عنوان`);
        }
        if (!order.total && !order.subtotal) {
          console.log(`   ❌ سبب محتمل: لا يوجد مبلغ`);
        }
      }
      
      // اختبار إعادة إرسال أحد الطلبات
      if (problematicOrders.length > 0) {
        console.log('\n🔄 === محاولة إعادة إرسال أحدث طلب ===');
        const latestProblematic = problematicOrders[0];
        await retryOrderToWaseet(latestProblematic);
      }
      
    } else {
      console.log('✅ لا توجد طلبات مشكوك فيها - جميع الطلبات في حالة توصيل مرسلة للوسيط');
    }
    
  } catch (error) {
    console.error('❌ خطأ في فحص الطلبات:', error.message);
    if (error.response) {
      console.error('📋 Status:', error.response.status);
      console.error('📋 Response:', error.response.data);
    }
  }
}

async function retryOrderToWaseet(order) {
  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    console.log(`🔄 محاولة إعادة إرسال الطلب: ${order.id}`);
    
    // محاولة تحديث الحالة مرة أخرى لتشغيل عملية الإرسال
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'إعادة محاولة إرسال للوسيط - اختبار تشخيصي',
      changedBy: 'diagnostic_retry'
    };
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${order.id}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 60000
      }
    );
    
    if (updateResponse.data.success) {
      console.log('✅ تم إرسال طلب إعادة المحاولة');
      
      // انتظار للمعالجة
      console.log('⏳ انتظار 30 ثانية للمعالجة...');
      await new Promise(resolve => setTimeout(resolve, 30000));
      
      // فحص النتيجة
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
        timeout: 30000
      });
      
      const updatedOrder = ordersResponse.data.data.find(o => o.id === order.id);
      
      if (updatedOrder && updatedOrder.waseet_order_id) {
        console.log('🎉 نجحت إعادة المحاولة!');
        console.log(`🆔 QR ID: ${updatedOrder.waseet_order_id}`);
      } else {
        console.log('❌ فشلت إعادة المحاولة - المشكلة أعمق من تحديث الحالة');
      }
      
    } else {
      console.log('❌ فشل في إرسال طلب إعادة المحاولة');
    }
    
  } catch (error) {
    console.error('❌ خطأ في إعادة المحاولة:', error.message);
  }
}

checkLatestOrders();
