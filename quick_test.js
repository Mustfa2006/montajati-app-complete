const axios = require('axios');

async function quickTest() {
  console.log('⚡ اختبار سريع للخادم');
  
  try {
    const response = await axios.get('https://montajati-backend.onrender.com/api/orders', { 
      timeout: 10000 
    });
    
    console.log(`✅ الخادم يعمل - عدد الطلبات: ${response.data.data.length}`);
    
    // فحص آخر طلب
    const lastOrder = response.data.data[0];
    if (lastOrder) {
      console.log(`📋 آخر طلب:`);
      console.log(`   ID: ${lastOrder.id}`);
      console.log(`   الحالة: ${lastOrder.status}`);
      console.log(`   معرف الوسيط: ${lastOrder.waseet_order_id || 'غير محدد'}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ: ${error.message}`);
  }
}

quickTest();
