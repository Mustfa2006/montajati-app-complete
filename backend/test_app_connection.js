// ===================================
// اختبار اتصال التطبيق بالخادم
// Test App Connection to Server
// ===================================

const express = require('express');
const cors = require('cors');
const InventoryMonitorService = require('./inventory_monitor_service');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3003;

// إعداد CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

// إعداد خدمة مراقبة المخزون
const inventoryMonitor = new InventoryMonitorService();

// متغير لتتبع الطلبات
let requestCount = 0;
const requestLog = [];

// Middleware لتسجيل الطلبات
app.use((req, res, next) => {
  requestCount++;
  const logEntry = {
    id: requestCount,
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    body: req.body
  };
  
  requestLog.push(logEntry);
  
  // الاحتفاظ بآخر 100 طلب فقط
  if (requestLog.length > 100) {
    requestLog.shift();
  }
  
  console.log(`📨 طلب ${requestCount}: ${req.method} ${req.url} من ${req.ip}`);
  
  next();
});

// صفحة رئيسية
app.get('/', (req, res) => {
  res.json({
    message: '🧪 خادم اختبار اتصال التطبيق',
    status: 'يعمل',
    timestamp: new Date().toISOString(),
    totalRequests: requestCount,
    endpoints: {
      '/': 'الصفحة الرئيسية',
      '/health': 'فحص الصحة',
      '/api/inventory/monitor/:productId': 'مراقبة منتج',
      '/api/inventory/monitor-all': 'مراقبة جميع المنتجات',
      '/api/test/connection': 'اختبار الاتصال',
      '/api/test/logs': 'سجل الطلبات'
    }
  });
});

// فحص الصحة
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    requests: requestCount
  });
});

// اختبار الاتصال
app.get('/api/test/connection', (req, res) => {
  res.json({
    success: true,
    message: '✅ الاتصال يعمل بنجاح',
    timestamp: new Date().toISOString(),
    server: 'montajati-backend',
    environment: process.env.NODE_ENV || 'development',
    requestId: requestCount
  });
});

// سجل الطلبات
app.get('/api/test/logs', (req, res) => {
  res.json({
    success: true,
    totalRequests: requestCount,
    recentRequests: requestLog.slice(-20), // آخر 20 طلب
    inventoryRequests: requestLog.filter(log => 
      log.url.includes('/api/inventory/monitor')
    ).slice(-10) // آخر 10 طلبات مراقبة مخزون
  });
});

// مراقبة منتج محدد
app.post('/api/inventory/monitor/:productId', async (req, res) => {
  try {
    const { productId } = req.params;
    
    console.log(`🔍 طلب مراقبة المنتج: ${productId}`);
    console.log(`📱 من التطبيق: ${req.get('User-Agent')}`);
    
    const result = await inventoryMonitor.monitorProduct(productId);
    
    if (result.success) {
      console.log(`✅ نجحت مراقبة المنتج: ${productId}`);
      console.log(`📊 الحالة: ${result.product?.status}`);
      
      if (result.alerts && result.alerts.length > 0) {
        console.log(`🚨 تم إرسال ${result.alerts.length} تنبيه`);
        result.alerts.forEach(alert => {
          console.log(`   - ${alert.type}: ${alert.sent ? 'تم الإرسال ✅' : 'فشل ❌'}`);
        });
      }
    } else {
      console.log(`❌ فشلت مراقبة المنتج: ${productId} - ${result.error}`);
    }
    
    res.json({
      ...result,
      requestId: requestCount,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`❌ خطأ في مراقبة المنتج: ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
      requestId: requestCount,
      timestamp: new Date().toISOString()
    });
  }
});

// مراقبة جميع المنتجات
app.post('/api/inventory/monitor-all', async (req, res) => {
  try {
    console.log('🔍 طلب مراقبة جميع المنتجات');
    console.log(`📱 من التطبيق: ${req.get('User-Agent')}`);
    
    const result = await inventoryMonitor.monitorAllProducts();
    
    if (result.success && result.results) {
      console.log(`✅ تمت مراقبة ${result.results.total} منتج`);
      console.log(`📊 نفد: ${result.results.outOfStock}, منخفض: ${result.results.lowStock}`);
      console.log(`🚨 إشعارات مرسلة: ${result.results.sentNotifications}`);
    }
    
    res.json({
      ...result,
      requestId: requestCount,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`❌ خطأ في مراقبة جميع المنتجات: ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
      requestId: requestCount,
      timestamp: new Date().toISOString()
    });
  }
});

// معالج 404
app.use('*', (req, res) => {
  console.log(`❌ طلب غير موجود: ${req.method} ${req.originalUrl}`);
  res.status(404).json({
    error: 'المسار غير موجود',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString(),
    requestId: requestCount
  });
});

// بدء الخادم
async function startTestServer() {
  try {
    console.log('🧪 === بدء خادم اختبار اتصال التطبيق ===\n');
    
    // اختبار نظام مراقبة المخزون
    console.log('🔍 اختبار نظام مراقبة المخزون...');
    const testResult = await inventoryMonitor.testSystem();
    
    if (testResult.success) {
      console.log('✅ نظام مراقبة المخزون جاهز');
    } else {
      console.log('⚠️ تحذير: مشكلة في نظام مراقبة المخزون');
    }
    
    // بدء الخادم
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`\n🚀 خادم اختبار الاتصال يعمل على المنفذ ${PORT}`);
      console.log(`🌐 الرابط المحلي: http://localhost:${PORT}`);
  console.log(`🌐 رابط الإنتاج: https://montajati-official-backend-production.up.railway.app`);
      console.log('\n📋 نقاط النهاية المتاحة:');
      console.log('   GET  /                           - الصفحة الرئيسية');
      console.log('   GET  /health                     - فحص الصحة');
      console.log('   GET  /api/test/connection        - اختبار الاتصال');
      console.log('   GET  /api/test/logs              - سجل الطلبات');
      console.log('   POST /api/inventory/monitor/:id  - مراقبة منتج');
      console.log('   POST /api/inventory/monitor-all  - مراقبة جميع المنتجات');
      console.log('\n⏳ في انتظار طلبات من التطبيق...');
  console.log(`🌐 رابط الإنتاج: https://montajati-official-backend-production.up.railway.app`);
    });

    // معالجة إغلاق الخادم
    process.on('SIGTERM', () => {
      console.log('\n🛑 إيقاف خادم الاختبار...');
      server.close(() => {
        console.log('✅ تم إيقاف الخادم بأمان');
        process.exit(0);
      });
    });

  } catch (error) {
    console.error('❌ خطأ في بدء خادم الاختبار:', error.message);
    process.exit(1);
  }
}

// تشغيل الخادم
if (require.main === module) {
  startTestServer();
}

module.exports = { app, startTestServer };
