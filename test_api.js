const axios = require('axios');

async function testUpdateOrderStatus() {
  try {
    console.log('🧪 اختبار تحديث حالة الطلب عبر Backend API...');
    
    const orderId = 'test_order_1753115468';
    const newStatus = 'مغلق';
    
    console.log(`📦 الطلب: ${orderId}`);
    console.log(`🔄 الحالة الجديدة: ${newStatus}`);
    
    const response = await axios.put(
      `https://montajati-backend.onrender.com/api/orders/${orderId}/status`,
      {
        status: newStatus,
        notes: 'اختبار تحديث الحالة من سكريبت الاختبار',
        changedBy: 'test_script'
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 30000
      }
    );

    console.log(`✅ نجح تحديث الحالة عبر API:`);
    console.log(`   📊 كود الاستجابة: ${response.status}`);
    console.log(`   📝 الرسالة: ${response.data.message}`);
    console.log(`   🔄 البيانات:`, response.data.data);
    
  } catch (error) {
    console.error('❌ خطأ في اختبار API:', error.message);
    if (error.response) {
      console.error('   📊 كود الخطأ:', error.response.status);
      console.error('   📝 رسالة الخطأ:', error.response.data);
    }
  }
}

testUpdateOrderStatus();
