// ===================================
// اختبار إنشاء طلب جديد
// ===================================

const axios = require('axios');

const BACKEND_URL = 'https://montajati-official-backend-production.up.railway.app';

async function testCreateOrder() {
  console.log('🧪 اختبار إنشاء طلب جديد...\n');

  const testOrder = {
    customer_name: 'اختبار تنظيف Logs',
    primary_phone: '07501234567',
    province: 'بغداد',
    city: 'الكرادة',
    notes: 'طلب اختبار لتنظيف console.log',
    subtotal: 10000,
    total: 10000,
    profit: 2000,
    user_phone: '07511111111',
    items: [
      {
        product_id: 'test-product-id',
        product_name: 'منتج اختبار',
        quantity: 1,
        customer_price: 10000,
        wholesale_price: 8000,
        profit_per_item: 2000
      }
    ]
  };

  try {
    console.log('📤 إرسال طلب إنشاء...');
    const response = await axios.post(`${BACKEND_URL}/api/orders`, testOrder, {
      timeout: 30000
    });

    console.log('✅ تم إنشاء الطلب بنجاح');
    console.log('📋 معرف الطلب:', response.data.data?.id);
    console.log('📊 الاستجابة:', JSON.stringify(response.data, null, 2));

  } catch (error) {
    if (error.response) {
      console.error('❌ خطأ في إنشاء الطلب:', error.response.status, error.response.data);
    } else {
      console.error('❌ خطأ في إنشاء الطلب:', error.message);
    }
  }
}

// تشغيل الاختبار
testCreateOrder().catch(console.error);

