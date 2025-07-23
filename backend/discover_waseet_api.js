// ===================================
// اكتشاف API الصحيح لشركة الوسيط
// Discover Correct Waseet API
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function discoverWaseetAPI() {
  try {
    console.log('🔍 اكتشاف API الصحيح لشركة الوسيط...\n');

    // إعداد Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات شركة الوسيط
    const waseetConfig = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD
    };

    // 1. تسجيل الدخول
    console.log('🔐 تسجيل الدخول...');
    const loginData = new URLSearchParams({
      username: waseetConfig.username,
      password: waseetConfig.password
    });

    const loginResponse = await axios.post(
      `${waseetConfig.baseUrl}/merchant/login`,
      loginData,
      {
        timeout: 15000,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        maxRedirects: 0,
        validateStatus: () => true
      }
    );

    if (loginResponse.status !== 302 && loginResponse.status !== 303) {
      throw new Error(`فشل تسجيل الدخول: ${loginResponse.status}`);
    }

    const token = loginResponse.headers['set-cookie']?.join('; ') || '';
    console.log('✅ تم تسجيل الدخول بنجاح');

    // 2. جلب طلب حقيقي للاختبار
    console.log('\n📋 جلب طلب حقيقي للاختبار...');
    const { data: orders } = await supabase
      .from('orders')
      .select('id, order_number, waseet_order_id')
      .not('waseet_order_id', 'is', null)
      .limit(1);

    if (!orders || orders.length === 0) {
      throw new Error('لا توجد طلبات للاختبار');
    }

    const testOrder = orders[0];
    console.log(`✅ طلب الاختبار: ${testOrder.order_number} (ID: ${testOrder.waseet_order_id})`);

    // 3. اختبار endpoints مختلفة بطرق متنوعة
    const testEndpoints = [
      // الطرق الأساسية
      '/merchant',
      '/merchant/',
      '/merchant/home',
      '/merchant/dashboard',
      '/merchant/index',
      
      // طرق جلب الطلبات
      '/merchant-orders',
      '/merchant/order-list',
      '/merchant/my-orders',
      '/merchant/orders-list',
      '/merchant/all-orders',
      
      // طرق جلب حالة طلب
      '/merchant/order-status',
      '/merchant/status',
      '/merchant/check-order',
      '/merchant/order-info',
      '/merchant/order-details',
      
      // API endpoints
      '/api/merchant',
      '/api/orders',
      '/api/status',
      '/v1/merchant',
      '/v1/orders',
      
      // طرق أخرى محتملة
      '/merchant/get-orders',
      '/merchant/fetch-orders',
      '/merchant/order-tracking',
      '/merchant/track-order'
    ];

    const workingEndpoints = [];
    const statusData = [];

    for (const endpoint of testEndpoints) {
      try {
        console.log(`🔍 اختبار: ${endpoint}`);
        
        // اختبار GET أولاً
        const getResponse = await axios.get(`${waseetConfig.baseUrl}${endpoint}`, {
          timeout: 10000,
          headers: {
            'Cookie': token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          validateStatus: () => true
        });

        if (getResponse.status === 200) {
          console.log(`✅ GET ${endpoint} - نجح`);
          workingEndpoints.push({ endpoint, method: 'GET', status: getResponse.status });
          
          // تحليل المحتوى للبحث عن الحالات
          const content = typeof getResponse.data === 'string' ? getResponse.data : JSON.stringify(getResponse.data);
          
          // البحث عن الحالات المطلوبة
          const expectedStatuses = [
            "قيد التوصيل الى الزبون",
            "تم تغيير محافظة الزبون",
            "لا يرد",
            "مغلق",
            "مؤجل",
            "الغاء الطلب",
            "رفض الطلب"
          ];

          const foundStatuses = expectedStatuses.filter(status => content.includes(status));
          if (foundStatuses.length > 0) {
            console.log(`   🎯 وجدت حالات: ${foundStatuses.join(', ')}`);
            statusData.push({ endpoint, statuses: foundStatuses });
          }

          // البحث عن معرفات الطلبات
          if (content.includes(testOrder.waseet_order_id)) {
            console.log(`   📦 وجدت معرف الطلب: ${testOrder.waseet_order_id}`);
          }

          // البحث عن جداول أو قوائم
          if (content.includes('<table>') || content.includes('order') || content.includes('طلب')) {
            console.log(`   📋 يحتوي على بيانات طلبات`);
          }
        }

        // اختبار POST مع معاملات
        if (endpoint.includes('status') || endpoint.includes('order')) {
          try {
            const postData = new URLSearchParams({
              order_id: testOrder.waseet_order_id,
              id: testOrder.waseet_order_id,
              qr_id: testOrder.waseet_order_id
            });

            const postResponse = await axios.post(`${waseetConfig.baseUrl}${endpoint}`, postData, {
              timeout: 10000,
              headers: {
                'Cookie': token,
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
              },
              validateStatus: () => true
            });

            if (postResponse.status === 200) {
              console.log(`✅ POST ${endpoint} - نجح`);
              workingEndpoints.push({ endpoint, method: 'POST', status: postResponse.status });
            }
          } catch (e) {
            // تجاهل أخطاء POST
          }
        }

      } catch (error) {
        // تجاهل الأخطاء وتابع
      }
    }

    // 4. اختبار طرق خاصة بناءً على الوثائق
    console.log('\n🔍 اختبار طرق خاصة...');
    
    const specialMethods = [
      {
        name: 'جلب الطلبات بـ AJAX',
        url: `${waseetConfig.baseUrl}/merchant/ajax/get-orders`,
        method: 'POST',
        data: { page: 1, limit: 10 }
      },
      {
        name: 'فحص حالة بـ AJAX',
        url: `${waseetConfig.baseUrl}/merchant/ajax/check-status`,
        method: 'POST',
        data: { order_id: testOrder.waseet_order_id }
      },
      {
        name: 'API جلب الطلبات',
        url: `${waseetConfig.baseUrl}/api/v1/merchant/orders`,
        method: 'GET'
      },
      {
        name: 'جلب الحالات المتاحة',
        url: `${waseetConfig.baseUrl}/merchant/get-statuses`,
        method: 'GET'
      }
    ];

    for (const method of specialMethods) {
      try {
        console.log(`🔍 ${method.name}...`);
        
        let response;
        if (method.method === 'GET') {
          response = await axios.get(method.url, {
            timeout: 10000,
            headers: {
              'Cookie': token,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            },
            validateStatus: () => true
          });
        } else {
          const postData = new URLSearchParams(method.data);
          response = await axios.post(method.url, postData, {
            timeout: 10000,
            headers: {
              'Cookie': token,
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            },
            validateStatus: () => true
          });
        }

        if (response.status === 200) {
          console.log(`✅ ${method.name} - نجح`);
          console.log(`📊 البيانات:`, JSON.stringify(response.data, null, 2));
        } else {
          console.log(`❌ ${method.name} - فشل (${response.status})`);
        }
      } catch (error) {
        console.log(`❌ ${method.name} - خطأ: ${error.message}`);
      }
    }

    // 5. تقرير النتائج
    console.log('\n🎯 تقرير اكتشاف API:');
    console.log('=' * 60);

    console.log(`📊 endpoints تعمل: ${workingEndpoints.length}`);
    if (workingEndpoints.length > 0) {
      console.log('✅ endpoints الناجحة:');
      workingEndpoints.forEach((ep, index) => {
        console.log(`   ${index + 1}. ${ep.method} ${ep.endpoint} (${ep.status})`);
      });
    }

    console.log(`\n📊 endpoints تحتوي على حالات: ${statusData.length}`);
    if (statusData.length > 0) {
      console.log('🎯 endpoints مع الحالات:');
      statusData.forEach((data, index) => {
        console.log(`   ${index + 1}. ${data.endpoint}:`);
        data.statuses.forEach(status => {
          console.log(`      - ${status}`);
        });
      });
    }

    // 6. توصيات
    console.log('\n💡 توصيات:');
    if (workingEndpoints.length === 0) {
      console.log('🚨 لم يتم العثور على API يعمل');
      console.log('📞 يجب التواصل مع الدعم التقني لشركة الوسيط');
      console.log('📋 طلب وثائق API الصحيحة');
    } else {
      console.log('✅ تم العثور على endpoints تعمل');
      console.log('🔧 طور النظام لاستخدام هذه endpoints');
      if (statusData.length > 0) {
        console.log('🎯 يمكن جلب الحالات من endpoints المكتشفة');
      }
    }

    console.log('\n🎉 انتهى اكتشاف API!');

    return {
      working_endpoints: workingEndpoints,
      status_endpoints: statusData,
      recommendations: workingEndpoints.length > 0 ? 'استخدم endpoints المكتشفة' : 'اتصل بالدعم التقني'
    };

  } catch (error) {
    console.error('❌ خطأ في اكتشاف API:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

// تشغيل الاختبار
if (require.main === module) {
  discoverWaseetAPI().then(report => {
    console.log('\n📊 ملخص الاكتشاف:');
    if (report.working_endpoints) {
      console.log(`🎯 endpoints تعمل: ${report.working_endpoints.length}`);
      console.log(`📊 endpoints مع حالات: ${report.status_endpoints.length}`);
      console.log(`💡 التوصية: ${report.recommendations}`);
    }
  }).catch(error => {
    console.error('❌ خطأ في تشغيل الاكتشاف:', error.message);
  });
}

module.exports = discoverWaseetAPI;
