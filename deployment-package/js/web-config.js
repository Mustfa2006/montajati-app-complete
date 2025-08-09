// إعدادات خاصة بالموقع
window.webConfig = {
  // رابط الخادم
  apiBaseUrl: 'https://clownfish-app-krnk9.ondigitalocean.app',
  
  // مسارات خاصة بالويب
  webApiPaths: {
    health: '/api/web/health',
    corsTest: '/api/web/cors-test',
    updateOrderStatus: '/api/web/orders/{orderId}/status'
  },
  
  // إعدادات الطلبات
  requestConfig: {
    timeout: 30000,
    retries: 3,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache'
    }
  },
  
  // إعدادات CORS
  corsConfig: {
    credentials: 'include',
    mode: 'cors'
  },
  
  // رسائل الأخطاء
  errorMessages: {
    cors: 'مشكلة في الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
    network: 'مشكلة في الشبكة. تحقق من اتصال الإنترنت.',
    server: 'خطأ في الخادم. يرجى المحاولة لاحقاً.',
    timeout: 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.'
  },
  
  // معلومات الإصدار
  version: '1.0.0',
  buildDate: new Date().toISOString(),
  platform: 'web'
};

// دالة لاختبار الاتصال بالخادم
window.testServerConnection = async function() {
  try {
    const response = await fetch(window.webConfig.apiBaseUrl + window.webConfig.webApiPaths.health, {
      method: 'GET',
      headers: window.webConfig.requestConfig.headers,
      ...window.webConfig.corsConfig
    });
    
    const data = await response.json();
    console.log('✅ اختبار الاتصال بالخادم نجح:', data);
    return data;
  } catch (error) {
    console.error('❌ فشل اختبار الاتصال بالخادم:', error);
    return null;
  }
};

// دالة لاختبار CORS
window.testCORS = async function() {
  try {
    const response = await fetch(window.webConfig.apiBaseUrl + window.webConfig.webApiPaths.corsTest, {
      method: 'GET',
      headers: window.webConfig.requestConfig.headers,
      ...window.webConfig.corsConfig
    });
    
    const data = await response.json();
    console.log('✅ اختبار CORS نجح:', data);
    return data;
  } catch (error) {
    console.error('❌ فشل اختبار CORS:', error);
    return null;
  }
};

// دالة محسنة لتحديث حالة الطلب
window.updateOrderStatusWeb = async function(orderId, status, reason = '', changedBy = 'web_user') {
  try {
    console.log('🚀 بدء تحديث حالة الطلب من الويب:', orderId);
    
    const url = window.webConfig.apiBaseUrl + 
                window.webConfig.webApiPaths.updateOrderStatus.replace('{orderId}', orderId);
    
    const requestData = {
      status: status,
      reason: reason,
      changedBy: changedBy
    };
    
    console.log('📤 إرسال طلب التحديث:', url, requestData);
    
    const response = await fetch(url, {
      method: 'PUT',
      headers: window.webConfig.requestConfig.headers,
      body: JSON.stringify(requestData),
      ...window.webConfig.corsConfig
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const data = await response.json();
    console.log('✅ تم تحديث حالة الطلب بنجاح:', data);
    return data;
    
  } catch (error) {
    console.error('❌ خطأ في تحديث حالة الطلب:', error);
    throw error;
  }
};

// تشغيل اختبارات الاتصال عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
  console.log('🌐 تم تحميل إعدادات الويب');
  console.log('📊 إعدادات الخادم:', window.webConfig);
  
  // اختبار الاتصال بعد 2 ثانية
  setTimeout(async () => {
    console.log('🔍 اختبار الاتصال بالخادم...');
    await window.testServerConnection();
    await window.testCORS();
  }, 2000);
});

console.log('✅ تم تحميل ملف إعدادات الويب');
