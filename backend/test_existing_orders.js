// ===================================
// اختبار الطلبات الموجودة وتحديث حالتها
// Test Existing Orders and Update Status
// ===================================

const https = require('https');

async function testExistingOrders() {
  console.log('🔍 فحص الطلبات الموجودة واختبار تحديث الحالة...');
  console.log('='.repeat(60));

  const baseUrl = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    // 1. جلب جميع الطلبات
    console.log('\n1️⃣ جلب جميع الطلبات من قاعدة البيانات...');
    const allOrdersResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=10`);
    
    if (!allOrdersResult.success) {
      console.log('❌ فشل في جلب الطلبات');
      console.log('📋 الخطأ:', allOrdersResult.error);
      return;
    }
    
    const orders = allOrdersResult.data?.orders || [];
    console.log(`📊 عدد الطلبات الموجودة: ${orders.length}`);
    
    if (orders.length === 0) {
      console.log('⚠️ لا توجد طلبات في قاعدة البيانات');
      console.log('💡 يرجى إنشاء طلب من التطبيق أولاً ثم إعادة تشغيل هذا الاختبار');
      return;
    }

    // 2. عرض تفاصيل الطلبات
    console.log('\n2️⃣ تفاصيل الطلبات الموجودة:');
    orders.forEach((order, index) => {
      console.log(`\n📦 الطلب ${index + 1}:`);
      console.log(`   - المعرف: ${order.id}`);
      console.log(`   - العميل: ${order.customer_name}`);
      console.log(`   - الحالة: ${order.status}`);
      console.log(`   - الهاتف: ${order.customer_phone || order.primary_phone}`);
      console.log(`   - المجموع: ${order.total}`);
      console.log(`   - تاريخ الإنشاء: ${order.created_at}`);
      console.log(`   - معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
      console.log(`   - حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
    });

    // 3. اختيار طلب للاختبار
    const testOrder = orders.find(order => order.status !== 'in_delivery') || orders[0];
    
    console.log(`\n3️⃣ اختبار الطلب: ${testOrder.id}`);
    console.log(`👤 العميل: ${testOrder.customer_name}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);

    // 4. تحديث حالة الطلب إلى "قيد التوصيل"
    console.log('\n4️⃣ تحديث حالة الطلب إلى "قيد التوصيل"...');
    
    const updateData = {
      status: 'in_delivery',
      notes: 'اختبار نظام الوسيط - تحديث من الاختبار المباشر',
      changedBy: 'test_existing_orders'
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
    console.log('📋 استجابة التحديث:', updateResult.data);

    // 5. انتظار معالجة الطلب
    console.log('\n5️⃣ انتظار 25 ثانية لمعالجة الطلب وإرساله للوسيط...');
    await new Promise(resolve => setTimeout(resolve, 25000));

    // 6. فحص النتيجة النهائية
    console.log('\n6️⃣ فحص النتيجة النهائية...');
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

    // 7. تحليل مفصل لبيانات الوسيط
    console.log('\n7️⃣ تحليل مفصل لبيانات الوسيط:');
    
    if (finalOrder.waseet_data) {
      try {
        const waseetData = JSON.parse(finalOrder.waseet_data);
        console.log('📋 بيانات الوسيط موجودة:');
        console.log(JSON.stringify(waseetData, null, 2));
        
        if (waseetData.success) {
          console.log('\n🎉 تم إرسال الطلب للوسيط بنجاح!');
          console.log(`🆔 QR ID: ${waseetData.qrId}`);
          console.log('✅ النظام يعمل بشكل مثالي 100%!');
          console.log('🚀 المشكلة محلولة - التطبيق جاهز للاستخدام');
          
        } else if (waseetData.error) {
          console.log('\n❌ فشل في إرسال الطلب للوسيط');
          console.log(`📋 سبب الفشل: ${waseetData.error}`);
          
          // تحليل نوع الخطأ
          if (waseetData.error.includes('فشل في المصادقة') || 
              waseetData.error.includes('اسم المستخدم') ||
              waseetData.error.includes('رمز الدخول')) {
            console.log('\n🔑 المشكلة: بيانات المصادقة مع شركة الوسيط');
            console.log('💡 الحلول:');
            console.log('   1. التواصل مع شركة الوسيط للتحقق من الحساب');
            console.log('   2. التأكد من أن الحساب غير مقفل');
            console.log('   3. فحص تغيير في بيانات المصادقة');
            console.log('   4. التحقق من صحة اسم المستخدم وكلمة المرور');
            
          } else if (waseetData.error.includes('timeout') || 
                     waseetData.error.includes('ECONNRESET') ||
                     waseetData.error.includes('network')) {
            console.log('\n🌐 المشكلة: مشكلة في الاتصال بخدمة الوسيط');
            console.log('💡 الحلول:');
            console.log('   1. إعادة المحاولة لاحقاً');
            console.log('   2. فحص حالة خدمة الوسيط');
            console.log('   3. زيادة timeout في الكود');
            
          } else {
            console.log('\n🔍 مشكلة أخرى:');
            console.log(`   ❌ الخطأ: ${waseetData.error}`);
            console.log('   💡 يحتاج فحص أعمق مع شركة الوسيط');
          }
        }
        
      } catch (e) {
        console.log('❌ لا يمكن تحليل بيانات الوسيط');
        console.log('📋 البيانات الخام:', finalOrder.waseet_data);
      }
    } else {
      console.log('⚠️ لا توجد بيانات وسيط');
      console.log('❌ لم يتم محاولة إرسال الطلب للوسيط');
      console.log('🔍 المشكلة: الكود لا يتم تنفيذه عند تغيير الحالة');
      console.log('💡 يحتاج فحص الكود في routes/orders.js');
    }

    // 8. الخلاصة والتوصيات
    console.log('\n🎯 الخلاصة والتوصيات:');
    console.log('='.repeat(60));
    
    if (finalOrder.waseet_order_id) {
      console.log('🎉 النظام يعمل بشكل مثالي!');
      console.log('✅ تم حل المشكلة');
      
    } else if (finalOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
      console.log('⚠️ النظام يعمل لكن يفشل في الإرسال للوسيط');
      console.log('🔧 المشكلة: بيانات المصادقة مع شركة الوسيط');
      console.log('📞 التوصية: التواصل مع شركة الوسيط لحل مشكلة المصادقة');
      
    } else {
      console.log('❌ النظام لا يحاول إرسال الطلبات للوسيط');
      console.log('🔍 المشكلة: خطأ في الكود أو الإعدادات');
    }

    console.log('\n🎯 انتهى فحص الطلبات الموجودة');

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
        'User-Agent': 'Montajati-Existing-Orders-Test/1.0'
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
  testExistingOrders()
    .then(() => {
      console.log('\n✅ انتهى فحص الطلبات الموجودة');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل فحص الطلبات الموجودة:', error);
      process.exit(1);
    });
}

module.exports = { testExistingOrders };
