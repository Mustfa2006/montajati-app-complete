const axios = require('axios');

async function debugDetailedError() {
  console.log('🔍 === تشخيص مفصل للخطأ ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  const testOrderData = {
    customer_name: 'اختبار تفصيلي',
    primary_phone: '07901234567',
    secondary_phone: '07709876543',
    customer_address: 'بغداد - الكرخ - اختبار',
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
    order_number: `ORD-DEBUG-${Date.now()}`,
    notes: 'طلب اختبار تفصيلي'
  };
  
  try {
    console.log('📤 إرسال طلب اختبار...');
    console.log('📋 البيانات:', JSON.stringify(testOrderData, null, 2));
    
    const response = await axios.post(`${baseURL}/api/orders`, testOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000,
      validateStatus: () => true
    });
    
    console.log(`\n📥 استجابة مفصلة:`);
    console.log(`📊 Status: ${response.status}`);
    console.log(`📋 Response:`, JSON.stringify(response.data, null, 2));
    
    if (response.data.details) {
      console.log(`\n🔍 تفاصيل الخطأ: ${response.data.details}`);
    }
    
    if (response.data.code) {
      console.log(`🔍 كود الخطأ: ${response.data.code}`);
    }
    
  } catch (error) {
    console.error('❌ خطأ في الطلب:', error.message);
    if (error.response) {
      console.error('📋 Response:', error.response.data);
    }
  }
}

debugDetailedError();
