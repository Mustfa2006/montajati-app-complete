// ===================================
// تحليل دقيق للخادم الحي على Render
// Live Server Analysis on Render
// ===================================

const https = require('https');

async function analyzeLiveServer() {
  console.log('🔍 تحليل دقيق للخادم الحي على Render...');
  console.log('='.repeat(70));

  const baseUrl = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. فحص حالة الخادم
    console.log('\n1️⃣ فحص حالة الخادم...');
    const healthResult = await makeRequest('GET', `${baseUrl}/health`);
    
    if (healthResult.success) {
      console.log('✅ الخادم متاح ويعمل');
      console.log('📋 معلومات الخادم:', JSON.stringify(healthResult.data, null, 2));
    } else {
      console.log('❌ الخادم غير متاح:', healthResult.error);
      return;
    }

    // 2. جلب طلب للاختبار
    console.log('\n2️⃣ جلب طلب للاختبار...');
    const ordersResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=1`);
    
    if (!ordersResult.success) {
      console.log('❌ فشل في جلب الطلبات:', ordersResult.error);
      return;
    }
    
    const orders = ordersResult.data?.data || ordersResult.data?.orders || ordersResult.data || [];
    
    if (!orders.length) {
      console.log('❌ لا توجد طلبات للاختبار');
      return;
    }

    const testOrder = orders[0];
    console.log(`📦 طلب الاختبار: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🆔 معرف الوسيط الحالي: ${testOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`📋 حالة الوسيط: ${testOrder.waseet_status || 'غير محدد'}`);

    // 3. اختبار تحديث الحالة مع مراقبة دقيقة
    console.log('\n3️⃣ اختبار تحديث الحالة مع مراقبة دقيقة...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار تحليل دقيق للخادم الحي - ' + new Date().toISOString(),
      changedBy: 'live_server_analysis_test'
    };
    
    console.log('📤 إرسال طلب تحديث الحالة...');
    console.log('📋 البيانات المرسلة:', JSON.stringify(updateData, null, 2));
    
    const updateResult = await makeRequest(
      'PUT', 
      `${baseUrl}/api/orders/${testOrder.id}/status`,
      updateData
    );
    
    if (!updateResult.success) {
      console.log('❌ فشل في تحديث حالة الطلب');
      console.log('📋 الخطأ:', updateResult.error);
      console.log('📋 الاستجابة الخام:', updateResult.rawResponse);
      return;
    }
    
    console.log('✅ تم إرسال طلب التحديث بنجاح');
    console.log('📋 استجابة الخادم:', JSON.stringify(updateResult.data, null, 2));

    // 4. انتظار ومراقبة التغييرات
    console.log('\n4️⃣ مراقبة التغييرات كل 5 ثوان لمدة 30 ثانية...');
    
    for (let i = 1; i <= 6; i++) {
      console.log(`\n⏱️ فحص ${i}/6 (بعد ${i * 5} ثوان):`);
      
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      const checkResult = await makeRequest('GET', `${baseUrl}/api/orders/${testOrder.id}`);
      
      if (checkResult.success) {
        const currentOrder = checkResult.data;
        
        console.log(`   📊 الحالة: ${currentOrder.status}`);
        console.log(`   🆔 معرف الوسيط: ${currentOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📋 حالة الوسيط: ${currentOrder.waseet_status || 'غير محدد'}`);
        console.log(`   📅 تاريخ التحديث: ${currentOrder.updated_at}`);
        
        if (currentOrder.waseet_data) {
          try {
            const waseetData = JSON.parse(currentOrder.waseet_data);
            console.log(`   📋 بيانات الوسيط: موجودة`);
            
            if (waseetData.success) {
              console.log(`   ✅ تم إرسال الطلب للوسيط بنجاح!`);
              console.log(`   🆔 QR ID: ${waseetData.qrId}`);
              break;
            } else if (waseetData.error) {
              console.log(`   ❌ فشل في إرسال الطلب للوسيط: ${waseetData.error}`);
            }
          } catch (e) {
            console.log(`   ⚠️ بيانات الوسيط غير قابلة للقراءة`);
          }
        } else {
          console.log(`   ⚠️ لا توجد بيانات وسيط`);
        }
        
        // إذا تم إرسال الطلب بنجاح، توقف
        if (currentOrder.waseet_order_id) {
          console.log(`\n🎉 تم إرسال الطلب للوسيط بنجاح!`);
          break;
        }
      } else {
        console.log(`   ❌ فشل في جلب الطلب: ${checkResult.error}`);
      }
    }

    // 5. التحليل النهائي
    console.log('\n5️⃣ التحليل النهائي...');
    
    const finalResult = await makeRequest('GET', `${baseUrl}/api/orders/${testOrder.id}`);
    
    if (finalResult.success) {
      const finalOrder = finalResult.data;
      
      console.log('\n📊 النتائج النهائية:');
      console.log('='.repeat(50));
      console.log(`📦 معرف الطلب: ${finalOrder.id}`);
      console.log(`👤 العميل: ${finalOrder.customer_name}`);
      console.log(`📊 الحالة: ${finalOrder.status}`);
      console.log(`🆔 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
      console.log(`📋 حالة الوسيط: ${finalOrder.waseet_status || 'غير محدد'}`);
      console.log(`📅 تاريخ التحديث: ${finalOrder.updated_at}`);

      // تحليل مفصل للنتيجة
      console.log('\n🎯 تحليل النتيجة:');
      console.log('='.repeat(50));
      
      if (finalOrder.waseet_order_id) {
        console.log('🎉 الإصلاح نجح! تم إرسال الطلب للوسيط بنجاح');
        console.log('✅ النظام يعمل بشكل مثالي على الخادم الحي');
        
      } else if (finalOrder.waseet_data) {
        try {
          const waseetData = JSON.parse(finalOrder.waseet_data);
          
          if (waseetData.error) {
            console.log('✅ الإصلاح نجح جزئياً - النظام يحاول إرسال الطلبات');
            console.log(`❌ لكن هناك مشكلة في الوسيط: ${waseetData.error}`);
            
            if (waseetData.error.includes('فشل في المصادقة') || 
                waseetData.error.includes('اسم المستخدم') ||
                waseetData.error.includes('رمز الدخول')) {
              console.log('🔑 المشكلة: بيانات المصادقة مع شركة الوسيط خاطئة');
              console.log('💡 الحل: تحديث بيانات المصادقة مع شركة الوسيط');
              
            } else if (waseetData.error.includes('timeout') || 
                       waseetData.error.includes('ECONNRESET') ||
                       waseetData.error.includes('network')) {
              console.log('🌐 المشكلة: مشكلة في الاتصال بخدمة الوسيط');
              console.log('💡 الحل: إعادة المحاولة لاحقاً أو التواصل مع الوسيط');
              
            } else {
              console.log('🔍 مشكلة أخرى في خدمة الوسيط');
              console.log('💡 الحل: فحص تفاصيل الخطأ والتواصل مع الدعم');
            }
          } else {
            console.log('⚠️ بيانات الوسيط موجودة لكن غير واضحة');
          }
        } catch (e) {
          console.log('❌ بيانات الوسيط غير قابلة للقراءة');
        }
        
      } else if (finalOrder.waseet_status === 'pending') {
        console.log('❌ الإصلاح لم ينجح - النظام لا يحاول إرسال الطلبات للوسيط');
        console.log('🔍 المشكلة: الكود المحدث لم يصل للخادم أو لا يعمل');
        console.log('💡 الحل: فحص الكود على الخادم وإعادة النشر');
        
      } else {
        console.log('❓ حالة غير متوقعة - يحتاج فحص أعمق');
      }
    }

    console.log('\n🎯 انتهى التحليل الدقيق للخادم الحي');

  } catch (error) {
    console.error('❌ خطأ في تحليل الخادم الحي:', error);
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
        'User-Agent': 'Montajati-Live-Analysis/1.0'
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

// تشغيل التحليل
if (require.main === module) {
  analyzeLiveServer()
    .then(() => {
      console.log('\n✅ انتهى التحليل الدقيق للخادم الحي');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل التحليل الدقيق للخادم الحي:', error);
      process.exit(1);
    });
}

module.exports = { analyzeLiveServer };
