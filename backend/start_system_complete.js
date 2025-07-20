// ===================================
// تشغيل النظام الكامل مع جميع الخدمات
// ===================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');

// استيراد الخدمات الأساسية فقط
const { firebaseConfig } = require('./config/firebase');
const SimpleNotificationProcessor = require('./notification_processor_simple');
const OrderStatusSyncService = require('./sync/order_status_sync_service');

class SystemManager {
  constructor() {
    this.app = express();
    this.port = process.env.PORT || 3003;
    this.services = {};
    this.isRunning = false;

    // تهيئة معالج الإشعارات البسيط
    this.notificationProcessor = new SimpleNotificationProcessor();

    this.setupExpress();
  }

  // ===================================
  // إعداد Express
  // ===================================
  setupExpress() {
    // إعدادات أساسية
    this.app.use(cors());
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));

    // مسار الصحة
    this.app.get('/health', async (req, res) => {
      const health = await this.getSystemHealth();
      res.json(health);
    });

    // مسار حالة الخدمات
    this.app.get('/services/status', (req, res) => {
      res.json(this.getServicesStatus());
    });

    // مسار اختبار النظام
    this.app.get('/test', async (req, res) => {
      try {
        const tester = new SystemTester();
        await tester.runAllTests();
        res.json({
          success: true,
          results: tester.results
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });

    // مسار إعادة تشغيل الخدمات
    this.app.post('/services/restart', async (req, res) => {
      try {
        await this.restartServices();
        res.json({
          success: true,
          message: 'تم إعادة تشغيل الخدمات بنجاح'
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });
  }

  // ===================================
  // تهيئة جميع الخدمات
  // ===================================
  async initializeServices() {
    console.log('🚀 تهيئة جميع خدمات النظام...');

    try {
      // تم إزالة نظام Firebase والإشعارات
      console.log('⚠️ تم إزالة نظام Firebase والإشعارات من التطبيق');
      this.services.firebase = { status: 'removed', initialized: false };

      // 2. تهيئة Telegram
      console.log('📱 تهيئة خدمة Telegram...');
      try {
        this.services.telegram = new TelegramNotificationService();
        const telegramTest = await this.services.telegram.testConnection();
        
        if (telegramTest.success) {
          console.log('✅ خدمة Telegram تعمل بنجاح');
          this.services.telegram.status = 'active';
        } else {
          console.warn('⚠️ خدمة Telegram معطلة:', telegramTest.error);
          this.services.telegram.status = 'disabled';
        }
      } catch (error) {
        console.error('❌ خطأ في تهيئة Telegram:', error.message);
        this.services.telegram = { status: 'error', error: error.message };
      }

      // 3. تهيئة خدمة مزامنة الطلبات
      console.log('🔄 تهيئة خدمة مزامنة الطلبات...');
      try {
        this.services.orderSync = new OrderStatusSyncService();
        await this.services.orderSync.initialize();
        this.services.orderSync.status = 'active';
        console.log('✅ خدمة مزامنة الطلبات مهيأة');
      } catch (error) {
        console.error('❌ خطأ في تهيئة مزامنة الطلبات:', error.message);
        this.services.orderSync = { status: 'error', error: error.message };
      }

      // 4. تهيئة خدمة الإشعارات الرئيسية
      console.log('🔔 تهيئة خدمة الإشعارات الرئيسية...');
      try {
        this.services.notifications = new NotificationMasterService();
        await this.services.notifications.startAllServices();
        this.services.notifications.status = 'active';
        console.log('✅ خدمة الإشعارات الرئيسية مهيأة');
      } catch (error) {
        console.error('❌ خطأ في تهيئة الإشعارات:', error.message);
        this.services.notifications = { status: 'error', error: error.message };
      }

      console.log('✅ تم تهيئة جميع الخدمات');

    } catch (error) {
      console.error('❌ خطأ في تهيئة الخدمات:', error.message);
      throw error;
    }
  }

  // ===================================
  // بدء المزامنة التلقائية
  // ===================================
  startAutoSync() {
    console.log('🔄 بدء المزامنة التلقائية...');
    
    if (this.services.orderSync && this.services.orderSync.status === 'active') {
      try {
        this.services.orderSync.startAutoSync();
        console.log('✅ تم تفعيل المزامنة التلقائية');
      } catch (error) {
        console.error('❌ خطأ في بدء المزامنة التلقائية:', error.message);
      }
    } else {
      console.warn('⚠️ خدمة مزامنة الطلبات غير متاحة');
    }
  }

  // ===================================
  // الحصول على حالة النظام
  // ===================================
  async getSystemHealth() {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {},
      uptime: process.uptime()
    };

    // فحص كل خدمة
    for (const [name, service] of Object.entries(this.services)) {
      if (service && typeof service === 'object') {
        health.services[name] = {
          status: service.status || 'unknown',
          error: service.error || null
        };
      }
    }

    // تحديد الحالة العامة
    const hasErrors = Object.values(health.services).some(s => s.status === 'error');
    const hasDisabled = Object.values(health.services).some(s => s.status === 'disabled');
    
    if (hasErrors) {
      health.status = 'degraded';
    } else if (hasDisabled) {
      health.status = 'partial';
    }

    return health;
  }

  // ===================================
  // الحصول على حالة الخدمات
  // ===================================
  getServicesStatus() {
    const status = {
      timestamp: new Date().toISOString(),
      services: {}
    };

    for (const [name, service] of Object.entries(this.services)) {
      if (service && typeof service === 'object') {
        status.services[name] = {
          status: service.status || 'unknown',
          error: service.error || null,
          stats: service.getSyncStats ? service.getSyncStats() : null
        };
      }
    }

    return status;
  }

  // ===================================
  // إعادة تشغيل الخدمات
  // ===================================
  async restartServices() {
    console.log('🔄 إعادة تشغيل الخدمات...');
    
    // إيقاف الخدمات الحالية
    if (this.services.orderSync && this.services.orderSync.stopAutoSync) {
      this.services.orderSync.stopAutoSync();
    }
    
    if (this.services.notifications && this.services.notifications.stopAllServices) {
      await this.services.notifications.stopAllServices();
    }

    // إعادة تهيئة الخدمات
    await this.initializeServices();
    this.startAutoSync();
    
    console.log('✅ تم إعادة تشغيل الخدمات بنجاح');
  }

  // ===================================
  // بدء تشغيل النظام الكامل
  // ===================================
  async start() {
    try {
      console.log('🚀 بدء تشغيل النظام الكامل...');
      console.log(`📊 البيئة: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🌐 المنفذ: ${this.port}`);

      // تهيئة الخدمات
      await this.initializeServices();

      // بدء المزامنة التلقائية
      this.startAutoSync();

      // بدء الخادم
      this.app.listen(this.port, () => {
        console.log('\n' + '='.repeat(50));
        console.log('🎉 النظام يعمل بنجاح!');
        console.log(`🌐 الرابط: http://localhost:${this.port}`);
        console.log(`🔗 فحص الصحة: http://localhost:${this.port}/health`);
        console.log(`📊 حالة الخدمات: http://localhost:${this.port}/services/status`);
        console.log(`🧪 اختبار النظام: http://localhost:${this.port}/test`);
        console.log('='.repeat(50));
        
        this.isRunning = true;
      });

      // معالجة إشارات الإغلاق
      process.on('SIGTERM', () => this.gracefulShutdown());
      process.on('SIGINT', () => this.gracefulShutdown());

    } catch (error) {
      console.error('❌ خطأ في بدء تشغيل النظام:', error.message);
      process.exit(1);
    }
  }

  // ===================================
  // إغلاق النظام بأمان
  // ===================================
  async gracefulShutdown() {
    console.log('\n🛑 بدء إغلاق النظام بأمان...');
    
    this.isRunning = false;
    
    // إيقاف المزامنة
    if (this.services.orderSync && this.services.orderSync.stopAutoSync) {
      this.services.orderSync.stopAutoSync();
    }
    
    // إيقاف الإشعارات
    if (this.services.notifications && this.services.notifications.stopAllServices) {
      await this.services.notifications.stopAllServices();
    }
    
    console.log('✅ تم إغلاق النظام بأمان');
    process.exit(0);
  }
}

// تشغيل النظام
if (require.main === module) {
  const systemManager = new SystemManager();
  systemManager.start().catch(console.error);
}

module.exports = SystemManager;
