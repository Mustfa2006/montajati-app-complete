// ===================================
// خدمة المراقبة الإنتاجية
// مراقبة صحة النظام والخدمات المختلفة
// ===================================

const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');
require('dotenv').config();

class ProductionMonitoringService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات المراقبة
    this.monitoringConfig = {
      healthCheckInterval: 5, // دقائق
      alertThresholds: {
        errorRate: 0.1, // 10%
        responseTime: 5000, // 5 ثوان
        failedSyncs: 5, // 5 مزامنات فاشلة متتالية
        diskUsage: 0.9, // 90%
        memoryUsage: 0.9 // 90%
      },
      retentionDays: 30 // الاحتفاظ بالسجلات لمدة 30 يوم
    };

    // إحصائيات النظام
    this.systemStats = {
      uptime: process.uptime(),
      startTime: new Date(),
      totalRequests: 0,
      totalErrors: 0,
      lastHealthCheck: null,
      services: {
        database: 'unknown',
        waseet: 'unknown',
        firebase: 'unknown',
        sync: 'unknown'
      }
    };

    console.log('📊 تم تهيئة خدمة المراقبة الإنتاجية');
  }

  // ===================================
  // فحص صحة قاعدة البيانات
  // ===================================
  async checkDatabaseHealth() {
    try {
      const startTime = Date.now();
      
      // فحص الاتصال الأساسي
      const { data, error } = await this.supabase
        .from('orders')
        .select('count')
        .limit(1);

      if (error) {
        throw new Error(`خطأ في الاتصال: ${error.message}`);
      }

      const responseTime = Date.now() - startTime;

      // فحص أداء الاستعلامات
      const performanceCheck = await this.checkDatabasePerformance();

      return {
        status: 'healthy',
        responseTime,
        performance: performanceCheck,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // فحص أداء قاعدة البيانات
  // ===================================
  async checkDatabasePerformance() {
    try {
      const checks = [];

      // فحص عدد الطلبات النشطة
      const activeOrdersCheck = await this.supabase
        .from('orders')
        .select('count')
        .in('status', ['active', 'in_delivery']);

      checks.push({
        name: 'active_orders',
        value: activeOrdersCheck.count || 0,
        status: 'ok'
      });

      // فحص آخر طلب تم إنشاؤه
      const lastOrderCheck = await this.supabase
        .from('orders')
        .select('created_at')
        .order('created_at', { ascending: false })
        .limit(1);

      const lastOrderTime = lastOrderCheck.data?.[0]?.created_at;
      const timeSinceLastOrder = lastOrderTime ? 
        Date.now() - new Date(lastOrderTime).getTime() : null;

      checks.push({
        name: 'last_order_age',
        value: timeSinceLastOrder,
        status: timeSinceLastOrder && timeSinceLastOrder < 24 * 60 * 60 * 1000 ? 'ok' : 'warning'
      });

      // فحص حجم جدول السجلات
      const logsCheck = await this.supabase
        .from('system_logs')
        .select('count')
        .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

      checks.push({
        name: 'daily_logs',
        value: logsCheck.count || 0,
        status: 'ok'
      });

      return checks;
    } catch (error) {
      return [{
        name: 'performance_check',
        error: error.message,
        status: 'error'
      }];
    }
  }

  // ===================================
  // فحص صحة شركة الوسيط
  // ===================================
  async checkWaseetHealth() {
    try {
      const startTime = Date.now();
      
      // محاولة الوصول لصفحة تسجيل الدخول
      const response = await axios.get(
        'https://api.alwaseet-iq.net/v1/merchant/login',
        {
          timeout: 10000,
          validateStatus: () => true // قبول جميع رموز الحالة
        }
      );

      const responseTime = Date.now() - startTime;
      const isHealthy = response.status < 500;

      return {
        status: isHealthy ? 'healthy' : 'unhealthy',
        responseTime,
        httpStatus: response.status,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // فحص صحة خدمة المزامنة
  // ===================================
  async checkSyncServiceHealth() {
    try {
      // فحص آخر مزامنة ناجحة
      const { data: lastSync, error } = await this.supabase
        .from('system_logs')
        .select('created_at, event_data')
        .eq('event_type', 'sync_cycle_complete')
        .order('created_at', { ascending: false })
        .limit(1);

      if (error) {
        throw new Error(`خطأ في جلب سجلات المزامنة: ${error.message}`);
      }

      const lastSyncTime = lastSync?.[0]?.created_at;
      const timeSinceLastSync = lastSyncTime ? 
        Date.now() - new Date(lastSyncTime).getTime() : null;

      // فحص المزامنات الفاشلة الأخيرة
      const { data: failedSyncs, error: failedError } = await this.supabase
        .from('system_logs')
        .select('created_at')
        .eq('event_type', 'sync_cycle_error')
        .gte('created_at', new Date(Date.now() - 60 * 60 * 1000).toISOString()); // آخر ساعة

      const recentFailures = failedSyncs?.length || 0;

      const isHealthy = timeSinceLastSync && 
                       timeSinceLastSync < 15 * 60 * 1000 && // أقل من 15 دقيقة
                       recentFailures < this.monitoringConfig.alertThresholds.failedSyncs;

      return {
        status: isHealthy ? 'healthy' : 'unhealthy',
        lastSyncTime,
        timeSinceLastSync,
        recentFailures,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // فحص صحة النظام العام
  // ===================================
  async checkSystemHealth() {
    try {
      const memoryUsage = process.memoryUsage();
      const cpuUsage = process.cpuUsage();
      
      return {
        status: 'healthy',
        uptime: process.uptime(),
        memory: {
          used: memoryUsage.heapUsed,
          total: memoryUsage.heapTotal,
          external: memoryUsage.external,
          usage_percentage: memoryUsage.heapUsed / memoryUsage.heapTotal
        },
        cpu: cpuUsage,
        nodeVersion: process.version,
        platform: process.platform,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // تشغيل فحص شامل للصحة
  // ===================================
  async runHealthCheck() {
    console.log('🏥 تشغيل فحص شامل لصحة النظام...');
    
    const healthReport = {
      timestamp: new Date().toISOString(),
      overall_status: 'healthy',
      services: {}
    };

    try {
      // فحص قاعدة البيانات
      console.log('🔍 فحص قاعدة البيانات...');
      healthReport.services.database = await this.checkDatabaseHealth();
      
      // فحص شركة الوسيط
      console.log('🔍 فحص شركة الوسيط...');
      healthReport.services.waseet = await this.checkWaseetHealth();
      
      // فحص خدمة المزامنة
      console.log('🔍 فحص خدمة المزامنة...');
      healthReport.services.sync = await this.checkSyncServiceHealth();
      
      // فحص النظام العام
      console.log('🔍 فحص النظام العام...');
      healthReport.services.system = await this.checkSystemHealth();

      // تحديد الحالة العامة
      const unhealthyServices = Object.values(healthReport.services)
        .filter(service => service.status === 'unhealthy');
      
      if (unhealthyServices.length > 0) {
        healthReport.overall_status = 'degraded';
      }

      // حفظ تقرير الصحة
      await this.saveHealthReport(healthReport);
      
      // تحديث إحصائيات النظام
      this.updateSystemStats(healthReport);

      console.log(`✅ انتهى فحص الصحة - الحالة العامة: ${healthReport.overall_status}`);
      
      return healthReport;
    } catch (error) {
      console.error('❌ خطأ في فحص الصحة:', error.message);
      
      healthReport.overall_status = 'unhealthy';
      healthReport.error = error.message;
      
      return healthReport;
    }
  }

  // ===================================
  // حفظ تقرير الصحة
  // ===================================
  async saveHealthReport(healthReport) {
    try {
      await this.supabase
        .from('system_logs')
        .insert({
          event_type: 'health_check',
          event_data: healthReport,
          service: 'monitoring',
          created_at: new Date().toISOString()
        });
    } catch (error) {
      console.warn('⚠️ فشل في حفظ تقرير الصحة:', error.message);
    }
  }

  // ===================================
  // تحديث إحصائيات النظام
  // ===================================
  updateSystemStats(healthReport) {
    this.systemStats.lastHealthCheck = new Date();
    this.systemStats.uptime = process.uptime();
    
    // تحديث حالة الخدمات
    Object.keys(healthReport.services).forEach(service => {
      this.systemStats.services[service] = healthReport.services[service].status;
    });
  }

  // ===================================
  // الحصول على إحصائيات النظام
  // ===================================
  getSystemStats() {
    return {
      ...this.systemStats,
      currentTime: new Date().toISOString(),
      uptimeFormatted: this.formatUptime(this.systemStats.uptime)
    };
  }

  // ===================================
  // تنسيق وقت التشغيل
  // ===================================
  formatUptime(seconds) {
    const days = Math.floor(seconds / (24 * 60 * 60));
    const hours = Math.floor((seconds % (24 * 60 * 60)) / (60 * 60));
    const minutes = Math.floor((seconds % (60 * 60)) / 60);
    
    return `${days}d ${hours}h ${minutes}m`;
  }

  // ===================================
  // تنظيف السجلات القديمة
  // ===================================
  async cleanupOldLogs() {
    try {
      const cutoffDate = new Date(
        Date.now() - this.monitoringConfig.retentionDays * 24 * 60 * 60 * 1000
      ).toISOString();

      const { error } = await this.supabase
        .from('system_logs')
        .delete()
        .lt('created_at', cutoffDate);

      if (error) {
        throw new Error(`خطأ في تنظيف السجلات: ${error.message}`);
      }

      // تم تنظيف السجلات بصمت
    } catch (error) {
      // تنظيف صامت
    }
  }
}

// تصدير مثيل واحد من الخدمة (Singleton)
const monitoringService = new ProductionMonitoringService();

module.exports = monitoringService;
