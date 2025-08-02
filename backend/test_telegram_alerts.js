// ===================================
// اختبار إشعارات التلغرام للمخزون
// Test Telegram Inventory Alerts
// ===================================

const { createClient } = require('@supabase/supabase-js');
const InventoryMonitorService = require('./inventory_monitor_service');
const TelegramNotificationService = require('./telegram_notification_service');
require('dotenv').config();

async function testTelegramAlerts() {
  console.log('🧪 === اختبار إشعارات التلغرام للمخزون ===\n');

  try {
    // 1. اختبار اتصال التلغرام
    console.log('📱 اختبار اتصال التلغرام...');
    const telegramService = new TelegramNotificationService();
    const connectionTest = await telegramService.testConnection();
    
    if (connectionTest.success) {
      console.log('✅ اتصال التلغرام يعمل بنجاح');
      console.log(`🤖 البوت: ${connectionTest.botInfo.username}`);
      console.log(`📋 الاسم: ${connectionTest.botInfo.first_name}`);
    } else {
      console.log('❌ فشل اتصال التلغرام:', connectionTest.error);
      return;
    }

    // 2. اختبار إرسال رسالة تجريبية
    console.log('\n📤 اختبار إرسال رسالة تجريبية...');
    const testMessage = await telegramService.sendMessage('🧪 اختبار نظام إشعارات المخزون\n\n⏰ الوقت: ' + new Date().toLocaleString('ar-EG'));
    
    if (testMessage.success) {
      console.log('✅ تم إرسال الرسالة التجريبية بنجاح');
      console.log(`📨 معرف الرسالة: ${testMessage.messageId}`);
    } else {
      console.log('❌ فشل إرسال الرسالة التجريبية:', testMessage.error);
    }

    // 3. إنشاء منتج تجريبي بكمية 5
    console.log('\n📦 إنشاء منتج تجريبي بكمية 5...');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    const testProduct = {
      name: 'منتج اختبار التلغرام - كمية 5',
      description: 'منتج تجريبي لاختبار إشعارات التلغرام',
      wholesale_price: 10.0,
      min_price: 12.0,
      max_price: 15.0,
      available_quantity: 5, // كمية منخفضة لتفعيل التنبيه
      stock_quantity: 5,
      minimum_stock: 3,
      maximum_stock: 5,
      available_from: 3,
      available_to: 5,
      category: 'اختبار',
      is_active: true,
      smart_range_enabled: true
    };

    const { data: product, error: createError } = await supabase
      .from('products')
      .insert(testProduct)
      .select()
      .single();

    if (createError) {
      console.log('❌ فشل إنشاء المنتج التجريبي:', createError.message);
      return;
    }

    console.log('✅ تم إنشاء المنتج التجريبي:', product.name);
    console.log(`📊 الكمية: ${product.available_quantity}`);

    // 4. اختبار مراقبة المنتج (كمية 5)
    console.log('\n🔍 اختبار مراقبة المنتج بكمية 5...');
    const inventoryMonitor = new InventoryMonitorService();
    const monitorResult = await inventoryMonitor.monitorProduct(product.id);

    console.log('📊 نتيجة المراقبة:');
    console.log('- النجاح:', monitorResult.success);
    console.log('- حالة المنتج:', monitorResult.product?.status);
    console.log('- الكمية:', monitorResult.product?.quantity);

    if (monitorResult.alerts && monitorResult.alerts.length > 0) {
      console.log('🚨 التنبيهات المرسلة:');
      monitorResult.alerts.forEach(alert => {
        console.log(`  - ${alert.type}: ${alert.sent ? 'تم الإرسال ✅' : 'فشل الإرسال ❌'}`);
      });
    } else {
      console.log('📭 لا توجد تنبيهات');
    }

    // 5. تحديث المنتج إلى كمية 0
    console.log('\n📉 تحديث المنتج إلى كمية 0...');
    const { error: updateError } = await supabase
      .from('products')
      .update({ 
        available_quantity: 0,
        stock_quantity: 0,
        available_from: 0,
        available_to: 0
      })
      .eq('id', product.id);

    if (updateError) {
      console.log('❌ فشل تحديث المنتج:', updateError.message);
    } else {
      console.log('✅ تم تحديث المنتج إلى كمية 0');

      // 6. اختبار مراقبة المنتج (كمية 0)
      console.log('\n🔍 اختبار مراقبة المنتج بكمية 0...');
      const zeroMonitorResult = await inventoryMonitor.monitorProduct(product.id);

      console.log('📊 نتيجة المراقبة (كمية 0):');
      console.log('- النجاح:', zeroMonitorResult.success);
      console.log('- حالة المنتج:', zeroMonitorResult.product?.status);
      console.log('- الكمية:', zeroMonitorResult.product?.quantity);

      if (zeroMonitorResult.alerts && zeroMonitorResult.alerts.length > 0) {
        console.log('🚨 التنبيهات المرسلة:');
        zeroMonitorResult.alerts.forEach(alert => {
          console.log(`  - ${alert.type}: ${alert.sent ? 'تم الإرسال ✅' : 'فشل الإرسال ❌'}`);
        });
      } else {
        console.log('📭 لا توجد تنبيهات');
      }
    }

    // 7. حذف المنتج التجريبي
    console.log('\n🗑️ حذف المنتج التجريبي...');
    const { error: deleteError } = await supabase
      .from('products')
      .delete()
      .eq('id', product.id);

    if (deleteError) {
      console.log('❌ فشل حذف المنتج التجريبي:', deleteError.message);
    } else {
      console.log('✅ تم حذف المنتج التجريبي');
    }

    // 8. اختبار مراقبة جميع المنتجات
    console.log('\n🔍 اختبار مراقبة جميع المنتجات...');
    const allProductsResult = await inventoryMonitor.monitorAllProducts();

    if (allProductsResult.success && allProductsResult.results) {
      console.log('📊 إحصائيات المراقبة الشاملة:');
      console.log(`- إجمالي المنتجات: ${allProductsResult.results.total}`);
      console.log(`- نفد المخزون: ${allProductsResult.results.outOfStock}`);
      console.log(`- مخزون منخفض: ${allProductsResult.results.lowStock}`);
      console.log(`- مخزون طبيعي: ${allProductsResult.results.normal}`);
      console.log(`- إشعارات مرسلة: ${allProductsResult.results.sentNotifications}`);
    }

    console.log('\n✅ === انتهى اختبار إشعارات التلغرام ===');

  } catch (error) {
    console.error('❌ خطأ في اختبار إشعارات التلغرام:', error.message);
    console.error('📋 التفاصيل:', error);
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testTelegramAlerts()
    .then(() => {
      console.log('\n🎯 تم الانتهاء من الاختبار');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ خطأ في تشغيل الاختبار:', error);
      process.exit(1);
    });
}

module.exports = { testTelegramAlerts };
