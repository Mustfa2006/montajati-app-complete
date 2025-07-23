// ===================================
// النظام الإنتاجي الرئيسي لمزامنة حالات الطلبات
// Main Production System for Order Status Sync
// ===================================

const config = require('./config');
const logger = require('./logger');
const ProductionSyncService = require('./sync_service');
const ProductionMonitoring = require('./monitoring');

class MontajatiProductionSystem {
  constructor() {
    this.syncService = null;
    this.monitoring = null;
    this.isRunning = false;
    this.startTime = null;
    
    // معالجة إشارات النظام
    this.setupSignalHandlers();
    
    // تهيئة النظام الإنتاجي بصمت
  }

  /**
   * بدء النظام الإنتاجي
   */
  async start() {
    if (this.isRunning) {
      logger.warn('⚠️ النظام يعمل بالفعل');
      return;
    }

    try {
      this.startTime = new Date();
      
      // بدء النظام الإنتاجي بصمت
      
      // التحقق من التكوين
      await this.validateSystem();
      
      // تهيئة الخدمات
      await this.initializeServices();
      
      // بدء الخدمات
      await this.startServices();
      
      this.isRunning = true;
      
      // تم بدء النظام بنجاح
      console.log('✅ تم بدء النظام الإنتاجي بنجاح');

    } catch (error) {
      await logger.critical('❌ فشل بدء النظام الإنتاجي', {
        error: error.message,
        stack: error.stack
      });
      
      console.error('\n🚨 فشل بدء النظام:');
      console.error(`❌ ${error.message}`);
      console.error('\n📋 تحقق من:');
      console.error('   1. متغيرات البيئة (.env)');
      console.error('   2. الاتصال بقاعدة البيانات');
      console.error('   3. الاتصال بشركة الوسيط');
      console.error('   4. صحة التكوين\n');
      
      process.exit(1);
    }
  }

  /**
   * إيقاف النظام
   */
  async stop() {
    if (!this.isRunning) {
      logger.warn('⚠️ النظام متوقف بالفعل');
      return;
    }

    try {
      logger.info('🛑 بدء إيقاف النظام الإنتاجي...');
      
      // إيقاف الخدمات
      await this.stopServices();
      
      this.isRunning = false;
      
      const uptime = Date.now() - this.startTime.getTime();
      
      await logger.info('✅ تم إيقاف النظام الإنتاجي بنجاح', {
        uptime: uptime,
        stopTime: new Date().toISOString()
      });

      console.log('\n✅ تم إيقاف النظام بنجاح');
      console.log(`⏱️ مدة التشغيل: ${this.formatUptime(uptime)}`);

    } catch (error) {
      await logger.error('❌ خطأ في إيقاف النظام', {
        error: error.message
      });
      
      console.error(`❌ خطأ في إيقاف النظام: ${error.message}`);
    }
  }

  /**
   * عرض شعار النظام
   */
  displaySystemBanner() {
    const systemInfo = config.getSystemInfo();
    
    console.log('\n' + '='.repeat(80));
    console.log('🎯 نظام مزامنة حالات الطلبات - منتجاتي');
    console.log('   Montajati Order Status Sync System');
    console.log('='.repeat(80));
    console.log(`📋 النظام: ${systemInfo.name}`);
    console.log(`🔢 الإصدار: ${systemInfo.version}`);
    console.log(`🌍 البيئة: ${systemInfo.environment}`);
    console.log(`🖥️ المنصة: ${systemInfo.platform}`);
    console.log(`⚡ Node.js: ${systemInfo.nodeVersion}`);
    console.log(`🆔 معرف العملية: ${systemInfo.pid}`);
    console.log(`📅 وقت البدء: ${new Date().toLocaleString('ar-IQ')}`);
    console.log('='.repeat(80));
  }

  /**
   * التحقق من صحة النظام
   */
  async validateSystem() {
    // التحقق من صحة النظام بصمت
    
    // التحقق من متغيرات البيئة
    const requiredEnvVars = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'WASEET_USERNAME',
      'WASEET_PASSWORD'
    ];

    const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
      throw new Error(`متغيرات البيئة المطلوبة مفقودة: ${missingVars.join(', ')}`);
    }

    // التحقق من إنشاء المجلدات
    config.createDirectories();
    
    // تم التحقق من صحة النظام بصمت
  }

  /**
   * تهيئة الخدمات
   */
  async initializeServices() {
    // تهيئة الخدمات بصمت
    this.syncService = new ProductionSyncService();
    this.monitoring = new ProductionMonitoring();
  }

  /**
   * بدء الخدمات
   */
  async startServices() {
    // بدء الخدمات بصمت
    await this.monitoring.start();
    await this.syncService.start();
    this.optimizeMemoryUsage();
  }

  /**
   * إيقاف الخدمات
   */
  async stopServices() {
    logger.info('🛑 إيقاف الخدمات...');
    
    // إيقاف خدمة المزامنة
    if (this.syncService) {
      await this.syncService.stop();
      logger.info('✅ تم إيقاف خدمة المزامنة');
    }
    
    // إيقاف نظام المراقبة
    if (this.monitoring) {
      await this.monitoring.stop();
      logger.info('✅ تم إيقاف نظام المراقبة');
    }
    
    logger.info('✅ تم إيقاف جميع الخدمات');
  }

  /**
   * إعداد معالجات إشارات النظام
   */
  setupSignalHandlers() {
    // معالجة إشارة الإيقاف العادي
    process.on('SIGTERM', async () => {
      console.log('\n📨 تم استلام إشارة SIGTERM - إيقاف النظام...');
      await this.stop();
      process.exit(0);
    });

    // معالجة إشارة المقاطعة (Ctrl+C)
    process.on('SIGINT', async () => {
      console.log('\n📨 تم استلام إشارة SIGINT - إيقاف النظام...');
      await this.stop();
      process.exit(0);
    });

    // معالجة الأخطاء غير المعالجة
    process.on('uncaughtException', async (error) => {
      await logger.critical('💥 خطأ غير معالج', {
        error: error.message,
        stack: error.stack
      });
      
      console.error('\n💥 خطأ غير معالج:');
      console.error(error);
      
      await this.stop();
      process.exit(1);
    });

    // معالجة الوعود المرفوضة
    process.on('unhandledRejection', async (reason, promise) => {
      await logger.critical('💥 وعد مرفوض غير معالج', {
        reason: reason?.toString(),
        promise: promise?.toString()
      });
      
      console.error('\n💥 وعد مرفوض غير معالج:');
      console.error(reason);
      
      await this.stop();
      process.exit(1);
    });
  }

  /**
   * تسجيل معلومات النظام
   */
  logSystemInfo() {
    const systemInfo = config.getSystemInfo();
    
    logger.info('📊 معلومات النظام', {
      name: systemInfo.name,
      version: systemInfo.version,
      environment: systemInfo.environment,
      platform: systemInfo.platform,
      nodeVersion: systemInfo.nodeVersion,
      pid: systemInfo.pid,
      memory: systemInfo.memory
    });
  }

  /**
   * تحسين استخدام الذاكرة
   */
  optimizeMemoryUsage() {
    try {
      // تشغيل garbage collection إذا كان متاحاً
      if (global.gc) {
        global.gc();
        logger.info('🧹 تم تشغيل garbage collection');
      }

      // تعيين حدود الذاكرة
      if (process.env.NODE_OPTIONS && !process.env.NODE_OPTIONS.includes('--max-old-space-size')) {
        logger.warn('⚠️ يُنصح بتعيين --max-old-space-size=512 لتحسين الذاكرة');
      }

      // مراقبة استخدام الذاكرة
      const memUsage = process.memoryUsage();
      const memUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024);
      const memTotalMB = Math.round(memUsage.heapTotal / 1024 / 1024);

      // مراقبة الذاكرة بصمت

      // تحذير إذا كان الاستخدام عالي
      if (memUsedMB > 400) {
        logger.warn(`⚠️ استخدام ذاكرة عالي: ${memUsedMB}MB`);
      }

    } catch (error) {
      logger.error('❌ خطأ في تحسين الذاكرة', { error: error.message });
    }
  }

  /**
   * عرض رسالة النجاح
   */
  displaySuccessMessage() {
    const syncConfig = config.get('sync');
    const monitoringConfig = config.get('monitoring');
    
    console.log('\n🎉 تم بدء النظام الإنتاجي بنجاح!');
    console.log('='.repeat(50));
    console.log('📊 حالة الخدمات:');
    console.log(`   🔄 المزامنة: نشطة (كل ${syncConfig.interval / 1000} ثانية)`);
    console.log(`   📊 المراقبة: نشطة (كل ${monitoringConfig.healthCheckInterval / 1000} ثانية)`);
    console.log(`   📝 التسجيل: نشط`);
    console.log(`   🚨 التنبيهات: ${monitoringConfig.alerting.enabled ? 'نشطة' : 'معطلة'}`);
    console.log('\n🎯 الوظائف:');
    console.log('   ✅ جلب الحالات من شركة الوسيط');
    console.log('   ✅ تحديث قاعدة البيانات فورياً');
    console.log('   ✅ دعم جميع الحالات الـ 20');
    console.log('   ✅ مراقبة مستمرة للنظام');
    console.log('   ✅ تسجيل شامل للأحداث');
    console.log('   ✅ إشعارات تلقائية للمشاكل');
    console.log('\n📋 للمراقبة:');
    console.log('   📊 تحقق من السجلات في: backend/logs/');
    console.log('   📈 راقب الأداء عبر قاعدة البيانات');
    console.log('   🚨 ستصل التنبيهات عند حدوث مشاكل');
    console.log('\n⏹️ لإيقاف النظام: اضغط Ctrl+C');
    console.log('='.repeat(50));
  }

  /**
   * تنسيق وقت التشغيل
   */
  formatUptime(milliseconds) {
    const seconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return `${days} يوم، ${hours % 24} ساعة، ${minutes % 60} دقيقة`;
    } else if (hours > 0) {
      return `${hours} ساعة، ${minutes % 60} دقيقة`;
    } else if (minutes > 0) {
      return `${minutes} دقيقة، ${seconds % 60} ثانية`;
    } else {
      return `${seconds} ثانية`;
    }
  }

  /**
   * الحصول على حالة النظام
   */
  getStatus() {
    return {
      isRunning: this.isRunning,
      startTime: this.startTime?.toISOString(),
      uptime: this.startTime ? Date.now() - this.startTime.getTime() : 0,
      services: {
        sync: this.syncService?.getStatus(),
        monitoring: this.monitoring?.getStatus()
      },
      system: config.getSystemInfo()
    };
  }

  /**
   * إعادة تشغيل النظام
   */
  async restart() {
    logger.info('🔄 إعادة تشغيل النظام...');
    
    await this.stop();
    await new Promise(resolve => setTimeout(resolve, 2000)); // انتظار ثانيتين
    await this.start();
    
    logger.info('✅ تم إعادة تشغيل النظام بنجاح');
  }
}

// إنشاء وتشغيل النظام
const productionSystem = new MontajatiProductionSystem();

// تشغيل النظام إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  productionSystem.start().catch(error => {
    console.error('💥 فشل بدء النظام:', error.message);
    process.exit(1);
  });
}

module.exports = productionSystem;
