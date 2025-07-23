// ===================================
// نظام المراقبة والإشعارات الإنتاجي
// Production Monitoring and Alerting System
// ===================================

const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');
const config = require('./config');
const logger = require('./logger');

class ProductionMonitoring {
  constructor() {
    this.config = config.get('monitoring');
    this.supabase = createClient(
      config.get('database', 'supabase').url,
      config.get('database', 'supabase').serviceRoleKey
    );
    
    this.isMonitoring = false;
    this.healthCheckInterval = null;
    this.lastHealthCheck = null;
    
    // مقاييس الأداء
    this.metrics = {
      systemHealth: 'unknown',
      databaseHealth: 'unknown',
      waseetHealth: 'unknown',
      syncHealth: 'unknown',
      lastUpdate: null,
      uptime: 0,
      memoryUsage: 0,
      cpuUsage: 0,
      errorRate: 0,
      responseTime: 0
    };

    // تنبيهات نشطة
    this.activeAlerts = new Map();
    
    logger.info('📊 تم تهيئة نظام المراقبة الإنتاجي');
  }

  /**
   * بدء نظام المراقبة
   */
  async start() {
    if (this.isMonitoring) {
      logger.warn('⚠️ نظام المراقبة يعمل بالفعل');
      return;
    }

    if (!this.config.enabled) {
      logger.info('⏸️ نظام المراقبة معطل في التكوين');
      return;
    }

    try {
      logger.info('🚀 بدء نظام المراقبة');
      
      // إجراء فحص صحة أولي
      await this.performHealthCheck();
      
      // بدء الفحص الدوري
      this.startPeriodicHealthCheck();
      
      this.isMonitoring = true;
      logger.info(`✅ تم بدء نظام المراقبة - فحص كل ${this.config.healthCheckInterval / 1000} ثانية`);
      
    } catch (error) {
      logger.error('❌ فشل بدء نظام المراقبة', {
        error: error.message
      });
      throw error;
    }
  }

  /**
   * إيقاف نظام المراقبة
   */
  async stop() {
    if (!this.isMonitoring) {
      logger.warn('⚠️ نظام المراقبة متوقف بالفعل');
      return;
    }

    logger.info('🛑 إيقاف نظام المراقبة');
    
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
      this.healthCheckInterval = null;
    }
    
    this.isMonitoring = false;
    logger.info('✅ تم إيقاف نظام المراقبة');
  }

  /**
   * بدء الفحص الدوري للصحة
   */
  startPeriodicHealthCheck() {
    this.healthCheckInterval = setInterval(async () => {
      try {
        await this.performHealthCheck();
      } catch (error) {
        logger.error('❌ خطأ في الفحص الدوري للصحة', {
          error: error.message
        });
      }
    }, this.config.healthCheckInterval);
  }

  /**
   * إجراء فحص شامل للصحة
   */
  async performHealthCheck() {
    const operationId = await logger.startOperation('health_check');
    const startTime = Date.now();
    
    try {
      logger.debug('🔍 بدء فحص الصحة الشامل');
      
      // فحص صحة النظام
      const systemHealth = await this.checkSystemHealth();
      
      // فحص صحة قاعدة البيانات
      const databaseHealth = await this.checkDatabaseHealth();
      
      // فحص صحة خدمة الوسيط
      const waseetHealth = await this.checkWaseetHealth();
      
      // فحص صحة المزامنة
      const syncHealth = await this.checkSyncHealth();
      
      // تحديث المقاييس
      this.updateMetrics({
        systemHealth: systemHealth.status,
        databaseHealth: databaseHealth.status,
        waseetHealth: waseetHealth.status,
        syncHealth: syncHealth.status,
        lastUpdate: new Date().toISOString(),
        responseTime: Date.now() - startTime
      });

      // تحليل الصحة العامة
      const overallHealth = this.calculateOverallHealth();
      
      // إرسال تنبيهات إذا لزم الأمر
      await this.processAlerts({
        overall: overallHealth,
        system: systemHealth,
        database: databaseHealth,
        waseet: waseetHealth,
        sync: syncHealth
      });

      this.lastHealthCheck = new Date().toISOString();
      
      await logger.endOperation(operationId, 'health_check', true, {
        overallHealth,
        duration: Date.now() - startTime
      });

      logger.debug(`✅ انتهى فحص الصحة - الحالة العامة: ${overallHealth}`);

    } catch (error) {
      await logger.error('❌ فشل فحص الصحة', {
        error: error.message
      });
      
      await logger.endOperation(operationId, 'health_check', false, {
        error: error.message
      });
      
      // إرسال تنبيه بالفشل
      await this.sendAlert('critical', 'فشل فحص الصحة', error.message);
    }
  }

  /**
   * فحص صحة النظام
   */
  async checkSystemHealth() {
    try {
      const memoryUsage = process.memoryUsage();
      const uptime = process.uptime();
      
      // فحص استخدام الذاكرة (تحذير عند 80%, خطر عند 90%)
      const memoryPercent = (memoryUsage.heapUsed / memoryUsage.heapTotal) * 100;
      
      let status = 'healthy';
      let issues = [];
      
      if (memoryPercent > 90) {
        status = 'critical';
        issues.push(`استخدام ذاكرة عالي جداً: ${memoryPercent.toFixed(1)}%`);
      } else if (memoryPercent > 80) {
        status = 'warning';
        issues.push(`استخدام ذاكرة عالي: ${memoryPercent.toFixed(1)}%`);
      }

      // تحديث مقاييس النظام
      this.metrics.uptime = uptime;
      this.metrics.memoryUsage = memoryPercent;

      return {
        status,
        details: {
          uptime: uptime,
          memory: {
            used: memoryUsage.heapUsed,
            total: memoryUsage.heapTotal,
            percent: memoryPercent
          },
          platform: process.platform,
          nodeVersion: process.version,
          pid: process.pid
        },
        issues
      };

    } catch (error) {
      return {
        status: 'critical',
        error: error.message,
        issues: ['فشل فحص صحة النظام']
      };
    }
  }

  /**
   * فحص صحة قاعدة البيانات
   */
  async checkDatabaseHealth() {
    try {
      const startTime = Date.now();
      
      // اختبار الاتصال
      const { data, error } = await this.supabase
        .from('orders')
        .select('id')
        .limit(1);

      const responseTime = Date.now() - startTime;

      if (error) {
        return {
          status: 'critical',
          error: error.message,
          issues: ['فشل الاتصال بقاعدة البيانات']
        };
      }

      // فحص وقت الاستجابة
      let status = 'healthy';
      let issues = [];

      if (responseTime > 5000) {
        status = 'critical';
        issues.push(`وقت استجابة بطيء جداً: ${responseTime}ms`);
      } else if (responseTime > 2000) {
        status = 'warning';
        issues.push(`وقت استجابة بطيء: ${responseTime}ms`);
      }

      return {
        status,
        details: {
          responseTime,
          connected: true,
          recordsFound: data?.length || 0
        },
        issues
      };

    } catch (error) {
      return {
        status: 'critical',
        error: error.message,
        issues: ['خطأ في فحص قاعدة البيانات']
      };
    }
  }

  /**
   * فحص صحة خدمة الوسيط
   */
  async checkWaseetHealth() {
    try {
      const waseetConfig = config.get('waseet');
      const startTime = Date.now();
      
      // اختبار الاتصال الأساسي
      const response = await axios.get(waseetConfig.baseUrl, {
        timeout: 10000,
        validateStatus: () => true
      });

      const responseTime = Date.now() - startTime;

      let status = 'healthy';
      let issues = [];

      // فحص حالة الاستجابة
      if (response.status >= 500) {
        status = 'critical';
        issues.push(`خطأ خادم الوسيط: HTTP ${response.status}`);
      } else if (response.status >= 400) {
        status = 'warning';
        issues.push(`مشكلة في الوسيط: HTTP ${response.status}`);
      }

      // فحص وقت الاستجابة
      if (responseTime > 10000) {
        status = 'critical';
        issues.push(`وقت استجابة بطيء جداً: ${responseTime}ms`);
      } else if (responseTime > 5000) {
        status = 'warning';
        issues.push(`وقت استجابة بطيء: ${responseTime}ms`);
      }

      return {
        status,
        details: {
          responseTime,
          httpStatus: response.status,
          baseUrl: waseetConfig.baseUrl,
          accessible: response.status < 500
        },
        issues
      };

    } catch (error) {
      return {
        status: 'critical',
        error: error.message,
        issues: ['فشل الاتصال بخدمة الوسيط']
      };
    }
  }

  /**
   * فحص صحة المزامنة
   */
  async checkSyncHealth() {
    try {
      // فحص آخر عمليات المزامنة
      const { data: recentSyncs, error } = await this.supabase
        .from('sync_logs')
        .select('*')
        .order('sync_timestamp', { ascending: false })
        .limit(5);

      if (error) {
        return {
          status: 'warning',
          error: error.message,
          issues: ['فشل جلب سجلات المزامنة']
        };
      }

      let status = 'healthy';
      let issues = [];

      if (recentSyncs.length === 0) {
        status = 'warning';
        issues.push('لا توجد سجلات مزامنة');
      } else {
        // فحص آخر مزامنة
        const lastSync = recentSyncs[0];
        const timeSinceLastSync = Date.now() - new Date(lastSync.sync_timestamp).getTime();
        const maxAge = config.get('sync', 'interval') * 3; // 3 أضعاف فترة المزامنة

        if (timeSinceLastSync > maxAge) {
          status = 'critical';
          issues.push(`آخر مزامنة قديمة: ${Math.round(timeSinceLastSync / 60000)} دقيقة`);
        }

        // فحص معدل نجاح المزامنة
        const successfulSyncs = recentSyncs.filter(sync => sync.success).length;
        const successRate = (successfulSyncs / recentSyncs.length) * 100;

        if (successRate < 50) {
          status = 'critical';
          issues.push(`معدل نجاح منخفض: ${successRate.toFixed(1)}%`);
        } else if (successRate < 80) {
          status = 'warning';
          issues.push(`معدل نجاح متوسط: ${successRate.toFixed(1)}%`);
        }
      }

      return {
        status,
        details: {
          recentSyncsCount: recentSyncs.length,
          lastSyncTime: recentSyncs[0]?.sync_timestamp,
          successRate: recentSyncs.length > 0 ? 
            (recentSyncs.filter(s => s.success).length / recentSyncs.length) * 100 : 0
        },
        issues
      };

    } catch (error) {
      return {
        status: 'critical',
        error: error.message,
        issues: ['خطأ في فحص صحة المزامنة']
      };
    }
  }

  /**
   * تحديث المقاييس
   */
  updateMetrics(newMetrics) {
    Object.assign(this.metrics, newMetrics);
  }

  /**
   * حساب الصحة العامة
   */
  calculateOverallHealth() {
    const healthScores = {
      'healthy': 3,
      'warning': 2,
      'critical': 1,
      'unknown': 0
    };

    const components = [
      this.metrics.systemHealth,
      this.metrics.databaseHealth,
      this.metrics.waseetHealth,
      this.metrics.syncHealth
    ];

    const totalScore = components.reduce((sum, health) => 
      sum + (healthScores[health] || 0), 0);
    
    const maxScore = components.length * 3;
    const healthPercent = (totalScore / maxScore) * 100;

    if (healthPercent >= 90) return 'healthy';
    if (healthPercent >= 70) return 'warning';
    return 'critical';
  }

  /**
   * معالجة التنبيهات
   */
  async processAlerts(healthData) {
    const alertConfig = config.get('notifications');
    
    if (!alertConfig.enabled) {
      return;
    }

    // فحص التنبيهات الحرجة
    if (healthData.overall === 'critical') {
      await this.sendAlert('critical', 'حالة النظام حرجة', 
        'النظام في حالة حرجة - يتطلب تدخل فوري');
    }

    // فحص تنبيهات المكونات
    for (const [component, data] of Object.entries(healthData)) {
      if (component === 'overall') continue;
      
      if (data.status === 'critical' && data.issues?.length > 0) {
        await this.sendAlert('critical', `مشكلة حرجة في ${component}`, 
          data.issues.join(', '));
      } else if (data.status === 'warning' && data.issues?.length > 0) {
        await this.sendAlert('warning', `تحذير في ${component}`, 
          data.issues.join(', '));
      }
    }
  }

  /**
   * إرسال تنبيه
   */
  async sendAlert(level, title, message) {
    const alertKey = `${level}_${title}`;
    const now = Date.now();
    
    // تجنب إرسال نفس التنبيه بشكل متكرر (كل 15 دقيقة)
    if (this.activeAlerts.has(alertKey)) {
      const lastSent = this.activeAlerts.get(alertKey);
      if (now - lastSent < 15 * 60 * 1000) {
        return;
      }
    }

    try {
      const alertData = {
        level,
        title,
        message,
        timestamp: new Date().toISOString(),
        system: config.get('system', 'name'),
        version: config.get('system', 'version')
      };

      // إرسال عبر webhook
      await this.sendWebhookAlert(alertData);
      
      // حفظ في قاعدة البيانات
      await this.saveAlertToDatabase(alertData);
      
      // تسجيل في السجلات
      await logger.warn(`🚨 تنبيه ${level}: ${title}`, {
        message,
        alertData
      });

      this.activeAlerts.set(alertKey, now);

    } catch (error) {
      logger.error('❌ فشل إرسال التنبيه', {
        level,
        title,
        message,
        error: error.message
      });
    }
  }

  /**
   * إرسال تنبيه عبر webhook
   */
  async sendWebhookAlert(alertData) {
    const webhookConfig = config.get('notifications', 'channels').webhook;
    
    if (!webhookConfig.enabled || !webhookConfig.url) {
      return;
    }

    try {
      await axios.post(webhookConfig.url, {
        text: `🚨 ${alertData.title}`,
        attachments: [{
          color: alertData.level === 'critical' ? 'danger' : 'warning',
          fields: [
            { title: 'النظام', value: alertData.system, short: true },
            { title: 'المستوى', value: alertData.level, short: true },
            { title: 'الرسالة', value: alertData.message, short: false },
            { title: 'الوقت', value: alertData.timestamp, short: true }
          ]
        }]
      }, {
        timeout: 10000
      });

    } catch (error) {
      logger.warn('⚠️ فشل إرسال webhook', {
        error: error.message
      });
    }
  }

  /**
   * حفظ التنبيه في قاعدة البيانات
   */
  async saveAlertToDatabase(alertData) {
    try {
      await this.supabase
        .from('system_alerts')
        .insert({
          level: alertData.level,
          title: alertData.title,
          message: alertData.message,
          timestamp: alertData.timestamp,
          system_name: alertData.system,
          system_version: alertData.version,
          resolved: false
        });

    } catch (error) {
      logger.warn('⚠️ فشل حفظ التنبيه في قاعدة البيانات', {
        error: error.message
      });
    }
  }

  /**
   * الحصول على حالة المراقبة
   */
  getStatus() {
    return {
      isMonitoring: this.isMonitoring,
      lastHealthCheck: this.lastHealthCheck,
      metrics: this.metrics,
      activeAlertsCount: this.activeAlerts.size,
      config: {
        enabled: this.config.enabled,
        healthCheckInterval: this.config.healthCheckInterval,
        alerting: this.config.alerting.enabled
      }
    };
  }

  /**
   * الحصول على المقاييس
   */
  getMetrics() {
    return this.metrics;
  }

  /**
   * إعادة تعيين التنبيهات النشطة
   */
  resetActiveAlerts() {
    this.activeAlerts.clear();
    logger.info('🔄 تم إعادة تعيين التنبيهات النشطة');
  }
}

module.exports = ProductionMonitoring;
