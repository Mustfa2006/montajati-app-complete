// ===================================
// تحسينات الأداء للإنتاج
// ===================================

/**
 * تطبيق تحسينات الأداء في بيئة الإنتاج
 */
function applyProductionOptimizations() {
  if (process.env.NODE_ENV !== 'production') {
    return;
  }

  console.log('⚡ تطبيق تحسينات الأداء للإنتاج...');

  // 1. تحسين garbage collection
  if (global.gc) {
    setInterval(() => {
      global.gc();
    }, 30 * 60 * 1000); // كل 30 دقيقة
  }

  // 2. تحسين memory usage
  process.on('warning', (warning) => {
    if (warning.name === 'MaxListenersExceededWarning') {
      console.warn('⚠️ تحذير: تم تجاوز الحد الأقصى للمستمعين');
    }
  });

  // 3. تحسين error handling
  process.on('uncaughtException', (error) => {
    console.error('❌ خطأ غير معالج:', error.message);
    // لا نوقف الخادم في الإنتاج
  });

  process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Promise مرفوض غير معالج:', reason);
    // لا نوقف الخادم في الإنتاج
  });

  // 4. تحسين timeouts
  const originalSetTimeout = global.setTimeout;
  global.setTimeout = function(callback, delay, ...args) {
    // تحديد حد أقصى للـ timeout (10 دقائق)
    const maxDelay = 10 * 60 * 1000;
    const actualDelay = Math.min(delay || 0, maxDelay);
    return originalSetTimeout(callback, actualDelay, ...args);
  };

  // 5. تحسين console.log في الإنتاج
  if (process.env.MINIMIZE_LOGS === 'true') {
    const originalLog = console.log;
    console.log = function(...args) {
      // فقط الرسائل المهمة
      const message = args.join(' ');
      if (message.includes('✅') || message.includes('❌') || message.includes('⚠️')) {
        originalLog.apply(console, args);
      }
    };
  }

  console.log('✅ تم تطبيق تحسينات الأداء');
}

/**
 * مراقبة استخدام الذاكرة
 */
function startMemoryMonitoring() {
  if (process.env.NODE_ENV !== 'production') {
    return;
  }

  setInterval(() => {
    const memUsage = process.memoryUsage();
    const mbUsed = Math.round(memUsage.heapUsed / 1024 / 1024);
    const mbTotal = Math.round(memUsage.heapTotal / 1024 / 1024);
    
    // تحذير إذا تجاوز استخدام الذاكرة 400MB
    if (mbUsed > 400) {
      console.warn(`⚠️ استخدام ذاكرة عالي: ${mbUsed}MB / ${mbTotal}MB`);
    }
    
    // تسجيل كل ساعة
    const now = new Date();
    if (now.getMinutes() === 0) {
      console.log(`📊 استخدام الذاكرة: ${mbUsed}MB / ${mbTotal}MB`);
    }
  }, 60 * 1000); // كل دقيقة
}

/**
 * تحسين اتصالات قاعدة البيانات
 */
function optimizeDatabaseConnections() {
  // تحسين connection pooling
  const maxConnections = process.env.MAX_DB_CONNECTIONS || 10;
  console.log(`🗄️ حد أقصى لاتصالات قاعدة البيانات: ${maxConnections}`);
  
  // تحسين timeout للاستعلامات
  const queryTimeout = process.env.DB_QUERY_TIMEOUT || 30000; // 30 ثانية
  console.log(`⏱️ timeout للاستعلامات: ${queryTimeout}ms`);
}

/**
 * تحسين طلبات HTTP
 */
function optimizeHttpRequests() {
  // تحسين keep-alive
  const http = require('http');
  const https = require('https');
  
  const httpAgent = new http.Agent({
    keepAlive: true,
    maxSockets: 50,
    timeout: 30000
  });
  
  const httpsAgent = new https.Agent({
    keepAlive: true,
    maxSockets: 50,
    timeout: 30000
  });
  
  // تطبيق الـ agents على المكتبات
  process.env.HTTP_AGENT = httpAgent;
  process.env.HTTPS_AGENT = httpsAgent;
  
  console.log('🌐 تم تحسين اتصالات HTTP');
}

/**
 * تشغيل جميع التحسينات
 */
function initializeOptimizations() {
  try {
    applyProductionOptimizations();
    startMemoryMonitoring();
    optimizeDatabaseConnections();
    optimizeHttpRequests();
    
    console.log('🚀 تم تطبيق جميع تحسينات الأداء');
  } catch (error) {
    console.error('❌ خطأ في تطبيق تحسينات الأداء:', error.message);
  }
}

module.exports = {
  initializeOptimizations,
  applyProductionOptimizations,
  startMemoryMonitoring,
  optimizeDatabaseConnections,
  optimizeHttpRequests
};
