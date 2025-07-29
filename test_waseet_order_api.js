const OfficialWaseetAPI = require('./backend/services/official_waseet_api');
require('dotenv').config();

async function testWaseetOrderAPI() {
  console.log('🔍 === اختبار جلب طلب محدد من الوسيط ===\n');
  
  try {
    // إنشاء API
    const api = new OfficialWaseetAPI(
      process.env.WASEET_USERNAME,
      process.env.WASEET_PASSWORD
    );

    // تسجيل الدخول
    console.log('🔐 تسجيل الدخول...');
    const token = await api.authenticate();
    
    if (!token) {
      throw new Error('فشل تسجيل الدخول');
    }
    
    console.log(`✅ تم تسجيل الدخول بنجاح`);
    console.log(`🎫 التوكن: ${token.substring(0, 20)}...`);

    // اختبار طلب موجود (من قاعدة البيانات)
    const testOrderId = '96613333'; // من الطلبات الموجودة
    
    console.log(`\n🔍 اختبار جلب الطلب: ${testOrderId}`);
    
    // قائمة endpoints محتملة
    const endpoints = [
      `/v1/merchant/order/${testOrderId}`,
      `/v1/merchant/orders/${testOrderId}`,
      `/v1/order/${testOrderId}`,
      `/v1/orders/${testOrderId}`,
      `/merchant/order/${testOrderId}`,
      `/merchant/orders/${testOrderId}`,
      `/order/${testOrderId}`,
      `/orders/${testOrderId}`,
      `/v1/merchant/order-status/${testOrderId}`,
      `/v1/merchant/order-details/${testOrderId}`,
      `/v1/merchant/track/${testOrderId}`,
      `/v1/track/${testOrderId}`
    ];

    let foundEndpoint = null;
    let orderData = null;

    for (const endpoint of endpoints) {
      try {
        const fullUrl = `https://api.alwaseet-iq.net${endpoint}`;
        console.log(`🔍 جرب: ${fullUrl}`);

        const axios = require('axios');
        
        // جرب مع التوكن في query parameter
        const response = await axios.get(fullUrl, {
          params: {
            token: token
          },
          headers: {
            'User-Agent': 'Montajati-App/2.2.0',
            'Accept': 'application/json'
          },
          timeout: 10000,
          validateStatus: (status) => status < 500
        });

        console.log(`📊 استجابة: ${response.status}`);
        
        if (response.status === 200 && response.data) {
          console.log(`✅ نجح endpoint: ${endpoint}`);
          console.log(`📄 البيانات:`, JSON.stringify(response.data, null, 2));
          
          foundEndpoint = endpoint;
          orderData = response.data;
          break;
        } else if (response.status === 404) {
          console.log(`❌ ${endpoint}: غير موجود (404)`);
        } else {
          console.log(`⚠️ ${endpoint}: ${response.status} - ${response.statusText}`);
        }

      } catch (error) {
        if (error.response?.status === 404) {
          console.log(`❌ ${endpoint}: غير موجود (404)`);
        } else {
          console.log(`❌ ${endpoint}: ${error.response?.status || error.message}`);
        }
      }
    }

    if (foundEndpoint) {
      console.log(`\n🎉 === تم العثور على endpoint صحيح ===`);
      console.log(`🔗 Endpoint: ${foundEndpoint}`);
      console.log(`📄 بيانات الطلب:`, orderData);
      
      // استخراج معلومات الحالة
      if (orderData.status) {
        console.log(`\n📊 === معلومات الحالة ===`);
        console.log(`🔢 ID الحالة: ${orderData.status_id || 'غير محدد'}`);
        console.log(`📝 نص الحالة: ${orderData.status || 'غير محدد'}`);
        console.log(`📅 تاريخ التحديث: ${orderData.updated_at || 'غير محدد'}`);
      }
      
    } else {
      console.log('\n❌ === لم يتم العثور على endpoint صحيح ===');
      console.log('💡 جرب endpoints أخرى أو تحقق من التوثيق');
      
      // جرب جلب جميع الطلبات
      console.log('\n🔍 جرب جلب جميع الطلبات...');
      
      const allOrdersEndpoints = [
        '/v1/merchant/orders',
        '/v1/orders',
        '/merchant/orders',
        '/orders'
      ];
      
      for (const endpoint of allOrdersEndpoints) {
        try {
          const fullUrl = `https://api.alwaseet-iq.net${endpoint}`;
          console.log(`🔍 جرب جميع الطلبات: ${fullUrl}`);

          const axios = require('axios');
          const response = await axios.get(fullUrl, {
            params: {
              token: token,
              limit: 5 // جلب 5 طلبات فقط للاختبار
            },
            headers: {
              'User-Agent': 'Montajati-App/2.2.0',
              'Accept': 'application/json'
            },
            timeout: 10000,
            validateStatus: (status) => status < 500
          });

          console.log(`📊 استجابة جميع الطلبات: ${response.status}`);
          
          if (response.status === 200 && response.data) {
            console.log(`✅ نجح endpoint جميع الطلبات: ${endpoint}`);
            console.log(`📄 عينة من الطلبات:`, JSON.stringify(response.data, null, 2));
            break;
          }

        } catch (error) {
          console.log(`❌ جميع الطلبات ${endpoint}: ${error.response?.status || error.message}`);
        }
      }
    }

  } catch (error) {
    console.error('\n❌ === خطأ في الاختبار ===');
    console.error(`📝 الخطأ: ${error.message}`);
    
    if (error.response) {
      console.error(`📊 كود HTTP: ${error.response.status}`);
      console.error(`📄 بيانات الخطأ:`, error.response.data);
    }
  }
}

// تشغيل الاختبار
testWaseetOrderAPI();
