// ===================================
// الخادم الرسمي المتكامل لنظام منتجاتي
// Official Integrated Montajati Server
// ===================================

// تحميل متغيرات البيئة (يعمل مع DigitalOcean تلقائياً)
require('dotenv').config();
const express = require('express');
const cors = require('cors');

// إضافة خدمة مراقبة المخزون
const InventoryMonitorService = require('./inventory_monitor_service');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

// ✅ إضافة middleware الأمان المحسن
const {
  corsOptions,
  generalRateLimit,
  authRateLimit,
  apiRateLimit,
  sanitizeInput,
  validateContentType,
  logSuspiciousActivity,
  helmet: secureHelmet
} = require('./middleware/security');

// استيراد الخدمات الرسمية
const OfficialNotificationManager = require('./services/official_notification_manager');
const AdvancedSyncManager = require('./services/advanced_sync_manager');
const SystemMonitor = require('./services/system_monitor');
const FCMCleanupService = require('./services/fcm_cleanup_service');

// نظام المزامنة المدمج مع الوسيط
const waseetSync = require('./services/integrated_waseet_sync');

class OfficialMontajatiServer {
  constructor() {
    this.app = express();
    this.port = process.env.PORT || 3003;
    this.environment = process.env.NODE_ENV || 'production';
    
    // حالة النظام
    this.state = {
      isRunning: false,
      isInitialized: false,
      startedAt: null,
      services: {
        notifications: null,
        inventoryMonitor: null,
        sync: null,
        monitor: null,
        fcmCleanup: null,
      }
    };

    // إعداد الخدمات
    this.notificationManager = new OfficialNotificationManager();
    this.syncManager = new AdvancedSyncManager();
    this.systemMonitor = new SystemMonitor();
    this.fcmCleanupService = FCMCleanupService;

    this.setupExpress();
    this.setupRoutes();
    this.setupEventHandlers();
  }

  // ===================================
  // إعداد Express
  // ===================================
  setupExpress() {
    // ✅ إعداد trust proxy لـ Render
    this.app.set('trust proxy', true);

    // ✅ إعدادات الأمان المحسنة
    this.app.use(secureHelmet);

    // ضغط الاستجابات
    this.app.use(compression());

    // ✅ إعدادات CORS الآمنة
    this.app.use(cors(corsOptions));

    // ✅ تنظيف وتعقيم المدخلات
    this.app.use(sanitizeInput);

    // ✅ التحقق من Content-Type
    this.app.use(validateContentType);

    // ✅ تسجيل النشاط المشبوه
    this.app.use(logSuspiciousActivity);

    // ✅ Rate Limiting المحسن
    this.app.use('/api/', generalRateLimit);
    this.app.use('/api/auth/', authRateLimit);
    this.app.use('/api/orders/', apiRateLimit);
    this.app.use('/api/notifications/', apiRateLimit);

    // معالجة البيانات
    this.app.use(express.json({
      limit: '10mb',
      verify: (req, res, buf) => {
        // فقط للطلبات التي تحتوي على بيانات
        if (buf && buf.length > 0) {
          try {
            JSON.parse(buf);
          } catch (e) {
            // لا نرسل استجابة هنا، فقط نرمي الخطأ
            throw new Error('Invalid JSON');
          }
        }
      }
    }));
    
    this.app.use(express.urlencoded({ 
      extended: true, 
      limit: '10mb' 
    }));

    // تسجيل الطلبات
    this.app.use((req, res, next) => {
      const timestamp = new Date().toISOString();
      const method = req.method;
      const url = req.originalUrl;
      const ip = req.ip || req.connection.remoteAddress;
      
      console.log(`📡 ${timestamp} - ${method} ${url} - ${ip}`);
      
      // إضافة معرف فريد للطلب
      req.requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      res.setHeader('X-Request-ID', req.requestId);
      
      next();
    });

    // معالجة الأخطاء العامة
    this.app.use((err, req, res, next) => {
      console.error(`❌ خطأ في الطلب ${req.requestId}:`, err);

      // تسجيل الخطأ في النظام
      this.logError(err, req);

      // التحقق من أن الاستجابة لم يتم إرسالها بعد
      if (!res.headersSent) {
        res.status(err.status || 500).json({
          success: false,
          message: this.environment === 'production'
            ? 'حدث خطأ داخلي في الخادم'
            : err.message,
          requestId: req.requestId,
          timestamp: new Date().toISOString()
        });
      }
    });
  }

  // ===================================
  // إعداد المسارات
  // ===================================
  setupRoutes() {
    // المسار الرئيسي
    this.app.get('/', (req, res) => {
      res.json({
        name: 'نظام منتجاتي - الخادم الرسمي',
        version: '1.0.0',
        environment: this.environment,
        status: 'running',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        services: {
          notifications: this.state.services.notifications?.isInitialized || false,
          sync: this.state.services.sync?.isInitialized || false,
          monitor: this.state.services.monitor?.isInitialized || false,
        },
        endpoints: {
          health: '/health',
          system: '/api/system',
          notifications: '/api/notifications',
          orders: '/api/orders',
          users: '/api/users',
          products: '/api/products',
          auth: '/api/auth',
          fcm: '/api/fcm',
          sync: '/api/sync',
          monitor: '/api/monitor'
        },
        documentation: '/api/docs'
      });
    });

    // مسار فحص الصحة المتقدم
    this.app.get('/health', async (req, res) => {
      try {
        const health = await this.getSystemHealth();
        const statusCode = health.status === 'healthy' ? 200 : 503;
        
        res.status(statusCode).json(health);
      } catch (error) {
        res.status(503).json({
          status: 'error',
          message: 'فشل في فحص صحة النظام',
          error: error.message,
          timestamp: new Date().toISOString()
        });
      }
    });

    // مسارات النظام
    this.app.get('/api/system/status', (req, res) => {
      res.json({
        success: true,
        data: {
          server: {
            isRunning: this.state.isRunning,
            isInitialized: this.state.isInitialized,
            startedAt: this.state.startedAt,
            uptime: process.uptime(),
            environment: this.environment,
            nodeVersion: process.version,
            platform: process.platform,
            arch: process.arch,
          },
          services: {
            notifications: this.notificationManager.getStats(),
            sync: this.syncManager.getStats(),
            monitor: this.systemMonitor.getSystemStatus(),
          }
        }
      });
    });

    // مسارات الإشعارات
    this.app.post('/api/notifications/send', async (req, res) => {
      try {
        const { orderData, statusChange } = req.body;
        
        if (!orderData || !statusChange) {
          return res.status(400).json({
            success: false,
            message: 'بيانات الطلب وتغيير الحالة مطلوبة'
          });
        }

        const notification = await this.notificationManager.addNotification(orderData, statusChange);
        
        res.json({
          success: true,
          message: 'تم إضافة الإشعار بنجاح',
          data: notification
        });

      } catch (error) {
        res.status(500).json({
          success: false,
          message: 'خطأ في إرسال الإشعار',
          error: error.message
        });
      }
    });

    // مسارات المزامنة
    this.app.post('/api/sync/trigger', async (req, res) => {
      try {
        await this.syncManager.performSync();
        
        res.json({
          success: true,
          message: 'تم تشغيل المزامنة بنجاح'
        });

      } catch (error) {
        res.status(500).json({
          success: false,
          message: 'خطأ في تشغيل المزامنة',
          error: error.message
        });
      }
    });

    // مسارات المراقبة
    this.app.get('/api/monitor/metrics', (req, res) => {
      const metrics = this.systemMonitor.getSystemStatus();
      
      res.json({
        success: true,
        data: metrics
      });
    });

    // تحميل المسارات الأساسية
    this.loadCoreRoutes();

    // معالجة المسارات غير الموجودة
    this.app.use('*', (req, res) => {
      res.status(404).json({
        success: false,
        message: 'المسار غير موجود',
        path: req.originalUrl,
        method: req.method,
        timestamp: new Date().toISOString()
      });
    });
  }

  // ===================================
  // تحميل المسارات الأساسية
  // ===================================
  loadCoreRoutes() {
    // مسارات FCM
    try {
      const fcmRoutes = require('./routes/fcm_tokens');
      this.app.use('/api/fcm', fcmRoutes);
      console.log('✅ تم تحميل مسارات FCM');
    } catch (error) {
      console.warn('⚠️ تحذير في تحميل مسارات FCM:', error.message);
    }

    // مسارات الإشعارات
    try {
      const notificationRoutes = require('./routes/notifications');
      this.app.use('/api/notifications', notificationRoutes);
      console.log('✅ تم تحميل مسارات الإشعارات');
    } catch (error) {
      console.warn('⚠️ تحذير في تحميل مسارات الإشعارات:', error.message);
    }

    // مسارات الطلبات
    try {
      const orderRoutes = require('./routes/orders');
      this.app.use('/api/orders', orderRoutes);
      console.log('✅ تم تحميل مسارات الطلبات');
    } catch (error) {
      console.warn('⚠️ تحذير في تحميل مسارات الطلبات:', error.message);
    }

    // مسارات المستخدمين
    try {
      const userRoutes = require('./routes/users');
      this.app.use('/api/users', userRoutes);
      console.log('✅ تم تحميل مسارات المستخدمين');
    } catch (error) {
      console.warn('⚠️ تحذير في تحميل مسارات المستخدمين:', error.message);
    }

    // مسارات المنتجات
    try {
      const productRoutes = require('./routes/products');
      this.app.use('/api/products', productRoutes);
      console.log('✅ تم تحميل مسارات المنتجات');
    } catch (error) {
      console.warn('⚠️ تحذير في تحميل مسارات المنتجات:', error.message);
    }

    // مسارات المصادقة
    try {
      const authRoutes = require('./routes/auth');
      this.app.use('/api/auth', authRoutes);
      console.log('✅ تم تحميل مسارات المصادقة');
    } catch (error) {
      console.warn('⚠️ تحذير في تحميل مسارات المصادقة:', error.message);
    }

    // مسارات حالات الوسيط
    try {
      const waseetStatusesRoutes = require('./routes/waseet_statuses');
      this.app.use('/api/waseet-statuses', waseetStatusesRoutes);
      console.log('✅ تم تحميل مسارات حالات الوسيط');
    } catch (error) {
      console.warn('⚠️ تحذير في تحميل مسارات حالات الوسيط:', error.message);
    }

    // مسارات دعم الطلبات
    try {
      const supportRoutes = require('./routes/support');
      this.app.use('/api/support', supportRoutes);
      console.log('✅ تم تحميل مسارات الدعم التلقائي للتلغرام - v2.0');
    } catch (error) {
      console.warn('⚠️ تحذير في تحميل مسارات الدعم:', error.message);
    }

    // مسارات مراقبة المخزون
    this.setupInventoryRoutes();

    console.log('✅ انتهى تحميل جميع المسارات');

    // معالج 404 للمسارات غير الموجودة
    this.app.use('*', (req, res) => {
      res.status(404).json({
        success: false,
        message: 'المسار غير موجود',
        path: req.originalUrl,
        method: req.method,
        timestamp: new Date().toISOString()
      });
    });
  }

  // ===================================
  // إعداد مسارات مراقبة المخزون
  // ===================================
  setupInventoryRoutes() {
    // مراقبة منتج محدد
    this.app.post('/api/inventory/monitor/:productId', async (req, res) => {
      try {
        const { productId } = req.params;
        console.log(`📦 طلب مراقبة المنتج: ${productId}`);

        const result = await this.inventoryMonitor.monitorProduct(productId);

        res.json({
          success: true,
          message: 'تم فحص المنتج بنجاح',
          data: result,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('❌ خطأ في مراقبة المنتج:', error);
        res.status(500).json({
          success: false,
          message: 'خطأ في مراقبة المنتج',
          error: error.message
        });
      }
    });

    // مراقبة جميع المنتجات
    this.app.post('/api/inventory/monitor-all', async (req, res) => {
      try {
        console.log('📦 طلب مراقبة جميع المنتجات');

        const result = await this.inventoryMonitor.monitorAllProducts();

        res.json({
          success: true,
          message: 'تم فحص جميع المنتجات بنجاح',
          data: result,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('❌ خطأ في مراقبة جميع المنتجات:', error);
        res.status(500).json({
          success: false,
          message: 'خطأ في مراقبة جميع المنتجات',
          error: error.message
        });
      }
    });

    console.log('✅ تم تحميل مسارات مراقبة المخزون');
  }

  // ===================================
  // بدء المراقبة الدورية للمخزون
  // ===================================
  startInventoryMonitoring() {
    console.log('📦 بدء المراقبة الدورية للمخزون...');

    // مراقبة فورية كل دقيقة
    setInterval(async () => {
      try {
        const result = await this.inventoryMonitor.monitorAllProducts();

        if (result.success && result.results) {
          const { outOfStock, lowStock, total, sentNotifications } = result.results;

          // عرض النتائج فقط عند وجود تنبيهات
          if (outOfStock > 0 || lowStock > 0) {
            console.log(`📦 فحص دوري للمخزون - ${total} منتج`);
            console.log(`📊 نفد: ${outOfStock}, منخفض: ${lowStock}, طبيعي: ${total - outOfStock - lowStock}`);

            if (sentNotifications > 0) {
              console.log(`📨 تم إرسال ${sentNotifications} إشعار تلغرام جديد`);
            }
          }
        }
      } catch (error) {
        console.error('❌ خطأ في المراقبة الدورية للمخزون:', error.message);
      }
    }, 60 * 1000); // كل دقيقة

    console.log('✅ تم بدء المراقبة الدورية للمخزون (كل دقيقة)');
  }

  // ===================================
  // إعداد معالجات الأحداث
  // ===================================
  setupEventHandlers() {
    // معالجات إشارات النظام
    process.on('SIGTERM', () => this.gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => this.gracefulShutdown('SIGINT'));
    process.on('uncaughtException', (error) => {
      console.error('❌ خطأ غير معالج:', error);
      this.logError(error);
      this.gracefulShutdown('uncaughtException');
    });
    process.on('unhandledRejection', (reason, promise) => {
      console.error('❌ رفض غير معالج:', reason);
      this.logError(new Error(`Unhandled Rejection: ${reason}`));
    });

    // معالجات أحداث الخدمات
    this.notificationManager.on('error', (error) => {
      console.error('❌ خطأ في خدمة الإشعارات:', error);
      this.logError(error, null, 'notification_service');
    });

    this.syncManager.on('error', (error) => {
      console.error('❌ خطأ في خدمة المزامنة:', error);
      this.logError(error, null, 'sync_service');
    });

    this.systemMonitor.on('alert', (alert) => {
      // تنبيه النظام (بصمت)
    });
  }

  // ===================================
  // تهيئة النظام الكامل
  // ===================================
  async initialize() {
    try {
      console.log('🚀 تهيئة الخادم الرسمي لنظام منتجاتي...');
      console.log(`📊 البيئة: ${this.environment}`);
      console.log(`🌐 المنفذ: ${this.port}`);

      // تهيئة الخدمات الأساسية
      await this.notificationManager.initialize();
      this.state.services.notifications = this.notificationManager;

      // تهيئة خدمة مراقبة المخزون
      console.log('📦 تهيئة خدمة مراقبة المخزون...');
      this.inventoryMonitor = new InventoryMonitorService();
      this.state.services.inventoryMonitor = this.inventoryMonitor;

      // تهيئة خدمة المزامنة المتقدمة
      try {
        await this.syncManager.initialize();
        this.state.services.sync = this.syncManager;
        console.log('✅ تم تهيئة خدمة المزامنة بنجاح');

        // تهيئة global.orderSyncService للمسارات القديمة
        try {
          const OrderSyncService = require('./services/order_sync_service');
          global.orderSyncService = new OrderSyncService();
          console.log('✅ تم تهيئة global.orderSyncService للمسارات');
        } catch (globalError) {
          console.warn('⚠️ تحذير: فشل في تهيئة global.orderSyncService:', globalError.message);
        }

      } catch (error) {
        console.error('❌ فشل في تهيئة خدمة المزامنة:', error);
        this.state.services.sync = null;
      }

      // تهيئة خدمة تنظيف FCM
      try {
        this.fcmCleanupService.start();
        this.state.services.fcmCleanup = this.fcmCleanupService;
      } catch (error) {
        this.state.services.fcmCleanup = null;
      }

      this.state.isInitialized = true;
      console.log('✅ تم تهيئة جميع الخدمات بنجاح');

      // بدء نظام المزامنة المدمج مع الوسيط
      console.log('🚀 بدء نظام المزامنة المدمج مع الوسيط...');
      waseetSync.autoStart();

      return true;

    } catch (error) {
      console.error('❌ خطأ في تهيئة النظام:', error);
      throw error;
    }
  }

  // ===================================
  // بدء تشغيل الخادم
  // ===================================
  async start() {
    try {
      // تهيئة النظام
      await this.initialize();

      // بدء الخادم
      const server = this.app.listen(this.port, () => {
        this.state.isRunning = true;
        this.state.startedAt = new Date();

        console.log('🎉 الخادم الرسمي لنظام منتجاتي يعمل بنجاح!');
        console.log(`🌐 الرابط: https://clownfish-app-krnk9.ondigitalocean.app`);

        // بدء المراقبة الدورية للمخزون
        this.startInventoryMonitoring();
      });

      // إعداد timeout للخادم
      server.timeout = 30000; // 30 ثانية

      // استخدام النظام المتقدم فقط (بدون النظام الإنتاجي المتضارب)
      console.log('✅ النظام يعمل بخدمة المزامنة المتقدمة المدمجة');

      return server;

    } catch (error) {
      console.error('❌ خطأ في بدء تشغيل الخادم:', error);
      process.exit(1);
    }
  }

  // ===================================
  // فحص صحة النظام الشامل
  // ===================================
  async getSystemHealth() {
    try {
      const health = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: this.environment,
        server: {
          isInitialized: this.state.isInitialized,
          isRunning: this.state.isRunning,
          startedAt: this.state.startedAt
        },
        services: {},
        system: {
          memory: process.memoryUsage(),
          cpu: process.cpuUsage(),
          platform: process.platform,
          nodeVersion: process.version,
        },
        checks: []
      };

      // فحص خدمة الإشعارات
      if (this.state.services.notifications &&
          (this.state.services.notifications.state?.isInitialized ||
           this.state.services.notifications.isInitialized)) {
        health.services.notifications = 'healthy';
        health.checks.push({ service: 'notifications', status: 'pass' });
      } else {
        health.services.notifications = 'unhealthy';
        health.checks.push({
          service: 'notifications',
          status: 'fail',
          error: 'خدمة الإشعارات غير مهيأة'
        });
        health.status = 'degraded';
      }

      // فحص خدمة المزامنة
      if (this.state.services.sync &&
          (this.state.services.sync.state?.isInitialized ||
           this.state.services.sync.isInitialized)) {
        health.services.sync = 'healthy';
        health.checks.push({ service: 'sync', status: 'pass' });
      } else {
        health.services.sync = 'unhealthy';
        health.checks.push({
          service: 'sync',
          status: 'fail',
          error: 'خدمة المزامنة غير مهيأة'
        });
        health.status = 'degraded';
      }

      // فحص خدمة المراقبة
      if (this.state.services.monitor &&
          (this.state.services.monitor.state?.isInitialized ||
           this.state.services.monitor.isInitialized)) {
        health.services.monitor = 'healthy';
        health.checks.push({ service: 'monitor', status: 'pass' });
      } else {
        health.services.monitor = 'unhealthy';
        health.checks.push({
          service: 'monitor',
          status: 'fail',
          error: 'خدمة المراقبة غير مهيأة'
        });
        health.status = 'degraded';
      }

      return health;

    } catch (error) {
      return {
        status: 'error',
        timestamp: new Date().toISOString(),
        error: error.message,
        checks: [{ service: 'health_check', status: 'fail', error: error.message }]
      };
    }
  }

  // ===================================
  // تسجيل الأخطاء
  // ===================================
  async logError(error, req = null, service = 'server') {
    try {
      const errorLog = {
        timestamp: new Date().toISOString(),
        service: service,
        error: {
          message: error.message,
          stack: error.stack,
          name: error.name,
        },
        request: req ? {
          id: req.requestId,
          method: req.method,
          url: req.originalUrl,
          ip: req.ip,
          userAgent: req.get('User-Agent'),
        } : null,
        system: {
          uptime: process.uptime(),
          memory: process.memoryUsage(),
          platform: process.platform,
        }
      };

      // يمكن إضافة تسجيل في قاعدة البيانات هنا
      console.error('📝 تسجيل خطأ:', errorLog);

    } catch (logError) {
      console.error('❌ خطأ في تسجيل الخطأ:', logError);
    }
  }

  // ===================================
  // إغلاق آمن للنظام
  // ===================================
  async gracefulShutdown(signal) {
    console.log(`\n🛑 تلقي إشارة ${signal} - بدء الإغلاق الآمن...`);
    
    this.state.isRunning = false;

    try {
      // إيقاف الخدمات بالترتيب العكسي
      if (this.state.services.sync) {
        console.log('🔄 إيقاف خدمة المزامنة...');
        await this.state.services.sync.shutdown();
      }

      if (this.state.services.notifications) {
        console.log('🔔 إيقاف خدمة الإشعارات...');
        await this.state.services.notifications.shutdown();
      }

      if (this.state.services.monitor) {
        console.log('📊 إيقاف خدمة المراقبة...');
        await this.state.services.monitor.shutdown();
      }

      // إيقاف النظام الإنتاجي
      if (this.state.services.productionSync) {
        console.log('🚀 إيقاف النظام الإنتاجي...');
        await this.state.services.productionSync.stop();
      }

      console.log('✅ تم إيقاف جميع الخدمات بأمان');
      console.log('👋 وداعاً!');
      
      process.exit(0);

    } catch (error) {
      console.error('❌ خطأ في الإغلاق الآمن:', error);
      process.exit(1);
    }
  }
}

// تشغيل الخادم
if (require.main === module) {
  const server = new OfficialMontajatiServer();
  server.start().catch(console.error);
}

module.exports = OfficialMontajatiServer;
