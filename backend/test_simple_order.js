// ===================================
// اختبار مبسط لإنشاء طلب
// Simple Order Creation Test
// ===================================

const https = require('https');

async function testSimpleOrder() {
  console.log('🧪 اختبار مبسط لإنشاء طلب...');
  console.log('='.repeat(50));

  const baseUrl = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    // 1. اختبار جلب الطلبات الموجودة
    console.log('\n1️⃣ اختبار جلب الطلبات الموجودة...');
    const getResult = await makeRequest('GET', `${baseUrl}/api/orders?limit=3`);
    
    if (getResult.success) {
      console.log('✅ API جلب الطلبات يعمل');
      console.log(`📊 عدد الطلبات: ${getResult.data?.orders?.length || 0}`);
      
      if (getResult.data?.orders?.length > 0) {
        const sampleOrder = getResult.data.orders[0];
        console.log('📋 مثال على طلب موجود:');
        console.log(`   - ID: ${sampleOrder.id}`);
        console.log(`   - العميل: ${sampleOrder.customer_name}`);
        console.log(`   - الحالة: ${sampleOrder.status}`);
        console.log(`   - التاريخ: ${sampleOrder.created_at}`);
        
        // اختبار تحديث هذا الطلب
        console.log('\n2️⃣ اختبار تحديث طلب موجود...');
        
        const updateData = {
          status: 'in_delivery',
          notes: 'اختبار تحديث مباشر',
          changedBy: 'simple_test'
        };
        
        const updateResult = await makeRequest(
          'PUT', 
          `${baseUrl}/api/orders/${sampleOrder.id}/status`,
          updateData
        );
        
        if (updateResult.success) {
          console.log('✅ تم تحديث الطلب بنجاح');
          console.log('📋 الاستجابة:', updateResult.data);
          
          // انتظار وفحص النتيجة
          console.log('\n3️⃣ انتظار 15 ثانية وفحص النتيجة...');
          await new Promise(resolve => setTimeout(resolve, 15000));
          
          const checkResult = await makeRequest('GET', `${baseUrl}/api/orders/${sampleOrder.id}`);
          
          if (checkResult.success) {
            const updatedOrder = checkResult.data;
            console.log('\n📊 نتائج الفحص النهائي:');
            console.log(`   - الحالة: ${updatedOrder.status}`);
            console.log(`   - معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
            console.log(`   - حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
            console.log(`   - تاريخ التحديث: ${updatedOrder.updated_at}`);
            
            if (updatedOrder.waseet_data) {
              try {
                const waseetData = JSON.parse(updatedOrder.waseet_data);
                console.log('\n📋 تفاصيل بيانات الوسيط:');
                console.log(JSON.stringify(waseetData, null, 2));
                
                // تحليل المشكلة
                if (waseetData.error) {
                  console.log('\n❌ تم العثور على خطأ في الوسيط:');
                  console.log(`   - الخطأ: ${waseetData.error}`);
                  
                  if (waseetData.error.includes('فشل في المصادقة')) {
                    console.log('\n🔍 تحليل مشكلة المصادقة:');
                    console.log('   - بيانات المصادقة موجودة في Render ✅');
                    console.log('   - المشكلة قد تكون في:');
                    console.log('     1. تغيير API endpoint للوسيط');
                    console.log('     2. تغيير في آلية المصادقة');
                    console.log('     3. مشكلة مؤقتة في خدمة الوسيط');
                    console.log('     4. الحساب مقفل أو معطل');
                  }
                  
                } else if (waseetData.success) {
                  console.log('\n✅ تم إرسال الطلب للوسيط بنجاح!');
                  console.log(`🆔 QR ID: ${waseetData.qrId}`);
                  console.log('🎉 النظام يعمل بشكل مثالي!');
                }
                
              } catch (e) {
                console.log('\n❌ لا يمكن تحليل بيانات الوسيط');
                console.log('📋 البيانات الخام:', updatedOrder.waseet_data);
              }
            } else {
              console.log('\n⚠️ لا توجد بيانات وسيط - لم يتم محاولة الإرسال');
            }
            
            // الخلاصة النهائية
            console.log('\n🎯 الخلاصة النهائية:');
            console.log('='.repeat(40));
            
            if (updatedOrder.waseet_order_id) {
              console.log('✅ النظام يعمل بشكل مثالي 100%!');
              console.log('🚀 التطبيق جاهز للاستخدام الفعلي');
            } else if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
              console.log('⚠️ النظام يعمل لكن فشل في إرسال الطلب للوسيط');
              console.log('🔧 يحتاج إصلاح بيانات المصادقة مع الوسيط');
            } else {
              console.log('❌ النظام لا يحاول إرسال الطلبات للوسيط');
              console.log('🔍 يحتاج فحص الكود والإعدادات');
            }
            
          } else {
            console.log('❌ فشل في جلب الطلب المحدث');
          }
          
        } else {
          console.log('❌ فشل في تحديث الطلب');
          console.log('📋 الخطأ:', updateResult.error);
        }
        
      } else {
        console.log('⚠️ لا توجد طلبات في قاعدة البيانات');
      }
      
    } else {
      console.log('❌ API جلب الطلبات لا يعمل');
      console.log('📋 الخطأ:', getResult.error);
    }

    console.log('\n🎯 انتهى الاختبار المبسط');

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
        'User-Agent': 'Montajati-Simple-Test/1.0'
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
  testSimpleOrder()
    .then(() => {
      console.log('\n✅ انتهى الاختبار المبسط');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار المبسط:', error);
      process.exit(1);
    });
}

module.exports = { testSimpleOrder };
