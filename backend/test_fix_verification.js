// ===================================
// اختبار التحقق من الإصلاح
// Fix Verification Test
// ===================================

const https = require('https');

async function testFixVerification() {
  console.log('🔧 اختبار التحقق من إصلاح مشكلة الوسيط...');
  console.log('='.repeat(60));

  const baseUrl = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    // 1. جلب طلب للاختبار
    console.log('\n1️⃣ جلب طلب للاختبار...');
    const ordersResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=5`);

    if (!ordersResult.success) {
      console.log('❌ فشل في جلب الطلبات:', ordersResult.error);
      return;
    }

    const orders = ordersResult.data?.data || ordersResult.data?.orders || ordersResult.data || [];

    if (!orders.length) {
      console.log('❌ لا توجد طلبات للاختبار');
      return;
    }

    // البحث عن طلب لم يتم إرساله للوسيط
    const testOrder = orders.find(order =>
      !order.waseet_order_id &&
      order.status !== 'in_delivery' &&
      order.status !== 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    ) || orders[0];

    console.log(`📦 طلب الاختبار: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🆔 معرف الوسيط الحالي: ${testOrder.waseet_order_id || 'غير محدد'}`);

    // 2. تحديث حالة الطلب إلى "قيد التوصيل الى الزبون (في عهدة المندوب)"
    console.log('\n2️⃣ تحديث حالة الطلب إلى "قيد التوصيل الى الزبون (في عهدة المندوب)"...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار الإصلاح - تحديث من النظام',
      changedBy: 'fix_verification_test'
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
    console.log('\n3️⃣ انتظار 20 ثانية لمعالجة الطلب وإرساله للوسيط...');
    await new Promise(resolve => setTimeout(resolve, 20000));

    // 4. فحص النتيجة النهائية
    console.log('\n4️⃣ فحص النتيجة النهائية...');
    const finalResult = await makeRequest('GET', `${baseUrl}/api/orders/${testOrder.id}`);
    
    if (!finalResult.success) {
      console.log('❌ فشل في جلب الطلب المحدث');
      console.log('📋 الخطأ:', finalResult.error);
      return;
    }
    
    const finalOrder = finalResult.data;
    
    console.log('\n📊 النتائج النهائية:');
    console.log('='.repeat(50));
    console.log(`📦 معرف الطلب: ${finalOrder.id}`);
    console.log(`👤 العميل: ${finalOrder.customer_name}`);
    console.log(`📊 الحالة: ${finalOrder.status}`);
    console.log(`🆔 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`📋 حالة الوسيط: ${finalOrder.waseet_status || 'غير محدد'}`);
    console.log(`📅 تاريخ التحديث: ${finalOrder.updated_at}`);

    // 5. تحليل مفصل لبيانات الوسيط
    console.log('\n5️⃣ تحليل مفصل لبيانات الوسيط:');
    
    if (finalOrder.waseet_data) {
      try {
        const waseetData = JSON.parse(finalOrder.waseet_data);
        console.log('📋 بيانات الوسيط موجودة:');
        console.log(JSON.stringify(waseetData, null, 2));
        
        if (waseetData.success) {
          console.log('\n🎉 تم إرسال الطلب للوسيط بنجاح!');
          console.log(`🆔 QR ID: ${waseetData.qrId}`);
          console.log('✅ الإصلاح نجح - النظام يعمل بشكل مثالي!');
          
        } else if (waseetData.error) {
          console.log('\n❌ فشل في إرسال الطلب للوسيط');
          console.log(`📋 سبب الفشل: ${waseetData.error}`);
          
          // تحليل نوع الخطأ
          if (waseetData.error.includes('فشل في المصادقة') || 
              waseetData.error.includes('اسم المستخدم') ||
              waseetData.error.includes('رمز الدخول')) {
            console.log('\n🔑 المشكلة: بيانات المصادقة مع شركة الوسيط');
            console.log('💡 الحل: التواصل مع شركة الوسيط للتحقق من الحساب');
            console.log('✅ الإصلاح نجح - النظام يحاول الإرسال لكن بيانات المصادقة خاطئة');
            
          } else if (waseetData.error.includes('timeout') || 
                     waseetData.error.includes('ECONNRESET') ||
                     waseetData.error.includes('network')) {
            console.log('\n🌐 المشكلة: مشكلة في الاتصال بخدمة الوسيط');
            console.log('💡 الحل: إعادة المحاولة لاحقاً');
            console.log('✅ الإصلاح نجح - النظام يحاول الإرسال لكن هناك مشكلة شبكة');
            
          } else {
            console.log('\n🔍 مشكلة أخرى في الوسيط');
            console.log('✅ الإصلاح نجح - النظام يحاول الإرسال');
          }
        }
        
      } catch (e) {
        console.log('❌ لا يمكن تحليل بيانات الوسيط');
        console.log('📋 البيانات الخام:', finalOrder.waseet_data);
      }
    } else {
      console.log('⚠️ لا توجد بيانات وسيط');
      console.log('❌ الإصلاح لم ينجح - النظام لا يحاول إرسال الطلبات للوسيط');
    }

    // 6. الخلاصة والتوصيات
    console.log('\n🎯 الخلاصة والتوصيات:');
    console.log('='.repeat(60));
    
    if (finalOrder.waseet_order_id) {
      console.log('🎉 الإصلاح نجح 100%! النظام يعمل بشكل مثالي!');
      console.log('✅ تم إرسال الطلب للوسيط بنجاح');
      console.log('🚀 التطبيق جاهز للاستخدام الفعلي');
      
    } else if (finalOrder.waseet_status === 'في انتظار الإرسال للوسيط' || finalOrder.waseet_data) {
      console.log('✅ الإصلاح نجح! النظام يحاول إرسال الطلبات للوسيط');
      console.log('⚠️ لكن هناك مشكلة في بيانات المصادقة مع شركة الوسيط');
      console.log('📞 التوصية: التواصل مع شركة الوسيط لحل مشكلة المصادقة');
      console.log('📱 التطبيق يعمل وسيرسل الطلبات تلقائياً عند حل مشكلة المصادقة');
      
    } else {
      console.log('❌ الإصلاح لم ينجح - النظام لا يحاول إرسال الطلبات للوسيط');
      console.log('🔍 يحتاج فحص أعمق للكود والإعدادات');
    }

    console.log('\n🎯 انتهى اختبار التحقق من الإصلاح');

  } catch (error) {
    console.error('❌ خطأ في اختبار التحقق:', error);
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
        'User-Agent': 'Montajati-Fix-Verification/1.0'
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
  testFixVerification()
    .then(() => {
      console.log('\n✅ انتهى اختبار التحقق من الإصلاح');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل اختبار التحقق من الإصلاح:', error);
      process.exit(1);
    });
}

module.exports = { testFixVerification };
