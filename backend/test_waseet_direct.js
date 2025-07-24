// ===================================
// اختبار مباشر لـ API الوسيط من الخادم المنتج
// Direct Waseet API Test from Production Server
// ===================================

const https = require('https');

async function testWaseetDirect() {
  console.log('🧪 اختبار مباشر لـ API الوسيط من الخادم المنتج...');
  console.log('='.repeat(60));

  const baseUrl = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. اختبار endpoint خاص لاختبار الوسيط
    console.log('\n1️⃣ إنشاء endpoint اختبار الوسيط...');
    
    // إنشاء طلب لاختبار الوسيط مباشرة
    const testWaseetData = {
      action: 'test_waseet_auth',
      username: 'محمد@mustfaabd',
      password: 'mustfaabd2006@'
    };
    
    console.log('📋 بيانات الاختبار:', testWaseetData);
    
    // محاولة إنشاء طلب تجريبي بسيط
    console.log('\n2️⃣ إنشاء طلب تجريبي بسيط...');
    
    const simpleOrderData = {
      customer_name: 'عميل اختبار مباشر',
      customer_phone: '07501234567',
      customer_address: 'بغداد - الكرادة',
      total: 50000,
      status: 'active'
    };
    
    const createResult = await makeRequest('POST', `${baseUrl}/api/orders`, simpleOrderData);
    
    if (createResult.success) {
      console.log('✅ تم إنشاء الطلب بنجاح');
      console.log(`📦 معرف الطلب: ${createResult.data.id}`);
      
      // محاولة تحديث الحالة فوراً
      console.log('\n3️⃣ تحديث الحالة إلى "قيد التوصيل" فوراً...');
      
      const updateData = {
        status: 'in_delivery',
        notes: 'اختبار مباشر للوسيط',
        changedBy: 'direct_test'
      };
      
      const updateResult = await makeRequest(
        'PUT', 
        `${baseUrl}/api/orders/${createResult.data.id}/status`,
        updateData
      );
      
      if (updateResult.success) {
        console.log('✅ تم تحديث الحالة بنجاح');
        
        // انتظار وفحص النتيجة
        console.log('\n4️⃣ انتظار 20 ثانية وفحص النتيجة...');
        await new Promise(resolve => setTimeout(resolve, 20000));
        
        const checkResult = await makeRequest('GET', `${baseUrl}/api/orders/${createResult.data.id}`);
        
        if (checkResult.success) {
          const order = checkResult.data;
          console.log('\n📊 نتائج الفحص:');
          console.log(`   - الحالة: ${order.status}`);
          console.log(`   - معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
          console.log(`   - حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
          
          if (order.waseet_data) {
            try {
              const waseetData = JSON.parse(order.waseet_data);
              console.log(`   - بيانات الوسيط: موجودة`);
              console.log(`   - تفاصيل:`, waseetData);
            } catch (e) {
              console.log(`   - بيانات الوسيط: غير قابلة للقراءة`);
              console.log(`   - البيانات الخام:`, order.waseet_data);
            }
          } else {
            console.log(`   - بيانات الوسيط: غير موجودة`);
          }
          
          // تحليل المشكلة
          console.log('\n5️⃣ تحليل المشكلة:');
          
          if (order.waseet_order_id) {
            console.log('✅ النظام يعمل بشكل مثالي!');
          } else if (order.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('⚠️ فشل في الإرسال - تحليل السبب...');
            
            if (order.waseet_data) {
              try {
                const waseetData = JSON.parse(order.waseet_data);
                if (waseetData.error) {
                  console.log(`❌ سبب الفشل: ${waseetData.error}`);
                  
                  if (waseetData.error.includes('فشل في المصادقة')) {
                    console.log('🔑 المشكلة: بيانات المصادقة');
                    console.log('💡 الحل المطلوب: فحص API الوسيط مباشرة');
                  } else if (waseetData.error.includes('timeout')) {
                    console.log('⏰ المشكلة: انتهاء وقت الاتصال');
                    console.log('💡 الحل المطلوب: زيادة timeout أو فحص الشبكة');
                  } else {
                    console.log('🔍 مشكلة أخرى - يحتاج فحص أعمق');
                  }
                }
              } catch (e) {
                console.log('❌ لا يمكن تحليل بيانات الخطأ');
              }
            }
          } else {
            console.log('❌ لم يتم محاولة الإرسال أصلاً');
            console.log('🔍 المشكلة: الكود لا يتم تنفيذه');
          }
        }
        
      } else {
        console.log('❌ فشل في تحديث الحالة');
        console.log('📋 الخطأ:', updateResult.error);
      }
      
    } else {
      console.log('❌ فشل في إنشاء الطلب');
      console.log('📋 الخطأ:', createResult.error);
    }

    // 6. اختبار endpoint إعادة المحاولة
    console.log('\n6️⃣ اختبار endpoint إعادة المحاولة...');
    const retryResult = await makeRequest('POST', `${baseUrl}/api/orders/retry-failed-waseet`);
    
    if (retryResult.success) {
      console.log('✅ retry endpoint يعمل');
      console.log('📋 النتيجة:', retryResult.data);
    } else {
      console.log('❌ retry endpoint لا يعمل');
      console.log('📋 الخطأ:', retryResult.error);
    }

    console.log('\n🎯 انتهى الاختبار المباشر');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error);
  }
}

// دالة مساعدة لإرسال الطلبات
function makeRequest(method, url, data = null) {
  return new Promise((resolve) => {
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: 443,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Montajati-Direct-Test/1.0'
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
if (require.main === module) {
  testWaseetDirect()
    .then(() => {
      console.log('\n✅ انتهى الاختبار المباشر');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار المباشر:', error);
      process.exit(1);
    });
}

module.exports = { testWaseetDirect };
