// ===================================
// خادم الإنتاج الرسمي - Montajati Backend
// ===================================

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
require('dotenv').config();

// استيراد الإعدادات
const { supabase, supabaseAdmin } = require('./config/supabase');
const { firebaseConfig } = require('./config/firebase');

// استيراد المسارات
const authRoutes = require('./routes/auth_supabase');
const productsRoutes = require('./routes/products');
const ordersRoutes = require('./routes/orders');
const statisticsRoutes = require('./routes/statistics_simple');
const uploadRoutes = require('./routes/upload');
const usersRoutes = require('./routes/users');
const targetedNotificationsRoutes = require('./routes/targeted_notifications');

// استيراد الخدمات
const OrderStatusSyncService = require('./sync/order_status_sync_service');
const OrderStatusWatcher = require('./services/order_status_watcher');
const InventoryMonitorService = require('./inventory_monitor_service');
const TelegramNotificationService = require('./telegram_notification_service');

const app = express();
// التأكد من استخدام PORT من Render
const PORT = parseInt(process.env.PORT) || 3003;

// ===================================
// تهيئة خدمات التلغرام والمخزون
// ===================================
const telegramService = new TelegramNotificationService();
const inventoryMonitor = new InventoryMonitorService();

// ===================================
// إعدادات الأمان
// ===================================

// Helmet للحماية من الثغرات الأمنية الشائعة
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// معدل الطلبات المحدود
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 دقيقة
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // حد الطلبات
  message: {
    error: 'تم تجاوز الحد المسموح من الطلبات. حاول مرة أخرى لاحقاً.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(limiter);

// ===================================
// إعدادات CORS
// ===================================

const allowedOrigins = process.env.CORS_ORIGINS 
  ? process.env.CORS_ORIGINS.split(',').map(origin => origin.trim())
  : ['http://localhost:3002', 'http://localhost:3000'];

app.use(cors({
  origin: function (origin, callback) {
    // السماح للطلبات بدون origin (مثل التطبيقات المحمولة)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      console.log(`❌ CORS blocked origin: ${origin}`);
      callback(new Error('غير مسموح بالوصول من هذا المصدر'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// ===================================
// إعدادات التطبيق
// ===================================

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// إضافة معلومات الطلب للسجلات
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path} - IP: ${req.ip}`);
  next();
});

// ===================================
// فحص الصحة
// ===================================

app.get('/health', async (req, res) => {
  try {
    const healthStatus = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0',
      services: {}
    };

    // فحص Supabase
    try {
      const { data, error } = await supabase.from('users').select('count').limit(1);
      healthStatus.services.supabase = error ? 'error' : 'healthy';
    } catch (error) {
      healthStatus.services.supabase = 'error';
    }

    // فحص Firebase
    try {
      const result = await firebaseConfig.initialize();
      healthStatus.services.firebase = result ? 'healthy' : 'disabled';
    } catch (error) {
      healthStatus.services.firebase = 'disabled';
    }

    // تحديد الحالة العامة
    const hasErrors = Object.values(healthStatus.services).includes('error');
    healthStatus.status = hasErrors ? 'degraded' : 'healthy';

    res.status(hasErrors ? 503 : 200).json(healthStatus);
  } catch (error) {
    res.status(500).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// ===================================
// المسارات الرئيسية
// ===================================

app.use('/api/auth', authRoutes);
app.use('/api/products', productsRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/statistics', statisticsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/notifications', targetedNotificationsRoutes);

// ===================================
// مسارات نظام التلغرام والمخزون
// ===================================

// اختبار اتصال التلغرام
app.get('/api/telegram/test', async (req, res) => {
  try {
    const result = await telegramService.testConnection();
    res.json({
      success: true,
      telegram_status: result.success ? 'connected' : 'failed',
      result: result
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// اختبار نظام مراقبة المخزون
app.get('/api/inventory/test', async (req, res) => {
  try {
    const result = await inventoryMonitor.testSystem();
    res.json({
      success: true,
      inventory_status: result.success ? 'working' : 'failed',
      result: result
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// مراقبة منتج محدد
app.post('/api/inventory/monitor/:productId', async (req, res) => {
  try {
    const { productId } = req.params;
    const result = await inventoryMonitor.monitorProduct(productId);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// مراقبة جميع المنتجات
app.post('/api/inventory/monitor-all', async (req, res) => {
  try {
    const result = await inventoryMonitor.monitorAllProducts();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// إرسال تقرير يومي - معطل (القناة مخصصة للتجار فقط)
app.post('/api/inventory/daily-report', async (req, res) => {
  try {
    const result = await inventoryMonitor.sendDailyReport();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// إرسال رسالة تلغرام مخصصة
app.post('/api/telegram/send', async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) {
      return res.status(400).json({
        success: false,
        error: 'الرسالة مطلوبة'
      });
    }

    const result = await telegramService.sendMessage(message);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// Hooks تلقائية لمراقبة المخزون
// ===================================

// Hook لتحديث المنتجات (يتم استدعاؤه من Frontend)
app.post('/api/products/update-hook', async (req, res) => {
  try {
    const { productId, oldQuantity, newQuantity } = req.body;

    console.log(`🔄 Hook تحديث المنتج: ${productId}`);
    console.log(`📊 الكمية السابقة: ${oldQuantity}, الكمية الجديدة: ${newQuantity}`);

    // تشغيل مراقبة المنتج تلقائياً
    const monitorResult = await inventoryMonitor.monitorProduct(productId);

    res.json({
      success: true,
      message: 'تم تحديث المنتج ومراقبة المخزون',
      monitor_result: monitorResult
    });
  } catch (error) {
    console.error('❌ خطأ في hook تحديث المنتج:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Hook لإنشاء الطلبات (يتم استدعاؤه عند إنشاء طلب جديد)
app.post('/api/orders/create-hook', async (req, res) => {
  try {
    const { orderId, items } = req.body;

    console.log(`📦 Hook إنشاء طلب: ${orderId}`);
    console.log(`📋 عدد المنتجات: ${items?.length || 0}`);

    // مراقبة جميع المنتجات في الطلب
    const monitorPromises = items.map(item =>
      inventoryMonitor.monitorProduct(item.product_id)
    );

    const monitorResults = await Promise.all(monitorPromises);

    res.json({
      success: true,
      message: 'تم إنشاء الطلب ومراقبة المخزون',
      monitor_results: monitorResults
    });
  } catch (error) {
    console.error('❌ خطأ في hook إنشاء الطلب:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Hook لإلغاء الطلبات (يتم استدعاؤه عند إلغاء طلب)
app.post('/api/orders/cancel-hook', async (req, res) => {
  try {
    const { orderId, items } = req.body;

    console.log(`❌ Hook إلغاء طلب: ${orderId}`);
    console.log(`📋 عدد المنتجات المُرجعة: ${items?.length || 0}`);

    // مراقبة جميع المنتجات المُرجعة
    const monitorPromises = items.map(item =>
      inventoryMonitor.monitorProduct(item.product_id)
    );

    const monitorResults = await Promise.all(monitorPromises);

    res.json({
      success: true,
      message: 'تم إلغاء الطلب ومراقبة المخزون',
      monitor_results: monitorResults
    });
  } catch (error) {
    console.error('❌ خطأ في hook إلغاء الطلب:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// معالجة الأخطاء
// ===================================

// معالج 404
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'المسار غير موجود',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

// معالج الأخطاء العام
app.use((error, req, res, next) => {
  console.error('❌ خطأ في الخادم:', error);

  // عدم إظهار تفاصيل الأخطاء في الإنتاج
  const isDevelopment = process.env.NODE_ENV !== 'production';
  
  res.status(error.status || 500).json({
    error: 'حدث خطأ في الخادم',
    message: isDevelopment ? error.message : 'خطأ داخلي في الخادم',
    timestamp: new Date().toISOString(),
    ...(isDevelopment && { stack: error.stack })
  });
});

// ===================================
// تهيئة الخدمات وبدء الخادم
// ===================================

async function startServer() {
  try {
    console.log('🚀 بدء تشغيل خادم الإنتاج...');
    console.log(`📊 البيئة: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 المنفذ: ${PORT}`);
    console.log(`🔍 معرف الإصدار: ${process.env.RENDER_GIT_COMMIT?.substring(0, 7) || 'local'} (إنتاج مُحسن)`);

    // تهيئة Firebase (إذا لم يكن مهيأ مسبقاً)
    const admin = require('firebase-admin');
    if (admin.apps.length === 0) {
      console.log('🔥 تهيئة Firebase...');
      try {
        const result = await firebaseConfig.initialize();
        if (result) {
          console.log('✅ Firebase جاهز للإشعارات');
        } else {
          console.log('ℹ️ Firebase غير متاح - الخادم سيعمل بدون إشعارات');
        }
      } catch (error) {
        console.log('ℹ️ Firebase غير متاح - الخادم سيعمل بدون إشعارات');
      }
    } else {
      console.log('✅ Firebase جاهز');
    }

    // تهيئة خدمة مزامنة حالة الطلبات
    console.log('🔄 تهيئة خدمة مزامنة الطلبات...');
    try {
      const orderStatusSyncService = new OrderStatusSyncService();
      await orderStatusSyncService.initialize();

      // بدء المزامنة التلقائية
      orderStatusSyncService.startAutoSync();
      console.log('✅ تم تهيئة خدمة مزامنة الطلبات بنجاح');
    } catch (error) {
      console.warn('⚠️ تحذير: فشل في تهيئة خدمة مزامنة الطلبات:', error.message);
    }

    // تشغيل مراقب حالة الطلبات للإشعارات
    console.log('👁️ تشغيل مراقب حالة الطلبات...');
    try {
      const orderStatusWatcher = new OrderStatusWatcher();
      orderStatusWatcher.startWatching();
      console.log('✅ تم تشغيل مراقب حالة الطلبات بنجاح');
    } catch (error) {
      console.warn('⚠️ تحذير: فشل في تشغيل مراقب الطلبات:', error.message);
    }

    // تهيئة وتشغيل نظام مراقبة المخزون والتلغرام
    console.log('📱 تهيئة نظام التلغرام ومراقبة المخزون...');

    // اختبار اتصال التلغرام
    const telegramTest = await telegramService.testConnection();
    if (telegramTest.success) {
      console.log('✅ تم الاتصال بـ Telegram Bot بنجاح');
    } else {
      console.log('⚠️ تحذير: فشل في الاتصال بـ Telegram Bot');
      console.log('💡 تأكد من إعداد TELEGRAM_BOT_TOKEN و TELEGRAM_CHAT_ID');
    }

    // اختبار نظام مراقبة المخزون
    const inventoryTest = await inventoryMonitor.testSystem();
    if (inventoryTest.success) {
      console.log('✅ نظام مراقبة المخزون جاهز');
    } else {
      console.log('⚠️ تحذير: مشكلة في نظام مراقبة المخزون');
    }

    // تشغيل مراقبة فورية للمخزون (كل دقيقة واحدة)
    console.log('⚡ تشغيل المراقبة الفورية للمخزون كل دقيقة...');
    setInterval(async () => {
      try {
        const result = await inventoryMonitor.monitorAllProducts();

        // عرض نتائج مفصلة عند وجود تنبيهات
        if (result.success && result.results) {
          const { outOfStock, lowStock, total, sentNotifications } = result.results;

          if (outOfStock > 0 || lowStock > 0) {
            console.log(`🔄 فحص فوري للمخزون - ${total} منتج`);
            console.log(`📊 نفد: ${outOfStock}, منخفض: ${lowStock}, طبيعي: ${total - outOfStock - lowStock}`);

            if (sentNotifications > 0) {
              console.log(`📨 تم إرسال ${sentNotifications} إشعار تلغرام جديد`);
            }
          }
        }
      } catch (error) {
        console.error('❌ خطأ في المراقبة الفورية:', error.message);
      }
    }, 60 * 1000); // كل دقيقة واحدة

    // بدء الخادم
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log('✅ خادم الإنتاج يعمل بنجاح!');

      // عرض الرابط الصحيح حسب البيئة
      if (process.env.NODE_ENV === 'production' && process.env.RENDER) {
        console.log(`🌐 الرابط: https://montajati-backend.onrender.com`);
        console.log(`🔗 فحص الصحة: https://montajati-backend.onrender.com/health`);
      } else {
        console.log(`🌐 الرابط: http://localhost:${PORT}`);
        console.log(`🔗 فحص الصحة: http://localhost:${PORT}/health`);
      }

      console.log('📱 جاهز لاستقبال الطلبات من التطبيق');
    });

    // معالجة إغلاق الخادم بأمان
    process.on('SIGTERM', () => {
      console.log('🛑 تلقي إشارة إيقاف الخادم...');
      server.close(() => {
        console.log('✅ تم إيقاف الخادم بأمان');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      console.log('🛑 تلقي إشارة مقاطعة...');
      server.close(() => {
        console.log('✅ تم إيقاف الخادم بأمان');
        process.exit(0);
      });
    });

  } catch (error) {
    console.error('❌ فشل في بدء تشغيل الخادم:', error);
    process.exit(1);
  }
}

// بدء الخادم
startServer();

module.exports = app;
