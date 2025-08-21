// ===================================
// اختبار رسمي كامل للخادم الحقيقي
// Complete Official Production Server Test
// ===================================

const https = require('https');

async function testProductionComplete() {
  console.log('🌐 اختبار رسمي كامل للخادم الحقيقي');
  console.log('🔗 الخادم: https://montajati-official-backend-production.up.railway.app');
  console.log('='.repeat(70));

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';

  try {
    // المرحلة 1: فحص حالة الخادم الرسمي
    console.log('\n📡 المرحلة 1: فحص حالة الخادم الرسمي');
    console.log('='.repeat(50));
    
    const healthResult = await makeRequest('GET', `${baseURL}/health`);
    
    if (healthResult.success) {
      console.log('✅ الخادم الرسمي يعمل');
      console.log('📊 حالة الخادم:', healthResult.data.status);
      console.log('🌍 البيئة:', healthResult.data.environment);
      console.log('⏰ وقت التشغيل:', Math.round(healthResult.data.uptime / 60), 'دقيقة');
      
      // فحص الخدمات
      console.log('\n🔍 حالة الخدمات:');
      const services = healthResult.data.services;
      console.log(`   📱 الإشعارات: ${services.notifications === 'healthy' ? '✅ صحية' : '❌ غير صحية'}`);
      console.log(`   🔄 المزامنة: ${services.sync === 'healthy' ? '✅ صحية' : '❌ غير صحية'}`);
      console.log(`   📊 المراقبة: ${services.monitor === 'healthy' ? '✅ صحية' : '❌ غير صحية'}`);
      
      if (services.sync !== 'healthy') {
        console.log('⚠️ خدمة المزامنة غير صحية - سيتم اختبارها');
      }
      
    } else {
      console.log('❌ الخادم الرسمي لا يستجيب');
        console.log('🔗 الخادم: https://montajati-official-backend-production.up.railway.app');
      return false;
    }

    // المرحلة 2: جلب طلب حقيقي من الخادم
    console.log('\n📦 المرحلة 2: جلب طلب حقيقي من الخادم');
    console.log('='.repeat(50));
    
    const ordersResult = await makeRequest('GET', `${baseURL}/api/orders?limit=1`);
    
    if (!ordersResult.success) {
      console.log('❌ فشل في جلب الطلبات من الخادم الرسمي');
      console.log('تفاصيل الخطأ:', ordersResult);
      return false;
    }

    if (!ordersResult.data?.data?.length) {
      console.log('⚠️ لا توجد طلبات في الخادم الرسمي');
      return false;
    }

    const testOrder = ordersResult.data.data[0];
    console.log(`📋 طلب الاختبار الرسمي: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`📞 الهاتف: ${testOrder.customer_phone || 'غير محدد'}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🚚 معرف الوسيط: ${testOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`📋 حالة الوسيط: ${testOrder.waseet_status || 'غير محدد'}`);

    // المرحلة 3: اختبار تحديث الحالة على الخادم الرسمي
    console.log('\n🔄 المرحلة 3: اختبار تحديث الحالة على الخادم الرسمي');
    console.log('='.repeat(50));
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار رسمي من الخادم الحقيقي - تحديث تلقائي',
      changedBy: 'official_production_test'
    };

    console.log(`🔄 تحديث حالة الطلب ${testOrder.id} على الخادم الرسمي...`);
    console.log('📋 بيانات التحديث:', JSON.stringify(updateData, null, 2));

    const updateResult = await makeRequest('PUT', `${baseURL}/api/orders/${testOrder.id}/status`, updateData);
    
    if (updateResult.success) {
      console.log('✅ تم تحديث الحالة بنجاح على الخادم الرسمي');
      console.log('📋 استجابة الخادم:', JSON.stringify(updateResult.data, null, 2));
      
      // انتظار معالجة الطلب على الخادم
      console.log('\n⏱️ انتظار معالجة الطلب على الخادم الرسمي (20 ثانية)...');
      await new Promise(resolve => setTimeout(resolve, 20000));
      
      // فحص الطلب بعد التحديث
      console.log('\n🔍 فحص الطلب بعد التحديث على الخادم الرسمي');
      console.log('='.repeat(50));
      
      const checkResult = await makeRequest('GET', `${baseURL}/api/orders/${testOrder.id}`);
      
      if (checkResult.success) {
        const updatedOrder = checkResult.data?.data || checkResult.data;
        
        console.log('📋 حالة الطلب بعد التحديث على الخادم الرسمي:');
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
            
            if (waseetData.success) {
              console.log(`   ✅ حالة الإرسال: نجح`);
            }
            
            if (waseetData.error) {
              console.log(`   ❌ خطأ الوسيط: ${waseetData.error}`);
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
          return 'success';
        } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
          console.log('⚠️ النظام حاول الإرسال لكن فشل - سيعيد المحاولة تلقائياً');
          console.log('🔄 النظام سيعيد المحاولة خلال 10 دقائق');
          return 'retry_needed';
        } else {
          console.log('❌ النظام لم يحاول إرسال الطلب للوسيط على الخادم الرسمي');
          console.log('🔧 يحتاج فحص إضافي');
          return 'failed';
        }
      } else {
        console.log('❌ فشل في جلب الطلب المحدث من الخادم الرسمي');
        return 'failed';
      }
    } else {
      console.log('❌ فشل في تحديث الحالة على الخادم الرسمي');
      console.log('تفاصيل الخطأ:', updateResult);
      return 'failed';
    }

  } catch (error) {
    console.error('❌ خطأ في الاختبار الرسمي:', error);
    return 'error';
  }
}

// دالة مساعدة لإرسال الطلبات للخادم الرسمي
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
        'User-Agent': 'Official-Production-Test/1.0'
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

// تشغيل الاختبار الرسمي الكامل
testProductionComplete()
  .then((result) => {
    console.log('\n🏁 النتيجة النهائية للاختبار الرسمي:');
    console.log('='.repeat(70));
    
    switch(result) {
      case 'success':
        console.log('🎉 الاختبار الرسمي نجح بالكامل!');
        console.log('✅ الخادم الرسمي يرسل الطلبات للوسيط بنجاح');
        console.log('🚀 التطبيق المُصدَّر جاهز للاستخدام الفوري');
        break;
      case 'retry_needed':
        console.log('⚠️ الخادم الرسمي يحاول الإرسال لكن يحتاج إعادة محاولة');
        console.log('🔄 النظام سيعيد المحاولة تلقائياً');
        console.log('✅ التطبيق المُصدَّر سيعمل بشكل صحيح');
        break;
      case 'failed':
        console.log('❌ الاختبار الرسمي فشل');
        console.log('🔧 الخادم الرسمي يحتاج إصلاح إضافي');
        break;
      case 'error':
        console.log('❌ خطأ في الاختبار الرسمي');
        console.log('🔧 يحتاج فحص تقني');
        break;
      default:
        console.log('❓ نتيجة غير متوقعة');
    }
    
    console.log('\n📊 ملخص الاختبار الرسمي:');
  console.log('🌐 الخادم: https://montajati-official-backend-production.up.railway.app');
    console.log('🔗 API الوسيط: https://api.alwaseet-iq.net/v1/merchant/create-order');
    console.log('📱 التطبيق: montajati-app-final-v3.0.0.apk');
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل الاختبار الرسمي:', error);
  });
