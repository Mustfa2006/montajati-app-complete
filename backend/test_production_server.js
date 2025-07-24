// ===================================
// اختبار الخادم المنتج مباشرة
// Test Production Server Directly
// ===================================

const https = require('https');
const http = require('http');

// تحميل متغيرات البيئة
require('dotenv').config();

async function testProductionServer() {
  console.log('🧪 اختبار الخادم المنتج مباشرة...');
  console.log('='.repeat(60));

  const baseUrl = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. اختبار health endpoint
    console.log('\n1️⃣ اختبار health endpoint...');
    const healthResult = await makeRequest('GET', `${baseUrl}/health`);
    
    if (healthResult.success) {
      console.log('✅ الخادم يعمل بشكل طبيعي');
      console.log(`📋 الاستجابة:`, healthResult.data);
    } else {
      console.log('❌ الخادم لا يستجيب');
      console.log(`📋 الخطأ:`, healthResult.error);
      return;
    }

    // 2. اختبار orders endpoint
    console.log('\n2️⃣ اختبار orders endpoint...');
    const ordersResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=1`);
    
    if (ordersResult.success) {
      console.log('✅ orders endpoint يعمل');
      console.log(`📊 عدد الطلبات في الاستجابة: ${ordersResult.data?.orders?.length || 0}`);
    } else {
      console.log('❌ orders endpoint لا يعمل');
      console.log(`📋 الخطأ:`, ordersResult.error);
    }

    // 3. اختبار تحديث حالة طلب (محاكاة)
    console.log('\n3️⃣ اختبار تحديث حالة طلب...');
    
    // أولاً نجلب طلب للاختبار
    const testOrdersResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=1&status=active`);
    
    if (testOrdersResult.success && testOrdersResult.data?.orders?.length > 0) {
      const testOrder = testOrdersResult.data.orders[0];
      console.log(`📦 طلب الاختبار: ${testOrder.id} - ${testOrder.customer_name}`);
      
      // محاولة تحديث الحالة
      const updateData = {
        status: 'in_delivery',
        notes: 'اختبار من النظام - تحديث تلقائي',
        changedBy: 'test_system'
      };
      
      const updateResult = await makeRequest(
        'PUT', 
        `${baseUrl}/api/orders/${testOrder.id}/status`,
        updateData
      );
      
      if (updateResult.success) {
        console.log('✅ تم تحديث حالة الطلب بنجاح');
        console.log(`📋 الاستجابة:`, updateResult.data);
        
        // انتظار قليل ثم فحص الطلب
        console.log('\n⏳ انتظار 5 ثوان ثم فحص الطلب...');
        await new Promise(resolve => setTimeout(resolve, 5000));
        
        const checkResult = await makeRequest('GET', `${baseUrl}/api/orders/${testOrder.id}`);
        
        if (checkResult.success) {
          const updatedOrder = checkResult.data;
          console.log('📊 حالة الطلب بعد التحديث:');
          console.log(`   - الحالة: ${updatedOrder.status}`);
          console.log(`   - معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`   - حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
          console.log(`   - بيانات الوسيط: ${updatedOrder.waseet_data ? 'موجودة' : 'غير موجودة'}`);
          
          // تحليل النتائج
          if (updatedOrder.status === 'in_delivery') {
            console.log('✅ تم تحديث حالة الطلب بنجاح');
            
            if (updatedOrder.waseet_order_id) {
              console.log('✅ تم إرسال الطلب لشركة الوسيط بنجاح');
              console.log('🎉 النظام يعمل بشكل مثالي!');
            } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
              console.log('⚠️ فشل في إرسال الطلب للوسيط - في قائمة الانتظار');
              
              if (updatedOrder.waseet_data) {
                try {
                  const waseetData = JSON.parse(updatedOrder.waseet_data);
                  console.log(`📋 سبب الفشل: ${waseetData.error}`);
                } catch (e) {
                  console.log('📋 بيانات الوسيط غير قابلة للقراءة');
                }
              }
            } else {
              console.log('❌ لم يتم محاولة إرسال الطلب للوسيط');
            }
          } else {
            console.log('❌ لم يتم تحديث حالة الطلب');
          }
        } else {
          console.log('❌ فشل في جلب الطلب المحدث');
        }
        
      } else {
        console.log('❌ فشل في تحديث حالة الطلب');
        console.log(`📋 الخطأ:`, updateResult.error);
      }
      
    } else {
      console.log('⚠️ لا توجد طلبات نشطة للاختبار');
    }

    // 4. اختبار retry endpoint
    console.log('\n4️⃣ اختبار retry endpoint...');
    const retryResult = await makeRequest('POST', `${baseUrl}/api/orders/retry-failed-waseet`);
    
    if (retryResult.success) {
      console.log('✅ retry endpoint يعمل');
      console.log(`📋 النتيجة:`, retryResult.data);
    } else {
      console.log('❌ retry endpoint لا يعمل');
      console.log(`📋 الخطأ:`, retryResult.error);
    }

    console.log('\n🎯 انتهى اختبار الخادم المنتج');

  } catch (error) {
    console.error('❌ خطأ في اختبار الخادم:', error);
  }
}

// دالة مساعدة لإرسال الطلبات
function makeRequest(method, url, data = null) {
  return new Promise((resolve) => {
    const urlObj = new URL(url);
    const isHttps = urlObj.protocol === 'https:';
    const client = isHttps ? https : http;
    
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Montajati-Test-Client/1.0'
      },
      timeout: 30000
    };

    if (data && (method === 'POST' || method === 'PUT')) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = client.request(options, (res) => {
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
if (require.main === module) {
  testProductionServer()
    .then(() => {
      console.log('\n✅ انتهى الاختبار');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار:', error);
      process.exit(1);
    });
}

module.exports = { testProductionServer };
