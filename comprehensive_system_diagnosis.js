const axios = require('axios');

/**
 * 🔍 تشخيص شامل لنظام إرسال الطلبات للوسيط
 * 
 * يفحص:
 * 1. حالة الخادم وخدمة المزامنة
 * 2. اتصال API الوسيط
 * 3. قاعدة البيانات والطلبات
 * 4. نظام تحديث الحالات
 */

const BASE_URL = 'https://montajati-backend.onrender.com';

async function comprehensiveSystemDiagnosis() {
  console.log('🔍 === تشخيص شامل لنظام إرسال الطلبات للوسيط ===\n');

  try {
    // 1. فحص حالة الخادم
    console.log('🖥️ فحص حالة الخادم...');
    try {
      const healthResponse = await axios.get(`${BASE_URL}/health`, { timeout: 10000 });
      console.log('✅ الخادم يعمل بشكل طبيعي');
      
      if (healthResponse.data.services) {
        console.log('📋 حالة الخدمات:');
        Object.entries(healthResponse.data.services).forEach(([service, status]) => {
          console.log(`   ${service}: ${status}`);
        });
      }
    } catch (error) {
      console.log('⚠️ مشكلة في الاتصال بالخادم:', error.message);
    }

    // 2. فحص خدمة المزامنة
    console.log('\n🔄 فحص خدمة المزامنة...');
    try {
      const syncResponse = await axios.get(`${BASE_URL}/api/sync/status`, { timeout: 10000 });
      console.log('✅ خدمة المزامنة متاحة');
      console.log('📋 حالة المزامنة:', syncResponse.data);
    } catch (error) {
      console.log('⚠️ خدمة المزامنة غير متاحة:', error.message);
    }

    // 3. فحص اتصال الوسيط
    console.log('\n🔗 فحص اتصال الوسيط...');
    try {
      const waseetResponse = await axios.post(`${BASE_URL}/api/waseet/test-connection`, {}, { timeout: 15000 });
      console.log('✅ اتصال الوسيط يعمل بشكل طبيعي');
      console.log('📋 نتيجة الاختبار:', waseetResponse.data);
    } catch (error) {
      console.log('⚠️ مشكلة في اتصال الوسيط:', error.message);
    }

    // 4. فحص الطلبات في قاعدة البيانات
    console.log('\n📊 فحص الطلبات في قاعدة البيانات...');
    try {
      const ordersResponse = await axios.get(`${BASE_URL}/api/orders?limit=10`, { timeout: 10000 });
      
      if (ordersResponse.data.success && ordersResponse.data.data) {
        const orders = ordersResponse.data.data;
        console.log(`✅ تم العثور على ${orders.length} طلب`);
        
        // تحليل حالات الطلبات
        const statusCounts = {};
        const waseetSentCount = orders.filter(order => order.waseet_order_id).length;
        const inDeliveryCount = orders.filter(order => order.status === 'in_delivery').length;
        
        orders.forEach(order => {
          statusCounts[order.status] = (statusCounts[order.status] || 0) + 1;
        });
        
        console.log('📋 إحصائيات الحالات:');
        Object.entries(statusCounts).forEach(([status, count]) => {
          console.log(`   ${status}: ${count} طلب`);
        });
        
        console.log(`📦 طلبات مرسلة للوسيط: ${waseetSentCount}`);
        console.log(`🚚 طلبات قيد التوصيل: ${inDeliveryCount}`);
        
        // فحص الطلبات قيد التوصيل التي لم ترسل للوسيط
        const inDeliveryNotSent = orders.filter(order => 
          order.status === 'in_delivery' && !order.waseet_order_id
        );
        
        if (inDeliveryNotSent.length > 0) {
          console.log(`⚠️ ${inDeliveryNotSent.length} طلب قيد التوصيل لم يرسل للوسيط:`);
          inDeliveryNotSent.forEach(order => {
            console.log(`   - ${order.id} (${order.customer_name})`);
          });
        } else {
          console.log('✅ جميع الطلبات قيد التوصيل مرسلة للوسيط');
        }
        
      } else {
        console.log('⚠️ لا توجد طلبات في قاعدة البيانات');
      }
    } catch (error) {
      console.log('❌ خطأ في جلب الطلبات:', error.message);
    }

    // 5. اختبار تحديث حالة طلب
    console.log('\n🧪 اختبار تحديث حالة طلب...');
    try {
      const ordersResponse = await axios.get(`${BASE_URL}/api/orders?limit=1`, { timeout: 10000 });
      
      if (ordersResponse.data.success && ordersResponse.data.data && ordersResponse.data.data.length > 0) {
        const testOrder = ordersResponse.data.data[0];
        console.log(`📋 طلب الاختبار: ${testOrder.id}`);
        console.log(`📊 الحالة الحالية: ${testOrder.status}`);
        
        // محاولة تحديث الحالة (بدون تغيير فعلي)
        const currentStatus = testOrder.status;
        const updateResponse = await axios.put(
          `${BASE_URL}/api/orders/${testOrder.id}/status`,
          {
            status: currentStatus,
            notes: 'اختبار تشخيصي - لا تغيير',
            changedBy: 'diagnosis_script'
          },
          { timeout: 15000 }
        );
        
        if (updateResponse.data.success) {
          console.log('✅ نظام تحديث الحالات يعمل بشكل طبيعي');
        } else {
          console.log('⚠️ مشكلة في نظام تحديث الحالات');
        }
      } else {
        console.log('⚠️ لا توجد طلبات للاختبار');
      }
    } catch (error) {
      console.log('❌ خطأ في اختبار تحديث الحالة:', error.message);
    }

    // 6. فحص متغيرات البيئة (إذا كان متاحاً)
    console.log('\n🔧 فحص إعدادات النظام...');
    try {
      const configResponse = await axios.get(`${BASE_URL}/api/config/check`, { timeout: 10000 });
      console.log('✅ إعدادات النظام متاحة');
      console.log('📋 حالة الإعدادات:', configResponse.data);
    } catch (error) {
      console.log('ℹ️ معلومات الإعدادات غير متاحة (طبيعي للأمان)');
    }

    // النتيجة النهائية
    console.log('\n🏆 === ملخص التشخيص ===');
    console.log('✅ تم إكمال التشخيص الشامل');
    console.log('📋 راجع النتائج أعلاه لتحديد أي مشاكل محتملة');
    console.log('💡 إذا كانت جميع الفحوصات ناجحة، فالنظام يعمل بشكل طبيعي');

  } catch (error) {
    console.error('❌ خطأ عام في التشخيص:', error.message);
  }
}

// تشغيل التشخيص
comprehensiveSystemDiagnosis();
