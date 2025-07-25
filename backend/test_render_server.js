// ===================================
// اختبار الخادم الحقيقي على Render
// Test Real Server on Render
// ===================================

const https = require('https');

async function testRenderServer() {
  console.log('🌐 اختبار الخادم الحقيقي على Render.com...');
  console.log('🔗 URL: https://montajati-backend.onrender.com');
  console.log('='.repeat(60));

  const baseURL = 'https://montajati-backend.onrender.com';

  try {
    // المرحلة 1: اختبار حالة الخادم
    console.log('\n📡 المرحلة 1: اختبار حالة الخادم');
    console.log('='.repeat(40));
    
    const healthResult = await makeRequest('GET', `${baseURL}/health`);
    
    if (healthResult.success) {
      console.log('✅ الخادم يعمل بشكل صحيح');
      console.log('📋 استجابة الخادم:', JSON.stringify(healthResult.data, null, 2));
    } else {
      console.log('❌ الخادم لا يستجيب');
      console.log('تفاصيل الخطأ:', healthResult);
      return false;
    }

    // المرحلة 2: جلب طلب للاختبار
    console.log('\n📦 المرحلة 2: جلب طلب للاختبار');
    console.log('='.repeat(40));
    
    const ordersResult = await makeRequest('GET', `${baseURL}/api/orders?limit=1`);
    
    if (!ordersResult.success) {
      console.log('❌ فشل في جلب الطلبات');
      console.log('تفاصيل الخطأ:', ordersResult);
      return false;
    }

    if (!ordersResult.data?.data?.length) {
      console.log('⚠️ لا توجد طلبات للاختبار');
      return false;
    }

    const testOrder = ordersResult.data.data[0];
    console.log(`📋 طلب الاختبار: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🚚 معرف الوسيط: ${testOrder.waseet_order_id || 'غير محدد'}`);

    // المرحلة 3: اختبار تحديث الحالة
    console.log('\n🔄 المرحلة 3: اختبار تحديث الحالة');
    console.log('='.repeat(40));
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار تحديث الحالة من الخادم الحقيقي',
      changedBy: 'production_test'
    };

    console.log(`🔄 تحديث حالة الطلب ${testOrder.id}...`);
    console.log('📋 بيانات التحديث:', JSON.stringify(updateData, null, 2));

    const updateResult = await makeRequest('PUT', `${baseURL}/api/orders/${testOrder.id}/status`, updateData);
    
    if (updateResult.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      console.log('📋 استجابة الخادم:', JSON.stringify(updateResult.data, null, 2));
      
      // انتظار قليل ثم فحص الطلب
      console.log('\n⏱️ انتظار 15 ثانية ثم فحص الطلب...');
      await new Promise(resolve => setTimeout(resolve, 15000));
      
      const checkResult = await makeRequest('GET', `${baseURL}/api/orders/${testOrder.id}`);
      
      if (checkResult.success) {
        const updatedOrder = checkResult.data?.data || checkResult.data;
        
        console.log('\n📋 حالة الطلب بعد التحديث:');
        console.log(`   📊 الحالة: ${updatedOrder.status}`);
        console.log(`   🚚 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📋 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
        console.log(`   🕐 آخر تحديث: ${updatedOrder.updated_at}`);
        
        if (updatedOrder.waseet_data) {
          try {
            const waseetData = JSON.parse(updatedOrder.waseet_data);
            console.log(`   📋 بيانات الوسيط:`, waseetData);
          } catch (e) {
            console.log(`   📋 بيانات الوسيط (خام): ${updatedOrder.waseet_data}`);
          }
        }
        
        // تحليل النتيجة
        if (updatedOrder.waseet_order_id) {
          console.log('\n🎉 نجح! تم إرسال الطلب للوسيط');
          return true;
        } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
          console.log('\n⚠️ النظام حاول الإرسال لكن فشل - سيعيد المحاولة لاحقاً');
          return 'retry_needed';
        } else {
          console.log('\n❌ النظام لم يحاول إرسال الطلب للوسيط');
          return false;
        }
      } else {
        console.log('❌ فشل في جلب الطلب المحدث');
        return false;
      }
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('تفاصيل الخطأ:', updateResult);
      return false;
    }

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error);
    return false;
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
        'User-Agent': 'Production-Test/1.0'
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

// تشغيل الاختبار
testRenderServer()
  .then((result) => {
    console.log('\n🎯 النتيجة النهائية:');
    console.log('='.repeat(60));
    if (result === true) {
      console.log('🎉 الاختبار نجح! الخادم الحقيقي يرسل الطلبات للوسيط');
      console.log('✅ التطبيق المُصدَّر سيعمل بشكل صحيح');
    } else if (result === 'retry_needed') {
      console.log('⚠️ الخادم يحاول الإرسال لكن يحتاج إعادة محاولة');
      console.log('🔄 النظام سيعيد المحاولة تلقائياً');
    } else {
      console.log('❌ الخادم الحقيقي لا يرسل الطلبات للوسيط');
      console.log('🔧 يحتاج إصلاح قبل استخدام التطبيق');
    }
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل الاختبار:', error);
  });
