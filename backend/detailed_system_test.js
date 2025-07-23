// ===================================
// فحص شامل ومفصل لنظام المزامنة
// Comprehensive Detailed System Test
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
const statusMapper = require('./sync/status_mapper');
const InstantStatusUpdater = require('./sync/instant_status_updater');
require('dotenv').config();

class DetailedSystemTester {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات شركة الوسيط
    this.waseetConfig = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD,
      token: null
    };

    // نظام التحديث الفوري
    this.instantUpdater = new InstantStatusUpdater();

    // نتائج الاختبار
    this.testResults = {
      database_check: null,
      waseet_connection: null,
      status_fetch: null,
      status_mapping: null,
      database_update: null,
      history_log: null,
      app_update: null,
      full_flow: null
    };

    console.log('🔍 تم تهيئة أداة الفحص الشامل والمفصل');
  }

  // ===================================
  // 1. فحص قاعدة البيانات
  // ===================================
  async testDatabaseCheck() {
    try {
      console.log('\n🗄️ الخطوة 1: فحص قاعدة البيانات...');
      
      // فحص الطلبات المؤهلة للمزامنة
      const { data: orders, error } = await this.supabase
        .from('orders')
        .select('id, order_number, status, waseet_order_id, waseet_status, last_status_check')
        .not('waseet_order_id', 'is', null)
        .in('status', ['active', 'in_delivery'])
        .limit(5);

      if (error) {
        throw new Error(`خطأ في قاعدة البيانات: ${error.message}`);
      }

      console.log(`✅ تم العثور على ${orders.length} طلب مؤهل للمزامنة`);
      
      if (orders.length > 0) {
        console.log('📋 عينة من الطلبات:');
        orders.forEach((order, index) => {
          console.log(`   ${index + 1}. ${order.order_number} - ${order.status} (الوسيط: ${order.waseet_order_id})`);
        });
      }

      this.testResults.database_check = {
        success: true,
        orders_found: orders.length,
        sample_orders: orders
      };

      return orders;

    } catch (error) {
      console.error('❌ فشل فحص قاعدة البيانات:', error.message);
      this.testResults.database_check = {
        success: false,
        error: error.message
      };
      return [];
    }
  }

  // ===================================
  // 2. اختبار الاتصال مع شركة الوسيط
  // ===================================
  async testWaseetConnection() {
    try {
      console.log('\n🔗 الخطوة 2: اختبار الاتصال مع شركة الوسيط...');

      // تسجيل الدخول
      const loginData = new URLSearchParams({
        username: this.waseetConfig.username,
        password: this.waseetConfig.password
      });

      const response = await axios.post(
        `${this.waseetConfig.baseUrl}/merchant/login`,
        loginData,
        {
          timeout: 15000,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          maxRedirects: 0,
          validateStatus: () => true
        }
      );

      if (response.status === 302 || response.status === 303 || 
          (response.headers['set-cookie'] && 
           response.headers['set-cookie'].some(cookie => cookie.includes('PHPSESSID')))) {
        
        this.waseetConfig.token = response.headers['set-cookie']?.join('; ') || '';
        console.log('✅ تم تسجيل الدخول بنجاح');
        
        this.testResults.waseet_connection = {
          success: true,
          status_code: response.status,
          has_token: !!this.waseetConfig.token
        };

        return true;
      } else {
        throw new Error(`فشل تسجيل الدخول: ${response.status}`);
      }

    } catch (error) {
      console.error('❌ فشل الاتصال مع شركة الوسيط:', error.message);
      this.testResults.waseet_connection = {
        success: false,
        error: error.message
      };
      return false;
    }
  }

  // ===================================
  // 3. اختبار جلب حالة طلب محدد
  // ===================================
  async testStatusFetch(order) {
    try {
      console.log(`\n📊 الخطوة 3: اختبار جلب حالة الطلب ${order.order_number}...`);
      console.log(`🔍 معرف الوسيط: ${order.waseet_order_id}`);
      console.log(`📋 الحالة الحالية: ${order.status}`);

      if (!this.waseetConfig.token) {
        throw new Error('لا يوجد توكن صالح');
      }

      const response = await axios.get(
        `${this.waseetConfig.baseUrl}/merchant/get_order_status`,
        {
          params: { order_id: order.waseet_order_id },
          timeout: 15000,
          headers: {
            'Cookie': this.waseetConfig.token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          }
        }
      );

      console.log(`📡 استجابة الوسيط:`, JSON.stringify(response.data, null, 2));

      if (response.data && response.data.status) {
        const waseetStatus = response.data.status;
        console.log(`✅ تم جلب الحالة من الوسيط: ${waseetStatus}`);

        this.testResults.status_fetch = {
          success: true,
          order_id: order.id,
          waseet_order_id: order.waseet_order_id,
          current_status: order.status,
          waseet_status: waseetStatus,
          full_response: response.data
        };

        return {
          success: true,
          waseetStatus,
          waseetData: response.data
        };
      } else {
        throw new Error('استجابة غير صحيحة من شركة الوسيط');
      }

    } catch (error) {
      console.error(`❌ فشل جلب حالة الطلب ${order.order_number}:`, error.message);
      this.testResults.status_fetch = {
        success: false,
        order_id: order.id,
        error: error.message
      };
      return { success: false, error: error.message };
    }
  }

  // ===================================
  // 4. اختبار تحويل الحالات
  // ===================================
  async testStatusMapping(waseetStatus, currentStatus) {
    try {
      console.log(`\n🗺️ الخطوة 4: اختبار تحويل الحالات...`);
      console.log(`📥 حالة الوسيط: ${waseetStatus}`);
      console.log(`📋 الحالة الحالية: ${currentStatus}`);

      const localStatus = statusMapper.mapWaseetToLocal(waseetStatus);
      const hasChanged = localStatus !== currentStatus;

      console.log(`📤 الحالة المحلية: ${localStatus}`);
      console.log(`🔄 هل تغيرت الحالة؟ ${hasChanged ? 'نعم' : 'لا'}`);

      if (hasChanged) {
        console.log(`✨ تغيير الحالة: ${currentStatus} → ${localStatus}`);
      }

      this.testResults.status_mapping = {
        success: true,
        waseet_status: waseetStatus,
        current_status: currentStatus,
        mapped_status: localStatus,
        has_changed: hasChanged,
        description: statusMapper.getStatusDescription(localStatus),
        notification_message: statusMapper.getNotificationMessage(localStatus)
      };

      return {
        success: true,
        localStatus,
        hasChanged
      };

    } catch (error) {
      console.error('❌ فشل تحويل الحالات:', error.message);
      this.testResults.status_mapping = {
        success: false,
        error: error.message
      };
      return { success: false, error: error.message };
    }
  }

  // ===================================
  // 5. اختبار تحديث قاعدة البيانات
  // ===================================
  async testDatabaseUpdate(orderId, newWaseetStatus, waseetData) {
    try {
      console.log(`\n💾 الخطوة 5: اختبار تحديث قاعدة البيانات...`);
      console.log(`🆔 معرف الطلب: ${orderId}`);
      console.log(`📊 الحالة الجديدة: ${newWaseetStatus}`);

      // استخدام نظام التحديث الفوري
      const updateResult = await this.instantUpdater.instantUpdateOrderStatus(
        orderId,
        newWaseetStatus,
        waseetData
      );

      if (updateResult.success) {
        console.log(`✅ تم تحديث قاعدة البيانات بنجاح`);
        if (updateResult.changed) {
          console.log(`🔄 تغيير الحالة: ${updateResult.oldStatus} → ${updateResult.newStatus}`);
        } else {
          console.log(`📊 لا يوجد تغيير في الحالة`);
        }

        this.testResults.database_update = {
          success: true,
          order_id: orderId,
          changed: updateResult.changed,
          old_status: updateResult.oldStatus,
          new_status: updateResult.newStatus,
          update_time: updateResult.updateTime
        };

        return updateResult;
      } else {
        throw new Error(updateResult.error);
      }

    } catch (error) {
      console.error('❌ فشل تحديث قاعدة البيانات:', error.message);
      this.testResults.database_update = {
        success: false,
        order_id: orderId,
        error: error.message
      };
      return { success: false, error: error.message };
    }
  }

  // ===================================
  // 6. فحص سجل التغييرات
  // ===================================
  async testHistoryLog(orderId) {
    try {
      console.log(`\n📚 الخطوة 6: فحص سجل التغييرات...`);

      const { data: history, error } = await this.supabase
        .from('order_status_history')
        .select('*')
        .eq('order_id', orderId)
        .order('created_at', { ascending: false })
        .limit(3);

      if (error) {
        throw new Error(`خطأ في جلب السجل: ${error.message}`);
      }

      console.log(`📋 تم العثور على ${history.length} سجل تغيير`);
      
      if (history.length > 0) {
        console.log('📝 آخر التغييرات:');
        history.forEach((record, index) => {
          console.log(`   ${index + 1}. ${record.old_status} → ${record.new_status} (${record.created_at})`);
        });
      }

      this.testResults.history_log = {
        success: true,
        order_id: orderId,
        records_found: history.length,
        latest_records: history
      };

      return history;

    } catch (error) {
      console.error('❌ فشل فحص سجل التغييرات:', error.message);
      this.testResults.history_log = {
        success: false,
        order_id: orderId,
        error: error.message
      };
      return [];
    }
  }

  // ===================================
  // 7. اختبار التدفق الكامل
  // ===================================
  async testFullFlow() {
    try {
      console.log('\n🚀 بدء اختبار التدفق الكامل...');
      console.log('=' * 60);

      // 1. فحص قاعدة البيانات
      const orders = await this.testDatabaseCheck();
      if (orders.length === 0) {
        throw new Error('لا توجد طلبات للاختبار');
      }

      // 2. اختبار الاتصال
      const connectionSuccess = await this.testWaseetConnection();
      if (!connectionSuccess) {
        throw new Error('فشل الاتصال مع شركة الوسيط');
      }

      // 3. اختبار طلب واحد
      const testOrder = orders[0];
      console.log(`\n🎯 اختبار الطلب: ${testOrder.order_number}`);

      // 4. جلب الحالة
      const statusResult = await this.testStatusFetch(testOrder);
      if (!statusResult.success) {
        throw new Error('فشل جلب الحالة');
      }

      // 5. تحويل الحالة
      const mappingResult = await this.testStatusMapping(
        statusResult.waseetStatus,
        testOrder.status
      );
      if (!mappingResult.success) {
        throw new Error('فشل تحويل الحالة');
      }

      // 6. تحديث قاعدة البيانات
      const updateResult = await this.testDatabaseUpdate(
        testOrder.id,
        statusResult.waseetStatus,
        statusResult.waseetData
      );
      if (!updateResult.success) {
        throw new Error('فشل تحديث قاعدة البيانات');
      }

      // 7. فحص السجل
      await this.testHistoryLog(testOrder.id);

      this.testResults.full_flow = {
        success: true,
        test_order: testOrder.order_number,
        completed_steps: 7,
        message: 'تم اختبار التدفق الكامل بنجاح'
      };

      console.log('\n✅ تم اختبار التدفق الكامل بنجاح!');
      return true;

    } catch (error) {
      console.error('❌ فشل اختبار التدفق الكامل:', error.message);
      this.testResults.full_flow = {
        success: false,
        error: error.message
      };
      return false;
    }
  }

  // ===================================
  // طباعة التقرير النهائي
  // ===================================
  printFinalReport() {
    console.log('\n' + '🎯'.repeat(60));
    console.log('التقرير النهائي - فحص شامل لنظام المزامنة');
    console.log('🎯'.repeat(60));

    const tests = [
      { name: 'فحص قاعدة البيانات', result: this.testResults.database_check },
      { name: 'الاتصال مع الوسيط', result: this.testResults.waseet_connection },
      { name: 'جلب الحالة', result: this.testResults.status_fetch },
      { name: 'تحويل الحالات', result: this.testResults.status_mapping },
      { name: 'تحديث قاعدة البيانات', result: this.testResults.database_update },
      { name: 'سجل التغييرات', result: this.testResults.history_log },
      { name: 'التدفق الكامل', result: this.testResults.full_flow }
    ];

    tests.forEach(test => {
      const icon = test.result?.success ? '✅' : '❌';
      const status = test.result?.success ? 'نجح' : 'فشل';
      console.log(`${icon} ${test.name}: ${status}`);
      
      if (!test.result?.success && test.result?.error) {
        console.log(`   ❌ الخطأ: ${test.result.error}`);
      }
    });

    const successCount = tests.filter(test => test.result?.success).length;
    const successRate = (successCount / tests.length * 100).toFixed(1);

    console.log(`\n📈 معدل النجاح: ${successRate}% (${successCount}/${tests.length})`);
    console.log('\n🎯'.repeat(60));

    return {
      success_rate: successRate,
      successful_tests: successCount,
      total_tests: tests.length,
      results: this.testResults
    };
  }
}

// تشغيل الاختبار
async function main() {
  const tester = new DetailedSystemTester();
  await tester.testFullFlow();
  const report = tester.printFinalReport();
  
  console.log('\n📊 تفاصيل النتائج:');
  console.log(JSON.stringify(report.results, null, 2));
}

// تشغيل الاختبار إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  main().catch(error => {
    console.error('❌ خطأ في تشغيل الاختبار:', error.message);
    process.exit(1);
  });
}

module.exports = DetailedSystemTester;
