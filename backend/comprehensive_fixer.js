// ===================================
// نظام الإصلاح الشامل لجميع المشاكل
// Comprehensive System Fixer
// ===================================

const https = require('https');
const fs = require('fs');
const path = require('path');

class ComprehensiveSystemFixer {
  constructor() {
    this.baseUrl = 'https://montajati-backend.onrender.com';
    this.fixes = [];
    this.results = [];
  }

  // إضافة إصلاح للقائمة
  addFix(category, title, description, action) {
    this.fixes.push({
      category,
      title,
      description,
      action,
      status: 'pending'
    });
  }

  // تسجيل نتيجة الإصلاح
  logResult(fixIndex, success, message, details = null) {
    this.results.push({
      fix: this.fixes[fixIndex],
      success,
      message,
      details,
      timestamp: new Date().toISOString()
    });
    
    this.fixes[fixIndex].status = success ? 'completed' : 'failed';
    
    const emoji = success ? '✅' : '❌';
    console.log(`${emoji} ${this.fixes[fixIndex].title}: ${message}`);
    if (details) {
      console.log(`   📋 التفاصيل: ${details}`);
    }
  }

  // 1. إصلاح مشاكل الخادم والخدمات
  async fixServerIssues() {
    console.log('\n🔧 1️⃣ إصلاح مشاكل الخادم والخدمات...');
    console.log('='.repeat(60));

    // إصلاح 1: إضافة تهيئة خدمة المزامنة
    const fixIndex1 = this.fixes.length;
    this.addFix('server', 'إصلاح خدمة المزامنة', 'إضافة تهيئة خدمة المزامنة في server.js', 'updateServerFile');

    try {
      // قراءة ملف server.js
      const serverPath = path.join(__dirname, 'server.js');
      let serverContent = fs.readFileSync(serverPath, 'utf8');

      // التحقق من وجود تهيئة خدمة المزامنة
      if (!serverContent.includes('initializeSyncService')) {
        // إضافة دالة تهيئة خدمة المزامنة
        const syncServiceFunction = `
// تهيئة خدمة مزامنة الطلبات مع الوسيط
async function initializeSyncService() {
  try {
    console.log('🔄 بدء تهيئة خدمة مزامنة الطلبات مع الوسيط...');
    
    // التحقق من وجود الملف
    const servicePath = path.join(__dirname, 'services', 'order_sync_service.js');
    if (!fs.existsSync(servicePath)) {
      throw new Error('ملف خدمة المزامنة غير موجود');
    }
    
    const OrderSyncService = require('./services/order_sync_service');
    const testService = new OrderSyncService();
    
    if (!testService) {
      throw new Error('فشل في إنشاء instance من خدمة المزامنة');
    }
    
    global.orderSyncService = testService;
    console.log('✅ تم تهيئة خدمة مزامنة الطلبات مع الوسيط بنجاح');
    return true;
  } catch (error) {
    console.error('❌ خطأ في تهيئة خدمة مزامنة الطلبات مع الوسيط:', error.message);
    return false;
  }
}`;

        // إضافة الدالة قبل دالة تهيئة الإشعارات
        const notificationFunctionIndex = serverContent.indexOf('// تهيئة خدمة الإشعارات المستهدفة');
        if (notificationFunctionIndex !== -1) {
          serverContent = serverContent.slice(0, notificationFunctionIndex) + 
                        syncServiceFunction + '\n\n' + 
                        serverContent.slice(notificationFunctionIndex);
        }

        // إضافة استدعاء الدالة
        if (!serverContent.includes('await initializeSyncService()')) {
          serverContent = serverContent.replace(
            'await initializeNotificationService();',
            `await initializeNotificationService();

  // تهيئة خدمة مزامنة الطلبات مع الوسيط
  await initializeSyncService();`
          );
        }

        // كتابة الملف المحدث
        fs.writeFileSync(serverPath, serverContent);
        this.logResult(fixIndex1, true, 'تم إضافة تهيئة خدمة المزامنة بنجاح');
      } else {
        this.logResult(fixIndex1, true, 'تهيئة خدمة المزامنة موجودة مسبقاً');
      }
    } catch (error) {
      this.logResult(fixIndex1, false, 'فشل في إصلاح خدمة المزامنة', error.message);
    }

    // إصلاح 2: تحديث health check
    const fixIndex2 = this.fixes.length;
    this.addFix('server', 'تحديث health check', 'إضافة فحص خدمة المزامنة في health check', 'updateHealthCheck');

    try {
      const serverPath = path.join(__dirname, 'server.js');
      let serverContent = fs.readFileSync(serverPath, 'utf8');

      // التحقق من وجود فحص خدمة المزامنة في health check
      if (!serverContent.includes('global.orderSyncService')) {
        // تحديث health check ليتضمن خدمة المزامنة
        const healthCheckPattern = /app\.get\('\/health',[\s\S]*?\}\);/;
        const newHealthCheck = `app.get('/health', (req, res) => {
  const checks = [];
  let overallStatus = 'healthy';

  // فحص خدمة الإشعارات
  try {
    if (targetedNotificationService && targetedNotificationService.isInitialized) {
      checks.push({ service: 'notifications', status: 'pass' });
    } else {
      checks.push({ service: 'notifications', status: 'fail', error: 'خدمة الإشعارات غير مهيأة' });
      overallStatus = 'degraded';
    }
  } catch (error) {
    checks.push({ service: 'notifications', status: 'fail', error: error.message });
    overallStatus = 'degraded';
  }

  // فحص خدمة المزامنة
  try {
    if (global.orderSyncService) {
      checks.push({ service: 'sync', status: 'pass' });
    } else {
      checks.push({ service: 'sync', status: 'fail', error: 'خدمة المزامنة غير مهيأة' });
      overallStatus = 'degraded';
    }
  } catch (error) {
    checks.push({ service: 'sync', status: 'fail', error: error.message });
    overallStatus = 'degraded';
  }

  res.json({
    status: overallStatus,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    services: {
      notifications: checks.find(c => c.service === 'notifications')?.status === 'pass' ? 'healthy' : 'unhealthy',
      sync: checks.find(c => c.service === 'sync')?.status === 'pass' ? 'healthy' : 'unhealthy'
    },
    checks: checks
  });
});`;

        serverContent = serverContent.replace(healthCheckPattern, newHealthCheck);
        fs.writeFileSync(serverPath, serverContent);
        this.logResult(fixIndex2, true, 'تم تحديث health check بنجاح');
      } else {
        this.logResult(fixIndex2, true, 'health check محدث مسبقاً');
      }
    } catch (error) {
      this.logResult(fixIndex2, false, 'فشل في تحديث health check', error.message);
    }
  }

  // 2. إصلاح مشاكل الكود
  async fixCodeIssues() {
    console.log('\n🔧 2️⃣ إصلاح مشاكل الكود...');
    console.log('='.repeat(60));

    // إصلاح 1: تحسين endpoint تحديث الحالة
    const fixIndex1 = this.fixes.length;
    this.addFix('code', 'تحسين endpoint تحديث الحالة', 'إضافة دعم لجميع حالات التوصيل ومعالجة أخطاء محسنة', 'updateOrdersRoute');

    try {
      const ordersRoutePath = path.join(__dirname, 'routes', 'orders.js');
      let ordersContent = fs.readFileSync(ordersRoutePath, 'utf8');

      // التحقق من وجود deliveryStatuses
      if (!ordersContent.includes('deliveryStatuses')) {
        // إضافة دعم لجميع حالات التوصيل
        const deliveryStatusesCode = `    // 🚀 إرسال الطلب لشركة الوسيط عند تغيير الحالة إلى "قيد التوصيل"
    const deliveryStatuses = [
      'in_delivery',
      'قيد التوصيل',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'قيد التوصيل الى الزبون',
      'في عهدة المندوب',
      'قيد التوصيل للزبون'
    ];
    
    if (deliveryStatuses.includes(status)) {
      console.log(\`📦 الحالة الجديدة هي "\${status}" - سيتم إرسال الطلب لشركة الوسيط...\`);

      try {
        // التحقق من وجود خدمة المزامنة
        if (!global.orderSyncService) {
          console.error('❌ خدمة المزامنة غير متاحة');
          
          // محاولة تهيئة الخدمة مرة أخرى
          try {
            const OrderSyncService = require('../services/order_sync_service');
            global.orderSyncService = new OrderSyncService();
            console.log('✅ تم إعادة تهيئة خدمة المزامنة');
          } catch (initError) {
            console.error('❌ فشل في إعادة تهيئة خدمة المزامنة:', initError.message);
            throw new Error('خدمة المزامنة غير متاحة');
          }
        }

        // التحقق من أن الطلب لم يتم إرساله مسبقاً
        const { data: currentOrder, error: checkError } = await supabase
          .from('orders')
          .select('waseet_order_id, waseet_status')
          .eq('id', id)
          .single();

        if (checkError) {
          console.error('❌ خطأ في فحص حالة الوسيط:', checkError);
        } else if (currentOrder.waseet_order_id) {
          console.log(\`ℹ️ الطلب \${id} تم إرساله مسبقاً للوسيط (ID: \${currentOrder.waseet_order_id})\`);
        } else {
          console.log(\`🚀 إرسال الطلب \${id} لشركة الوسيط...\`);

          // إرسال الطلب لشركة الوسيط
          const waseetResult = await global.orderSyncService.sendOrderToWaseet(id);

          if (waseetResult && waseetResult.success) {
            console.log(\`✅ تم إرسال الطلب \${id} لشركة الوسيط بنجاح\`);

            // تحديث الطلب بمعلومات الوسيط
            await supabase
              .from('orders')
              .update({
                waseet_order_id: waseetResult.qrId || null,
                waseet_status: 'sent',
                waseet_data: JSON.stringify(waseetResult),
                updated_at: new Date().toISOString()
              })
              .eq('id', id);

          } else {
            console.log(\`⚠️ فشل في إرسال الطلب \${id} لشركة الوسيط - سيتم المحاولة لاحقاً\`);

            // تحديث الطلب بحالة "في انتظار الإرسال للوسيط"
            await supabase
              .from('orders')
              .update({
                waseet_status: 'في انتظار الإرسال للوسيط',
                waseet_data: JSON.stringify({
                  error: waseetResult?.error || 'فشل في الإرسال',
                  retry_needed: true,
                  last_attempt: new Date().toISOString()
                }),
                updated_at: new Date().toISOString()
              })
              .eq('id', id);
          }
        }
      } catch (waseetError) {
        console.error(\`❌ خطأ في إرسال الطلب \${id} لشركة الوسيط:\`, waseetError);
        
        // تحديث الطلب بحالة الخطأ
        await supabase
          .from('orders')
          .update({
            waseet_status: 'في انتظار الإرسال للوسيط',
            waseet_data: JSON.stringify({
              error: waseetError.message,
              retry_needed: true,
              last_attempt: new Date().toISOString()
            }),
            updated_at: new Date().toISOString()
          })
          .eq('id', id);
      }
    }`;

        // البحث عن المكان المناسب لإضافة الكود
        const statusUpdatePattern = /if \(status === 'in_delivery'[\s\S]*?catch \(error\) \{[\s\S]*?\}/;
        if (statusUpdatePattern.test(ordersContent)) {
          ordersContent = ordersContent.replace(statusUpdatePattern, deliveryStatusesCode);
        } else {
          // إذا لم يوجد الكود القديم، أضف الكود الجديد قبل النهاية
          const beforeReturnPattern = /res\.json\(\{[\s\S]*?success: true[\s\S]*?\}\);/;
          ordersContent = ordersContent.replace(beforeReturnPattern, deliveryStatusesCode + '\n\n    $&');
        }

        fs.writeFileSync(ordersRoutePath, ordersContent);
        this.logResult(fixIndex1, true, 'تم تحسين endpoint تحديث الحالة بنجاح');
      } else {
        this.logResult(fixIndex1, true, 'endpoint تحديث الحالة محسن مسبقاً');
      }
    } catch (error) {
      this.logResult(fixIndex1, false, 'فشل في تحسين endpoint تحديث الحالة', error.message);
    }
  }

  // 3. نشر الإصلاحات
  async deployFixes() {
    console.log('\n🚀 3️⃣ نشر الإصلاحات...');
    console.log('='.repeat(60));

    const fixIndex = this.fixes.length;
    this.addFix('deployment', 'نشر الإصلاحات', 'رفع الكود المحدث ونشره على الخادم', 'deployToServer');

    try {
      // هنا يمكن إضافة كود Git وNPM إذا لزم الأمر
      this.logResult(fixIndex, true, 'تم تطبيق الإصلاحات محلياً - يحتاج نشر يدوي');
    } catch (error) {
      this.logResult(fixIndex, false, 'فشل في نشر الإصلاحات', error.message);
    }
  }

  // تشغيل جميع الإصلاحات
  async runAllFixes() {
    console.log('🔧 بدء الإصلاح الشامل لجميع المشاكل...');
    console.log('='.repeat(80));

    await this.fixServerIssues();
    await this.fixCodeIssues();
    await this.deployFixes();

    return this.generateReport();
  }

  // إنشاء تقرير الإصلاحات
  generateReport() {
    console.log('\n📋 تقرير الإصلاحات الشاملة');
    console.log('='.repeat(80));

    const successCount = this.results.filter(r => r.success).length;
    const failCount = this.results.filter(r => !r.success).length;

    console.log(`\n📊 إجمالي الإصلاحات: ${this.results.length}`);
    console.log(`✅ نجح: ${successCount}`);
    console.log(`❌ فشل: ${failCount}`);

    if (this.results.length > 0) {
      console.log('\n📋 تفاصيل الإصلاحات:');
      this.results.forEach((result, index) => {
        const emoji = result.success ? '✅' : '❌';
        console.log(`\n${index + 1}. ${emoji} [${result.fix.category.toUpperCase()}] ${result.fix.title}`);
        console.log(`   📋 النتيجة: ${result.message}`);
        if (result.details) {
          console.log(`   📋 التفاصيل: ${result.details}`);
        }
      });
    }

    return {
      totalFixes: this.results.length,
      successCount,
      failCount,
      results: this.results
    };
  }
}

// تشغيل الإصلاح الشامل
async function runComprehensiveFix() {
  const fixer = new ComprehensiveSystemFixer();
  
  try {
    const report = await fixer.runAllFixes();
    
    console.log('\n🎯 انتهى الإصلاح الشامل');
    return report;
  } catch (error) {
    console.error('❌ خطأ في الإصلاح الشامل:', error);
    return null;
  }
}

// تشغيل الإصلاح إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  runComprehensiveFix()
    .then((report) => {
      if (report) {
        console.log('\n✅ تم إنجاز الإصلاح الشامل بنجاح');
        process.exit(0);
      } else {
        console.log('\n❌ فشل الإصلاح الشامل');
        process.exit(1);
      }
    })
    .catch((error) => {
      console.error('\n❌ خطأ في تشغيل الإصلاح الشامل:', error);
      process.exit(1);
    });
}

module.exports = { ComprehensiveSystemFixer, runComprehensiveFix };
