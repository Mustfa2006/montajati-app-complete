// ===================================
// إنشاء طلب تجريبي واختبار تحديثه
// Create Test Order and Test Update
// ===================================

const https = require('https');

async function testCreateAndUpdateOrder() {
  console.log('🧪 إنشاء طلب تجريبي واختبار تحديثه...');
  console.log('='.repeat(60));

  const baseUrl = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    // 1. إنشاء طلب تجريبي
    console.log('\n1️⃣ إنشاء طلب تجريبي...');
    
    const testOrderData = {
      id: `test_order_${Date.now()}`,
      customer_name: 'عميل اختبار النظام النهائي',
      customer_phone: '07501234567',
      primary_phone: '07501234567',
      secondary_phone: '07701234567',
      customer_address: 'بغداد - الكرادة - شارع الكرادة الداخل',
      province: 'بغداد',
      city: 'الكرادة',
      total: 75000,
      status: 'active',
      notes: 'طلب تجريبي لاختبار نظام الوسيط',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    const createResult = await makeRequest('POST', `${baseUrl}/api/orders`, testOrderData);
    
    if (!createResult.success) {
      console.log('❌ فشل في إنشاء الطلب التجريبي');
      console.log(`📋 الخطأ:`, createResult.error);
      return;
    }
    
    const createdOrder = createResult.data;
    console.log('✅ تم إنشاء الطلب التجريبي بنجاح');
    console.log(`📦 معرف الطلب: ${createdOrder.id}`);
    console.log(`👤 العميل: ${createdOrder.customer_name}`);
    console.log(`📊 الحالة: ${createdOrder.status}`);

    // 2. تحديث حالة الطلب إلى "قيد التوصيل"
    console.log('\n2️⃣ تحديث حالة الطلب إلى "قيد التوصيل"...');
    
    const updateData = {
      status: 'in_delivery',
      notes: 'اختبار إرسال للوسيط - تحديث تلقائي من النظام',
      changedBy: 'test_system_final'
    };
    
    const updateResult = await makeRequest(
      'PUT', 
      `${baseUrl}/api/orders/${createdOrder.id}/status`,
      updateData
    );
    
    if (updateResult.success) {
      console.log('✅ تم تحديث حالة الطلب بنجاح');
      console.log(`📋 الاستجابة:`, updateResult.data);
      
      // 3. انتظار قليل ثم فحص الطلب
      console.log('\n3️⃣ انتظار 15 ثانية ثم فحص الطلب...');
      await new Promise(resolve => setTimeout(resolve, 15000));
      
      const checkResult = await makeRequest('GET', `${baseUrl}/api/orders/${createdOrder.id}`);
      
      if (checkResult.success) {
        const updatedOrder = checkResult.data;
        console.log('\n📊 حالة الطلب بعد التحديث:');
        console.log(`   - الحالة: ${updatedOrder.status}`);
        console.log(`   - معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   - حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
        console.log(`   - تاريخ التحديث: ${updatedOrder.updated_at}`);
        
        if (updatedOrder.waseet_data) {
          try {
            const waseetData = JSON.parse(updatedOrder.waseet_data);
            console.log(`   - بيانات الوسيط: موجودة`);
            if (waseetData.error) {
              console.log(`   - خطأ الوسيط: ${waseetData.error}`);
            }
            if (waseetData.qrId) {
              console.log(`   - QR ID: ${waseetData.qrId}`);
            }
            if (waseetData.success !== undefined) {
              console.log(`   - نجح الإرسال: ${waseetData.success}`);
            }
          } catch (e) {
            console.log(`   - بيانات الوسيط: غير قابلة للقراءة`);
          }
        }
        
        // 4. تحليل النتائج النهائي
        console.log('\n4️⃣ تحليل النتائج النهائي:');
        console.log('='.repeat(50));
        
        if (updatedOrder.status === 'in_delivery') {
          console.log('✅ تم تحديث حالة الطلب إلى "قيد التوصيل" بنجاح');
          
          if (updatedOrder.waseet_order_id) {
            console.log('✅ تم إرسال الطلب لشركة الوسيط بنجاح');
            console.log('🎉 النظام يعمل بشكل مثالي 100%!');
            console.log(`🆔 معرف الوسيط: ${updatedOrder.waseet_order_id}`);
            console.log('🚀 التطبيق جاهز للاستخدام الفعلي');
            
          } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('⚠️ فشل في إرسال الطلب للوسيط - في قائمة الانتظار');
            console.log('🔄 سيتم إعادة المحاولة تلقائياً');
            
            if (updatedOrder.waseet_data) {
              try {
                const waseetData = JSON.parse(updatedOrder.waseet_data);
                console.log(`📋 سبب الفشل: ${waseetData.error}`);
                
                if (waseetData.error && waseetData.error.includes('فشل في المصادقة')) {
                  console.log('🔑 المشكلة: بيانات المصادقة مع شركة الوسيط');
                  console.log('💡 الحل: التحقق من WASEET_USERNAME و WASEET_PASSWORD');
                }
              } catch (e) {
                console.log('📋 بيانات الخطأ غير واضحة');
              }
            }
            
          } else {
            console.log('❌ لم يتم محاولة إرسال الطلب للوسيط');
            console.log('🔍 المشكلة: الكود لا يتم تنفيذه بشكل صحيح');
          }
        } else {
          console.log('❌ لم يتم تحديث حالة الطلب بشكل صحيح');
        }
        
        // 5. اختبار retry endpoint
        console.log('\n5️⃣ اختبار retry endpoint...');
        const retryResult = await makeRequest('POST', `${baseUrl}/api/orders/retry-failed-waseet`);
        
        if (retryResult.success) {
          console.log('✅ retry endpoint يعمل');
          console.log(`📋 النتيجة:`, retryResult.data);
          
          if (retryResult.data.retried > 0) {
            console.log(`🔄 تم إعادة محاولة ${retryResult.data.retried} طلب`);
            console.log(`✅ نجح: ${retryResult.data.successful}, فشل: ${retryResult.data.failed}`);
          }
        } else {
          console.log('❌ retry endpoint لا يعمل');
          console.log(`📋 الخطأ:`, retryResult.error);
        }
        
      } else {
        console.log('❌ فشل في جلب الطلب المحدث');
        console.log(`📋 الخطأ:`, checkResult.error);
      }
      
    } else {
      console.log('❌ فشل في تحديث حالة الطلب');
      console.log(`📋 الخطأ:`, updateResult.error);
    }

    console.log('\n🎯 انتهى اختبار إنشاء وتحديث الطلب');
    console.log('='.repeat(60));

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
        'User-Agent': 'Montajati-Final-Test/1.0'
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
  testCreateAndUpdateOrder()
    .then(() => {
      console.log('\n✅ انتهى الاختبار النهائي');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار النهائي:', error);
      process.exit(1);
    });
}

module.exports = { testCreateAndUpdateOrder };
