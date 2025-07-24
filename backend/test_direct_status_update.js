// ===================================
// اختبار تحديث حالة طلب مباشرة على الخادم الحي
// Direct Status Update Test on Live Server
// ===================================

const https = require('https');

async function testDirectStatusUpdate() {
  console.log('🔧 اختبار تحديث حالة طلب مباشرة على الخادم الحي...');
  console.log('='.repeat(70));

  const baseUrl = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. جلب طلب للاختبار
    console.log('\n1️⃣ جلب طلب للاختبار...');
    const ordersResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=1`);
    
    if (!ordersResult.success) {
      console.log('❌ فشل في جلب الطلبات:', ordersResult.error);
      return;
    }
    
    const orders = ordersResult.data?.data || ordersResult.data || [];
    
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

    // 2. تحديث الحالة مع مراقبة مفصلة
    console.log('\n2️⃣ تحديث الحالة إلى "قيد التوصيل الى الزبون (في عهدة المندوب)"...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار مباشر للخادم الحي - ' + new Date().toISOString(),
      changedBy: 'direct_live_test'
    };
    
    console.log('📤 إرسال طلب التحديث...');
    console.log('📋 البيانات:', JSON.stringify(updateData, null, 2));
    
    const updateResult = await makeRequest(
      'PUT', 
      `${baseUrl}/api/orders/${testOrder.id}/status`,
      updateData
    );
    
    console.log('\n📥 استجابة الخادم:');
    console.log('📊 نجح:', updateResult.success);
    console.log('📊 الحالة:', updateResult.status);
    
    if (updateResult.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      console.log('📋 البيانات:', JSON.stringify(updateResult.data, null, 2));
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('📋 الخطأ:', updateResult.error);
      console.log('📋 الاستجابة الخام:', updateResult.rawResponse);
      return;
    }

    // 3. مراقبة التغييرات لمدة 60 ثانية
    console.log('\n3️⃣ مراقبة التغييرات كل 10 ثوان لمدة 60 ثانية...');
    
    for (let i = 1; i <= 6; i++) {
      console.log(`\n⏱️ فحص ${i}/6 (بعد ${i * 10} ثوان):`);
      
      await new Promise(resolve => setTimeout(resolve, 10000));
      
      const checkResult = await makeRequest('GET', `${baseUrl}/api/orders/${testOrder.id}`);
      
      if (checkResult.success) {
        const currentOrder = checkResult.data;
        
        console.log(`   📊 الحالة: ${currentOrder.status}`);
        console.log(`   🆔 معرف الوسيط: ${currentOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📋 حالة الوسيط: ${currentOrder.waseet_status || 'غير محدد'}`);
        console.log(`   📅 آخر تحديث: ${currentOrder.updated_at}`);
        
        // فحص بيانات الوسيط
        if (currentOrder.waseet_data) {
          try {
            const waseetData = JSON.parse(currentOrder.waseet_data);
            console.log(`   📋 بيانات الوسيط: موجودة`);
            
            if (waseetData.success) {
              console.log(`   ✅ تم إرسال الطلب للوسيط بنجاح!`);
              console.log(`   🆔 QR ID: ${waseetData.qrId}`);
              console.log(`\n🎉 الاختبار نجح! النظام يعمل بشكل مثالي!`);
              return;
              
            } else if (waseetData.error) {
              console.log(`   ❌ فشل في إرسال الطلب للوسيط`);
              console.log(`   📋 سبب الفشل: ${waseetData.error}`);
              
              // تحليل نوع الخطأ
              if (waseetData.error.includes('فشل في المصادقة') || 
                  waseetData.error.includes('اسم المستخدم') ||
                  waseetData.error.includes('رمز الدخول') ||
                  waseetData.error.includes('unauthorized') ||
                  waseetData.error.includes('authentication')) {
                console.log(`   🔑 المشكلة: بيانات المصادقة مع شركة الوسيط`);
                
              } else if (waseetData.error.includes('timeout') || 
                         waseetData.error.includes('ECONNRESET') ||
                         waseetData.error.includes('network') ||
                         waseetData.error.includes('ENOTFOUND')) {
                console.log(`   🌐 المشكلة: مشكلة في الاتصال بخدمة الوسيط`);
                
              } else {
                console.log(`   🔍 مشكلة أخرى في خدمة الوسيط`);
              }
              
            } else {
              console.log(`   ⚠️ بيانات الوسيط غير واضحة`);
              console.log(`   📋 البيانات: ${JSON.stringify(waseetData, null, 2)}`);
            }
          } catch (e) {
            console.log(`   ❌ بيانات الوسيط غير قابلة للقراءة`);
            console.log(`   📋 البيانات الخام: ${currentOrder.waseet_data}`);
          }
        } else {
          console.log(`   ⚠️ لا توجد بيانات وسيط - النظام لم يحاول الإرسال`);
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

    // 4. النتيجة النهائية والتحليل
    console.log('\n4️⃣ النتيجة النهائية والتحليل...');
    
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

      // تحليل شامل للنتيجة
      console.log('\n🎯 التحليل الشامل:');
      console.log('='.repeat(50));
      
      if (finalOrder.waseet_order_id) {
        console.log('🎉 الإصلاح نجح 100%! النظام يعمل بشكل مثالي!');
        console.log('✅ تم إرسال الطلب للوسيط بنجاح');
        console.log('🚀 التطبيق جاهز للاستخدام الفعلي');
        
      } else if (finalOrder.waseet_data) {
        console.log('✅ الإصلاح نجح جزئياً - النظام يحاول إرسال الطلبات');
        console.log('❌ لكن هناك مشكلة في خدمة الوسيط أو بيانات المصادقة');
        console.log('📞 التوصية: التواصل مع شركة الوسيط لحل مشكلة المصادقة');
        
      } else if (finalOrder.waseet_status === 'pending') {
        console.log('❌ الإصلاح لم ينجح - النظام لا يحاول إرسال الطلبات للوسيط');
        console.log('🔍 المشكلة: الكود المحدث لم يصل للخادم أو خدمة المزامنة معطلة');
        console.log('💡 الحل: إعادة نشر الكود وإعادة تشغيل خدمة المزامنة');
        
      } else {
        console.log('❓ حالة غير متوقعة - يحتاج فحص أعمق');
        console.log('🔍 قد تكون المشكلة في تهيئة خدمة المزامنة على الخادم');
      }
      
      // عرض بيانات الوسيط إن وجدت
      if (finalOrder.waseet_data) {
        console.log('\n📋 بيانات الوسيط التفصيلية:');
        try {
          const waseetData = JSON.parse(finalOrder.waseet_data);
          console.log(JSON.stringify(waseetData, null, 2));
        } catch (e) {
          console.log('البيانات الخام:', finalOrder.waseet_data);
        }
      }
    }

    console.log('\n🎯 انتهى اختبار تحديث الحالة المباشر');

  } catch (error) {
    console.error('❌ خطأ في اختبار تحديث الحالة المباشر:', error);
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
  testDirectStatusUpdate()
    .then(() => {
      console.log('\n✅ انتهى اختبار تحديث الحالة المباشر');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل اختبار تحديث الحالة المباشر:', error);
      process.exit(1);
    });
}

module.exports = { testDirectStatusUpdate };
