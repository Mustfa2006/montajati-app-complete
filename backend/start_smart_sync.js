// ===================================
// تشغيل نظام المزامنة الذكي
// Start Smart Sync System
// ===================================

const SmartSyncService = require('./sync/smart_sync_service');
const express = require('express');
const cors = require('cors');
require('dotenv').config();

class SmartSyncManager {
  constructor() {
    this.app = express();
    this.port = process.env.SYNC_PORT || 3005;
    this.syncService = null;
    
    this.setupMiddleware();
    this.setupRoutes();
    
    console.log('🧠 تم تهيئة مدير المزامنة الذكي');
  }

  // ===================================
  // إعداد الوسطاء
  // ===================================
  setupMiddleware() {
    this.app.use(cors());
    this.app.use(express.json());
    
    // إضافة معلومات الطلب
    this.app.use((req, res, next) => {
      req.timestamp = new Date().toISOString();
      console.log(`📡 ${req.method} ${req.path} - ${req.timestamp}`);
      next();
    });
  }

  // ===================================
  // إعداد المسارات
  // ===================================
  setupRoutes() {
    // الصفحة الرئيسية
    this.app.get('/', (req, res) => {
      res.json({
        service: 'Smart Sync Service',
        status: 'running',
        version: '2.0.0',
        timestamp: new Date().toISOString(),
        endpoints: [
          'GET /status - حالة النظام',
          'GET /stats - إحصائيات مفصلة',
          'POST /sync/manual - مزامنة يدوية',
          'POST /sync/restart - إعادة تشغيل',
          'GET /health - فحص الصحة'
        ]
      });
    });

    // حالة النظام
    this.app.get('/status', (req, res) => {
      if (!this.syncService) {
        return res.status(503).json({
          status: 'not_initialized',
          message: 'خدمة المزامنة غير مهيأة'
        });
      }

      const stats = this.syncService.getDetailedStats();
      res.json({
        status: 'active',
        service: 'Smart Sync Service',
        ...stats,
        timestamp: new Date().toISOString()
      });
    });

    // إحصائيات مفصلة
    this.app.get('/stats', (req, res) => {
      if (!this.syncService) {
        return res.status(503).json({
          error: 'خدمة المزامنة غير مهيأة'
        });
      }

      const stats = this.syncService.getDetailedStats();
      res.json({
        detailed_stats: stats,
        system_info: {
          node_version: process.version,
          platform: process.platform,
          memory_usage: process.memoryUsage(),
          uptime: process.uptime()
        },
        timestamp: new Date().toISOString()
      });
    });

    // مزامنة يدوية
    this.app.post('/sync/manual', async (req, res) => {
      if (!this.syncService) {
        return res.status(503).json({
          error: 'خدمة المزامنة غير مهيأة'
        });
      }

      try {
        console.log('🔄 بدء مزامنة يدوية...');
        await this.syncService.runSmartSyncCycle();
        
        res.json({
          success: true,
          message: 'تم تشغيل المزامنة اليدوية بنجاح',
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('❌ خطأ في المزامنة اليدوية:', error.message);
        res.status(500).json({
          success: false,
          error: error.message,
          timestamp: new Date().toISOString()
        });
      }
    });

    // إعادة تشغيل النظام
    this.app.post('/sync/restart', async (req, res) => {
      try {
        console.log('🔄 إعادة تشغيل نظام المزامنة...');
        
        // إيقاف النظام الحالي
        if (this.syncService) {
          console.log('🛑 إيقاف النظام الحالي...');
        }

        // بدء نظام جديد
        await this.initializeSyncService();
        
        res.json({
          success: true,
          message: 'تم إعادة تشغيل النظام بنجاح',
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('❌ خطأ في إعادة التشغيل:', error.message);
        res.status(500).json({
          success: false,
          error: error.message,
          timestamp: new Date().toISOString()
        });
      }
    });

    // فحص الصحة
    this.app.get('/health', (req, res) => {
      const health = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        checks: {
          sync_service: this.syncService ? 'active' : 'inactive',
          memory: process.memoryUsage(),
          uptime: process.uptime()
        }
      };

      if (this.syncService) {
        const stats = this.syncService.getDetailedStats();
        health.checks.last_sync = stats.lastSyncTime;
        health.checks.success_rate = stats.successRate;
        health.checks.is_running = stats.isRunning;
      }

      res.json(health);
    });

    // معالجة الأخطاء
    this.app.use((error, req, res, next) => {
      console.error('❌ خطأ في الخادم:', error.message);
      res.status(500).json({
        error: 'خطأ داخلي في الخادم',
        message: error.message,
        timestamp: new Date().toISOString()
      });
    });
  }

  // ===================================
  // تهيئة خدمة المزامنة
  // ===================================
  async initializeSyncService() {
    try {
      console.log('🔧 تهيئة خدمة المزامنة الذكية...');
      
      this.syncService = new SmartSyncService();
      
      // بدء المزامنة التلقائية
      this.syncService.startSmartAutoSync();
      
      console.log('✅ تم تهيئة خدمة المزامنة الذكية بنجاح');
      return true;
    } catch (error) {
      console.error('❌ فشل في تهيئة خدمة المزامنة:', error.message);
      throw error;
    }
  }

  // ===================================
  // بدء الخادم
  // ===================================
  async start() {
    try {
      console.log('🚀 بدء تشغيل نظام المزامنة الذكي...\n');
      
      // تهيئة خدمة المزامنة
      await this.initializeSyncService();
      
      // بدء الخادم
      this.app.listen(this.port, () => {
        console.log('\n' + '🎉'.repeat(50));
        console.log('نظام المزامنة الذكي يعمل بنجاح!');
        console.log('🎉'.repeat(50));
        console.log(`🌐 الخادم: http://localhost:${this.port}`);
        console.log(`📊 الإحصائيات: http://localhost:${this.port}/stats`);
        console.log(`🔍 الحالة: http://localhost:${this.port}/status`);
        console.log(`💚 الصحة: http://localhost:${this.port}/health`);
        console.log('🎉'.repeat(50));
      });

      // معالجة إشارات النظام
      process.on('SIGINT', () => {
        console.log('\n🛑 تم استلام إشارة الإيقاف...');
        console.log('🔄 إيقاف النظام بأمان...');
        process.exit(0);
      });

      process.on('SIGTERM', () => {
        console.log('\n🛑 تم استلام إشارة الإنهاء...');
        console.log('🔄 إيقاف النظام بأمان...');
        process.exit(0);
      });

    } catch (error) {
      console.error('❌ فشل في بدء النظام:', error.message);
      process.exit(1);
    }
  }
}

// تشغيل النظام
async function main() {
  const manager = new SmartSyncManager();
  await manager.start();
}

// تشغيل النظام إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  main().catch(error => {
    console.error('❌ خطأ في تشغيل النظام:', error.message);
    process.exit(1);
  });
}

module.exports = SmartSyncManager;
