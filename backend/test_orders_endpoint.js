// ===================================
// اختبار endpoint الطلبات مباشرة
// ===================================

const axios = require('axios');

const BACKEND_URL = 'https://montajati-official-backend-production.up.railway.app';

async function testOrdersEndpoint() {
  console.log('🔍 اختبار endpoints الطلبات...\n');

  // اختبار 1: الصفحة الرئيسية
  console.log('📊 اختبار 1: الصفحة الرئيسية...');
  try {
    const response = await axios.get(`${BACKEND_URL}/`);
    console.log('✅ الصفحة الرئيسية تعمل');
    console.log('📋 البيانات:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('❌ خطأ في الصفحة الرئيسية:', error.message);
  }
  console.log('');

  // اختبار 2: health check
  console.log('📊 اختبار 2: health check...');
  try {
    const response = await axios.get(`${BACKEND_URL}/health`);
    console.log('✅ health check يعمل');
    console.log('📋 البيانات:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('❌ خطأ في health check:', error.message);
  }
  console.log('');

  // اختبار 3: system status
  console.log('📊 اختبار 3: system status...');
  try {
    const response = await axios.get(`${BACKEND_URL}/api/system/status`);
    console.log('✅ system status يعمل');
    console.log('📋 البيانات:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('❌ خطأ في system status:', error.message);
  }
  console.log('');

  // اختبار 4: monitor metrics
  console.log('📊 اختبار 4: monitor metrics...');
  try {
    const response = await axios.get(`${BACKEND_URL}/api/monitor/metrics`);
    console.log('✅ monitor metrics يعمل');
    console.log('📋 البيانات:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('❌ خطأ في monitor metrics:', error.message);
  }
  console.log('');

  // اختبار 5: user orders counts
  console.log('📊 اختبار 5: user orders counts...');
  try {
    const response = await axios.get(`${BACKEND_URL}/api/orders/user/07511111111/counts`, {
      timeout: 30000
    });
    console.log('✅ user orders counts يعمل');
    console.log('📋 البيانات:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    if (error.response) {
      console.error('❌ خطأ في user orders counts:', error.response.status, error.response.data);
    } else {
      console.error('❌ خطأ في user orders counts:', error.message);
    }
  }
  console.log('');

  // اختبار 6: user orders
  console.log('📊 اختبار 6: user orders...');
  try {
    const response = await axios.get(`${BACKEND_URL}/api/orders/user/07511111111?page=0&limit=5`, {
      timeout: 30000
    });
    console.log('✅ user orders يعمل');
    console.log('📋 عدد الطلبات:', response.data.data?.length || 0);
    console.log('📋 البيانات:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    if (error.response) {
      console.error('❌ خطأ في user orders:', error.response.status, error.response.data);
    } else {
      console.error('❌ خطأ في user orders:', error.message);
    }
  }
  console.log('');

  console.log('✅ جميع الاختبارات اكتملت!');
}

// تشغيل الاختبار
testOrdersEndpoint().catch(console.error);

