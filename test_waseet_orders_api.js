const OfficialWaseetAPI = require('./backend/services/official_waseet_api');
require('dotenv').config();

async function testWaseetOrdersAPI() {
  console.log('🔍 === اختبار APIs الطلبات من الوسيط ===\n');
  
  try {
    // إنشاء API مع الحساب الجديد
    const api = new OfficialWaseetAPI(
      'mustfaabd',
      '65888304'
    );

    // تسجيل الدخول
    console.log('🔐 تسجيل الدخول...');
    const token = await api.authenticate();
    
    if (!token) {
      throw new Error('فشل تسجيل الدخول');
    }
    
    console.log(`✅ تم تسجيل الدخول بنجاح`);

    const axios = require('axios');
    
    // قائمة APIs محتملة للطلبات (بناءً على نمط /v1/merchant/statuses)
    const possibleOrderAPIs = [
      '/v1/merchant/orders',
      '/v1/merchant/order',
      '/v1/merchant/shipments',
      '/v1/merchant/deliveries',
      '/v1/merchant/tracking',
      '/v1/merchant/my-orders',
      '/v1/merchant/order-list',
      '/v1/orders',
      '/v1/shipments',
      '/v1/deliveries'
    ];

    console.log(`📡 اختبار ${possibleOrderAPIs.length} API محتمل للطلبات...\n`);

    for (let i = 0; i < possibleOrderAPIs.length; i++) {
      const endpoint = possibleOrderAPIs[i];
      const fullUrl = `https://api.alwaseet-iq.net${endpoint}`;
      
      console.log(`${i + 1}/${possibleOrderAPIs.length} 🔍 ${endpoint}`);

      try {
        // جرب مع التوكن في query parameter (نفس طريقة /statuses)
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

        console.log(`📊 كود الاستجابة: ${response.status}`);
        
        if (response.status === 200 && response.data) {
          console.log(`✅ نجح! البيانات:`);
          console.log(JSON.stringify(response.data, null, 2));
          
          // تحقق من تنسيق البيانات
          const data = response.data;
          
          if (data.status === true && data.errNum === 'S000') {
            console.log(`🎉 === API صحيح وناجح ===`);
            console.log(`📝 الرسالة: ${data.msg}`);
            
            if (Array.isArray(data.data)) {
              console.log(`📊 عدد الطلبات: ${data.data.length}`);
              
              if (data.data.length > 0) {
                console.log(`🔍 عينة من الطلبات:`);
                data.data.slice(0, 3).forEach((order, index) => {
                  console.log(`   ${index + 1}. ID: ${order.id || 'غير محدد'}`);
                  console.log(`      الحالة: ${order.status || 'غير محدد'}`);
                  console.log(`      العميل: ${order.customer_name || order.client_name || 'غير محدد'}`);
                  console.log(`      التاريخ: ${order.created_at || order.date || 'غير محدد'}`);
                  console.log('');
                });
              }
            } else if (typeof data.data === 'object') {
              console.log(`📋 بيانات الطلب الواحد:`);
              console.log(`   ID: ${data.data.id || 'غير محدد'}`);
              console.log(`   الحالة: ${data.data.status || 'غير محدد'}`);
              console.log(`   العميل: ${data.data.customer_name || data.data.client_name || 'غير محدد'}`);
            }
            
            console.log(`\n🎯 === تم العثور على API الطلبات ===`);
            console.log(`🔗 API: ${endpoint}`);
            console.log(`📄 يمكن استخدام هذا API لجلب الطلبات`);
            break;
            
          } else {
            console.log(`⚠️ تنسيق غير متوقع:`, data);
          }
          
        } else if (response.status === 404) {
          console.log(`❌ غير موجود (404)`);
        } else if (response.status === 401) {
          console.log(`🔐 غير مصرح (401)`);
        } else if (response.status === 403) {
          console.log(`🚫 ممنوع (403)`);
        } else {
          console.log(`⚠️ كود: ${response.status}`);
          if (response.data) {
            console.log(`📄 البيانات:`, response.data);
          }
        }

      } catch (error) {
        if (error.response?.status === 404) {
          console.log(`❌ غير موجود (404)`);
        } else if (error.response?.status === 401) {
          console.log(`🔐 غير مصرح (401)`);
        } else if (error.response?.status === 403) {
          console.log(`🚫 ممنوع (403)`);
        } else if (error.code === 'ECONNABORTED') {
          console.log(`⏰ انتهت المهلة الزمنية`);
        } else {
          console.log(`❌ خطأ: ${error.response?.status || error.message}`);
        }
      }
      
      console.log(''); // سطر فارغ
      
      // توقف قصير لتجنب التحميل الزائد
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    console.log('\n📋 === ملخص النتائج ===');
    console.log('إذا لم يتم العثور على API للطلبات:');
    console.log('1. تواصل مع شركة الوسيط للحصول على التوثيق الكامل');
    console.log('2. اطلب API لجلب الطلبات أو حالات الطلبات');
    console.log('3. تأكد من صلاحيات الحساب');

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
testWaseetOrdersAPI();
