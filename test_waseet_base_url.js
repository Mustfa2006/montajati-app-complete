const axios = require('axios');

async function testWaseetBaseURLs() {
  console.log('🔍 === اختبار روابط شركة الوسيط المختلفة ===\n');
  
  const baseUrls = [
    'https://api.alwaseet-iq.net',
    'https://alwaseet-iq.net',
    'https://www.alwaseet-iq.net',
    'https://merchant.alwaseet-iq.net',
    'https://app.alwaseet-iq.net',
    'https://portal.alwaseet-iq.net'
  ];
  
  for (const baseUrl of baseUrls) {
    try {
      console.log(`🔍 اختبار: ${baseUrl}`);
      
      const response = await axios.get(baseUrl, {
        timeout: 10000,
        validateStatus: (status) => status < 500
      });
      
      console.log(`✅ ${baseUrl} - الحالة: ${response.status}`);
      
      if (response.data) {
        const content = response.data.toString().toLowerCase();
        if (content.includes('login') || content.includes('تسجيل') || content.includes('دخول')) {
          console.log(`   🎯 يحتوي على صفحة تسجيل دخول!`);
        }
        if (content.includes('api') || content.includes('merchant')) {
          console.log(`   📡 يحتوي على إشارات API!`);
        }
      }
      
    } catch (error) {
      console.log(`❌ ${baseUrl} - خطأ: ${error.message}`);
    }
    
    console.log('');
  }
  
  // اختبار مسارات API مختلفة
  console.log('🔍 === اختبار مسارات API ===\n');
  
  const apiPaths = [
    '/v1/merchant/statuses',
    '/api/v1/merchant/statuses', 
    '/merchant/statuses',
    '/statuses',
    '/v1/statuses'
  ];
  
  for (const baseUrl of ['https://api.alwaseet-iq.net', 'https://alwaseet-iq.net']) {
    console.log(`🔍 اختبار API على: ${baseUrl}`);
    
    for (const path of apiPaths) {
      try {
        const response = await axios.get(`${baseUrl}${path}`, {
          timeout: 5000,
          validateStatus: (status) => status < 500
        });
        
        console.log(`   ✅ ${path} - الحالة: ${response.status}`);
        
      } catch (error) {
        console.log(`   ❌ ${path} - خطأ: ${error.response?.status || error.message}`);
      }
    }
    console.log('');
  }
}

testWaseetBaseURLs().catch(console.error);
