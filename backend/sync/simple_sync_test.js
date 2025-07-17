// ===================================
// اختبار مبسط لنظام المزامنة
// اختبار سريع للتأكد من عمل النظام الأساسي
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class SimpleSyncTest {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    this.baseUrl = 'http://localhost:3003';
    this.waseetOrderId = '95580376'; // معرف طلب حقيقي من الوسيط
    this.testOrderId = null;

    console.log('🧪 اختبار مبسط لنظام المزامنة');
  }

  // ===================================
  // اختبار شامل مبسط
  // ===================================
  async runSimpleTest() {
    console.log('🚀 بدء الاختبار المبسط...\n');

    try {
      // 1. اختبار الخادم
      await this.testServer();

      // 2. إنشاء طلب تجريبي
      await this.createTestOrder();

      // 3. تشغيل مزامنة يدوية
      await this.runManualSync();

      // 4. فحص النتائج
      await this.checkResults();

      // 5. تنظيف
      await this.cleanup();

      console.log('\n✅ نجح الاختبار المبسط!');
      console.log('🎉 النظام يعمل بشكل صحيح');
      
      return { success: true, message: 'الاختبار نجح' };

    } catch (error) {
      console.error(`\n❌ فشل الاختبار: ${error.message}`);
      await this.cleanup();
      return { success: false, error: error.message };
    }
  }

  // ===================================
  // اختبار الخادم
  // ===================================
  async testServer() {
    console.log('🔍 اختبار الخادم...');
    
    const response = await axios.get(`${this.baseUrl}/api/health`, {
      timeout: 5000
    });

    if (response.status === 200) {
      console.log('✅ الخادم يعمل بشكل صحيح');
    } else {
      throw new Error(`الخادم لا يعمل: ${response.status}`);
    }
  }

  // ===================================
  // إنشاء طلب تجريبي
  // ===================================
  async createTestOrder() {
    console.log('📝 إنشاء طلب تجريبي...');

    const testOrderId = `order_simple_test_${Date.now()}`;
    const orderData = {
      id: testOrderId,
      order_number: `ORD-SIMPLE-TEST-${Date.now()}`,
      customer_name: 'عميل اختبار مبسط',
      primary_phone: '07501234567',
      province: 'بغداد',
      city: 'شارع فلسطين',
      customer_address: 'عنوان تجريبي للاختبار',
      total: 30000,
      delivery_fee: 5000,
      profit_amount: 10000,
      status: 'in_delivery',
      waseet_order_id: this.waseetOrderId,
      notes: 'طلب اختبار مبسط',
      created_at: new Date().toISOString()
    };

    const { data: order, error } = await this.supabase
      .from('orders')
      .insert(orderData)
      .select()
      .single();

    if (error) {
      throw new Error(`فشل في إنشاء الطلب: ${error.message}`);
    }

    this.testOrderId = order.id;
    console.log(`✅ تم إنشاء الطلب: ${order.order_number}`);

    // إضافة عناصر الطلب
    const orderItems = [
      {
        order_id: order.id,
        product_name: 'منتج تجريبي',
        quantity: 1,
        unit_price: 25000,
        total_price: 25000
      }
    ];

    const { error: itemsError } = await this.supabase
      .from('order_items')
      .insert(orderItems);

    if (itemsError) {
      console.warn(`⚠️ فشل في إضافة عناصر الطلب: ${itemsError.message}`);
    } else {
      console.log('✅ تم إضافة عناصر الطلب');
    }
  }

  // ===================================
  // تشغيل مزامنة يدوية
  // ===================================
  async runManualSync() {
    console.log('🔄 تشغيل مزامنة يدوية...');

    const response = await axios.post(`${this.baseUrl}/api/sync/manual`, {}, {
      timeout: 60000
    });

    if (response.status === 200 && response.data.success) {
      console.log('✅ تم تشغيل المزامنة بنجاح');
      
      // انتظار قصير للمعالجة
      await new Promise(resolve => setTimeout(resolve, 3000));
    } else {
      throw new Error(`فشل في المزامنة: ${response.data?.error || 'خطأ غير معروف'}`);
    }
  }

  // ===================================
  // فحص النتائج
  // ===================================
  async checkResults() {
    console.log('🔍 فحص النتائج...');

    // فحص الطلب المحدث
    const { data: order, error } = await this.supabase
      .from('orders')
      .select('*')
      .eq('id', this.testOrderId)
      .single();

    if (error) {
      throw new Error(`فشل في جلب الطلب: ${error.message}`);
    }

    // التحقق من تحديث وقت آخر فحص
    if (order.last_status_check) {
      const lastCheck = new Date(order.last_status_check);
      const now = new Date();
      const timeDiff = now - lastCheck;
      
      if (timeDiff < 5 * 60 * 1000) { // أقل من 5 دقائق
        console.log('✅ تم تحديث وقت آخر فحص');
      } else {
        console.log('⚠️ وقت آخر فحص قديم');
      }
    } else {
      console.log('⚠️ لم يتم تحديث وقت آخر فحص');
    }

    // فحص سجلات النظام
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    
    const { data: logs, error: logsError } = await this.supabase
      .from('system_logs')
      .select('*')
      .eq('service', 'order_status_sync')
      .gte('created_at', fiveMinutesAgo)
      .order('created_at', { ascending: false });

    if (!logsError && logs && logs.length > 0) {
      console.log(`✅ تم العثور على ${logs.length} سجل نظام حديث`);
    } else {
      console.log('⚠️ لا توجد سجلات نظام حديثة');
    }

    console.log('✅ تم فحص النتائج');
  }

  // ===================================
  // تنظيف البيانات التجريبية
  // ===================================
  async cleanup() {
    if (this.testOrderId) {
      console.log('🧹 تنظيف البيانات التجريبية...');

      try {
        // حذف عناصر الطلب
        await this.supabase
          .from('order_items')
          .delete()
          .eq('order_id', this.testOrderId);

        // حذف سجل التاريخ
        await this.supabase
          .from('order_status_history')
          .delete()
          .eq('order_id', this.testOrderId);

        // حذف الإشعارات
        await this.supabase
          .from('notifications')
          .delete()
          .eq('order_id', this.testOrderId);

        // حذف الطلب
        await this.supabase
          .from('orders')
          .delete()
          .eq('id', this.testOrderId);

        console.log('✅ تم تنظيف البيانات التجريبية');
      } catch (error) {
        console.warn(`⚠️ فشل في تنظيف البيانات: ${error.message}`);
      }
    }
  }

  // ===================================
  // اختبار سريع للمزامنة فقط
  // ===================================
  async quickSyncTest() {
    console.log('⚡ اختبار سريع للمزامنة...\n');

    try {
      // اختبار الخادم
      await this.testServer();

      // تشغيل مزامنة
      await this.runManualSync();

      console.log('\n✅ نجح الاختبار السريع!');
      return { success: true };

    } catch (error) {
      console.error(`\n❌ فشل الاختبار السريع: ${error.message}`);
      return { success: false, error: error.message };
    }
  }
}

// تشغيل الاختبار إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  const tester = new SimpleSyncTest();
  
  // تحديد نوع الاختبار من المعاملات
  const testType = process.argv[2] || 'full';
  
  if (testType === 'quick') {
    tester.quickSyncTest()
      .then(result => {
        process.exit(result.success ? 0 : 1);
      });
  } else {
    tester.runSimpleTest()
      .then(result => {
        process.exit(result.success ? 0 : 1);
      });
  }
}

module.exports = SimpleSyncTest;
