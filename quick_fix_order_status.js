const axios = require('axios');

// إعدادات الإصلاح السريع
const CONFIG = {
  baseURL: 'https://clownfish-app-krnk9.ondigitalocean.app',
  timeout: 30000,
  maxRetries: 5,
  retryDelay: 5000
};

// دالة فحص حالة الخادم
async function checkServerHealth() {
  console.log('🏥 === فحص حالة الخادم ===');
  
  for (let attempt = 1; attempt <= CONFIG.maxRetries; attempt++) {
    try {
      console.log(`🔄 محاولة ${attempt}/${CONFIG.maxRetries}...`);
      
      const response = await axios.get(`${CONFIG.baseURL}/health`, {
        timeout: CONFIG.timeout,
        validateStatus: () => true
      });
      
      if (response.status === 200) {
        console.log('✅ الخادم يعمل بشكل طبيعي!');
        console.log('📊 معلومات الخادم:', response.data);
        return true;
      } else {
        console.log(`❌ الخادم لا يعمل - Status: ${response.status}`);
        if (response.data) {
          console.log('📄 تفاصيل الخطأ:', typeof response.data === 'string' ? 
            response.data.substring(0, 200) + '...' : response.data);
        }
      }
    } catch (error) {
      console.log(`❌ خطأ في الاتصال: ${error.message}`);
    }
    
    if (attempt < CONFIG.maxRetries) {
      console.log(`⏳ انتظار ${CONFIG.retryDelay/1000} ثانية قبل المحاولة التالية...`);
      await new Promise(resolve => setTimeout(resolve, CONFIG.retryDelay));
    }
  }
  
  return false;
}

// دالة اختبار تحديث حالة الطلب
async function testOrderStatusUpdate() {
  console.log('\n🧪 === اختبار تحديث حالة الطلب ===');
  
  try {
    // 1. جلب قائمة الطلبات
    console.log('📋 جلب قائمة الطلبات...');
    const ordersResponse = await axios.get(`${CONFIG.baseURL}/api/orders?limit=5`, {
      timeout: CONFIG.timeout
    });
    
    if (!ordersResponse.data?.data?.length) {
      console.log('❌ لا توجد طلبات للاختبار');
      return false;
    }
    
    const testOrder = ordersResponse.data.data[0];
    console.log(`📦 طلب الاختبار: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: "${testOrder.status}"`);
    
    // 2. اختبار تحديث الحالة
    const newStatus = testOrder.status === 'نشط' ? 'قيد التحضير' : 'نشط';
    console.log(`🔄 تحديث الحالة إلى: "${newStatus}"`);
    
    const updateData = {
      status: newStatus,
      notes: 'اختبار إصلاح سريع',
      changedBy: 'quick_fix_test'
    };
    
    const updateResponse = await axios.put(
      `${CONFIG.baseURL}/api/orders/${testOrder.id}/status`,
      updateData,
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: CONFIG.timeout
      }
    );
    
    if (updateResponse.status === 200) {
      console.log('✅ تم تحديث الحالة بنجاح!');
      console.log('📊 النتيجة:', updateResponse.data);
      
      // 3. التحقق من التحديث
      console.log('🔍 التحقق من التحديث...');
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const verifyResponse = await axios.get(`${CONFIG.baseURL}/api/orders/${testOrder.id}`, {
        timeout: CONFIG.timeout
      });
      
      if (verifyResponse.data?.data?.status === newStatus) {
        console.log('✅ تم التحقق من التحديث بنجاح!');
        return true;
      } else {
        console.log('❌ فشل في التحقق من التحديث');
        console.log(`   المتوقع: "${newStatus}"`);
        console.log(`   الفعلي: "${verifyResponse.data?.data?.status}"`);
        return false;
      }
    } else {
      console.log(`❌ فشل في تحديث الحالة - Status: ${updateResponse.status}`);
      console.log('📄 تفاصيل الخطأ:', updateResponse.data);
      return false;
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار تحديث الحالة: ${error.message}`);
    if (error.response) {
      console.log(`📊 Status: ${error.response.status}`);
      console.log(`📄 البيانات:`, error.response.data);
    }
    return false;
  }
}

// دالة تشخيص شاملة
async function comprehensiveDiagnosis() {
  console.log('🔍 === تشخيص شامل للمشكلة ===');
  
  const diagnostics = {
    serverHealth: false,
    orderStatusUpdate: false,
    apiEndpoints: {},
    recommendations: []
  };
  
  // 1. فحص endpoints مختلفة
  const endpoints = [
    { path: '/health', name: 'Health Check' },
    { path: '/api/orders', name: 'Orders API' },
    { path: '/api/waseet-statuses', name: 'Waseet Status API' }
  ];
  
  console.log('\n📡 فحص API Endpoints...');
  for (const endpoint of endpoints) {
    try {
      const response = await axios.get(`${CONFIG.baseURL}${endpoint.path}`, {
        timeout: CONFIG.timeout,
        validateStatus: () => true
      });
      
      diagnostics.apiEndpoints[endpoint.name] = {
        status: response.status,
        working: response.status >= 200 && response.status < 300
      };
      
      console.log(`   ${endpoint.name}: ${response.status >= 200 && response.status < 300 ? '✅' : '❌'} (${response.status})`);
    } catch (error) {
      diagnostics.apiEndpoints[endpoint.name] = {
        status: 'ERROR',
        working: false,
        error: error.message
      };
      console.log(`   ${endpoint.name}: ❌ (${error.message})`);
    }
  }
  
  // 2. تحليل المشاكل وإعطاء توصيات
  console.log('\n💡 التوصيات:');
  
  const workingEndpoints = Object.values(diagnostics.apiEndpoints).filter(ep => ep.working).length;
  const totalEndpoints = Object.keys(diagnostics.apiEndpoints).length;
  
  if (workingEndpoints === 0) {
    diagnostics.recommendations.push('🚨 الخادم معطل تماماً - يحتاج إعادة تشغيل فوري');
    diagnostics.recommendations.push('🔧 فحص DigitalOcean App Platform Dashboard');
    diagnostics.recommendations.push('📋 فحص logs التطبيق');
    console.log('   🚨 الخادم معطل تماماً - يحتاج إعادة تشغيل فوري');
  } else if (workingEndpoints < totalEndpoints) {
    diagnostics.recommendations.push('⚠️ بعض APIs لا تعمل - فحص الكود والـ routing');
    diagnostics.recommendations.push('🔍 فحص middleware والـ authentication');
    console.log('   ⚠️ بعض APIs لا تعمل - فحص الكود والـ routing');
  } else {
    diagnostics.recommendations.push('✅ جميع APIs تعمل - المشكلة قد تكون في logic معين');
    diagnostics.recommendations.push('🧪 تشغيل اختبارات مفصلة أكثر');
    console.log('   ✅ جميع APIs تعمل - المشكلة قد تكون في logic معين');
  }
  
  return diagnostics;
}

// دالة الإصلاح الرئيسية
async function quickFix() {
  console.log('🚀 ===== بداية الإصلاح السريع =====');
  console.log(`⏰ الوقت: ${new Date().toISOString()}`);
  console.log(`🌐 الخادم: ${CONFIG.baseURL}`);
  
  try {
    // 1. فحص حالة الخادم
    const serverHealthy = await checkServerHealth();
    
    if (!serverHealthy) {
      console.log('\n🚨 === الخادم لا يعمل ===');
      console.log('📋 خطوات الإصلاح المطلوبة:');
      console.log('   1. الدخول إلى DigitalOcean Dashboard');
      console.log('   2. فحص App Platform logs');
      console.log('   3. إعادة تشغيل التطبيق (Force Rebuild and Deploy)');
      console.log('   4. فحص Environment Variables');
      console.log('   5. فحص استهلاك الموارد (Memory/CPU)');
      return;
    }
    
    // 2. اختبار تحديث الحالة
    const statusUpdateWorking = await testOrderStatusUpdate();
    
    if (statusUpdateWorking) {
      console.log('\n🎉 === المشكلة محلولة! ===');
      console.log('✅ تحديث حالة الطلب يعمل بشكل طبيعي');
    } else {
      console.log('\n🔍 === تشخيص إضافي مطلوب ===');
      const diagnosis = await comprehensiveDiagnosis();
      
      console.log('\n📋 ملخص التشخيص:');
      console.log(`   🏥 صحة الخادم: ${diagnosis.serverHealth ? '✅' : '❌'}`);
      console.log(`   🔄 تحديث الحالة: ${diagnosis.orderStatusUpdate ? '✅' : '❌'}`);
      console.log('\n💡 التوصيات:');
      diagnosis.recommendations.forEach(rec => console.log(`   ${rec}`));
    }
    
  } catch (error) {
    console.error('❌ خطأ في الإصلاح السريع:', error.message);
  }
  
  console.log('\n🏁 ===== انتهاء الإصلاح السريع =====');
}

// تشغيل الإصلاح السريع
if (require.main === module) {
  quickFix();
}

module.exports = { quickFix, checkServerHealth, testOrderStatusUpdate };
