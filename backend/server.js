// تطبيق منتجاتي - Backend Server
// Node.js + Express + Supabase + JWT

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const dotenv = require('dotenv');
const targetedNotificationService = require('./services/targeted_notification_service');
const tokenManagementService = require('./services/token_management_service');
const cron = require('node-cron');



// تحميل المتغيرات من ملف .env
dotenv.config();

const app = express();

// إعداد trust proxy لـ Render
app.set('trust proxy', 1);

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// إعدادات Middleware
const corsOrigins = process.env.NODE_ENV === 'production'
  ? (process.env.CORS_ORIGINS || '').split(',').filter(Boolean)
  : [
      'http://localhost:3002',
      'http://127.0.0.1:3002',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'http://localhost:3001',
      'http://127.0.0.1:3001'
    ];

app.use(cors({
  origin: corsOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// تحقق من اتصال Supabase
console.log('✅ تم إعداد Supabase بنجاح');



// Routes الأساسية
app.get('/', (req, res) => {
  res.json({
    message: 'مرحباً بك في API تطبيق منتجاتي 🚀',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  const checks = [];
  let overallStatus = 'healthy';

  // فحص خدمة الإشعارات
  try {
    if (targetedNotificationService && targetedNotificationService.isInitialized) {
      checks.push({ service: 'notifications', status: 'pass' });
    } else {
      checks.push({ service: 'notifications', status: 'fail', error: 'خدمة الإشعارات غير مهيأة' });
      overallStatus = 'degraded';
    }
  } catch (error) {
    checks.push({ service: 'notifications', status: 'fail', error: error.message });
    overallStatus = 'degraded';
  }

  // فحص خدمة المزامنة
  try {
    if (global.orderSyncService) {
      if (global.orderSyncService.isInitialized === true) {
        if (global.orderSyncService.waseetClient && global.orderSyncService.waseetClient.isConfigured) {
          checks.push({ service: 'sync', status: 'pass' });
        } else {
          checks.push({ service: 'sync', status: 'warn', error: 'خدمة المزامنة مهيأة لكن بيانات الوسيط غير موجودة' });
          overallStatus = 'degraded';
        }
      } else if (global.orderSyncService.isInitialized === false) {
        checks.push({ service: 'sync', status: 'warn', error: 'خدمة المزامنة مهيأة لكن عميل الوسيط غير مهيأ' });
        overallStatus = 'degraded';
      } else {
        // خدمة احتياطية
        checks.push({ service: 'sync', status: 'warn', error: 'خدمة المزامنة الاحتياطية نشطة' });
        overallStatus = 'degraded';
      }
    } else {
      checks.push({ service: 'sync', status: 'fail', error: 'خدمة المزامنة غير موجودة' });
      overallStatus = 'degraded';
    }
  } catch (error) {
    checks.push({ service: 'sync', status: 'fail', error: error.message });
    overallStatus = 'degraded';
  }

  // فحص خدمة المراقبة
  try {
    if (tokenManagementService) {
      checks.push({ service: 'monitor', status: 'pass' });
    } else {
      checks.push({ service: 'monitor', status: 'fail', error: 'خدمة المراقبة غير مهيأة' });
      overallStatus = 'degraded';
    }
  } catch (error) {
    checks.push({ service: 'monitor', status: 'fail', error: error.message });
    overallStatus = 'degraded';
  }



  res.json({
    status: overallStatus,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    server: {
      isInitialized: true,
      isRunning: true,
      startedAt: new Date(Date.now() - process.uptime() * 1000).toISOString()
    },
    services: {
      notifications: checks.find(c => c.service === 'notifications')?.status === 'pass' ? 'healthy' : 'unhealthy',
      sync: (() => {
        const syncCheck = checks.find(c => c.service === 'sync');
        if (syncCheck?.status === 'pass') return 'healthy';
        if (syncCheck?.status === 'warn') return 'warning';
        return 'unhealthy';
      })(),
      monitor: checks.find(c => c.service === 'monitor')?.status === 'pass' ? 'healthy' : 'unhealthy'
    },
    system: {
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      platform: process.platform,
      nodeVersion: process.version
    },
    checks: checks
  });
});

// Routes للمصادقة
try {
  const authRoutes = require('./routes/auth');
  app.use('/api/auth', authRoutes);
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/auth');
}

// Routes للمستخدمين
try {
  const userRoutes = require('./routes/users');
  app.use('/api/users', userRoutes);
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/users');
}

// Routes للمنتجات
try {
  const productRoutes = require('./routes/products');
  app.use('/api/products', productRoutes);
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/products');
}

// Routes للطلبات
try {
  const orderRoutes = require('./routes/orders');
  app.use('/api/orders', orderRoutes);
  console.log('✅ تم تحميل مسارات الطلبات');
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/orders');
}

// Routes لرفع الصور
try {
  const uploadRoutes = require('./routes/upload');
  app.use('/api/upload', uploadRoutes);
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/upload');
}

// 📊 Routes للإحصائيات المحفوظة (ذكي جداً!)
try {
  const statisticsRoutes = require('./routes/statistics');
  app.use('/api/statistics', statisticsRoutes);
  console.log('✅ تم تحميل routes الإحصائيات بنجاح');
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/statistics');
}

// Routes للإشعارات الفورية
try {
  const notificationRoutes = require('./routes/notifications');
  app.use('/api/notifications', notificationRoutes);
  console.log('✅ تم تحميل مسارات الإشعارات');
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/notifications');
}

// Routes لحالات الوسيط
try {
  const waseetStatusRoutes = require('./routes/waseet_statuses');
  app.use('/api/waseet-statuses', waseetStatusRoutes);
  console.log('✅ تم تحميل مسارات حالات الوسيط');
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/waseet_statuses');
}

// Routes للدعم
try {
  const supportRoutes = require('./routes/support');
  app.use('/api/support', supportRoutes);
  console.log('✅ تم تحميل مسارات الدعم بنجاح');
} catch (error) {
  console.log('❌ خطأ في تحميل routes/support:', error.message);
}

// معالجة الأخطاء العامة
app.use((err, req, res, next) => {
  console.error('خطأ في الخادم:', err.stack);
  res.status(500).json({
    success: false,
    message: 'حدث خطأ في الخادم',
    error: process.env.NODE_ENV === 'development' ? err.message : 'خطأ داخلي'
  });
});

// معالجة الطرق غير الموجودة
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'الطريق المطلوب غير موجود'
  });
});

// تهيئة خدمة الإشعارات المستهدفة
async function initializeNotificationService() {
  try {
    console.log('🔔 بدء تهيئة خدمة الإشعارات المستهدفة...');
    const initialized = await targetedNotificationService.initialize();

    if (initialized) {
      console.log('✅ تم تهيئة خدمة الإشعارات المستهدفة بنجاح');
    } else {
      console.log('⚠️ فشل في تهيئة خدمة الإشعارات المستهدفة');
    }
  } catch (error) {
    console.error('❌ خطأ في تهيئة خدمة الإشعارات:', error.message);
  }
}

// تهيئة خدمة مزامنة الطلبات مع الوسيط
async function initializeSyncService() {
  try {
    console.log('🔄 بدء تهيئة خدمة مزامنة الطلبات مع الوسيط...');

    // فحص متغيرات البيئة أولاً
    console.log('🔍 فحص متغيرات البيئة للوسيط...');
    console.log(`WASEET_USERNAME: ${process.env.WASEET_USERNAME ? '✅ موجود' : '❌ غير موجود'}`);
    console.log(`WASEET_PASSWORD: ${process.env.WASEET_PASSWORD ? '✅ موجود' : '❌ غير موجود'}`);

    // إضافة متغيرات البيئة يدوياً إذا لم تكن موجودة (للإنتاج فقط)
    if (process.env.NODE_ENV === 'production' && (!process.env.WASEET_USERNAME || !process.env.WASEET_PASSWORD)) {
      console.log('⚠️ متغيرات الوسيط غير موجودة في الإنتاج - إضافة يدوياً...');
      process.env.WASEET_USERNAME = 'محمد@mustfaabd';
      process.env.WASEET_PASSWORD = 'mustfaabd2006@';
      console.log('✅ تم إضافة متغيرات الوسيط يدوياً');
    }

    // استيراد خدمة المزامنة
    console.log('📦 استيراد OrderSyncService...');
    const OrderSyncService = require('./services/order_sync_service');
    console.log('✅ تم استيراد OrderSyncService بنجاح');

    // إنشاء instance من الخدمة
    console.log('🔧 إنشاء instance من OrderSyncService...');
    const syncService = new OrderSyncService();
    console.log('✅ تم إنشاء instance بنجاح');

    // التحقق من حالة التهيئة
    if (syncService.isInitialized === false) {
      console.warn('⚠️ خدمة المزامنة مهيأة لكن عميل الوسيط غير مهيأ (بيانات المصادقة ناقصة)');
      console.warn('💡 يرجى إضافة WASEET_USERNAME و WASEET_PASSWORD في متغيرات البيئة');
    } else {
      console.log('✅ خدمة المزامنة مهيأة بالكامل مع عميل الوسيط');
    }

    global.orderSyncService = syncService;
    console.log('✅ تم تهيئة خدمة مزامنة الطلبات مع الوسيط بنجاح');
    return true;

  } catch (error) {
    console.error('❌ خطأ في تهيئة خدمة مزامنة الطلبات مع الوسيط:', error.message);
    console.error('📋 تفاصيل الخطأ:', error.stack);

    // إنشاء خدمة مزامنة احتياطية
    console.log('🔧 إنشاء خدمة مزامنة احتياطية...');
    global.orderSyncService = {
      isInitialized: false,
      waseetClient: null,
      sendOrderToWaseet: async (orderId) => {
        console.log(`📦 محاولة إرسال الطلب ${orderId} للوسيط...`);
        console.error('❌ خدمة المزامنة غير متاحة:', error.message);
        return {
          success: false,
          error: `خطأ في خدمة المزامنة: ${error.message}`,
          needsConfiguration: true
        };
      }
    };

    console.log('⚠️ تم إنشاء خدمة مزامنة احتياطية');
    return false;
  }
}



// تشغيل الخادم
const PORT = process.env.PORT || 3003;
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 الخادم يعمل على المنفذ ${PORT}`);
  console.log(`🌐 البيئة: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🕐 وقت البدء: ${new Date().toISOString()}`);
  console.log(`🔧 إصدار التشخيص الشامل: v2.1 - ${new Date().toISOString()}`);
  if (process.env.NODE_ENV === 'production') {
    console.log(`🌍 الخادم متاح على: https://montajati-backend.onrender.com`);
  } else {
    console.log(`🌐 الرابط المحلي: http://localhost:${PORT}`);
  }

  // تهيئة خدمة الإشعارات
  await initializeNotificationService();

  // تهيئة خدمة مزامنة الطلبات مع الوسيط
  await initializeSyncService();



  // بدء مهمة دورية لإعادة محاولة الطلبات الفاشلة كل 10 دقائق
  if (global.orderSyncService && global.orderSyncService.retryFailedOrders) {
    setInterval(async () => {
      try {
        console.log('🔄 تشغيل مهمة إعادة محاولة الطلبات الفاشلة...');
        await global.orderSyncService.retryFailedOrders();
      } catch (error) {
        console.error('❌ خطأ في مهمة إعادة المحاولة:', error);
      }
    }, 10 * 60 * 1000); // كل 10 دقائق

    console.log('✅ تم تشغيل مهمة إعادة محاولة الطلبات الفاشلة');
  }

  // بدء مهام الصيانة الدورية
  startMaintenanceTasks();
});

// مهام الصيانة الدورية لـ FCM Tokens
function startMaintenanceTasks() {
  console.log('⏰ بدء جدولة مهام الصيانة الدورية...');

  // تنظيف الرموز القديمة كل يوم في الساعة 2:00 صباحاً
  cron.schedule('0 2 * * *', async () => {
    console.log('🧹 تشغيل مهمة تنظيف FCM Tokens القديمة...');
    try {
      const result = await tokenManagementService.cleanupOldTokens();
      console.log('✅ انتهت مهمة التنظيف:', result);
    } catch (error) {
      console.error('❌ خطأ في مهمة التنظيف:', error.message);
    }
  }, {
    timezone: 'Asia/Riyadh'
  });

  // التحقق من صحة الرموز كل أسبوع يوم الأحد في الساعة 3:00 صباحاً
  cron.schedule('0 3 * * 0', async () => {
    console.log('🔍 تشغيل مهمة التحقق من صحة FCM Tokens...');
    try {
      const result = await tokenManagementService.validateAllActiveTokens();
      console.log('✅ انتهت مهمة التحقق:', result);
    } catch (error) {
      console.error('❌ خطأ في مهمة التحقق:', error.message);
    }
  }, {
    timezone: 'Asia/Riyadh'
  });

  // تشغيل جميع مهام الصيانة كل شهر في اليوم الأول في الساعة 4:00 صباحاً
  cron.schedule('0 4 1 * *', async () => {
    console.log('🔧 تشغيل جميع مهام الصيانة الشهرية...');
    try {
      const result = await tokenManagementService.runMaintenanceTasks();
      console.log('✅ انتهت مهام الصيانة الشهرية:', result);
    } catch (error) {
      console.error('❌ خطأ في مهام الصيانة الشهرية:', error.message);
    }
  }, {
    timezone: 'Asia/Riyadh'
  });



  // مزامنة تلقائية لحالات الطلبات كل 5 دقائق باستخدام النظام الإنتاجي
  setInterval(async () => {
    try {
      console.log('🔍 بدء المزامنة التلقائية مع شركة الوسيط...');

      // استيراد النظام الإنتاجي الموجود
      const ProductionSyncService = require('./production/sync_service');
      const syncService = new ProductionSyncService();

      // تشغيل المزامنة
      const result = await syncService.performSync();

      console.log(`✅ انتهت المزامنة: فحص ${result.checked || 0} طلب، تحديث ${result.updated || 0} طلب`);

      if (result.errors && result.errors.length > 0) {
        console.log(`⚠️ أخطاء في ${result.errors.length} طلب`);
      }

    } catch (error) {
      console.error('❌ خطأ في المزامنة التلقائية:', error.message);
    }
  }, 5 * 60 * 1000); // كل 5 دقائق

  console.log('✅ تم جدولة مهام الصيانة الدورية بنجاح');
  console.log('🔍 سيتم فحص حالات الطلبات من الوسيط كل 5 دقائق تلقائياً');
}

module.exports = app;
