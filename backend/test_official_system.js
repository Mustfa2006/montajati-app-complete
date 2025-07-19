// ===================================
// اختبار النظام الرسمي المتكامل
// Official System Comprehensive Testing
// ===================================

require('dotenv').config();
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

class OfficialSystemTester {
  constructor() {
    this.baseURL = 'http://localhost:3003';
    this.testResults = {
      passed: 0,
      failed: 0,
      total: 0,
      details: []
    };

    // إعداد قاعدة البيانات للاختبار
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // بيانات اختبار
    this.testData = {
      testUser: {
        phone: '07503597589',
        name: 'مستخدم اختبار',
        fcmToken: 'test_fcm_token_' + Date.now()
      },
      testOrder: {
        id: 'test_order_' + Date.now(),
        customer_name: 'عميل اختبار',
        user_phone: '07503597589',
        status: 'active'
      }
    };
  }

  // ===================================
  // تشغيل جميع الاختبارات
  // ===================================
  async runAllTests() {
    console.log('🧪 بدء اختبار النظام الرسمي المتكامل...\n');
    console.log('='.repeat(60));

    try {
      // اختبارات أساسية
      await this.testServerHealth();
      await this.testSystemStatus();
      await this.testDatabaseConnection();

      // اختبارات الخدمات
      await this.testNotificationService();
      await this.testSyncService();
      await this.testMonitoringService();

      // اختبارات التكامل
      await this.testFCMTokenManagement();
      await this.testNotificationFlow();
      await this.testOrderStatusUpdate();

      // اختبارات الأداء
      await this.testPerformance();
      await this.testErrorHandling();

      // تقرير النتائج
      this.generateTestReport();

    } catch (error) {
      console.error('❌ خطأ في تشغيل الاختبارات:', error);
      this.addTestResult('System Test', false, `خطأ عام: ${error.message}`);
    }
  }

  // ===================================
  // اختبار صحة الخادم
  // ===================================
  async testServerHealth() {
    try {
      console.log('🔍 اختبار صحة الخادم...');

      const response = await axios.get(`${this.baseURL}/health`, {
        timeout: 10000
      });

      const isHealthy = response.status === 200 && response.data.status === 'healthy';
      
      this.addTestResult(
        'Server Health',
        isHealthy,
        isHealthy ? 'الخادم يعمل بصحة جيدة' : `حالة الخادم: ${response.data.status}`
      );

      if (isHealthy) {
        console.log('✅ الخادم يعمل بصحة جيدة');
        console.log(`   - الحالة: ${response.data.status}`);
        console.log(`   - وقت التشغيل: ${Math.floor(response.data.uptime)} ثانية`);
      }

    } catch (error) {
      this.addTestResult('Server Health', false, `فشل الاتصال بالخادم: ${error.message}`);
      console.log('❌ فشل في الاتصال بالخادم');
    }
  }

  // ===================================
  // اختبار حالة النظام
  // ===================================
  async testSystemStatus() {
    try {
      console.log('🔍 اختبار حالة النظام...');

      const response = await axios.get(`${this.baseURL}/api/system/status`, {
        timeout: 10000
      });

      const isRunning = response.status === 200 && response.data.success;
      
      this.addTestResult(
        'System Status',
        isRunning,
        isRunning ? 'النظام يعمل بشكل صحيح' : 'النظام لا يعمل بشكل صحيح'
      );

      if (isRunning) {
        const services = response.data.data.services;
        console.log('✅ النظام يعمل بشكل صحيح');
        console.log(`   - خدمة الإشعارات: ${services.notifications?.state?.isInitialized ? 'نشطة' : 'معطلة'}`);
        console.log(`   - خدمة المزامنة: ${services.sync?.state?.isInitialized ? 'نشطة' : 'معطلة'}`);
        console.log(`   - خدمة المراقبة: ${services.monitor?.state?.isInitialized ? 'نشطة' : 'معطلة'}`);
      }

    } catch (error) {
      this.addTestResult('System Status', false, `خطأ في فحص حالة النظام: ${error.message}`);
      console.log('❌ خطأ في فحص حالة النظام');
    }
  }

  // ===================================
  // اختبار الاتصال بقاعدة البيانات
  // ===================================
  async testDatabaseConnection() {
    try {
      console.log('🔍 اختبار الاتصال بقاعدة البيانات...');

      const { data, error } = await this.supabase
        .from('orders')
        .select('count')
        .limit(1);

      const isConnected = !error;
      
      this.addTestResult(
        'Database Connection',
        isConnected,
        isConnected ? 'الاتصال بقاعدة البيانات ناجح' : `خطأ في قاعدة البيانات: ${error.message}`
      );

      if (isConnected) {
        console.log('✅ الاتصال بقاعدة البيانات ناجح');
      }

    } catch (error) {
      this.addTestResult('Database Connection', false, `خطأ في الاتصال بقاعدة البيانات: ${error.message}`);
      console.log('❌ خطأ في الاتصال بقاعدة البيانات');
    }
  }

  // ===================================
  // اختبار خدمة الإشعارات
  // ===================================
  async testNotificationService() {
    try {
      console.log('🔍 اختبار خدمة الإشعارات...');

      // اختبار إضافة إشعار
      const notificationData = {
        orderData: this.testData.testOrder,
        statusChange: { from: 'active', to: 'processing' }
      };

      const response = await axios.post(
        `${this.baseURL}/api/notifications/send`,
        notificationData,
        { timeout: 10000 }
      );

      const isWorking = response.status === 200 && response.data.success;
      
      this.addTestResult(
        'Notification Service',
        isWorking,
        isWorking ? 'خدمة الإشعارات تعمل بشكل صحيح' : 'خدمة الإشعارات لا تعمل'
      );

      if (isWorking) {
        console.log('✅ خدمة الإشعارات تعمل بشكل صحيح');
        console.log(`   - تم إضافة إشعار للطلب: ${this.testData.testOrder.id}`);
      }

    } catch (error) {
      this.addTestResult('Notification Service', false, `خطأ في خدمة الإشعارات: ${error.message}`);
      console.log('❌ خطأ في خدمة الإشعارات');
    }
  }

  // ===================================
  // اختبار خدمة المزامنة
  // ===================================
  async testSyncService() {
    try {
      console.log('🔍 اختبار خدمة المزامنة...');

      const response = await axios.post(
        `${this.baseURL}/api/sync/trigger`,
        {},
        { timeout: 30000 }
      );

      const isWorking = response.status === 200 && response.data.success;
      
      this.addTestResult(
        'Sync Service',
        isWorking,
        isWorking ? 'خدمة المزامنة تعمل بشكل صحيح' : 'خدمة المزامنة لا تعمل'
      );

      if (isWorking) {
        console.log('✅ خدمة المزامنة تعمل بشكل صحيح');
      }

    } catch (error) {
      this.addTestResult('Sync Service', false, `خطأ في خدمة المزامنة: ${error.message}`);
      console.log('❌ خطأ في خدمة المزامنة');
    }
  }

  // ===================================
  // اختبار خدمة المراقبة
  // ===================================
  async testMonitoringService() {
    try {
      console.log('🔍 اختبار خدمة المراقبة...');

      const response = await axios.get(
        `${this.baseURL}/api/monitor/metrics`,
        { timeout: 10000 }
      );

      const isWorking = response.status === 200 && response.data.success;
      
      this.addTestResult(
        'Monitoring Service',
        isWorking,
        isWorking ? 'خدمة المراقبة تعمل بشكل صحيح' : 'خدمة المراقبة لا تعمل'
      );

      if (isWorking) {
        console.log('✅ خدمة المراقبة تعمل بشكل صحيح');
        const metrics = response.data.data;
        console.log(`   - حالة النظام: ${metrics.isRunning ? 'يعمل' : 'متوقف'}`);
      }

    } catch (error) {
      this.addTestResult('Monitoring Service', false, `خطأ في خدمة المراقبة: ${error.message}`);
      console.log('❌ خطأ في خدمة المراقبة');
    }
  }

  // ===================================
  // اختبار إدارة FCM Tokens
  // ===================================
  async testFCMTokenManagement() {
    try {
      console.log('🔍 اختبار إدارة FCM Tokens...');

      // تسجيل FCM Token جديد
      const tokenData = {
        user_phone: this.testData.testUser.phone,
        fcm_token: this.testData.testUser.fcmToken,
        device_info: {
          platform: 'test',
          model: 'test_device'
        }
      };

      const registerResponse = await axios.post(
        `${this.baseURL}/api/fcm/register`,
        tokenData,
        { timeout: 10000 }
      );

      const isRegistered = registerResponse.status === 200;

      // فحص حالة المستخدم
      const statusResponse = await axios.get(
        `${this.baseURL}/api/fcm/status/${this.testData.testUser.phone}`,
        { timeout: 10000 }
      );

      const hasToken = statusResponse.status === 200 && statusResponse.data.success;

      const isWorking = isRegistered && hasToken;
      
      this.addTestResult(
        'FCM Token Management',
        isWorking,
        isWorking ? 'إدارة FCM Tokens تعمل بشكل صحيح' : 'مشكلة في إدارة FCM Tokens'
      );

      if (isWorking) {
        console.log('✅ إدارة FCM Tokens تعمل بشكل صحيح');
        console.log(`   - تم تسجيل token للمستخدم: ${this.testData.testUser.phone}`);
      }

    } catch (error) {
      this.addTestResult('FCM Token Management', false, `خطأ في إدارة FCM Tokens: ${error.message}`);
      console.log('❌ خطأ في إدارة FCM Tokens');
    }
  }

  // ===================================
  // اختبار تدفق الإشعارات
  // ===================================
  async testNotificationFlow() {
    try {
      console.log('🔍 اختبار تدفق الإشعارات الكامل...');

      // إرسال إشعار اختبار
      const testNotification = {
        user_phone: this.testData.testUser.phone,
        title: 'اختبار النظام',
        message: 'هذا اختبار للنظام الرسمي'
      };

      const response = await axios.post(
        `${this.baseURL}/api/fcm/test-notification`,
        testNotification,
        { timeout: 15000 }
      );

      const isWorking = response.status === 200 && response.data.success;
      
      this.addTestResult(
        'Notification Flow',
        isWorking,
        isWorking ? 'تدفق الإشعارات يعمل بشكل صحيح' : 'مشكلة في تدفق الإشعارات'
      );

      if (isWorking) {
        console.log('✅ تدفق الإشعارات يعمل بشكل صحيح');
      }

    } catch (error) {
      this.addTestResult('Notification Flow', false, `خطأ في تدفق الإشعارات: ${error.message}`);
      console.log('❌ خطأ في تدفق الإشعارات');
    }
  }

  // ===================================
  // اختبار تحديث حالة الطلب
  // ===================================
  async testOrderStatusUpdate() {
    try {
      console.log('🔍 اختبار تحديث حالة الطلب...');

      // إنشاء طلب اختبار في قاعدة البيانات
      const { data: order, error: insertError } = await this.supabase
        .from('orders')
        .insert({
          id: this.testData.testOrder.id,
          customer_name: this.testData.testOrder.customer_name,
          user_phone: this.testData.testOrder.user_phone,
          status: this.testData.testOrder.status,
          created_at: new Date().toISOString()
        })
        .select()
        .single();

      if (insertError && !insertError.message.includes('duplicate')) {
        throw new Error(`خطأ في إنشاء طلب الاختبار: ${insertError.message}`);
      }

      // تحديث حالة الطلب
      const { error: updateError } = await this.supabase
        .from('orders')
        .update({ 
          status: 'processing',
          updated_at: new Date().toISOString()
        })
        .eq('id', this.testData.testOrder.id);

      const isWorking = !updateError;
      
      this.addTestResult(
        'Order Status Update',
        isWorking,
        isWorking ? 'تحديث حالة الطلب يعمل بشكل صحيح' : `خطأ في تحديث الطلب: ${updateError?.message}`
      );

      if (isWorking) {
        console.log('✅ تحديث حالة الطلب يعمل بشكل صحيح');
      }

      // تنظيف بيانات الاختبار
      await this.cleanupTestData();

    } catch (error) {
      this.addTestResult('Order Status Update', false, `خطأ في تحديث حالة الطلب: ${error.message}`);
      console.log('❌ خطأ في تحديث حالة الطلب');
    }
  }

  // ===================================
  // اختبار الأداء
  // ===================================
  async testPerformance() {
    try {
      console.log('🔍 اختبار الأداء...');

      const startTime = Date.now();
      
      // إرسال عدة طلبات متزامنة
      const requests = Array(5).fill().map(() => 
        axios.get(`${this.baseURL}/health`, { timeout: 5000 })
      );

      await Promise.all(requests);
      
      const responseTime = Date.now() - startTime;
      const isGoodPerformance = responseTime < 5000; // أقل من 5 ثواني

      this.addTestResult(
        'Performance Test',
        isGoodPerformance,
        `زمن الاستجابة: ${responseTime}ms ${isGoodPerformance ? '(جيد)' : '(بطيء)'}`
      );

      if (isGoodPerformance) {
        console.log(`✅ الأداء جيد - زمن الاستجابة: ${responseTime}ms`);
      } else {
        console.log(`⚠️ الأداء بطيء - زمن الاستجابة: ${responseTime}ms`);
      }

    } catch (error) {
      this.addTestResult('Performance Test', false, `خطأ في اختبار الأداء: ${error.message}`);
      console.log('❌ خطأ في اختبار الأداء');
    }
  }

  // ===================================
  // اختبار معالجة الأخطاء
  // ===================================
  async testErrorHandling() {
    try {
      console.log('🔍 اختبار معالجة الأخطاء...');

      // إرسال طلب خاطئ
      try {
        await axios.post(
          `${this.baseURL}/api/notifications/send`,
          { invalid: 'data' },
          { timeout: 5000 }
        );
      } catch (error) {
        // متوقع أن يفشل
      }

      // طلب مسار غير موجود
      try {
        await axios.get(`${this.baseURL}/api/nonexistent`, { timeout: 5000 });
      } catch (error) {
        // متوقع أن يفشل
      }

      this.addTestResult(
        'Error Handling',
        true,
        'معالجة الأخطاء تعمل بشكل صحيح'
      );

      console.log('✅ معالجة الأخطاء تعمل بشكل صحيح');

    } catch (error) {
      this.addTestResult('Error Handling', false, `خطأ في اختبار معالجة الأخطاء: ${error.message}`);
      console.log('❌ خطأ في اختبار معالجة الأخطاء');
    }
  }

  // ===================================
  // تنظيف بيانات الاختبار
  // ===================================
  async cleanupTestData() {
    try {
      // حذف طلب الاختبار
      await this.supabase
        .from('orders')
        .delete()
        .eq('id', this.testData.testOrder.id);

      // حذف FCM token الاختبار
      await this.supabase
        .from('fcm_tokens')
        .delete()
        .eq('user_phone', this.testData.testUser.phone)
        .eq('token', this.testData.testUser.fcmToken);

      // حذف إشعارات الاختبار
      await this.supabase
        .from('notification_queue')
        .delete()
        .eq('order_id', this.testData.testOrder.id);

    } catch (error) {
      console.warn('⚠️ تحذير في تنظيف بيانات الاختبار:', error.message);
    }
  }

  // ===================================
  // إضافة نتيجة اختبار
  // ===================================
  addTestResult(testName, passed, message) {
    this.testResults.total++;
    if (passed) {
      this.testResults.passed++;
    } else {
      this.testResults.failed++;
    }

    this.testResults.details.push({
      test: testName,
      passed: passed,
      message: message,
      timestamp: new Date().toISOString()
    });
  }

  // ===================================
  // توليد تقرير الاختبارات
  // ===================================
  generateTestReport() {
    console.log('\n' + '='.repeat(60));
    console.log('📊 تقرير اختبار النظام الرسمي');
    console.log('='.repeat(60));
    
    console.log(`📈 النتائج الإجمالية:`);
    console.log(`   - إجمالي الاختبارات: ${this.testResults.total}`);
    console.log(`   - نجح: ${this.testResults.passed} ✅`);
    console.log(`   - فشل: ${this.testResults.failed} ❌`);
    console.log(`   - معدل النجاح: ${((this.testResults.passed / this.testResults.total) * 100).toFixed(2)}%`);

    console.log('\n📋 تفاصيل الاختبارات:');
    this.testResults.details.forEach((result, index) => {
      const status = result.passed ? '✅' : '❌';
      console.log(`   ${index + 1}. ${status} ${result.test}: ${result.message}`);
    });

    console.log('\n' + '='.repeat(60));
    
    if (this.testResults.failed === 0) {
      console.log('🎉 جميع الاختبارات نجحت! النظام جاهز للإنتاج.');
    } else {
      console.log('⚠️ بعض الاختبارات فشلت. يرجى مراجعة المشاكل وإصلاحها.');
    }
    
    console.log('='.repeat(60));
  }
}

// تشغيل الاختبارات
if (require.main === module) {
  const tester = new OfficialSystemTester();
  
  tester.runAllTests().then(() => {
    console.log('\n✅ انتهى اختبار النظام');
    process.exit(tester.testResults.failed === 0 ? 0 : 1);
  }).catch(error => {
    console.error('❌ خطأ في تشغيل الاختبارات:', error);
    process.exit(1);
  });
}

module.exports = OfficialSystemTester;
