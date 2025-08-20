const axios = require('axios');

// اختبار مباشر للخادم الذي يعمل فعلياً
async function testDirectServer() {
  console.log('🔍 ===== اختبار مباشر للخادم =====');
  console.log(`⏰ الوقت: ${new Date().toISOString()}`);
  
  // قائمة الخوادم المحتملة للاختبار
  const servers = [
    {
      name: 'Railway (الرابط الرسمي الجديد)',
      url: 'https://montajati-official-backend-production.up.railway.app',
      port: null
    },
    {
      name: 'DigitalOcean (القديم - للمقارنة)',
      url: 'https://clownfish-app-krnk9.ondigitalocean.app',
      port: null
    }
  ];
  
  const results = [];
  
  for (const server of servers) {
    console.log(`\n🧪 اختبار: ${server.name}`);
    console.log(`🌐 الرابط: ${server.url}`);
    
    try {
      // اختبار health endpoint
      console.log('📡 اختبار /health...');
      const healthResponse = await axios.get(`${server.url}/health`, {
        timeout: 15000,
        validateStatus: () => true
      });
      
      const healthResult = {
        endpoint: '/health',
        status: healthResponse.status,
        success: healthResponse.status >= 200 && healthResponse.status < 300,
        data: healthResponse.data
      };
      
      console.log(`   📊 Status: ${healthResult.status}`);
      console.log(`   ✅ نجح: ${healthResult.success ? 'نعم' : 'لا'}`);
      
      if (healthResult.success) {
        console.log(`   📄 البيانات:`, JSON.stringify(healthResult.data, null, 2));
        
        // اختبار API الطلبات
        console.log('📡 اختبار /api/orders...');
        try {
          const ordersResponse = await axios.get(`${server.url}/api/orders?limit=1`, {
            timeout: 15000,
            validateStatus: () => true
          });
          
          const ordersResult = {
            endpoint: '/api/orders',
            status: ordersResponse.status,
            success: ordersResponse.status >= 200 && ordersResponse.status < 300,
            hasData: ordersResponse.data?.data?.length > 0
          };
          
          console.log(`   📊 Status: ${ordersResult.status}`);
          console.log(`   ✅ نجح: ${ordersResult.success ? 'نعم' : 'لا'}`);
          console.log(`   📦 يحتوي على طلبات: ${ordersResult.hasData ? 'نعم' : 'لا'}`);
          
          if (ordersResult.success && ordersResult.hasData) {
            // اختبار تحديث حالة طلب
            const testOrder = ordersResponse.data.data[0];
            console.log(`📋 طلب الاختبار: ${testOrder.id}`);
            console.log(`📊 الحالة الحالية: "${testOrder.status}"`);
            
            console.log('🔄 اختبار تحديث الحالة...');
            const newStatus = testOrder.status === 'نشط' ? 'قيد التحضير' : 'نشط';
            
            const updateData = {
              status: newStatus,
              notes: 'اختبار مباشر للخادم',
              changedBy: 'direct_test'
            };
            
            const updateResponse = await axios.put(
              `${server.url}/api/orders/${testOrder.id}/status`,
              updateData,
              {
                headers: { 'Content-Type': 'application/json' },
                timeout: 15000,
                validateStatus: () => true
              }
            );
            
            const updateResult = {
              endpoint: '/api/orders/:id/status',
              status: updateResponse.status,
              success: updateResponse.status >= 200 && updateResponse.status < 300,
              data: updateResponse.data
            };
            
            console.log(`   📊 Status: ${updateResult.status}`);
            console.log(`   ✅ نجح: ${updateResult.success ? 'نعم' : 'لا'}`);
            
            if (updateResult.success) {
              console.log('   🎉 تحديث الحالة نجح!');
              console.log(`   📄 النتيجة:`, JSON.stringify(updateResult.data, null, 2));
              
              // التحقق من التحديث
              console.log('🔍 التحقق من التحديث...');
              await new Promise(resolve => setTimeout(resolve, 2000));
              
              const verifyResponse = await axios.get(`${server.url}/api/orders/${testOrder.id}`, {
                timeout: 15000
              });
              
              if (verifyResponse.data?.data?.status === newStatus) {
                console.log('   ✅ تم التحقق من التحديث بنجاح!');
                console.log(`   📊 الحالة الجديدة: "${verifyResponse.data.data.status}"`);
              } else {
                console.log('   ❌ فشل في التحقق من التحديث');
                console.log(`   📊 المتوقع: "${newStatus}"`);
                console.log(`   📊 الفعلي: "${verifyResponse.data?.data?.status}"`);
              }
            } else {
              console.log('   ❌ فشل في تحديث الحالة');
              if (updateResult.data) {
                console.log(`   📄 تفاصيل الخطأ:`, JSON.stringify(updateResult.data, null, 2));
              }
            }
            
            results.push({
              server: server.name,
              url: server.url,
              working: true,
              health: healthResult,
              orders: ordersResult,
              statusUpdate: updateResult
            });
          } else {
            results.push({
              server: server.name,
              url: server.url,
              working: true,
              health: healthResult,
              orders: ordersResult,
              statusUpdate: null
            });
          }
        } catch (ordersError) {
          console.log(`   ❌ خطأ في اختبار الطلبات: ${ordersError.message}`);
          results.push({
            server: server.name,
            url: server.url,
            working: true,
            health: healthResult,
            orders: { error: ordersError.message },
            statusUpdate: null
          });
        }
      } else {
        console.log(`   ❌ الخادم لا يعمل`);
        if (healthResult.data && typeof healthResult.data === 'string') {
          console.log(`   📄 رسالة الخطأ: ${healthResult.data.substring(0, 200)}...`);
        }
        
        results.push({
          server: server.name,
          url: server.url,
          working: false,
          health: healthResult,
          orders: null,
          statusUpdate: null
        });
      }
      
    } catch (error) {
      console.log(`   ❌ خطأ في الاتصال: ${error.message}`);
      results.push({
        server: server.name,
        url: server.url,
        working: false,
        error: error.message,
        health: null,
        orders: null,
        statusUpdate: null
      });
    }
    
    console.log('─'.repeat(60));
  }
  
  // ملخص النتائج
  console.log('\n📋 ===== ملخص النتائج =====');
  
  const workingServers = results.filter(r => r.working);
  const failedServers = results.filter(r => !r.working);
  
  console.log(`✅ خوادم تعمل: ${workingServers.length}/${results.length}`);
  console.log(`❌ خوادم لا تعمل: ${failedServers.length}/${results.length}`);
  
  if (workingServers.length > 0) {
    console.log('\n🎉 الخوادم التي تعمل:');
    workingServers.forEach(server => {
      console.log(`   ✅ ${server.server}`);
      console.log(`      🌐 ${server.url}`);
      console.log(`      🏥 Health: ${server.health?.success ? '✅' : '❌'}`);
      console.log(`      📦 Orders: ${server.orders?.success ? '✅' : '❌'}`);
      console.log(`      🔄 Status Update: ${server.statusUpdate?.success ? '✅' : '❌'}`);
    });
    
    // اختيار أفضل خادم
    const bestServer = workingServers.find(s => 
      s.health?.success && s.orders?.success && s.statusUpdate?.success
    ) || workingServers.find(s => s.health?.success && s.orders?.success) || workingServers[0];
    
    if (bestServer) {
      console.log(`\n🏆 أفضل خادم للاستخدام:`);
      console.log(`   📛 الاسم: ${bestServer.server}`);
      console.log(`   🌐 الرابط: ${bestServer.url}`);
      console.log(`   ✅ يدعم تحديث الحالة: ${bestServer.statusUpdate?.success ? 'نعم' : 'لا'}`);
      
      // تحديث ملف الاختبار الشامل
      console.log(`\n💡 لاستخدام هذا الخادم، حدث الرابط في comprehensive_order_status_test.js:`);
      console.log(`   baseURL: '${bestServer.url}'`);
    }
  }
  
  if (failedServers.length > 0) {
    console.log('\n❌ الخوادم التي لا تعمل:');
    failedServers.forEach(server => {
      console.log(`   ❌ ${server.server}`);
      console.log(`      🌐 ${server.url}`);
      console.log(`      🔍 السبب: ${server.error || 'خطأ غير محدد'}`);
    });
  }
  
  // توصيات الإصلاح
  console.log('\n🔧 ===== توصيات الإصلاح =====');
  
  if (workingServers.length === 0) {
    console.log('🚨 جميع الخوادم لا تعمل - المشكلة في الـ hosting:');
    console.log('   1. فحص DigitalOcean App Platform Dashboard');
    console.log('   2. فحص logs التطبيق');
    console.log('   3. التأكد من environment variables');
    console.log('   4. إعادة تشغيل التطبيق');
  } else if (workingServers.some(s => s.statusUpdate?.success)) {
    console.log('✅ المشكلة محلولة! تحديث الحالة يعمل بشكل طبيعي');
  } else if (workingServers.some(s => s.health?.success)) {
    console.log('⚠️ الخادم يعمل لكن تحديث الحالة لا يعمل:');
    console.log('   1. فحص API endpoint للتحديث');
    console.log('   2. فحص database connection');
    console.log('   3. فحص validation logic');
    console.log('   4. فحص error handling');
  }
  
  console.log('\n🏁 ===== انتهاء الاختبار المباشر =====');
  return results;
}

// تشغيل الاختبار
if (require.main === module) {
  testDirectServer()
    .then(results => {
      console.log('\n📊 تم حفظ النتائج للمراجعة');
    })
    .catch(error => {
      console.error('❌ خطأ في الاختبار المباشر:', error);
    });
}

module.exports = { testDirectServer };
