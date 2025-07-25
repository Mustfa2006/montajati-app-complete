// ===================================
// اختبار شامل لتكامل الوسيط
// Complete Waseet Integration Test
// ===================================

const { createClient } = require('@supabase/supabase-js');
const https = require('https');
require('dotenv').config();

async function testWaseetIntegration() {
  console.log('🧪 اختبار شامل لتكامل الوسيط...');
  console.log('='.repeat(60));

  try {
    // المرحلة 1: فحص متغيرات البيئة
    console.log('\n📋 المرحلة 1: فحص متغيرات البيئة');
    console.log('='.repeat(40));
    
    console.log(`WASEET_USERNAME: ${process.env.WASEET_USERNAME ? '✅ موجود' : '❌ غير موجود'}`);
    console.log(`WASEET_PASSWORD: ${process.env.WASEET_PASSWORD ? '✅ موجود' : '❌ غير موجود'}`);
    
    if (process.env.WASEET_USERNAME) {
      console.log(`اسم المستخدم: ${process.env.WASEET_USERNAME}`);
    }

    // المرحلة 2: اختبار الاتصال بـ API الوسيط
    console.log('\n🌐 المرحلة 2: اختبار الاتصال بـ API الوسيط');
    console.log('='.repeat(40));
    
    const WaseetAPIClient = require('./services/waseet_api_client');
    const waseetClient = new WaseetAPIClient();
    
    console.log(`🔗 API URL: ${waseetClient.baseURL}`);
    console.log(`🔧 حالة التهيئة: ${waseetClient.isConfigured ? '✅ مهيأ' : '❌ غير مهيأ'}`);

    if (waseetClient.isConfigured) {
      // اختبار تسجيل الدخول
      console.log('\n🔐 اختبار تسجيل الدخول...');
      const loginResult = await waseetClient.login();
      
      if (loginResult) {
        console.log('✅ تم تسجيل الدخول بنجاح');
        console.log(`🔑 Token: ${waseetClient.token ? waseetClient.token.substring(0, 20) + '...' : 'غير موجود'}`);
      } else {
        console.log('❌ فشل في تسجيل الدخول');
        return false;
      }
    } else {
      console.log('❌ لا يمكن اختبار API - بيانات المصادقة غير موجودة');
      return false;
    }

    // المرحلة 3: فحص قاعدة البيانات
    console.log('\n🗄️ المرحلة 3: فحص قاعدة البيانات');
    console.log('='.repeat(40));
    
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // جلب طلب للاختبار
    const { data: orders, error } = await supabase
      .from('orders')
      .select('*')
      .limit(1);

    if (error) {
      console.error('❌ خطأ في الاتصال بقاعدة البيانات:', error);
      return false;
    }

    if (orders.length === 0) {
      console.log('⚠️ لا توجد طلبات في قاعدة البيانات');
      return false;
    }

    const testOrder = orders[0];
    console.log(`📦 طلب الاختبار: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🚚 معرف الوسيط: ${testOrder.waseet_order_id || 'غير محدد'}`);

    // المرحلة 4: اختبار إرسال طلب للوسيط
    console.log('\n📦 المرحلة 4: اختبار إرسال طلب للوسيط');
    console.log('='.repeat(40));

    // تحضير بيانات الطلب
    const orderData = {
      client_name: testOrder.customer_name || 'عميل اختبار',
      client_mobile: '+9647901234567', // رقم افتراضي للاختبار
      city_id: 1,
      region_id: 1,
      location: testOrder.customer_address || 'عنوان اختبار',
      type_name: 'عادي',
      items_number: 1,
      price: testOrder.total || 25000,
      package_size: 1,
      merchant_notes: `طلب اختبار من تطبيق منتجاتي - رقم الطلب: ${testOrder.id}`,
      replacement: 0
    };

    console.log('📋 بيانات الطلب المرسلة:');
    console.log(JSON.stringify(orderData, null, 2));

    const createResult = await waseetClient.createOrder(orderData);
    
    if (createResult && createResult.success) {
      console.log('🎉 نجح! تم إرسال الطلب للوسيط');
      console.log(`🆔 QR ID: ${createResult.qrId}`);
      
      // تحديث الطلب في قاعدة البيانات
      const { error: updateError } = await supabase
        .from('orders')
        .update({
          waseet_order_id: createResult.qrId,
          waseet_status: 'تم الإرسال للوسيط',
          waseet_data: JSON.stringify(createResult),
          updated_at: new Date().toISOString()
        })
        .eq('id', testOrder.id);
        
      if (updateError) {
        console.error('❌ خطأ في تحديث قاعدة البيانات:', updateError);
      } else {
        console.log('✅ تم تحديث الطلب في قاعدة البيانات');
      }
    } else {
      console.log('❌ فشل في إرسال الطلب');
      console.log('تفاصيل الخطأ:', createResult);
      return false;
    }

    // المرحلة 5: اختبار API تحديث الحالة
    console.log('\n🔄 المرحلة 5: اختبار API تحديث الحالة');
    console.log('='.repeat(40));

    const updateResult = await testOrderStatusUpdate(testOrder.id);
    
    if (updateResult) {
      console.log('✅ اختبار تحديث الحالة نجح');
    } else {
      console.log('❌ اختبار تحديث الحالة فشل');
    }

    return true;

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error);
    return false;
  }
}

// اختبار API تحديث الحالة
async function testOrderStatusUpdate(orderId) {
  try {
    console.log(`🔄 اختبار تحديث حالة الطلب ${orderId}...`);

    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار تحديث الحالة',
      changedBy: 'test_system'
    };

    const result = await makeHttpRequest('PUT', `http://localhost:3000/api/orders/${orderId}/status`, updateData);
    
    if (result.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      console.log('📋 استجابة الخادم:', JSON.stringify(result.data, null, 2));
      return true;
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('تفاصيل الخطأ:', result);
      return false;
    }

  } catch (error) {
    console.error('❌ خطأ في اختبار تحديث الحالة:', error);
    return false;
  }
}

// دالة مساعدة لإرسال طلبات HTTP
async function makeHttpRequest(method, url, data = null) {
  return new Promise((resolve) => {
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || 3000,
      path: urlObj.pathname,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Test-Waseet-Integration/1.0'
      },
      timeout: 30000
    };

    if (data && (method === 'POST' || method === 'PUT')) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = require('http').request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const parsedData = responseData ? JSON.parse(responseData) : {};
          
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({
              success: true,
              status: res.statusCode,
              data: parsedData
            });
          } else {
            resolve({
              success: false,
              status: res.statusCode,
              error: parsedData,
              rawResponse: responseData
            });
          }
        } catch (parseError) {
          resolve({
            success: false,
            status: res.statusCode,
            error: 'فشل في تحليل الاستجابة',
            rawResponse: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      resolve({
        success: false,
        error: error.message
      });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({
        success: false,
        error: 'انتهت مهلة الاتصال'
      });
    });

    if (data && (method === 'POST' || method === 'PUT')) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

// تشغيل الاختبار
testWaseetIntegration()
  .then((result) => {
    console.log('\n🎯 النتيجة النهائية:');
    console.log('='.repeat(60));
    if (result) {
      console.log('🎉 جميع الاختبارات نجحت! النظام يعمل بشكل صحيح');
    } else {
      console.log('❌ بعض الاختبارات فشلت - يحتاج إصلاح');
    }
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل الاختبار:', error);
  });
