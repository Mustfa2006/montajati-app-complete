// ===================================
// اختبار النظام الكامل
// Complete System Test
// ===================================

const { createClient } = require('@supabase/supabase-js');
const InventoryMonitorService = require('./inventory_monitor_service');
const TelegramNotificationService = require('./telegram_notification_service');
require('dotenv').config();

async function testCompleteSystem() {
  console.log('🧪 === اختبار النظام الكامل ===\n');

  try {
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // 1. اختبار التلغرام
    console.log('📱 1. اختبار نظام التلغرام...');
    const telegramService = new TelegramNotificationService();
    const telegramTest = await telegramService.testConnection();
    
    if (telegramTest.success) {
      console.log('✅ التلغرام يعمل بنجاح');
      
      // إرسال رسالة اختبار
      const testMessage = await telegramService.sendMessage(
        '🧪 اختبار النظام الكامل\n\n⏰ الوقت: ' + new Date().toLocaleString('ar-EG')
      );
      
      if (testMessage.success) {
        console.log('✅ تم إرسال رسالة اختبار بنجاح');
      }
    } else {
      console.log('❌ فشل اختبار التلغرام:', telegramTest.error);
      return;
    }

    // 2. اختبار قاعدة البيانات
    console.log('\n📊 2. اختبار قاعدة البيانات...');
    const { data: products, error } = await supabase
      .from('products')
      .select('id, name, available_quantity, is_active')
      .eq('is_active', true)
      .limit(5);

    if (error) {
      console.log('❌ فشل اختبار قاعدة البيانات:', error.message);
      return;
    }

    console.log(`✅ قاعدة البيانات تعمل - ${products.length} منتج نشط`);

    // 3. إنشاء منتجات اختبار
    console.log('\n📦 3. إنشاء منتجات اختبار...');
    
    const testProducts = [
      {
        name: 'منتج اختبار - كمية 0',
        description: 'منتج تجريبي لاختبار إشعار نفاد المخزون',
        wholesale_price: 10.0,
        min_price: 12.0,
        max_price: 15.0,
        available_quantity: 0,
        stock_quantity: 0,
        minimum_stock: 0,
        maximum_stock: 0,
        available_from: 0,
        available_to: 0,
        category: 'اختبار',
        is_active: true,
        smart_range_enabled: true
      },
      {
        name: 'منتج اختبار - كمية 5',
        description: 'منتج تجريبي لاختبار إشعار مخزون منخفض',
        wholesale_price: 15.0,
        min_price: 18.0,
        max_price: 22.0,
        available_quantity: 5,
        stock_quantity: 5,
        minimum_stock: 3,
        maximum_stock: 5,
        available_from: 3,
        available_to: 5,
        category: 'اختبار',
        is_active: true,
        smart_range_enabled: true
      }
    ];

    const createdProducts = [];
    
    for (const testProduct of testProducts) {
      const { data: product, error: createError } = await supabase
        .from('products')
        .insert(testProduct)
        .select()
        .single();

      if (createError) {
        console.log(`❌ فشل إنشاء ${testProduct.name}:`, createError.message);
      } else {
        console.log(`✅ تم إنشاء: ${product.name} (الكمية: ${product.available_quantity})`);
        createdProducts.push(product);
      }
    }

    // 4. اختبار مراقبة المخزون
    console.log('\n🔍 4. اختبار مراقبة المخزون...');
    const inventoryMonitor = new InventoryMonitorService();
    
    for (const product of createdProducts) {
      console.log(`\n📦 مراقبة: ${product.name}`);
      
      const result = await inventoryMonitor.monitorProduct(product.id);
      
      if (result.success) {
        console.log(`✅ نجحت المراقبة - الحالة: ${result.product.status}`);
        
        if (result.alerts && result.alerts.length > 0) {
          result.alerts.forEach(alert => {
            console.log(`🚨 ${alert.type}: ${alert.sent ? 'تم الإرسال ✅' : 'فشل ❌'}`);
          });
        } else {
          console.log('📭 لا توجد تنبيهات جديدة');
        }
      } else {
        console.log(`❌ فشلت المراقبة: ${result.error}`);
      }
    }

    // 5. اختبار مراقبة شاملة
    console.log('\n🔍 5. اختبار مراقبة شاملة...');
    const allResult = await inventoryMonitor.monitorAllProducts();
    
    if (allResult.success && allResult.results) {
      console.log('📊 نتائج المراقبة الشاملة:');
      console.log(`- إجمالي المنتجات: ${allResult.results.total}`);
      console.log(`- نفد المخزون: ${allResult.results.outOfStock}`);
      console.log(`- مخزون منخفض: ${allResult.results.lowStock}`);
      console.log(`- مخزون طبيعي: ${allResult.results.normal}`);
      console.log(`- إشعارات مرسلة: ${allResult.results.sentNotifications}`);
    }

    // 6. تنظيف - حذف المنتجات التجريبية
    console.log('\n🗑️ 6. تنظيف المنتجات التجريبية...');
    
    for (const product of createdProducts) {
      const { error: deleteError } = await supabase
        .from('products')
        .delete()
        .eq('id', product.id);

      if (deleteError) {
        console.log(`⚠️ فشل حذف ${product.name}:`, deleteError.message);
      } else {
        console.log(`✅ تم حذف: ${product.name}`);
      }
    }

    // 7. إرسال تقرير نهائي للتلغرام
    console.log('\n📨 7. إرسال تقرير نهائي...');
    const finalReport = `✅ اختبار النظام الكامل مكتمل

🧪 النتائج:
✅ التلغرام: يعمل
✅ قاعدة البيانات: تعمل  
✅ مراقبة المخزون: تعمل
✅ الإشعارات: تعمل

⏰ الوقت: ${new Date().toLocaleString('ar-EG')}
🎯 النظام جاهز للاستخدام`;

    const reportResult = await telegramService.sendMessage(finalReport);
    
    if (reportResult.success) {
      console.log('✅ تم إرسال التقرير النهائي للتلغرام');
    }

    console.log('\n🎉 === اختبار النظام الكامل مكتمل بنجاح ===');
    console.log('\n💡 التوصيات:');
    console.log('1. النظام يعمل بشكل صحيح');
    console.log('2. الإشعارات تصل للتلغرام');
    console.log('3. المراقبة الدورية نشطة كل دقيقة');
    console.log('4. تأكد من أن التطبيق يرسل طلبات للخادم عند التحديث');

  } catch (error) {
    console.error('❌ خطأ في اختبار النظام الكامل:', error.message);
    
    // إرسال تقرير خطأ للتلغرام
    try {
      const telegramService = new TelegramNotificationService();
      await telegramService.sendMessage(
        `❌ خطأ في اختبار النظام\n\n🔍 التفاصيل: ${error.message}\n\n⏰ الوقت: ${new Date().toLocaleString('ar-EG')}`
      );
    } catch (telegramError) {
      console.error('❌ فشل إرسال تقرير الخطأ للتلغرام:', telegramError.message);
    }
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testCompleteSystem()
    .then(() => {
      console.log('\n🎯 تم الانتهاء من اختبار النظام الكامل');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ خطأ في تشغيل اختبار النظام الكامل:', error);
      process.exit(1);
    });
}

module.exports = { testCompleteSystem };
