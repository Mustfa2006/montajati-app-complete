// ===================================
// واجهة الإدارة للنظام الإنتاجي
// Production System Admin Interface
// ===================================

const express = require('express');
const path = require('path');
const config = require('./config');
const logger = require('./logger');

class AdminInterface {
  constructor(productionSystem) {
    this.app = express();
    this.server = null;
    this.productionSystem = productionSystem;
    this.config = config.get('admin');
    
    this.setupMiddleware();
    this.setupRoutes();
    
    logger.info('🖥️ تم تهيئة واجهة الإدارة');
  }

  /**
   * إعداد الوسطاء
   */
  setupMiddleware() {
    // تحليل JSON
    this.app.use(express.json());
    
    // تحليل URL encoded
    this.app.use(express.urlencoded({ extended: true }));
    
    // إعداد الملفات الثابتة
    this.app.use('/static', express.static(path.join(__dirname, 'admin_static')));
    
    // تسجيل الطلبات
    this.app.use((req, res, next) => {
      logger.debug(`📡 طلب إداري: ${req.method} ${req.path}`, {
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });
      next();
    });

    // المصادقة البسيطة
    if (this.config.enableAuth) {
      this.app.use(this.basicAuth.bind(this));
    }
  }

  /**
   * المصادقة الأساسية
   */
  basicAuth(req, res, next) {
    // تجاهل المصادقة للملفات الثابتة
    if (req.path.startsWith('/static')) {
      return next();
    }

    const auth = req.headers.authorization;
    
    if (!auth || !auth.startsWith('Basic ')) {
      res.setHeader('WWW-Authenticate', 'Basic realm="Admin Interface"');
      return res.status(401).json({ error: 'مطلوب تسجيل دخول' });
    }

    const credentials = Buffer.from(auth.slice(6), 'base64').toString().split(':');
    const [username, password] = credentials;

    if (username !== this.config.username || password !== this.config.password) {
      return res.status(401).json({ error: 'بيانات دخول خاطئة' });
    }

    next();
  }

  /**
   * إعداد المسارات
   */
  setupRoutes() {
    // الصفحة الرئيسية
    this.app.get('/', this.getHomePage.bind(this));
    
    // حالة النظام
    this.app.get('/api/status', this.getSystemStatus.bind(this));
    
    // إحصائيات المزامنة
    this.app.get('/api/sync/stats', this.getSyncStats.bind(this));
    
    // إحصائيات المراقبة
    this.app.get('/api/monitoring/metrics', this.getMonitoringMetrics.bind(this));
    
    // السجلات
    this.app.get('/api/logs', this.getLogs.bind(this));
    
    // تحكم في النظام
    this.app.post('/api/system/restart', this.restartSystem.bind(this));
    this.app.post('/api/system/stop', this.stopSystem.bind(this));
    
    // تحكم في المزامنة
    this.app.post('/api/sync/start', this.startSync.bind(this));
    this.app.post('/api/sync/stop', this.stopSync.bind(this));
    this.app.post('/api/sync/trigger', this.triggerSync.bind(this));
    
    // إعادة تعيين الإحصائيات
    this.app.post('/api/stats/reset', this.resetStats.bind(this));
    
    // معالجة الأخطاء
    this.app.use(this.errorHandler.bind(this));
  }

  /**
   * الصفحة الرئيسية
   */
  async getHomePage(req, res) {
    try {
      const html = this.generateHomePage();
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.send(html);
    } catch (error) {
      logger.error('❌ خطأ في عرض الصفحة الرئيسية', { error: error.message });
      res.status(500).json({ error: 'خطأ في الخادم' });
    }
  }

  /**
   * إنشاء الصفحة الرئيسية
   */
  generateHomePage() {
    const systemInfo = config.getSystemInfo();
    const status = this.productionSystem.getStatus();
    
    return `
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>لوحة تحكم نظام مزامنة الطلبات</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .card { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status-good { color: #27ae60; }
        .status-warning { color: #f39c12; }
        .status-error { color: #e74c3c; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .btn { padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; margin: 5px; }
        .btn-primary { background: #3498db; color: white; }
        .btn-success { background: #27ae60; color: white; }
        .btn-warning { background: #f39c12; color: white; }
        .btn-danger { background: #e74c3c; color: white; }
        .metric { display: flex; justify-content: space-between; margin: 10px 0; }
        .refresh-btn { position: fixed; top: 20px; left: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎯 لوحة تحكم نظام مزامنة الطلبات</h1>
            <p>النظام: ${systemInfo.name} - الإصدار: ${systemInfo.version}</p>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>📊 حالة النظام</h3>
                <div class="metric">
                    <span>حالة التشغيل:</span>
                    <span class="${status.isRunning ? 'status-good' : 'status-error'}">
                        ${status.isRunning ? '🟢 يعمل' : '🔴 متوقف'}
                    </span>
                </div>
                <div class="metric">
                    <span>وقت البدء:</span>
                    <span>${status.startTime ? new Date(status.startTime).toLocaleString('ar-IQ') : 'غير محدد'}</span>
                </div>
                <div class="metric">
                    <span>مدة التشغيل:</span>
                    <span>${this.formatUptime(status.uptime)}</span>
                </div>
                <div class="metric">
                    <span>معرف العملية:</span>
                    <span>${systemInfo.pid}</span>
                </div>
            </div>
            
            <div class="card">
                <h3>🔄 حالة المزامنة</h3>
                <div class="metric">
                    <span>حالة الخدمة:</span>
                    <span class="${status.services?.sync?.isRunning ? 'status-good' : 'status-error'}">
                        ${status.services?.sync?.isRunning ? '🟢 نشطة' : '🔴 متوقفة'}
                    </span>
                </div>
                <div class="metric">
                    <span>عدد المزامنات:</span>
                    <span>${status.services?.sync?.syncCount || 0}</span>
                </div>
                <div class="metric">
                    <span>آخر مزامنة:</span>
                    <span>${status.services?.sync?.lastSyncTime ? new Date(status.services.sync.lastSyncTime).toLocaleString('ar-IQ') : 'لم تتم بعد'}</span>
                </div>
            </div>
            
            <div class="card">
                <h3>📊 حالة المراقبة</h3>
                <div class="metric">
                    <span>حالة الخدمة:</span>
                    <span class="${status.services?.monitoring?.isMonitoring ? 'status-good' : 'status-error'}">
                        ${status.services?.monitoring?.isMonitoring ? '🟢 نشطة' : '🔴 متوقفة'}
                    </span>
                </div>
                <div class="metric">
                    <span>آخر فحص:</span>
                    <span>${status.services?.monitoring?.lastHealthCheck ? new Date(status.services.monitoring.lastHealthCheck).toLocaleString('ar-IQ') : 'لم يتم بعد'}</span>
                </div>
                <div class="metric">
                    <span>التنبيهات النشطة:</span>
                    <span>${status.services?.monitoring?.activeAlertsCount || 0}</span>
                </div>
            </div>
            
            <div class="card">
                <h3>⚙️ التحكم في النظام</h3>
                <button class="btn btn-warning" onclick="restartSystem()">🔄 إعادة تشغيل النظام</button>
                <button class="btn btn-danger" onclick="stopSystem()">🛑 إيقاف النظام</button>
                <button class="btn btn-success" onclick="triggerSync()">🔄 تشغيل مزامنة فورية</button>
                <button class="btn btn-primary" onclick="resetStats()">📊 إعادة تعيين الإحصائيات</button>
            </div>
        </div>
    </div>
    
    <button class="btn btn-primary refresh-btn" onclick="location.reload()">🔄 تحديث</button>
    
    <script>
        async function restartSystem() {
            if (confirm('هل أنت متأكد من إعادة تشغيل النظام؟')) {
                try {
                    const response = await fetch('/api/system/restart', { method: 'POST' });
                    const result = await response.json();
                    alert(result.message || 'تم إعادة تشغيل النظام');
                    setTimeout(() => location.reload(), 3000);
                } catch (error) {
                    alert('خطأ: ' + error.message);
                }
            }
        }
        
        async function stopSystem() {
            if (confirm('هل أنت متأكد من إيقاف النظام؟')) {
                try {
                    const response = await fetch('/api/system/stop', { method: 'POST' });
                    const result = await response.json();
                    alert(result.message || 'تم إيقاف النظام');
                    setTimeout(() => location.reload(), 2000);
                } catch (error) {
                    alert('خطأ: ' + error.message);
                }
            }
        }
        
        async function triggerSync() {
            try {
                const response = await fetch('/api/sync/trigger', { method: 'POST' });
                const result = await response.json();
                alert(result.message || 'تم تشغيل المزامنة');
                setTimeout(() => location.reload(), 2000);
            } catch (error) {
                alert('خطأ: ' + error.message);
            }
        }
        
        async function resetStats() {
            if (confirm('هل أنت متأكد من إعادة تعيين الإحصائيات؟')) {
                try {
                    const response = await fetch('/api/stats/reset', { method: 'POST' });
                    const result = await response.json();
                    alert(result.message || 'تم إعادة تعيين الإحصائيات');
                    location.reload();
                } catch (error) {
                    alert('خطأ: ' + error.message);
                }
            }
        }
        
        // تحديث تلقائي كل 30 ثانية
        setInterval(() => {
            location.reload();
        }, 30000);
    </script>
</body>
</html>`;
  }

  /**
   * حالة النظام
   */
  async getSystemStatus(req, res) {
    try {
      const status = this.productionSystem.getStatus();
      res.json(status);
    } catch (error) {
      logger.error('❌ خطأ في جلب حالة النظام', { error: error.message });
      res.status(500).json({ error: 'خطأ في الخادم' });
    }
  }

  /**
   * إحصائيات المزامنة
   */
  async getSyncStats(req, res) {
    try {
      const syncService = this.productionSystem.syncService;
      const stats = syncService ? syncService.getStatus() : null;
      res.json(stats);
    } catch (error) {
      logger.error('❌ خطأ في جلب إحصائيات المزامنة', { error: error.message });
      res.status(500).json({ error: 'خطأ في الخادم' });
    }
  }

  /**
   * مقاييس المراقبة
   */
  async getMonitoringMetrics(req, res) {
    try {
      const monitoring = this.productionSystem.monitoring;
      const metrics = monitoring ? monitoring.getMetrics() : null;
      res.json(metrics);
    } catch (error) {
      logger.error('❌ خطأ في جلب مقاييس المراقبة', { error: error.message });
      res.status(500).json({ error: 'خطأ في الخادم' });
    }
  }

  /**
   * السجلات
   */
  async getLogs(req, res) {
    try {
      const { hours = 24 } = req.query;
      const stats = await logger.getLogStats(parseInt(hours));
      res.json(stats);
    } catch (error) {
      logger.error('❌ خطأ في جلب السجلات', { error: error.message });
      res.status(500).json({ error: 'خطأ في الخادم' });
    }
  }

  /**
   * إعادة تشغيل النظام
   */
  async restartSystem(req, res) {
    try {
      logger.info('🔄 طلب إعادة تشغيل النظام من واجهة الإدارة');
      
      // إعادة تشغيل في الخلفية
      setTimeout(async () => {
        try {
          await this.productionSystem.restart();
        } catch (error) {
          logger.error('❌ فشل إعادة تشغيل النظام', { error: error.message });
        }
      }, 1000);
      
      res.json({ message: 'تم بدء إعادة تشغيل النظام' });
    } catch (error) {
      logger.error('❌ خطأ في إعادة تشغيل النظام', { error: error.message });
      res.status(500).json({ error: 'خطأ في الخادم' });
    }
  }

  /**
   * إيقاف النظام
   */
  async stopSystem(req, res) {
    try {
      logger.info('🛑 طلب إيقاف النظام من واجهة الإدارة');
      
      res.json({ message: 'تم بدء إيقاف النظام' });
      
      // إيقاف النظام في الخلفية
      setTimeout(async () => {
        try {
          await this.productionSystem.stop();
          process.exit(0);
        } catch (error) {
          logger.error('❌ فشل إيقاف النظام', { error: error.message });
          process.exit(1);
        }
      }, 1000);
      
    } catch (error) {
      logger.error('❌ خطأ في إيقاف النظام', { error: error.message });
      res.status(500).json({ error: 'خطأ في الخادم' });
    }
  }

  /**
   * بدء المزامنة
   */
  async startSync(req, res) {
    try {
      const syncService = this.productionSystem.syncService;
      if (syncService) {
        await syncService.start();
        res.json({ message: 'تم بدء المزامنة' });
      } else {
        res.status(400).json({ error: 'خدمة المزامنة غير متاحة' });
      }
    } catch (error) {
      logger.error('❌ خطأ في بدء المزامنة', { error: error.message });
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * إيقاف المزامنة
   */
  async stopSync(req, res) {
    try {
      const syncService = this.productionSystem.syncService;
      if (syncService) {
        await syncService.stop();
        res.json({ message: 'تم إيقاف المزامنة' });
      } else {
        res.status(400).json({ error: 'خدمة المزامنة غير متاحة' });
      }
    } catch (error) {
      logger.error('❌ خطأ في إيقاف المزامنة', { error: error.message });
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * تشغيل مزامنة فورية
   */
  async triggerSync(req, res) {
    try {
      const syncService = this.productionSystem.syncService;
      if (syncService) {
        await syncService.performSync();
        res.json({ message: 'تم تشغيل المزامنة الفورية' });
      } else {
        res.status(400).json({ error: 'خدمة المزامنة غير متاحة' });
      }
    } catch (error) {
      logger.error('❌ خطأ في المزامنة الفورية', { error: error.message });
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * إعادة تعيين الإحصائيات
   */
  async resetStats(req, res) {
    try {
      const syncService = this.productionSystem.syncService;
      if (syncService) {
        syncService.resetStats();
      }
      
      const monitoring = this.productionSystem.monitoring;
      if (monitoring) {
        monitoring.resetActiveAlerts();
      }
      
      res.json({ message: 'تم إعادة تعيين الإحصائيات' });
    } catch (error) {
      logger.error('❌ خطأ في إعادة تعيين الإحصائيات', { error: error.message });
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * معالج الأخطاء
   */
  errorHandler(error, req, res, next) {
    logger.error('❌ خطأ في واجهة الإدارة', {
      error: error.message,
      path: req.path,
      method: req.method
    });
    
    res.status(500).json({
      error: 'خطأ في الخادم',
      message: error.message
    });
  }

  /**
   * تنسيق وقت التشغيل
   */
  formatUptime(milliseconds) {
    if (!milliseconds) return 'غير محدد';
    
    const seconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return `${days} يوم، ${hours % 24} ساعة`;
    } else if (hours > 0) {
      return `${hours} ساعة، ${minutes % 60} دقيقة`;
    } else if (minutes > 0) {
      return `${minutes} دقيقة`;
    } else {
      return `${seconds} ثانية`;
    }
  }

  /**
   * بدء الخادم
   */
  async start() {
    if (!this.config.enabled) {
      logger.info('⏸️ واجهة الإدارة معطلة في التكوين');
      return;
    }

    return new Promise((resolve, reject) => {
      this.server = this.app.listen(this.config.port, (error) => {
        if (error) {
          logger.error('❌ فشل بدء واجهة الإدارة', { error: error.message });
          reject(error);
        } else {
          logger.info(`🖥️ تم بدء واجهة الإدارة على المنفذ ${this.config.port}`);
          console.log(`🖥️ واجهة الإدارة متاحة على: http://localhost:${this.config.port}`);
          resolve();
        }
      });
    });
  }

  /**
   * إيقاف الخادم
   */
  async stop() {
    if (this.server) {
      return new Promise((resolve) => {
        this.server.close(() => {
          logger.info('🖥️ تم إيقاف واجهة الإدارة');
          resolve();
        });
      });
    }
  }
}

module.exports = AdminInterface;
