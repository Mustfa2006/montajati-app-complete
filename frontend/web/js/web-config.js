// إعدادات خاصة بالموقع - نفس نظام التطبيق بالضبط
window.webConfig = {
  // رابط الخادم - Railway الجديد
  apiBaseUrl: 'https://montajati-official-backend-production.up.railway.app',
  
  // مسارات API - نفس التطبيق بالضبط
  webApiPaths: {
    health: '/api/web/health',
    corsTest: '/api/web/cors-test',
    updateOrderStatus: '/api/orders/{orderId}/status'  // 🎯 نفس مسار التطبيق
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
  version: '2.2.0',
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

// دالة محسنة لتحديث حالة الطلب - نفس نظام التطبيق بالضبط
window.updateOrderStatusWeb = async function(orderId, status, reason = '', changedBy = 'web_user') {
  try {
    console.log('🚀 بدء تحديث حالة الطلب من الويب:', orderId);
    
    const url = window.webConfig.apiBaseUrl + 
                window.webConfig.webApiPaths.updateOrderStatus.replace('{orderId}', orderId);
    
    // 🎯 نفس البيانات المرسلة من التطبيق بالضبط
    const requestData = {
      status: status,
      notes: reason || 'تم التحديث من الويب',  // نفس اسم الحقل في التطبيق
      changedBy: changedBy || 'web_user'
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
    
    // تحديد نوع الخطأ وإرجاع رسالة مناسبة
    let errorMessage = window.webConfig.errorMessages.server;
    
    if (error.name === 'TypeError' && error.message.includes('fetch')) {
      errorMessage = window.webConfig.errorMessages.network;
    } else if (error.message.includes('CORS')) {
      errorMessage = window.webConfig.errorMessages.cors;
    } else if (error.name === 'AbortError') {
      errorMessage = window.webConfig.errorMessages.timeout;
    }
    
    throw new Error(errorMessage);
  }
};

console.log('🌐 تم تحميل إعدادات الموقع - نفس نظام التطبيق بالضبط');
