// ===================================
// اختبار مباشر للخادم الرسمي
// Direct Official Server Test
// ===================================

const https = require('https');

async function testOfficialServerDirect() {
  console.log('🎯 اختبار مباشر للخادم الرسمي');
  console.log('🔗 الخادم: https://montajati-official-backend-production.up.railway.app');
  console.log('='.repeat(70));

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';

  try {
    // المرحلة 1: اختبار endpoint الصحة
    console.log('\n📡 المرحلة 1: اختبار endpoint الصحة');
    console.log('='.repeat(50));
    
    const healthResult = await makeRequest('GET', `${baseURL}/health`);
    console.log('📊 نتيجة فحص الصحة:', healthResult.success ? '✅ نجح' : '❌ فشل');
    
    if (healthResult.success) {
      console.log('📋 حالة الخادم:', healthResult.data.status);
      console.log('🌍 البيئة:', healthResult.data.environment);
      
      if (healthResult.data.services) {
        console.log('🔍 حالة الخدمات:');
        Object.entries(healthResult.data.services).forEach(([service, status]) => {
          console.log(`   ${service}: ${status === 'healthy' ? '✅' : '❌'} ${status}`);
        });
      }
    }

    // المرحلة 2: اختبار مسار الطلبات مباشرة
    console.log('\n📦 المرحلة 2: اختبار مسار الطلبات مباشرة');
    console.log('='.repeat(50));
    
    console.log('🔍 اختبار GET /api/orders...');
    const ordersResult = await makeRequest('GET', `${baseURL}/api/orders?limit=5`);
    
    if (ordersResult.success) {
      console.log('✅ مسار /api/orders يعمل بنجاح!');
      console.log(`📊 عدد الطلبات: ${ordersResult.data?.data?.length || 0}`);
      
      if (ordersResult.data?.data?.length > 0) {
        const firstOrder = ordersResult.data.data[0];
        console.log(`📋 أول طلب: ${firstOrder.id} - ${firstOrder.customer_name}`);
        console.log(`📊 الحالة: ${firstOrder.status}`);
        console.log(`🚚 معرف الوسيط: ${firstOrder.waseet_order_id || 'غير محدد'}`);
      }
    } else {
      console.log('❌ مسار /api/orders لا يعمل');
      console.log('تفاصيل الخطأ:', ordersResult);
    }

    // المرحلة 3: اختبار إنشاء طلب تجريبي
    console.log('\n📝 المرحلة 3: اختبار إنشاء طلب تجريبي');
    console.log('='.repeat(50));
    
    console.log('🔍 اختبار POST /api/orders/create-test-order...');
    const createTestResult = await makeRequest('POST', `${baseURL}/api/orders/create-test-order`);
    
    if (createTestResult.success) {
      console.log('✅ إنشاء الطلب التجريبي نجح!');
      const newOrder = createTestResult.data?.data || createTestResult.data;
      console.log(`🆔 معرف الطلب الجديد: ${newOrder.id}`);
      
      // انتظار قصير ثم اختبار تحديث الحالة
      console.log('\n⏱️ انتظار 5 ثوان ثم اختبار تحديث الحالة...');
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      // المرحلة 4: اختبار تحديث حالة الطلب
      console.log('\n🔄 المرحلة 4: اختبار تحديث حالة الطلب');
      console.log('='.repeat(50));
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار مباشر للخادم الرسمي - تحديث تلقائي',
        changedBy: 'direct_official_test'
      };

      console.log(`🔄 تحديث حالة الطلب ${newOrder.id}...`);
      const updateResult = await makeRequest('PUT', `${baseURL}/api/orders/${newOrder.id}/status`, updateData);
      
      if (updateResult.success) {
        console.log('✅ تحديث الحالة نجح!');
        
        // انتظار معالجة الطلب
        console.log('\n⏱️ انتظار 20 ثانية لمعالجة الطلب...');
        await new Promise(resolve => setTimeout(resolve, 20000));
        
        // فحص الطلب بعد التحديث
        console.log('\n🔍 فحص الطلب بعد التحديث...');
        const checkResult = await makeRequest('GET', `${baseURL}/api/orders/${newOrder.id}`);
        
        if (checkResult.success) {
          const updatedOrder = checkResult.data?.data || checkResult.data;
          
          console.log('📋 حالة الطلب بعد التحديث:');
          console.log(`   📊 الحالة: ${updatedOrder.status}`);
          console.log(`   🚚 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`   📋 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
          console.log(`   🕐 آخر تحديث: ${updatedOrder.updated_at}`);
          
          if (updatedOrder.waseet_data) {
            try {
              const waseetData = JSON.parse(updatedOrder.waseet_data);
              console.log(`   📋 بيانات الوسيط:`, waseetData);
              
              if (waseetData.qrId) {
                console.log(`   🆔 QR ID من الوسيط: ${waseetData.qrId}`);
              }
              
            } catch (e) {
              console.log(`   📋 بيانات الوسيط (خام): ${updatedOrder.waseet_data}`);
            }
          }
          
          // تحليل النتيجة النهائية
          console.log('\n🎯 تحليل النتيجة النهائية:');
          console.log('='.repeat(50));
          
          if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
            console.log('🎉 نجح! تم إرسال الطلب للوسيط على الخادم الرسمي');
            console.log(`🆔 معرف الوسيط: ${updatedOrder.waseet_order_id}`);
            console.log('✅ النظام يعمل بشكل مثالي على الخادم الرسمي');
            console.log('🚀 التطبيق المُصدَّر جاهز للاستخدام الفوري');
            return 'success';
          } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('⚠️ النظام حاول الإرسال لكن فشل على الخادم الرسمي');
            console.log('🔄 النظام سيعيد المحاولة تلقائياً');
            return 'retry_needed';
          } else {
            console.log('❌ النظام لم يحاول إرسال الطلب للوسيط على الخادم الرسمي');
            console.log('🔧 خدمة المزامنة قد تحتاج إصلاح');
            return 'sync_issue';
          }
        } else {
          console.log('❌ فشل في جلب الطلب المحدث');
          return 'failed';
        }
      } else {
        console.log('❌ فشل في تحديث الحالة');
        console.log('تفاصيل الخطأ:', updateResult);
        return 'failed';
      }
    } else {
      console.log('❌ فشل في إنشاء الطلب التجريبي');
      console.log('تفاصيل الخطأ:', createTestResult);
      return 'failed';
    }

  } catch (error) {
    console.error('❌ خطأ في الاختبار المباشر:', error);
    return 'error';
  }
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
        'User-Agent': 'Direct-Official-Test/1.0'
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

// تشغيل الاختبار المباشر
testOfficialServerDirect()
  .then((result) => {
    console.log('\n🏁 النتيجة النهائية للاختبار المباشر:');
    console.log('='.repeat(70));
    
    switch(result) {
      case 'success':
        console.log('🎉 الاختبار المباشر نجح بالكامل!');
        console.log('✅ الخادم الرسمي يرسل الطلبات للوسيط بنجاح');
        console.log('🚀 التطبيق المُصدَّر جاهز للاستخدام الفوري');
        console.log('📱 يمكن تثبيت montajati-app-final-v3.0.0.apk واستخدامه');
        break;
      case 'retry_needed':
        console.log('⚠️ الخادم الرسمي يحاول الإرسال لكن يحتاج إعادة محاولة');
        console.log('🔄 النظام سيعيد المحاولة تلقائياً');
        console.log('✅ التطبيق المُصدَّر سيعمل بشكل صحيح');
        break;
      case 'sync_issue':
        console.log('❌ خدمة المزامنة تحتاج إصلاح على الخادم الرسمي');
        console.log('🔧 يحتاج فحص إضافي للخدمة');
        break;
      case 'failed':
        console.log('❌ الاختبار المباشر فشل');
        console.log('🔧 الخادم الرسمي يحتاج إصلاح');
        break;
      case 'error':
        console.log('❌ خطأ في الاختبار المباشر');
        break;
      default:
        console.log('❓ نتيجة غير متوقعة');
    }
    
    console.log('\n📊 ملخص الاختبار المباشر النهائي:');
  console.log('🌐 الخادم الرسمي: https://montajati-official-backend-production.up.railway.app');
    console.log('🔗 API الوسيط: https://api.alwaseet-iq.net/v1/merchant/create-order');
    console.log('📱 التطبيق المُصدَّر: montajati-app-final-v3.0.0.apk');
    console.log('🎯 الاختبار: مباشر كامل على الخادم الرسمي');
    console.log('📋 الملف المستخدم: official_montajati_server.js');
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل الاختبار المباشر:', error);
  });
