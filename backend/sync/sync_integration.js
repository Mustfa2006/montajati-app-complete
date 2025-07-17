// ===================================
// تكامل نظام المزامنة مع الخادم الرئيسي
// تهيئة وتشغيل جميع خدمات المزامنة
// ===================================

const syncService = require('./order_status_sync_service');
const monitoringService = require('../monitoring/production_monitoring_service');
const notifier = require('./notifier');
const statusMapper = require('./status_mapper');

class SyncIntegration {
  constructor() {
    this.isInitialized = false;
    this.services = {
      sync: syncService,
      monitoring: monitoringService,
      notifier: notifier,
      statusMapper: statusMapper
    };

    console.log('🔗 تم تهيئة تكامل نظام المزامنة');
  }

  // ===================================
  // تهيئة جميع الخدمات
  // ===================================
  async initialize() {
    if (this.isInitialized) {
      console.log('⚠️ نظام المزامنة مهيأ بالفعل');
      return;
    }

    try {
      console.log('🚀 بدء تهيئة نظام المزامنة التلقائية...');

      // تشغيل فحص صحة أولي
      console.log('🏥 فحص صحة الخدمات...');
      const healthCheck = await this.runInitialHealthCheck();
      
      if (!healthCheck.success) {
        throw new Error(`فشل في فحص الصحة الأولي: ${healthCheck.error}`);
      }

      // بدء المزامنة التلقائية
      console.log('🔄 بدء المزامنة التلقائية...');
      this.services.sync.startAutoSync();

      // بدء المراقبة الدورية
      console.log('📊 بدء المراقبة الدورية...');
      this.startPeriodicMonitoring();

      // تسجيل بدء النظام
      await this.logSystemStart();

      this.isInitialized = true;
      console.log('✅ تم تهيئة نظام المزامنة التلقائية بنجاح');

      return {
        success: true,
        message: 'تم تهيئة نظام المزامنة بنجاح',
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ خطأ في تهيئة نظام المزامنة:', error.message);
      
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // فحص صحة أولي
  // ===================================
  async runInitialHealthCheck() {
    try {
      // فحص صحة خدمة المزامنة (مع تجاهل مشاكل تسجيل الدخول)
      const syncHealth = await this.services.sync.healthCheck();
      if (syncHealth.status === 'unhealthy' && !syncHealth.error?.includes('التوكن')) {
        throw new Error(`خدمة المزامنة غير صحية: ${syncHealth.error}`);
      }

      // فحص صحة خدمة الإشعارات
      const notifierHealth = await this.services.notifier.healthCheck();
      if (notifierHealth.status === 'unhealthy') {
        console.warn('⚠️ تحذير: خدمة الإشعارات غير صحية، ستعمل بدونها');
      }

      // فحص صحة النظام العام
      const systemHealth = await this.services.monitoring.runHealthCheck();
      if (systemHealth.overall_status === 'unhealthy') {
        throw new Error('النظام العام غير صحي');
      }

      return {
        success: true,
        health: {
          sync: syncHealth,
          notifier: notifierHealth,
          system: systemHealth
        }
      };

    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  // ===================================
  // بدء المراقبة الدورية
  // ===================================
  startPeriodicMonitoring() {
    // فحص صحة كل 5 دقائق
    setInterval(async () => {
      try {
        await this.services.monitoring.runHealthCheck();
      } catch (error) {
        console.error('❌ خطأ في فحص الصحة الدوري:', error.message);
      }
    }, 5 * 60 * 1000);

    // تنظيف السجلات القديمة كل يوم
    setInterval(async () => {
      try {
        await this.services.monitoring.cleanupOldLogs();
      } catch (error) {
        console.error('❌ خطأ في تنظيف السجلات:', error.message);
      }
    }, 24 * 60 * 60 * 1000);

    console.log('📊 تم بدء المراقبة الدورية');
  }

  // ===================================
  // تسجيل بدء النظام
  // ===================================
  async logSystemStart() {
    try {
      await this.services.sync.logSystemEvent('sync_system_started', {
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        services: Object.keys(this.services),
        node_version: process.version,
        platform: process.platform
      });
    } catch (error) {
      console.warn('⚠️ فشل في تسجيل بدء النظام:', error.message);
    }
  }

  // ===================================
  // إيقاف النظام بأمان
  // ===================================
  async shutdown() {
    try {
      console.log('🛑 بدء إيقاف نظام المزامنة...');

      // إيقاف المزامنة التلقائية
      this.services.sync.stopAutoSync();

      // تسجيل إيقاف النظام
      await this.services.sync.logSystemEvent('sync_system_stopped', {
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
      });

      this.isInitialized = false;
      console.log('✅ تم إيقاف نظام المزامنة بأمان');

    } catch (error) {
      console.error('❌ خطأ في إيقاف النظام:', error.message);
    }
  }

  // ===================================
  // الحصول على حالة النظام
  // ===================================
  async getSystemStatus() {
    try {
      const status = {
        initialized: this.isInitialized,
        timestamp: new Date().toISOString(),
        services: {}
      };

      // حالة خدمة المزامنة
      status.services.sync = {
        stats: this.services.sync.getSyncStats(),
        health: await this.services.sync.healthCheck()
      };

      // حالة خدمة المراقبة
      status.services.monitoring = {
        stats: this.services.monitoring.getSystemStats(),
        health: await this.services.monitoring.runHealthCheck()
      };

      // حالة خدمة الإشعارات
      status.services.notifier = {
        health: await this.services.notifier.healthCheck()
      };

      // إحصائيات خريطة الحالات
      status.services.statusMapper = {
        stats: this.services.statusMapper.getMapStats(),
        supported_statuses: this.services.statusMapper.getAllSupportedStatuses()
      };

      return status;

    } catch (error) {
      return {
        initialized: this.isInitialized,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // تشغيل مزامنة يدوية
  // ===================================
  async runManualSync() {
    try {
      console.log('🔄 تشغيل مزامنة يدوية...');
      
      await this.services.sync.runSyncCycle();
      
      return {
        success: true,
        message: 'تم تشغيل المزامنة اليدوية بنجاح',
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ خطأ في المزامنة اليدوية:', error.message);
      
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // إرسال إشعار مخصص
  // ===================================
  async sendCustomNotification(customerPhone, title, message, data = {}) {
    try {
      const result = await this.services.notifier.sendCustomNotification(
        customerPhone, 
        title, 
        message, 
        data
      );

      return {
        success: true,
        result,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // الحصول على إحصائيات مفصلة
  // ===================================
  async getDetailedStats() {
    try {
      const stats = {
        timestamp: new Date().toISOString(),
        system: this.services.monitoring.getSystemStats(),
        sync: this.services.sync.getSyncStats(),
        status_mapper: this.services.statusMapper.exportMapReport()
      };

      // إضافة إحصائيات قاعدة البيانات
      const healthReport = await this.services.monitoring.runHealthCheck();
      stats.database = healthReport.services.database;

      return stats;

    } catch (error) {
      return {
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // إعادة تشغيل النظام
  // ===================================
  async restart() {
    try {
      console.log('🔄 إعادة تشغيل نظام المزامنة...');
      
      await this.shutdown();
      await new Promise(resolve => setTimeout(resolve, 2000)); // انتظار ثانيتين
      await this.initialize();

      return {
        success: true,
        message: 'تم إعادة تشغيل النظام بنجاح',
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
}

// تصدير مثيل واحد من التكامل (Singleton)
const syncIntegration = new SyncIntegration();

module.exports = syncIntegration;
