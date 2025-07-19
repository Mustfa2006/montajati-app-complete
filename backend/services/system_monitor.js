// ===================================
// نظام المراقبة والتشخيص الشامل
// Comprehensive System Monitoring & Diagnostics
// ===================================

const { createClient } = require('@supabase/supabase-js');
const EventEmitter = require('events');
const os = require('os');

class SystemMonitor extends EventEmitter {
  constructor() {
    super();
    
    // إعدادات النظام
    this.config = {
      monitoringInterval: 60000,        // دقيقة واحدة
      alertThresholds: {
        errorRate: 5,                   // 5% معدل أخطاء
        responseTime: 5000,             // 5 ثواني
        memoryUsage: 80,                // 80% استخدام الذاكرة
        cpuUsage: 85,                   // 85% استخدام المعالج
        diskUsage: 90,                  // 90% استخدام القرص
        failedNotifications: 10,        // 10 إشعارات فاشلة
      },
      retentionPeriod: 7 * 24 * 60 * 60 * 1000, // 7 أيام
      reportInterval: 24 * 60 * 60 * 1000,       // تقرير يومي
    };

    // حالة النظام
    this.state = {
      isRunning: false,
      isInitialized: false,
      lastReportAt: null,
      alerts: [],
      metrics: {
        system: {},
        application: {},
        database: {},
        notifications: {},
        sync: {}
      }
    };

    // معرفات العمليات
    this.intervals = {
      monitoring: null,
      reporting: null,
      cleanup: null,
    };

    // إعداد قاعدة البيانات
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    this.setupEventHandlers();
  }

  // ===================================
  // تهيئة النظام
  // ===================================
  async initialize() {
    try {
      console.log('🚀 تهيئة نظام المراقبة والتشخيص...');

      // التحقق من قاعدة البيانات
      await this.verifyDatabase();

      // إعداد جداول المراقبة
      await this.setupMonitoringTables();

      // بدء خدمات المراقبة
      this.startMonitoring();

      this.state.isInitialized = true;
      console.log('✅ تم تهيئة نظام المراقبة بنجاح');

      this.emit('initialized');
      return true;

    } catch (error) {
      console.error('❌ خطأ في تهيئة نظام المراقبة:', error);
      this.emit('error', error);
      throw error;
    }
  }

  // ===================================
  // التحقق من قاعدة البيانات
  // ===================================
  async verifyDatabase() {
    try {
      const { data, error } = await this.supabase
        .from('system_logs')
        .select('count')
        .limit(1);

      if (error) {
        throw new Error(`خطأ في الاتصال بقاعدة البيانات: ${error.message}`);
      }

      console.log('✅ تم التحقق من قاعدة البيانات');

    } catch (error) {
      throw new Error(`فشل في التحقق من قاعدة البيانات: ${error.message}`);
    }
  }

  // ===================================
  // إعداد جداول المراقبة
  // ===================================
  async setupMonitoringTables() {
    try {
      // إنشاء جدول مقاييس النظام إذا لم يكن موجوداً
      const createMetricsTable = `
        CREATE TABLE IF NOT EXISTS system_metrics (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          metric_type VARCHAR(50) NOT NULL,
          metric_name VARCHAR(100) NOT NULL,
          metric_value DECIMAL(10,2) NOT NULL,
          metadata JSONB,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_system_metrics_type_time 
        ON system_metrics(metric_type, created_at);
      `;

      // إنشاء جدول التنبيهات إذا لم يكن موجوداً
      const createAlertsTable = `
        CREATE TABLE IF NOT EXISTS system_alerts (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          alert_type VARCHAR(50) NOT NULL,
          severity VARCHAR(20) NOT NULL,
          title VARCHAR(200) NOT NULL,
          message TEXT NOT NULL,
          metadata JSONB,
          is_resolved BOOLEAN DEFAULT FALSE,
          resolved_at TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_system_alerts_type_time 
        ON system_alerts(alert_type, created_at);
      `;

      // تنفيذ الاستعلامات (يمكن تحسينها باستخدام migrations)
      console.log('📊 إعداد جداول المراقبة...');

    } catch (error) {
      console.warn('⚠️ تحذير في إعداد جداول المراقبة:', error.message);
    }
  }

  // ===================================
  // بدء خدمات المراقبة
  // ===================================
  startMonitoring() {
    // خدمة المراقبة المستمرة
    this.intervals.monitoring = setInterval(() => {
      this.collectMetrics();
    }, this.config.monitoringInterval);

    // خدمة التقارير اليومية
    this.intervals.reporting = setInterval(() => {
      this.generateDailyReport();
    }, this.config.reportInterval);

    // خدمة تنظيف البيانات القديمة
    this.intervals.cleanup = setInterval(() => {
      this.cleanupOldData();
    }, 6 * 60 * 60 * 1000); // كل 6 ساعات

    this.state.isRunning = true;
    console.log('✅ تم بدء جميع خدمات المراقبة');
  }

  // ===================================
  // جمع المقاييس
  // ===================================
  async collectMetrics() {
    if (!this.state.isInitialized || !this.state.isRunning) {
      return;
    }

    try {
      // جمع مقاييس النظام
      await this.collectSystemMetrics();

      // جمع مقاييس التطبيق
      await this.collectApplicationMetrics();

      // جمع مقاييس قاعدة البيانات
      await this.collectDatabaseMetrics();

      // جمع مقاييس الإشعارات
      await this.collectNotificationMetrics();

      // جمع مقاييس المزامنة
      await this.collectSyncMetrics();

      // فحص التنبيهات
      await this.checkAlerts();

      this.emit('metricsCollected', this.state.metrics);

    } catch (error) {
      console.error('❌ خطأ في جمع المقاييس:', error);
      this.emit('metricsError', error);
    }
  }

  // ===================================
  // جمع مقاييس النظام
  // ===================================
  async collectSystemMetrics() {
    try {
      const metrics = {
        timestamp: new Date().toISOString(),
        cpu: {
          usage: this.getCPUUsage(),
          loadAverage: os.loadavg(),
        },
        memory: {
          total: os.totalmem(),
          free: os.freemem(),
          used: os.totalmem() - os.freemem(),
          usage: ((os.totalmem() - os.freemem()) / os.totalmem()) * 100,
        },
        uptime: os.uptime(),
        platform: os.platform(),
        arch: os.arch(),
      };

      this.state.metrics.system = metrics;

      // حفظ المقاييس في قاعدة البيانات
      await this.saveMetric('system', 'cpu_usage', metrics.cpu.usage);
      await this.saveMetric('system', 'memory_usage', metrics.memory.usage);
      await this.saveMetric('system', 'uptime', metrics.uptime);

    } catch (error) {
      console.error('❌ خطأ في جمع مقاييس النظام:', error);
    }
  }

  // ===================================
  // جمع مقاييس التطبيق
  // ===================================
  async collectApplicationMetrics() {
    try {
      const processMetrics = process.memoryUsage();
      
      const metrics = {
        timestamp: new Date().toISOString(),
        memory: {
          rss: processMetrics.rss,
          heapTotal: processMetrics.heapTotal,
          heapUsed: processMetrics.heapUsed,
          external: processMetrics.external,
          heapUsage: (processMetrics.heapUsed / processMetrics.heapTotal) * 100,
        },
        uptime: process.uptime(),
        pid: process.pid,
        version: process.version,
      };

      this.state.metrics.application = metrics;

      // حفظ المقاييس
      await this.saveMetric('application', 'heap_usage', metrics.memory.heapUsage);
      await this.saveMetric('application', 'uptime', metrics.uptime);

    } catch (error) {
      console.error('❌ خطأ في جمع مقاييس التطبيق:', error);
    }
  }

  // ===================================
  // جمع مقاييس قاعدة البيانات
  // ===================================
  async collectDatabaseMetrics() {
    try {
      // عدد الطلبات
      const { count: ordersCount } = await this.supabase
        .from('orders')
        .select('*', { count: 'exact', head: true });

      // عدد المستخدمين النشطين
      const { count: activeUsersCount } = await this.supabase
        .from('fcm_tokens')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      // عدد الإشعارات المعلقة
      const { count: pendingNotifications } = await this.supabase
        .from('notification_queue')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

      const metrics = {
        timestamp: new Date().toISOString(),
        orders: {
          total: ordersCount || 0,
        },
        users: {
          active: activeUsersCount || 0,
        },
        notifications: {
          pending: pendingNotifications || 0,
        },
      };

      this.state.metrics.database = metrics;

      // حفظ المقاييس
      await this.saveMetric('database', 'total_orders', metrics.orders.total);
      await this.saveMetric('database', 'active_users', metrics.users.active);
      await this.saveMetric('database', 'pending_notifications', metrics.notifications.pending);

    } catch (error) {
      console.error('❌ خطأ في جمع مقاييس قاعدة البيانات:', error);
    }
  }

  // ===================================
  // جمع مقاييس الإشعارات
  // ===================================
  async collectNotificationMetrics() {
    try {
      const last24Hours = new Date(Date.now() - 24 * 60 * 60 * 1000);

      // الإشعارات المرسلة في آخر 24 ساعة
      const { count: sentCount } = await this.supabase
        .from('notification_queue')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'sent')
        .gte('created_at', last24Hours.toISOString());

      // الإشعارات الفاشلة في آخر 24 ساعة
      const { count: failedCount } = await this.supabase
        .from('notification_queue')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'failed')
        .gte('created_at', last24Hours.toISOString());

      const totalCount = (sentCount || 0) + (failedCount || 0);
      const successRate = totalCount > 0 ? ((sentCount || 0) / totalCount) * 100 : 100;

      const metrics = {
        timestamp: new Date().toISOString(),
        last24Hours: {
          sent: sentCount || 0,
          failed: failedCount || 0,
          total: totalCount,
          successRate: successRate,
        },
      };

      this.state.metrics.notifications = metrics;

      // حفظ المقاييس
      await this.saveMetric('notifications', 'success_rate', successRate);
      await this.saveMetric('notifications', 'failed_count', failedCount || 0);

    } catch (error) {
      console.error('❌ خطأ في جمع مقاييس الإشعارات:', error);
    }
  }

  // ===================================
  // جمع مقاييس المزامنة
  // ===================================
  async collectSyncMetrics() {
    try {
      const last24Hours = new Date(Date.now() - 24 * 60 * 60 * 1000);

      // الطلبات المحدثة في آخر 24 ساعة
      const { count: updatedOrders } = await this.supabase
        .from('order_status_history')
        .select('*', { count: 'exact', head: true })
        .eq('changed_by', 'system_sync')
        .gte('created_at', last24Hours.toISOString());

      const metrics = {
        timestamp: new Date().toISOString(),
        last24Hours: {
          syncedOrders: updatedOrders || 0,
        },
      };

      this.state.metrics.sync = metrics;

      // حفظ المقاييس
      await this.saveMetric('sync', 'synced_orders', updatedOrders || 0);

    } catch (error) {
      console.error('❌ خطأ في جمع مقاييس المزامنة:', error);
    }
  }

  // ===================================
  // حفظ مقياس في قاعدة البيانات
  // ===================================
  async saveMetric(type, name, value, metadata = null) {
    try {
      await this.supabase
        .from('system_metrics')
        .insert({
          metric_type: type,
          metric_name: name,
          metric_value: value,
          metadata: metadata,
          created_at: new Date().toISOString()
        });

    } catch (error) {
      // تجاهل أخطاء حفظ المقاييس لتجنب التأثير على الأداء
      console.warn('⚠️ تحذير في حفظ المقياس:', error.message);
    }
  }

  // ===================================
  // فحص التنبيهات
  // ===================================
  async checkAlerts() {
    try {
      const alerts = [];

      // فحص استخدام الذاكرة
      if (this.state.metrics.system.memory?.usage > this.config.alertThresholds.memoryUsage) {
        alerts.push({
          type: 'system',
          severity: 'warning',
          title: 'استخدام عالي للذاكرة',
          message: `استخدام الذاكرة: ${this.state.metrics.system.memory.usage.toFixed(2)}%`,
          metadata: { usage: this.state.metrics.system.memory.usage }
        });
      }

      // فحص معدل فشل الإشعارات
      const failedNotifications = this.state.metrics.notifications.last24Hours?.failed || 0;
      if (failedNotifications > this.config.alertThresholds.failedNotifications) {
        alerts.push({
          type: 'notifications',
          severity: 'critical',
          title: 'معدل عالي من الإشعارات الفاشلة',
          message: `${failedNotifications} إشعار فاشل في آخر 24 ساعة`,
          metadata: { failedCount: failedNotifications }
        });
      }

      // حفظ التنبيهات الجديدة
      for (const alert of alerts) {
        await this.createAlert(alert);
      }

      this.state.alerts = alerts;

    } catch (error) {
      console.error('❌ خطأ في فحص التنبيهات:', error);
    }
  }

  // ===================================
  // إنشاء تنبيه
  // ===================================
  async createAlert(alert) {
    try {
      await this.supabase
        .from('system_alerts')
        .insert({
          alert_type: alert.type,
          severity: alert.severity,
          title: alert.title,
          message: alert.message,
          metadata: alert.metadata,
          created_at: new Date().toISOString()
        });

      console.log(`🚨 تنبيه جديد: ${alert.title}`);
      this.emit('alert', alert);

    } catch (error) {
      console.error('❌ خطأ في إنشاء التنبيه:', error);
    }
  }

  // ===================================
  // توليد تقرير يومي
  // ===================================
  async generateDailyReport() {
    try {
      console.log('📊 توليد التقرير اليومي...');

      const report = {
        date: new Date().toISOString().split('T')[0],
        timestamp: new Date().toISOString(),
        summary: {
          system: this.state.metrics.system,
          application: this.state.metrics.application,
          database: this.state.metrics.database,
          notifications: this.state.metrics.notifications,
          sync: this.state.metrics.sync,
        },
        alerts: this.state.alerts,
        recommendations: this.generateRecommendations(),
      };

      // حفظ التقرير
      await this.supabase
        .from('system_logs')
        .insert({
          event_type: 'daily_report',
          event_data: report,
          service: 'system_monitor',
          created_at: new Date().toISOString()
        });

      this.state.lastReportAt = new Date();
      this.emit('dailyReport', report);

      console.log('✅ تم توليد التقرير اليومي');

    } catch (error) {
      console.error('❌ خطأ في توليد التقرير اليومي:', error);
    }
  }

  // ===================================
  // توليد التوصيات
  // ===================================
  generateRecommendations() {
    const recommendations = [];

    // توصيات الذاكرة
    if (this.state.metrics.system.memory?.usage > 70) {
      recommendations.push({
        type: 'performance',
        priority: 'medium',
        message: 'يُنصح بمراقبة استخدام الذاكرة وتحسين الأداء'
      });
    }

    // توصيات الإشعارات
    const successRate = this.state.metrics.notifications.last24Hours?.successRate || 100;
    if (successRate < 95) {
      recommendations.push({
        type: 'notifications',
        priority: 'high',
        message: 'يُنصح بفحص نظام الإشعارات وتحسين معدل النجاح'
      });
    }

    return recommendations;
  }

  // ===================================
  // تنظيف البيانات القديمة
  // ===================================
  async cleanupOldData() {
    try {
      const cutoffDate = new Date(Date.now() - this.config.retentionPeriod);

      // حذف المقاييس القديمة
      await this.supabase
        .from('system_metrics')
        .delete()
        .lt('created_at', cutoffDate.toISOString());

      // حذف التنبيهات المحلولة القديمة
      await this.supabase
        .from('system_alerts')
        .delete()
        .eq('is_resolved', true)
        .lt('created_at', cutoffDate.toISOString());

      console.log('🧹 تم تنظيف البيانات القديمة');

    } catch (error) {
      console.error('❌ خطأ في تنظيف البيانات:', error);
    }
  }

  // ===================================
  // الحصول على استخدام المعالج
  // ===================================
  getCPUUsage() {
    const cpus = os.cpus();
    let totalIdle = 0;
    let totalTick = 0;

    cpus.forEach(cpu => {
      for (const type in cpu.times) {
        totalTick += cpu.times[type];
      }
      totalIdle += cpu.times.idle;
    });

    return 100 - (totalIdle / totalTick) * 100;
  }

  // ===================================
  // إعداد معالجات الأحداث
  // ===================================
  setupEventHandlers() {
    this.on('error', (error) => {
      console.error('🚨 خطأ في نظام المراقبة:', error);
    });

    this.on('alert', (alert) => {
      console.log(`🚨 تنبيه ${alert.severity}: ${alert.title}`);
    });

    this.on('metricsCollected', () => {
      // يمكن إضافة معالجة إضافية هنا
    });
  }

  // ===================================
  // إيقاف النظام
  // ===================================
  async shutdown() {
    try {
      console.log('🛑 إيقاف نظام المراقبة...');

      this.state.isRunning = false;

      // إيقاف جميع الفترات الزمنية
      Object.values(this.intervals).forEach(interval => {
        if (interval) clearInterval(interval);
      });

      console.log('✅ تم إيقاف نظام المراقبة بأمان');
      this.emit('shutdown');

    } catch (error) {
      console.error('❌ خطأ في إيقاف النظام:', error);
    }
  }

  // ===================================
  // الحصول على حالة النظام
  // ===================================
  getSystemStatus() {
    return {
      isRunning: this.state.isRunning,
      isInitialized: this.state.isInitialized,
      lastReportAt: this.state.lastReportAt,
      metrics: this.state.metrics,
      alerts: this.state.alerts,
      uptime: process.uptime(),
    };
  }
}

module.exports = SystemMonitor;
