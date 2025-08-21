// ===================================
// اختبار تحديث حالة الطلب مباشرة
// Test Order Status Update Directly
// ===================================

const https = require('https');

async function testOrderUpdate() {
  console.log('🧪 اختبار تحديث حالة الطلب مباشرة...');
  console.log('='.repeat(60));

  try {
    // جلب طلب للاختبار
    console.log('📦 جلب طلب للاختبار...');
  const ordersResult = await makeRequest('GET', 'https://montajati-official-backend-production.up.railway.app/api/orders?limit=1');
    
    if (!ordersResult.success || !ordersResult.data?.data?.length) {
      console.log('❌ لا توجد طلبات للاختبار');
      return false;
    }

    const testOrder = ordersResult.data.data[0];
    console.log(`📋 طلب الاختبار: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);

    // تحديث الحالة إلى "قيد التوصيل"
    console.log('\n🔄 تحديث الحالة إلى "قيد التوصيل الى الزبون (في عهدة المندوب)"...');
    
  const updateResult = await makeRequest('PUT', `https://montajati-official-backend-production.up.railway.app/api/orders/${testOrder.id}/status`, {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار مباشر لإرسال الطلب للوسيط',
      changedBy: 'test_order_update'
    });

    if (updateResult.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      console.log('📋 استجابة الخادم:', JSON.stringify(updateResult.data, null, 2));
      
      // انتظار قليل ثم فحص الطلب
      console.log('\n⏱️ انتظار 10 ثوان ثم فحص الطلب...');
      await new Promise(resolve => setTimeout(resolve, 10000));
      
  const checkResult = await makeRequest('GET', `https://montajati-official-backend-production.up.railway.app/api/orders/${testOrder.id}`);
      
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
        'User-Agent': 'Test-Order-Update/1.0'
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
testOrderUpdate()
  .then((result) => {
    console.log('\n🎯 النتيجة النهائية:');
    if (result === true) {
      console.log('🎉 الاختبار نجح! النظام يرسل الطلبات للوسيط');
    } else if (result === 'retry_needed') {
      console.log('⚠️ النظام يحاول الإرسال لكن يحتاج إعادة محاولة');
    } else {
      console.log('❌ النظام لا يرسل الطلبات للوسيط');
    }
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل الاختبار:', error);
  });
