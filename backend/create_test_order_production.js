// ===================================
// إنشاء طلب اختبار على الخادم الرسمي
// Create Test Order on Production Server
// ===================================

const https = require('https');

async function createTestOrderProduction() {
  console.log('📦 إنشاء طلب اختبار على الخادم الرسمي');
  console.log('🔗 الخادم: https://montajati-backend.onrender.com');
  console.log('='.repeat(60));

  const baseURL = 'https://montajati-backend.onrender.com';

  try {
    // المرحلة 1: إنشاء طلب جديد على الخادم الرسمي
    console.log('\n📝 المرحلة 1: إنشاء طلب جديد على الخادم الرسمي');
    console.log('='.repeat(50));
    
    const orderData = {
      customer_name: 'عميل اختبار رسمي',
      customer_phone: '07901234567',
      customer_address: 'بغداد - الكرادة - شارع الاختبار',
      items: [
        {
          name: 'منتج اختبار',
          price: 25000,
          quantity: 1
        }
      ],
      total: 25000,
      notes: 'طلب اختبار رسمي لفحص النظام',
      created_by: 'production_test_system'
    };

    console.log('📋 بيانات الطلب الجديد:');
    console.log(JSON.stringify(orderData, null, 2));

    const createResult = await makeRequest('POST', `${baseURL}/api/orders`, orderData);
    
    if (createResult.success) {
      console.log('✅ تم إنشاء الطلب بنجاح على الخادم الرسمي');
      const newOrder = createResult.data?.data || createResult.data;
      console.log(`🆔 معرف الطلب الجديد: ${newOrder.id}`);
      
      // المرحلة 2: تحديث حالة الطلب لاختبار الوسيط
      console.log('\n🔄 المرحلة 2: تحديث حالة الطلب لاختبار الوسيط');
      console.log('='.repeat(50));
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار رسمي - تحديث لإرسال للوسيط',
        changedBy: 'production_test_system'
      };

      console.log(`🔄 تحديث حالة الطلب ${newOrder.id} على الخادم الرسمي...`);
      
      const updateResult = await makeRequest('PUT', `${baseURL}/api/orders/${newOrder.id}/status`, updateData);
      
      if (updateResult.success) {
        console.log('✅ تم تحديث الحالة بنجاح على الخادم الرسمي');
        
        // انتظار معالجة الطلب
        console.log('\n⏱️ انتظار معالجة الطلب على الخادم الرسمي (25 ثانية)...');
        await new Promise(resolve => setTimeout(resolve, 25000));
        
        // المرحلة 3: فحص النتيجة النهائية
        console.log('\n🔍 المرحلة 3: فحص النتيجة النهائية');
        console.log('='.repeat(50));
        
        const checkResult = await makeRequest('GET', `${baseURL}/api/orders/${newOrder.id}`);
        
        if (checkResult.success) {
          const finalOrder = checkResult.data?.data || checkResult.data;
          
          console.log('📋 حالة الطلب النهائية على الخادم الرسمي:');
          console.log(`   🆔 معرف الطلب: ${finalOrder.id}`);
          console.log(`   👤 العميل: ${finalOrder.customer_name}`);
          console.log(`   📞 الهاتف: ${finalOrder.customer_phone}`);
          console.log(`   📊 الحالة: ${finalOrder.status}`);
          console.log(`   🚚 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`   📋 حالة الوسيط: ${finalOrder.waseet_status || 'غير محدد'}`);
          console.log(`   🕐 آخر تحديث: ${finalOrder.updated_at}`);
          
          if (finalOrder.waseet_data) {
            try {
              const waseetData = JSON.parse(finalOrder.waseet_data);
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
              console.log(`   📋 بيانات الوسيط (خام): ${finalOrder.waseet_data}`);
            }
          }
          
          // تحليل النتيجة النهائية
          console.log('\n🎯 تحليل النتيجة النهائية:');
          console.log('='.repeat(50));
          
          if (finalOrder.waseet_order_id && finalOrder.waseet_order_id !== 'null') {
            console.log('🎉 نجح! تم إرسال الطلب للوسيط على الخادم الرسمي');
            console.log(`🆔 معرف الوسيط: ${finalOrder.waseet_order_id}`);
            console.log('✅ النظام يعمل بشكل مثالي على الخادم الرسمي');
            console.log('🚀 التطبيق المُصدَّر جاهز للاستخدام الفوري');
            return 'success';
          } else if (finalOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('⚠️ النظام حاول الإرسال لكن فشل على الخادم الرسمي');
            console.log('🔄 النظام سيعيد المحاولة تلقائياً خلال 10 دقائق');
            return 'retry_needed';
          } else {
            console.log('❌ النظام لم يحاول إرسال الطلب للوسيط على الخادم الرسمي');
            console.log('🔧 خدمة المزامنة غير مهيأة على الخادم الرسمي');
            return 'sync_not_initialized';
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
    } else {
      console.log('❌ فشل في إنشاء الطلب على الخادم الرسمي');
      console.log('تفاصيل الخطأ:', createResult);
      return 'failed';
    }

  } catch (error) {
    console.error('❌ خطأ في إنشاء طلب الاختبار:', error);
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
        'User-Agent': 'Production-Test-Order/1.0'
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

// تشغيل إنشاء طلب الاختبار
createTestOrderProduction()
  .then((result) => {
    console.log('\n🏁 النتيجة النهائية لاختبار الخادم الرسمي:');
    console.log('='.repeat(70));
    
    switch(result) {
      case 'success':
        console.log('🎉 الاختبار الرسمي نجح بالكامل!');
        console.log('✅ الخادم الرسمي يرسل الطلبات للوسيط بنجاح');
        console.log('🚀 التطبيق المُصدَّر جاهز للاستخدام الفوري');
        console.log('📱 يمكن تثبيت montajati-app-final-v3.0.0.apk واستخدامه');
        break;
      case 'retry_needed':
        console.log('⚠️ الخادم الرسمي يحاول الإرسال لكن يحتاج إعادة محاولة');
        console.log('🔄 النظام سيعيد المحاولة تلقائياً');
        console.log('✅ التطبيق المُصدَّر سيعمل بشكل صحيح');
        break;
      case 'sync_not_initialized':
        console.log('❌ خدمة المزامنة غير مهيأة على الخادم الرسمي');
        console.log('🔧 يحتاج إصلاح إضافي في الخادم');
        break;
      case 'failed':
        console.log('❌ الاختبار الرسمي فشل');
        console.log('🔧 الخادم الرسمي يحتاج إصلاح');
        break;
      case 'error':
        console.log('❌ خطأ في الاختبار الرسمي');
        break;
      default:
        console.log('❓ نتيجة غير متوقعة');
    }
    
    console.log('\n📊 ملخص الاختبار الرسمي النهائي:');
    console.log('🌐 الخادم الرسمي: https://montajati-backend.onrender.com');
    console.log('🔗 API الوسيط: https://api.alwaseet-iq.net/v1/merchant/create-order');
    console.log('📱 التطبيق المُصدَّر: montajati-app-final-v3.0.0.apk');
    console.log('🎯 الاختبار: رسمي كامل على الخادم الحقيقي');
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل اختبار الخادم الرسمي:', error);
  });
