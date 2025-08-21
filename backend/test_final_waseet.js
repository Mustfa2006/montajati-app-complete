// ===================================
// الاختبار النهائي لنظام الوسيط
// Final Waseet System Test
// ===================================

const https = require('https');

async function testFinalWaseet() {
  console.log('🎯 الاختبار النهائي لنظام الوسيط...');
  console.log('='.repeat(60));

  const baseUrl = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    // 1. إنشاء طلب تجريبي
    console.log('\n1️⃣ إنشاء طلب تجريبي...');
    const createResult = await makeRequest('POST', `${baseUrl}/api/orders/create-test-order`);
    
    if (!createResult.success) {
      console.log('❌ فشل في إنشاء الطلب التجريبي');
      console.log('📋 الخطأ:', createResult.error);
      return;
    }
    
    const testOrder = createResult.data;
    console.log('✅ تم إنشاء الطلب التجريبي بنجاح');
    console.log(`📦 معرف الطلب: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`📊 الحالة: ${testOrder.status}`);

    // 2. تحديث حالة الطلب إلى "قيد التوصيل"
    console.log('\n2️⃣ تحديث حالة الطلب إلى "قيد التوصيل"...');
    
    const updateData = {
      status: 'in_delivery',
      notes: 'اختبار نهائي لنظام الوسيط',
      changedBy: 'final_test_system'
    };
    
    const updateResult = await makeRequest(
      'PUT', 
      `${baseUrl}/api/orders/${testOrder.id}/status`,
      updateData
    );
    
    if (!updateResult.success) {
      console.log('❌ فشل في تحديث حالة الطلب');
      console.log('📋 الخطأ:', updateResult.error);
      return;
    }
    
    console.log('✅ تم تحديث حالة الطلب بنجاح');
    console.log('📋 الاستجابة:', updateResult.data);

    // 3. انتظار معالجة الطلب
    console.log('\n3️⃣ انتظار 20 ثانية لمعالجة الطلب...');
    await new Promise(resolve => setTimeout(resolve, 20000));

    // 4. فحص النتيجة النهائية
    console.log('\n4️⃣ فحص النتيجة النهائية...');
    const checkResult = await makeRequest('GET', `${baseUrl}/api/orders/${testOrder.id}`);
    
    if (!checkResult.success) {
      console.log('❌ فشل في جلب الطلب المحدث');
      console.log('📋 الخطأ:', checkResult.error);
      return;
    }
    
    const finalOrder = checkResult.data;
    
    console.log('\n📊 النتائج النهائية:');
    console.log('='.repeat(50));
    console.log(`📦 معرف الطلب: ${finalOrder.id}`);
    console.log(`👤 العميل: ${finalOrder.customer_name}`);
    console.log(`📊 الحالة: ${finalOrder.status}`);
    console.log(`🆔 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`📋 حالة الوسيط: ${finalOrder.waseet_status || 'غير محدد'}`);
    console.log(`📅 تاريخ التحديث: ${finalOrder.updated_at}`);

    // 5. تحليل بيانات الوسيط
    if (finalOrder.waseet_data) {
      try {
        const waseetData = JSON.parse(finalOrder.waseet_data);
        console.log('\n📋 تفاصيل بيانات الوسيط:');
        console.log(JSON.stringify(waseetData, null, 2));
        
        if (waseetData.success) {
          console.log('\n🎉 نجح إرسال الطلب للوسيط!');
          console.log(`🆔 QR ID: ${waseetData.qrId}`);
          console.log('✅ النظام يعمل بشكل مثالي 100%!');
          
        } else if (waseetData.error) {
          console.log('\n❌ فشل في إرسال الطلب للوسيط');
          console.log(`📋 سبب الفشل: ${waseetData.error}`);
          
          if (waseetData.error.includes('فشل في المصادقة')) {
            console.log('\n🔍 تحليل مشكلة المصادقة:');
            console.log('   ❌ المشكلة: بيانات المصادقة مع شركة الوسيط');
            console.log('   💡 الحلول المحتملة:');
            console.log('      1. التحقق من صحة اسم المستخدم وكلمة المرور');
            console.log('      2. التواصل مع شركة الوسيط للتأكد من الحساب');
            console.log('      3. فحص تغيير في API endpoints');
            console.log('      4. التحقق من أن الحساب غير مقفل');
            
          } else if (waseetData.error.includes('timeout')) {
            console.log('\n🔍 تحليل مشكلة الاتصال:');
            console.log('   ❌ المشكلة: انتهاء وقت الاتصال');
            console.log('   💡 الحلول المحتملة:');
            console.log('      1. زيادة timeout في الكود');
            console.log('      2. فحص استقرار شبكة الخادم');
            console.log('      3. التحقق من حالة خدمة الوسيط');
            
          } else {
            console.log('\n🔍 مشكلة أخرى:');
            console.log(`   ❌ الخطأ: ${waseetData.error}`);
            console.log('   💡 يحتاج فحص أعمق للمشكلة');
          }
        }
        
      } catch (e) {
        console.log('\n❌ لا يمكن تحليل بيانات الوسيط');
        console.log('📋 البيانات الخام:', finalOrder.waseet_data);
      }
    } else {
      console.log('\n⚠️ لا توجد بيانات وسيط');
      console.log('❌ لم يتم محاولة إرسال الطلب للوسيط');
      console.log('🔍 المشكلة: الكود لا يتم تنفيذه');
    }

    // 6. اختبار إعادة المحاولة
    console.log('\n5️⃣ اختبار إعادة المحاولة...');
    const retryResult = await makeRequest('POST', `${baseUrl}/api/orders/retry-failed-waseet`);
    
    if (retryResult.success) {
      console.log('✅ endpoint إعادة المحاولة يعمل');
      console.log('📋 النتيجة:', retryResult.data);
    } else {
      console.log('❌ endpoint إعادة المحاولة لا يعمل');
      console.log('📋 الخطأ:', retryResult.error);
    }

    // 7. الخلاصة النهائية
    console.log('\n🎯 الخلاصة النهائية:');
    console.log('='.repeat(60));
    
    if (finalOrder.waseet_order_id) {
      console.log('🎉 النظام يعمل بشكل مثالي 100%!');
      console.log('✅ تم إرسال الطلب لشركة الوسيط بنجاح');
      console.log('🚀 التطبيق جاهز للاستخدام الفعلي');
      
    } else if (finalOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
      console.log('⚠️ النظام يعمل لكن فشل في إرسال الطلب للوسيط');
      console.log('🔧 المشكلة: بيانات المصادقة مع شركة الوسيط');
      console.log('💡 الحل: التواصل مع شركة الوسيط لحل مشكلة المصادقة');
      console.log('📱 التطبيق يعمل وسيرسل الطلبات عند حل المشكلة');
      
    } else {
      console.log('❌ النظام لا يحاول إرسال الطلبات للوسيط');
      console.log('🔍 المشكلة: خطأ في الكود أو الإعدادات');
      console.log('🔧 يحتاج فحص أعمق للنظام');
    }

    console.log('\n🎯 انتهى الاختبار النهائي');

  } catch (error) {
    console.error('❌ خطأ في الاختبار النهائي:', error);
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
  testFinalWaseet()
    .then(() => {
      console.log('\n✅ انتهى الاختبار النهائي');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار النهائي:', error);
      process.exit(1);
    });
}

module.exports = { testFinalWaseet };
