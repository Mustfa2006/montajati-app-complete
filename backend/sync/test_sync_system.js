// ===================================
// اختبار شامل لنظام المزامنة التلقائية
// فحص جميع المكونات والوظائف
// ===================================

const syncService = require('./order_status_sync_service');
const statusMapper = require('./status_mapper');
const notifier = require('./notifier');
const monitoringService = require('../monitoring/production_monitoring_service');
const syncIntegration = require('./sync_integration');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class SyncSystemTester {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.testResults = {
      total: 0,
      passed: 0,
      failed: 0,
      warnings: 0,
      tests: []
    };

    console.log('🧪 تم تهيئة نظام اختبار المزامنة التلقائية');
  }

  // ===================================
  // تسجيل نتيجة اختبار
  // ===================================
  logTest(name, status, message, details = null) {
    const test = {
      name,
      status,
      message,
      details,
      timestamp: new Date().toISOString()
    };

    this.testResults.tests.push(test);
    this.testResults.total++;

    switch (status) {
      case 'passed':
        this.testResults.passed++;
        console.log(`✅ ${name}: ${message}`);
        break;
      case 'failed':
        this.testResults.failed++;
        console.log(`❌ ${name}: ${message}`);
        if (details) console.log(`   التفاصيل: ${JSON.stringify(details, null, 2)}`);
        break;
      case 'warning':
        this.testResults.warnings++;
        console.log(`⚠️ ${name}: ${message}`);
        break;
    }
  }

  // ===================================
  // اختبار خريطة تحويل الحالات
  // ===================================
  async testStatusMapper() {
    console.log('\n🗺️ اختبار خريطة تحويل الحالات...');

    try {
      // اختبار التحويل من الوسيط للمحلي
      const testCases = [
        { waseet: 'confirmed', expected: 'active' },
        { waseet: 'shipped', expected: 'in_delivery' },
        { waseet: 'delivered', expected: 'delivered' },
        { waseet: 'cancelled', expected: 'cancelled' },
        { waseet: 'unknown_status', expected: 'active' }
      ];

      for (const testCase of testCases) {
        const result = statusMapper.mapWaseetToLocal(testCase.waseet);
        if (result === testCase.expected) {
          this.logTest(
            `تحويل الحالة ${testCase.waseet}`,
            'passed',
            `تم التحويل بنجاح إلى ${result}`
          );
        } else {
          this.logTest(
            `تحويل الحالة ${testCase.waseet}`,
            'failed',
            `متوقع ${testCase.expected} لكن حصلت على ${result}`
          );
        }
      }

      // اختبار الدوال المساعدة
      const stats = statusMapper.getMapStats();
      this.logTest(
        'إحصائيات خريطة الحالات',
        'passed',
        `${stats.waseet_statuses} حالة وسيط، ${stats.local_statuses} حالة محلية`
      );

    } catch (error) {
      this.logTest(
        'خريطة تحويل الحالات',
        'failed',
        `خطأ في الاختبار: ${error.message}`
      );
    }
  }

  // ===================================
  // اختبار خدمة الإشعارات
  // ===================================
  async testNotificationService() {
    console.log('\n📱 اختبار خدمة الإشعارات...');

    try {
      // فحص صحة الخدمة
      const health = await notifier.healthCheck();
      
      if (health.status === 'healthy') {
        this.logTest(
          'صحة خدمة الإشعارات',
          'passed',
          'الخدمة تعمل بشكل صحيح'
        );
      } else if (health.status === 'degraded') {
        this.logTest(
          'صحة خدمة الإشعارات',
          'warning',
          'الخدمة تعمل بشكل محدود'
        );
      } else {
        this.logTest(
          'صحة خدمة الإشعارات',
          'failed',
          `الخدمة غير صحية: ${health.error}`
        );
      }

      // اختبار بناء رسالة الإشعار
      const testOrder = {
        id: 'test_order_123',
        order_number: 'ORD-TEST-123',
        status: 'active'
      };

      const notification = notifier.buildStatusNotification(testOrder, 'delivered');
      
      if (notification.notification && notification.notification.title && notification.notification.body) {
        this.logTest(
          'بناء رسالة الإشعار',
          'passed',
          'تم بناء الرسالة بنجاح'
        );
      } else {
        this.logTest(
          'بناء رسالة الإشعار',
          'failed',
          'فشل في بناء الرسالة'
        );
      }

    } catch (error) {
      this.logTest(
        'خدمة الإشعارات',
        'failed',
        `خطأ في الاختبار: ${error.message}`
      );
    }
  }

  // ===================================
  // اختبار خدمة المراقبة
  // ===================================
  async testMonitoringService() {
    console.log('\n📊 اختبار خدمة المراقبة...');

    try {
      // فحص صحة قاعدة البيانات
      const dbHealth = await monitoringService.checkDatabaseHealth();
      
      if (dbHealth.status === 'healthy') {
        this.logTest(
          'صحة قاعدة البيانات',
          'passed',
          `وقت الاستجابة: ${dbHealth.responseTime}ms`
        );
      } else {
        this.logTest(
          'صحة قاعدة البيانات',
          'failed',
          `قاعدة البيانات غير صحية: ${dbHealth.error}`
        );
      }

      // فحص صحة شركة الوسيط
      const waseetHealth = await monitoringService.checkWaseetHealth();
      
      if (waseetHealth.status === 'healthy') {
        this.logTest(
          'صحة شركة الوسيط',
          'passed',
          `وقت الاستجابة: ${waseetHealth.responseTime}ms`
        );
      } else {
        this.logTest(
          'صحة شركة الوسيط',
          'warning',
          `مشكلة في الاتصال: ${waseetHealth.error}`
        );
      }

      // فحص النظام العام
      const systemHealth = await monitoringService.checkSystemHealth();
      
      if (systemHealth.status === 'healthy') {
        this.logTest(
          'صحة النظام العام',
          'passed',
          `وقت التشغيل: ${Math.floor(systemHealth.uptime / 60)} دقيقة`
        );
      } else {
        this.logTest(
          'صحة النظام العام',
          'failed',
          `النظام غير صحي: ${systemHealth.error}`
        );
      }

    } catch (error) {
      this.logTest(
        'خدمة المراقبة',
        'failed',
        `خطأ في الاختبار: ${error.message}`
      );
    }
  }

  // ===================================
  // اختبار خدمة المزامنة
  // ===================================
  async testSyncService() {
    console.log('\n🔄 اختبار خدمة المزامنة...');

    try {
      // فحص صحة الخدمة
      const health = await syncService.healthCheck();
      
      if (health.status === 'healthy') {
        this.logTest(
          'صحة خدمة المزامنة',
          'passed',
          'الخدمة تعمل بشكل صحيح'
        );
      } else {
        this.logTest(
          'صحة خدمة المزامنة',
          'failed',
          `الخدمة غير صحية: ${health.error}`
        );
      }

      // اختبار جلب الطلبات للمزامنة
      const orders = await syncService.getOrdersForSync();
      this.logTest(
        'جلب الطلبات للمزامنة',
        'passed',
        `تم العثور على ${orders.length} طلب مؤهل للمزامنة`
      );

      // اختبار الإحصائيات
      const stats = syncService.getSyncStats();
      this.logTest(
        'إحصائيات المزامنة',
        'passed',
        `إجمالي الفحص: ${stats.totalChecked}, التحديث: ${stats.totalUpdated}`
      );

    } catch (error) {
      this.logTest(
        'خدمة المزامنة',
        'failed',
        `خطأ في الاختبار: ${error.message}`
      );
    }
  }

  // ===================================
  // اختبار التكامل العام
  // ===================================
  async testSyncIntegration() {
    console.log('\n🔗 اختبار التكامل العام...');

    try {
      // الحصول على حالة النظام
      const status = await syncIntegration.getSystemStatus();
      
      if (status.initialized) {
        this.logTest(
          'تهيئة النظام',
          'passed',
          'النظام مهيأ ويعمل'
        );
      } else {
        this.logTest(
          'تهيئة النظام',
          'warning',
          'النظام غير مهيأ بالكامل'
        );
      }

      // الحصول على الإحصائيات المفصلة
      const detailedStats = await syncIntegration.getDetailedStats();
      
      if (detailedStats.timestamp) {
        this.logTest(
          'الإحصائيات المفصلة',
          'passed',
          'تم الحصول على الإحصائيات بنجاح'
        );
      } else {
        this.logTest(
          'الإحصائيات المفصلة',
          'failed',
          'فشل في الحصول على الإحصائيات'
        );
      }

    } catch (error) {
      this.logTest(
        'التكامل العام',
        'failed',
        `خطأ في الاختبار: ${error.message}`
      );
    }
  }

  // ===================================
  // تشغيل جميع الاختبارات
  // ===================================
  async runAllTests() {
    console.log('🚀 بدء الاختبار الشامل لنظام المزامنة التلقائية');
    console.log('=' .repeat(60));

    const startTime = Date.now();

    // تشغيل جميع الاختبارات
    await this.testStatusMapper();
    await this.testNotificationService();
    await this.testMonitoringService();
    await this.testSyncService();
    await this.testSyncIntegration();

    const endTime = Date.now();
    const duration = endTime - startTime;

    // عرض النتائج النهائية
    console.log('\n' + '=' .repeat(60));
    console.log('📊 نتائج الاختبار الشامل:');
    console.log(`⏱️ المدة: ${duration}ms`);
    console.log(`📈 إجمالي الاختبارات: ${this.testResults.total}`);
    console.log(`✅ نجح: ${this.testResults.passed}`);
    console.log(`❌ فشل: ${this.testResults.failed}`);
    console.log(`⚠️ تحذيرات: ${this.testResults.warnings}`);

    const successRate = this.testResults.total > 0 ? 
      (this.testResults.passed / this.testResults.total * 100).toFixed(2) : 0;
    
    console.log(`📊 معدل النجاح: ${successRate}%`);

    if (this.testResults.failed === 0) {
      console.log('🎉 جميع الاختبارات نجحت! النظام جاهز للإنتاج');
    } else if (this.testResults.failed <= 2) {
      console.log('⚠️ بعض الاختبارات فشلت، يرجى المراجعة');
    } else {
      console.log('❌ عدة اختبارات فشلت، النظام يحتاج إصلاح');
    }

    return this.testResults;
  }
}

// تشغيل الاختبار إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  const tester = new SyncSystemTester();
  
  tester.runAllTests()
    .then(results => {
      if (results.failed === 0) {
        process.exit(0);
      } else {
        process.exit(1);
      }
    })
    .catch(error => {
      console.error('❌ خطأ في تشغيل الاختبارات:', error);
      process.exit(1);
    });
}

module.exports = SyncSystemTester;
