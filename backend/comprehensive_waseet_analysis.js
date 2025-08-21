// ===================================
// تحليل شامل لمشكلة الوسيط
// Comprehensive Waseet Issue Analysis
// ===================================

const https = require('https');

async function comprehensiveWaseetAnalysis() {
  console.log('🔍 تحليل شامل لمشكلة عدم إضافة الطلب للوسيط');
  console.log('🔗 الخادم: https://montajati-official-backend-production.up.railway.app');
  console.log('='.repeat(80));

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';

  try {
    // المرحلة 1: فحص حالة الخادم
    console.log('\n📡 المرحلة 1: فحص حالة الخادم');
    console.log('='.repeat(50));
    
    const healthResult = await makeRequest('GET', `${baseURL}/health`);
    
    if (healthResult.success) {
      console.log('✅ الخادم يعمل');
      console.log('📊 حالة الخادم:', healthResult.data.status);
      console.log('🌍 البيئة:', healthResult.data.environment);
      
      if (healthResult.data.services) {
        console.log('\n🔍 حالة الخدمات:');
        Object.entries(healthResult.data.services).forEach(([service, status]) => {
          console.log(`   ${service}: ${status === 'healthy' ? '✅' : '❌'} ${status}`);
        });
      }
    } else {
      console.log('❌ الخادم لا يستجيب');
      console.log('تفاصيل:', healthResult);
      return;
    }

    // المرحلة 2: إنشاء طلب اختبار
    console.log('\n📦 المرحلة 2: إنشاء طلب اختبار');
    console.log('='.repeat(50));
    
    const createResult = await makeRequest('POST', `${baseURL}/api/orders/create-test-order`);
    
    if (!createResult.success) {
      console.log('❌ فشل في إنشاء طلب اختبار');
      console.log('تفاصيل الخطأ:', createResult);
      return;
    }

    const testOrder = createResult.data?.data || createResult.data;
    console.log(`✅ تم إنشاء طلب اختبار: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`📊 الحالة الأولية: ${testOrder.status}`);

    // المرحلة 3: تحديث حالة الطلب لحالة توصيل
    console.log('\n🔄 المرحلة 3: تحديث حالة الطلب لحالة توصيل');
    console.log('='.repeat(50));
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'تحليل شامل - اختبار إرسال للوسيط',
      changedBy: 'comprehensive_analysis'
    };

    console.log(`🔄 تحديث حالة الطلب ${testOrder.id}...`);
    console.log('📋 بيانات التحديث:', JSON.stringify(updateData, null, 2));
    
    const updateResult = await makeRequest('PUT', `${baseURL}/api/orders/${testOrder.id}/status`, updateData);
    
    if (!updateResult.success) {
      console.log('❌ فشل في تحديث الحالة');
      console.log('تفاصيل الخطأ:', updateResult);
      return;
    }

    console.log('✅ تم تحديث الحالة بنجاح');

    // المرحلة 4: انتظار ومراقبة المعالجة
    console.log('\n⏱️ المرحلة 4: انتظار ومراقبة المعالجة');
    console.log('='.repeat(50));
    
    const monitoringIntervals = [5, 10, 20, 30];
    
    for (const interval of monitoringIntervals) {
      console.log(`\n⏰ انتظار ${interval} ثانية...`);
      await new Promise(resolve => setTimeout(resolve, interval * 1000));
      
      console.log(`🔍 فحص الطلب بعد ${interval} ثانية:`);
      
      const checkResult = await makeRequest('GET', `${baseURL}/api/orders/${testOrder.id}`);
      
      if (checkResult.success) {
        const currentOrder = checkResult.data?.data || checkResult.data;
        
        console.log(`   📊 الحالة: ${currentOrder.status}`);
        console.log(`   🚚 معرف الوسيط: ${currentOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📋 حالة الوسيط: ${currentOrder.waseet_status || 'غير محدد'}`);
        console.log(`   🕐 آخر تحديث: ${currentOrder.updated_at}`);
        
        if (currentOrder.waseet_data) {
          try {
            const waseetData = JSON.parse(currentOrder.waseet_data);
            console.log(`   📋 بيانات الوسيط:`, waseetData);
            
            if (waseetData.qrId) {
              console.log(`   🆔 QR ID: ${waseetData.qrId}`);
              console.log('🎉 نجح! تم إرسال الطلب للوسيط');
              return 'success';
            }
            
            if (waseetData.error) {
              console.log(`   ❌ خطأ الوسيط: ${waseetData.error}`);
            }
            
          } catch (e) {
            console.log(`   📋 بيانات الوسيط (خام): ${currentOrder.waseet_data}`);
          }
        }
        
        // تحليل الحالة
        if (currentOrder.waseet_order_id && currentOrder.waseet_order_id !== 'null') {
          console.log('🎉 نجح! تم إرسال الطلب للوسيط');
          return 'success';
        } else if (currentOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
          console.log('⚠️ النظام يحاول لكن يفشل');
        } else {
          console.log('❌ النظام لم يحاول إرسال الطلب');
        }
      } else {
        console.log('❌ فشل في جلب الطلب');
      }
    }

    // المرحلة 5: تحليل السبب
    console.log('\n🔍 المرحلة 5: تحليل السبب');
    console.log('='.repeat(50));
    
    const finalCheckResult = await makeRequest('GET', `${baseURL}/api/orders/${testOrder.id}`);
    
    if (finalCheckResult.success) {
      const finalOrder = finalCheckResult.data?.data || finalCheckResult.data;
      
      console.log('\n📋 التحليل النهائي:');
      console.log(`   📊 الحالة النهائية: ${finalOrder.status}`);
      console.log(`   🚚 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
      console.log(`   📋 حالة الوسيط: ${finalOrder.waseet_status || 'غير محدد'}`);
      
      if (!finalOrder.waseet_order_id || finalOrder.waseet_order_id === 'null') {
        console.log('\n🔍 تحليل أسباب الفشل:');
        
        if (!finalOrder.waseet_status) {
          console.log('❌ السبب: النظام لم يحاول إرسال الطلب للوسيط');
          console.log('🔧 المشكلة المحتملة: خدمة المزامنة غير مهيأة أو معطلة');
          return 'sync_service_not_initialized';
        } else if (finalOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
          console.log('❌ السبب: النظام حاول لكن فشل في الإرسال');
          console.log('🔧 المشكلة المحتملة: مشكلة في API الوسيط أو بيانات المصادقة');
          return 'waseet_api_error';
        } else {
          console.log('❌ السبب: حالة غير متوقعة');
          return 'unknown_error';
        }
      } else {
        console.log('🎉 النظام يعمل بشكل صحيح!');
        return 'success';
      }
    }

    return 'analysis_failed';

  } catch (error) {
    console.error('❌ خطأ في التحليل الشامل:', error);
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
        'User-Agent': 'Comprehensive-Analysis/1.0'
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

// تشغيل التحليل الشامل
comprehensiveWaseetAnalysis()
  .then((result) => {
    console.log('\n🏁 نتيجة التحليل الشامل:');
    console.log('='.repeat(80));
    
    switch(result) {
      case 'success':
        console.log('🎉 النظام يعمل بشكل مثالي!');
        console.log('✅ الطلبات يتم إرسالها للوسيط بنجاح');
        break;
      case 'sync_service_not_initialized':
        console.log('❌ خدمة المزامنة غير مهيأة');
        console.log('🔧 الحل: فحص تهيئة global.orderSyncService');
        break;
      case 'waseet_api_error':
        console.log('❌ مشكلة في API الوسيط');
        console.log('🔧 الحل: فحص بيانات المصادقة وحالة API');
        break;
      case 'unknown_error':
        console.log('❌ خطأ غير معروف');
        console.log('🔧 الحل: فحص السجلات للمزيد من التفاصيل');
        break;
      case 'analysis_failed':
        console.log('❌ فشل في التحليل');
        break;
      case 'error':
        console.log('❌ خطأ في تشغيل التحليل');
        break;
      default:
        console.log('❓ نتيجة غير متوقعة');
    }
    
    console.log('\n📊 ملخص التحليل:');
  console.log('🌐 الخادم: https://montajati-official-backend-production.up.railway.app');
    console.log('🔗 API الوسيط: https://api.alwaseet-iq.net/v1/merchant/create-order');
    console.log('🎯 الهدف: تحديد سبب عدم إضافة الطلب للوسيط');
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل التحليل الشامل:', error);
  });
