const OfficialWaseetAPI = require('./backend/services/official_waseet_api');
require('dotenv').config();

async function findOrderStatusAPI() {
  console.log('🔍 === البحث عن API جلب حالة الطلب الفعلية ===\n');
  
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

    // طلب موجود للاختبار
    const testOrderId = '96613333';
    console.log(`\n🎯 البحث عن حالة الطلب: ${testOrderId}`);
    
    const axios = require('axios');
    
    // قائمة شاملة من endpoints محتملة
    const possibleAPIs = [
      // APIs للطلب المحدد
      `/v1/merchant/order/${testOrderId}`,
      `/v1/merchant/orders/${testOrderId}`,
      `/v1/merchant/order-status/${testOrderId}`,
      `/v1/merchant/order-details/${testOrderId}`,
      `/v1/merchant/track/${testOrderId}`,
      `/v1/order/${testOrderId}`,
      `/v1/orders/${testOrderId}`,
      `/v1/track/${testOrderId}`,
      `/merchant/order/${testOrderId}`,
      `/merchant/orders/${testOrderId}`,
      `/order/${testOrderId}`,
      `/orders/${testOrderId}`,
      
      // APIs لجميع الطلبات (قد تحتوي على الطلب المطلوب)
      `/v1/merchant/orders`,
      `/v1/merchant/my-orders`,
      `/v1/orders`,
      `/merchant/orders`,
      `/orders`,
      
      // APIs أخرى محتملة
      `/v1/merchant/order-list`,
      `/v1/merchant/shipments`,
      `/v1/shipments`,
      `/v1/merchant/deliveries`,
      `/v1/deliveries`
    ];

    let foundAPI = null;
    let orderData = null;

    console.log(`📡 اختبار ${possibleAPIs.length} API محتمل...\n`);

    for (let i = 0; i < possibleAPIs.length; i++) {
      const endpoint = possibleAPIs[i];
      const fullUrl = `https://api.alwaseet-iq.net${endpoint}`;
      
      console.log(`${i + 1}/${possibleAPIs.length} 🔍 ${endpoint}`);

      try {
        // جرب مع التوكن في query parameter
        const response = await axios.get(fullUrl, {
          params: {
            token: token
          },
          headers: {
            'User-Agent': 'Montajati-App/2.2.0',
            'Accept': 'application/json'
          },
          timeout: 8000,
          validateStatus: (status) => status < 500
        });

        if (response.status === 200 && response.data) {
          console.log(`✅ نجح! كود: ${response.status}`);
          
          // تحقق من وجود بيانات مفيدة
          const data = response.data;
          
          if (data.status === true && data.data) {
            console.log(`📄 البيانات:`, JSON.stringify(data, null, 2));
            
            // تحقق من وجود الطلب المطلوب في البيانات
            let containsOrder = false;
            
            if (Array.isArray(data.data)) {
              // إذا كانت مصفوفة، ابحث عن الطلب
              containsOrder = data.data.some(item => 
                item.id === testOrderId || 
                item.order_id === testOrderId ||
                item.waseet_order_id === testOrderId ||
                JSON.stringify(item).includes(testOrderId)
              );
            } else if (typeof data.data === 'object') {
              // إذا كان كائن واحد، تحقق منه
              containsOrder = 
                data.data.id === testOrderId || 
                data.data.order_id === testOrderId ||
                data.data.waseet_order_id === testOrderId ||
                JSON.stringify(data.data).includes(testOrderId);
            }
            
            if (containsOrder) {
              console.log(`🎉 تم العثور على الطلب ${testOrderId} في هذا API!`);
              foundAPI = endpoint;
              orderData = data;
              break;
            } else {
              console.log(`⚠️ API يعمل لكن لا يحتوي على الطلب ${testOrderId}`);
              
              // إذا كان يحتوي على طلبات أخرى، اعرض عينة
              if (Array.isArray(data.data) && data.data.length > 0) {
                console.log(`📋 عينة من الطلبات الموجودة:`);
                data.data.slice(0, 3).forEach(order => {
                  console.log(`   - ID: ${order.id || order.order_id || 'غير محدد'}, الحالة: ${order.status || 'غير محدد'}`);
                });
              }
            }
          } else {
            console.log(`⚠️ استجابة غير متوقعة:`, data);
          }
          
        } else if (response.status === 404) {
          console.log(`❌ غير موجود (404)`);
        } else {
          console.log(`⚠️ كود: ${response.status}`);
        }

      } catch (error) {
        if (error.response?.status === 404) {
          console.log(`❌ غير موجود (404)`);
        } else if (error.response?.status === 401) {
          console.log(`🔐 غير مصرح (401) - مشكلة في التوكن`);
        } else if (error.response?.status === 403) {
          console.log(`🚫 ممنوع (403) - لا توجد صلاحية`);
        } else if (error.code === 'ECONNABORTED') {
          console.log(`⏰ انتهت المهلة الزمنية`);
        } else {
          console.log(`❌ خطأ: ${error.response?.status || error.message}`);
        }
      }
      
      // توقف قصير لتجنب التحميل الزائد
      await new Promise(resolve => setTimeout(resolve, 200));
    }

    if (foundAPI) {
      console.log(`\n🎉 === تم العثور على API الصحيح ===`);
      console.log(`🔗 API: ${foundAPI}`);
      console.log(`📄 بيانات الطلب:`, JSON.stringify(orderData, null, 2));
      
      // استخراج معلومات الحالة
      console.log(`\n📊 === تحليل بيانات الحالة ===`);
      if (orderData.data) {
        const order = Array.isArray(orderData.data) ? 
          orderData.data.find(o => o.id === testOrderId || JSON.stringify(o).includes(testOrderId)) :
          orderData.data;
          
        if (order) {
          console.log(`🔢 ID الطلب: ${order.id || order.order_id || 'غير محدد'}`);
          console.log(`📝 حالة الطلب: ${order.status || 'غير محدد'}`);
          console.log(`🔢 ID الحالة: ${order.status_id || 'غير محدد'}`);
          console.log(`📅 تاريخ التحديث: ${order.updated_at || order.last_update || 'غير محدد'}`);
          console.log(`👤 اسم العميل: ${order.customer_name || order.client_name || 'غير محدد'}`);
        }
      }
      
    } else {
      console.log(`\n❌ === لم يتم العثور على API مناسب ===`);
      console.log(`💡 قد تحتاج إلى:`);
      console.log(`   1. التحقق من صحة ID الطلب: ${testOrderId}`);
      console.log(`   2. التواصل مع شركة الوسيط للحصول على التوثيق الكامل`);
      console.log(`   3. التحقق من صلاحيات الحساب`);
    }

  } catch (error) {
    console.error('\n❌ === خطأ في البحث ===');
    console.error(`📝 الخطأ: ${error.message}`);
  }
}

// تشغيل البحث
findOrderStatusAPI();
