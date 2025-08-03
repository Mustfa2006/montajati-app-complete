const axios = require('axios');

async function getRealOrders() {
  const baseURL = 'https://clownfish-app-krnk9.ondigitalocean.app';
  
  console.log('📋 === جلب الطلبات الموجودة ===');
  
  try {
    const response = await axios.get(`${baseURL}/api/orders`, {
      timeout: 10000,
      validateStatus: () => true
    });
    
    console.log(`📊 Status: ${response.status}`);
    
    if (response.status === 200 && response.data?.data) {
      const orders = response.data.data;
      console.log(`✅ تم جلب ${orders.length} طلب`);
      
      if (orders.length > 0) {
        console.log('\n📦 أول 5 طلبات:');
        orders.slice(0, 5).forEach((order, index) => {
          console.log(`${index + 1}. ID: ${order.id} | الحالة: "${order.status}" | العميل: ${order.customer_name}`);
        });
        
        // اختبار تحديث حالة أول طلب
        const firstOrder = orders[0];
        console.log(`\n🧪 اختبار تحديث حالة الطلب: ${firstOrder.id}`);
        
        const updateData = {
          status: 'قيد التحضير',
          notes: 'اختبار تحديث من أداة التشخيص',
          changedBy: 'test_tool'
        };
        
        const updateResponse = await axios.put(`${baseURL}/api/orders/${firstOrder.id}/status`, updateData, {
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000,
          validateStatus: () => true
        });
        
        console.log(`📊 Status تحديث الحالة: ${updateResponse.status}`);
        
        if (updateResponse.status >= 200 && updateResponse.status < 300) {
          console.log('🎉 نجح تحديث الحالة!');
          console.log('✅ المشكلة الأصلية تم حلها - تحديث حالة الطلب يعمل الآن');
          console.log(`📄 النتيجة: ${JSON.stringify(updateResponse.data, null, 2)}`);
        } else {
          console.log('❌ فشل تحديث الحالة');
          console.log(`📄 تفاصيل الخطأ: ${JSON.stringify(updateResponse.data, null, 2)}`);
        }
        
      } else {
        console.log('⚠️ لا توجد طلبات في النظام');
      }
      
    } else {
      console.log(`❌ فشل في جلب الطلبات: ${response.status}`);
      if (response.data) {
        console.log(`📄 التفاصيل: ${JSON.stringify(response.data, null, 2)}`);
      }
    }
    
  } catch (error) {
    console.log(`❌ خطأ في جلب الطلبات: ${error.message}`);
  }
}

getRealOrders().catch(console.error);
