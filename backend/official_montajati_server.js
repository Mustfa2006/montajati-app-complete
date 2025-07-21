// ===================================
// الخادم الرسمي المتكامل لنظام منتجاتي
// Official Integrated Montajati Server
// ===================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
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
        try {
          JSON.parse(buf);
        } catch (e) {
          res.status(400).json({
            success: false,
            message: 'بيانات JSON غير صحيحة'
          });
          throw new Error('Invalid JSON');
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
      
      res.status(err.status || 500).json({
        success: false,
        message: this.environment === 'production' 
          ? 'حدث خطأ داخلي في الخادم'
          : err.message,
        requestId: req.requestId,
        timestamp: new Date().toISOString()
      });
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
    try {
      // مسارات FCM
      const fcmRoutes = require('./routes/fcm_tokens');
      this.app.use('/api/fcm', fcmRoutes);

      // مسارات الإشعارات
      const notificationRoutes = require('./routes/notifications');
      this.app.use('/api/notifications', notificationRoutes);

      // مسارات الطلبات
      const orderRoutes = require('./routes/orders');
      this.app.use('/api/orders', orderRoutes);

      // مسارات المستخدمين
      const userRoutes = require('./routes/users');
      this.app.use('/api/users', userRoutes);

      // مسارات المنتجات
      const productRoutes = require('./routes/products');
      this.app.use('/api/products', productRoutes);

      // مسارات المصادقة
      const authRoutes = require('./routes/auth');
      this.app.use('/api/auth', authRoutes);

      console.log('✅ تم تحميل جميع المسارات الأساسية');

    } catch (error) {
      console.warn('⚠️ تحذير في تحميل بعض المسارات:', error.message);
    }
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
      console.log(`🚨 تنبيه النظام: ${alert.title}`);
      // يمكن إضافة إرسال تنبيهات للمدراء هنا
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

      // تهيئة خدمة المراقبة أولاً
      console.log('📊 تهيئة خدمة المراقبة...');
      await this.systemMonitor.initialize();
      this.state.services.monitor = this.systemMonitor;

      // تهيئة خدمة الإشعارات
      console.log('🔔 تهيئة خدمة الإشعارات...');
      await this.notificationManager.initialize();
      this.state.services.notifications = this.notificationManager;

      // تهيئة خدمة المزامنة (اختيارية)
      console.log('🔄 تهيئة خدمة المزامنة...');
      try {
        await this.syncManager.initialize();
        this.state.services.sync = this.syncManager;
        console.log('✅ تم تهيئة خدمة المزامنة بنجاح');
      } catch (error) {
        console.warn('⚠️ تحذير: فشل في تهيئة خدمة المزامنة، سيتم تشغيل النظام بدونها');
        console.warn(`   السبب: ${error.message}`);
        this.state.services.sync = null;
      }

      // تهيئة خدمة تنظيف FCM Tokens
      console.log('🧹 تهيئة خدمة تنظيف FCM Tokens...');
      try {
        this.fcmCleanupService.start();
        this.state.services.fcmCleanup = this.fcmCleanupService;
        console.log('✅ تم تهيئة خدمة تنظيف FCM Tokens بنجاح');
      } catch (error) {
        console.warn('⚠️ تحذير: فشل في تهيئة خدمة تنظيف FCM Tokens');
        console.warn(`   السبب: ${error.message}`);
        this.state.services.fcmCleanup = null;
      }

      this.state.isInitialized = true;
      console.log('✅ تم تهيئة جميع الخدمات بنجاح');

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

        console.log('\n' + '='.repeat(80));
        console.log('🎉 الخادم الرسمي لنظام منتجاتي يعمل بنجاح!');
        console.log('='.repeat(80));
        console.log(`🌐 الرابط: http://localhost:${this.port}`);
        console.log(`🔗 فحص الصحة: http://localhost:${this.port}/health`);
        console.log(`📊 حالة النظام: http://localhost:${this.port}/api/system/status`);
        console.log(`📱 إدارة الإشعارات: http://localhost:${this.port}/api/notifications`);
        console.log(`🔄 إدارة المزامنة: http://localhost:${this.port}/api/sync`);
        console.log(`📈 المراقبة: http://localhost:${this.port}/api/monitor`);
        console.log('='.repeat(80));
        console.log(`📅 تاريخ البدء: ${this.state.startedAt.toLocaleString('ar-IQ')}`);
        console.log(`🏷️ البيئة: ${this.environment}`);
        console.log(`🔧 إصدار Node.js: ${process.version}`);
        console.log('='.repeat(80));
      });

      // إعداد timeout للخادم
      server.timeout = 30000; // 30 ثانية

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
      if (this.state.services.notifications?.state.isInitialized) {
        health.services.notifications = 'healthy';
        health.checks.push({ service: 'notifications', status: 'pass' });
      } else {
        health.services.notifications = 'unhealthy';
        health.checks.push({ service: 'notifications', status: 'fail' });
        health.status = 'degraded';
      }

      // فحص خدمة المزامنة
      if (this.state.services.sync?.state.isInitialized) {
        health.services.sync = 'healthy';
        health.checks.push({ service: 'sync', status: 'pass' });
      } else {
        health.services.sync = 'unhealthy';
        health.checks.push({ service: 'sync', status: 'fail' });
        health.status = 'degraded';
      }

      // فحص خدمة المراقبة
      if (this.state.services.monitor?.state.isInitialized) {
        health.services.monitor = 'healthy';
        health.checks.push({ service: 'monitor', status: 'pass' });
      } else {
        health.services.monitor = 'unhealthy';
        health.checks.push({ service: 'monitor', status: 'fail' });
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
