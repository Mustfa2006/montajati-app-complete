// ===================================
// فحص سجلات الخادم الرسمي
// Check Production Server Logs
// ===================================

const https = require('https');

async function checkProductionLogs() {
  console.log('📋 فحص سجلات الخادم الرسمي');
  console.log('🔗 الخادم: https://montajati-backend.onrender.com');
  console.log('='.repeat(60));

  const baseURL = 'https://montajati-backend.onrender.com';

  try {
    // فحص endpoint خاص لعرض حالة التهيئة
    console.log('\n🔍 فحص حالة التهيئة على الخادم الرسمي...');
    
    const debugResult = await makeRequest('GET', `${baseURL}/debug/sync-status`);
    
    if (debugResult.success) {
      console.log('✅ تم الحصول على معلومات التهيئة');
      console.log('📋 حالة التهيئة:', JSON.stringify(debugResult.data, null, 2));
    } else {
      console.log('❌ لا يوجد endpoint للتشخيص - سأنشئ واحد');
      
      // إنشاء طلب اختبار لتحديث الحالة
      console.log('\n🧪 إنشاء طلب اختبار لتحديث الحالة...');
      
      // أولاً جلب طلب موجود
      const ordersResult = await makeRequest('GET', `${baseURL}/api/orders?limit=1`);
      
      if (ordersResult.success && ordersResult.data?.data?.length) {
        const testOrder = ordersResult.data.data[0];
        console.log(`📦 طلب الاختبار: ${testOrder.id}`);
        
        // محاولة تحديث الحالة لرؤية السجلات
        const updateData = {
          status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
          notes: 'اختبار فحص السجلات',
          changedBy: 'log_check_test'
        };
        
        console.log('🔄 تحديث الحالة لفحص السجلات...');
        const updateResult = await makeRequest('PUT', `${baseURL}/api/orders/${testOrder.id}/status`, updateData);
        
        if (updateResult.success) {
          console.log('✅ تم تحديث الحالة - فحص النتيجة...');
          
          // انتظار قصير ثم فحص الطلب
          await new Promise(resolve => setTimeout(resolve, 10000));
          
          const checkResult = await makeRequest('GET', `${baseURL}/api/orders/${testOrder.id}`);
          
          if (checkResult.success) {
            const updatedOrder = checkResult.data?.data || checkResult.data;
            
            console.log('\n📋 نتيجة الاختبار:');
            console.log(`   📊 الحالة: ${updatedOrder.status}`);
            console.log(`   🚚 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
            console.log(`   📋 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
            
            if (updatedOrder.waseet_data) {
              try {
                const waseetData = JSON.parse(updatedOrder.waseet_data);
                console.log(`   📋 بيانات الوسيط:`, waseetData);
              } catch (e) {
                console.log(`   📋 بيانات الوسيط (خام): ${updatedOrder.waseet_data}`);
              }
            }
            
            // تحليل المشكلة
            if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
              console.log('\n🎉 النظام يعمل! تم إرسال الطلب للوسيط');
              return 'working';
            } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
              console.log('\n⚠️ النظام يحاول لكن يفشل');
              return 'trying_but_failing';
            } else {
              console.log('\n❌ النظام لا يحاول إرسال الطلب');
              return 'not_trying';
            }
          }
        } else {
          console.log('❌ فشل في تحديث الحالة');
          console.log('تفاصيل الخطأ:', updateResult);
        }
      } else {
        console.log('❌ لا توجد طلبات للاختبار');
      }
    }

  } catch (error) {
    console.error('❌ خطأ في فحص السجلات:', error);
    return 'error';
  }
  
  return 'unknown';
}

// دالة مساعدة لإرسال الطلبات
async function makeRequest(method, url, data = null) {
  return new Promise((resolve) => {
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: 443,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Production-Log-Check/1.0'
      },
      timeout: 30000
    };

    if (data && (method === 'POST' || method === 'PUT')) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = https.request(options, (res) => {
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

// تشغيل فحص السجلات
checkProductionLogs()
  .then((result) => {
    console.log('\n🎯 نتيجة فحص السجلات:');
    console.log('='.repeat(60));
    
    switch(result) {
      case 'working':
        console.log('🎉 النظام يعمل بشكل صحيح على الخادم الرسمي!');
        break;
      case 'trying_but_failing':
        console.log('⚠️ النظام يحاول لكن يفشل - مشكلة في الاتصال بالوسيط');
        break;
      case 'not_trying':
        console.log('❌ النظام لا يحاول إرسال الطلب - مشكلة في التهيئة');
        break;
      case 'error':
        console.log('❌ خطأ في الفحص');
        break;
      default:
        console.log('❓ نتيجة غير واضحة');
    }
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل فحص السجلات:', error);
  });
