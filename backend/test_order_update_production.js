// ===================================
// اختبار تحديث حالة الطلب في الإنتاج
// Test Order Status Update in Production
// ===================================

const https = require('https');

async function testOrderUpdateProduction() {
  console.log('🧪 اختبار تحديث حالة الطلب في الإنتاج...');
  console.log('='.repeat(60));

  const baseUrl = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    // 1. جلب طلب للاختبار
    console.log('\n1️⃣ جلب طلب للاختبار...');
    let ordersResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=5&status=active`);

    if (!ordersResult.success || !ordersResult.data?.orders?.length) {
      console.log('⚠️ لا توجد طلبات نشطة - البحث عن أي طلب...');
      ordersResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=5`);

      if (!ordersResult.success || !ordersResult.data?.orders?.length) {
        console.log('❌ لا توجد طلبات للاختبار');
        return;
      }
    }

    const testOrder = ordersResult.data.orders[0];
    console.log(`📦 طلب الاختبار: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`📞 الهاتف: ${testOrder.customer_phone || testOrder.primary_phone}`);

    // 2. تحديث حالة الطلب إلى "قيد التوصيل"
    console.log('\n2️⃣ تحديث حالة الطلب إلى "قيد التوصيل"...');
    
    const updateData = {
      status: 'in_delivery',
      notes: 'اختبار إرسال للوسيط - تحديث تلقائي من النظام',
      changedBy: 'test_system_production'
    };
    
    const updateResult = await makeRequest(
      'PUT', 
      `${baseUrl}/api/orders/${testOrder.id}/status`,
      updateData
    );
    
    if (updateResult.success) {
      console.log('✅ تم تحديث حالة الطلب بنجاح');
      console.log(`📋 الاستجابة:`, updateResult.data);
      
      // 3. انتظار قليل ثم فحص الطلب
      console.log('\n3️⃣ انتظار 10 ثوان ثم فحص الطلب...');
      await new Promise(resolve => setTimeout(resolve, 10000));
      
      const checkResult = await makeRequest('GET', `${baseUrl}/api/orders/${testOrder.id}`);
      
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
          } catch (e) {
            console.log(`   - بيانات الوسيط: غير قابلة للقراءة`);
          }
        }
        
        // 4. تحليل النتائج
        console.log('\n4️⃣ تحليل النتائج:');
        
        if (updatedOrder.status === 'in_delivery') {
          console.log('✅ تم تحديث حالة الطلب إلى "قيد التوصيل" بنجاح');
          
          if (updatedOrder.waseet_order_id) {
            console.log('✅ تم إرسال الطلب لشركة الوسيط بنجاح');
            console.log('🎉 النظام يعمل بشكل مثالي!');
            console.log(`🆔 معرف الوسيط: ${updatedOrder.waseet_order_id}`);
            
          } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('⚠️ فشل في إرسال الطلب للوسيط - في قائمة الانتظار');
            console.log('🔄 يمكن إعادة المحاولة لاحقاً');
            
            if (updatedOrder.waseet_data) {
              try {
                const waseetData = JSON.parse(updatedOrder.waseet_data);
                console.log(`📋 سبب الفشل: ${waseetData.error}`);
              } catch (e) {
                console.log('📋 بيانات الخطأ غير واضحة');
              }
            }
            
          } else {
            console.log('❌ لم يتم محاولة إرسال الطلب للوسيط');
            console.log('🔍 يجب فحص الكود والإعدادات');
          }
        } else {
          console.log('❌ لم يتم تحديث حالة الطلب بشكل صحيح');
        }
        
      } else {
        console.log('❌ فشل في جلب الطلب المحدث');
        console.log(`📋 الخطأ:`, checkResult.error);
      }
      
    } else {
      console.log('❌ فشل في تحديث حالة الطلب');
      console.log(`📋 الخطأ:`, updateResult.error);
    }

    // 5. اختبار retry endpoint
    console.log('\n5️⃣ اختبار retry endpoint...');
    const retryResult = await makeRequest('POST', `${baseUrl}/api/orders/retry-failed-waseet`);
    
    if (retryResult.success) {
      console.log('✅ retry endpoint يعمل');
      console.log(`📋 النتيجة:`, retryResult.data);
    } else {
      console.log('❌ retry endpoint لا يعمل');
      console.log(`📋 الخطأ:`, retryResult.error);
    }

    console.log('\n🎯 انتهى اختبار تحديث الطلب في الإنتاج');

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
        'User-Agent': 'Montajati-Production-Test/1.0'
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
  testOrderUpdateProduction()
    .then(() => {
      console.log('\n✅ انتهى الاختبار');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار:', error);
      process.exit(1);
    });
}

module.exports = { testOrderUpdateProduction };
