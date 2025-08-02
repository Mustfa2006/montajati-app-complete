// ===================================
// اختبار مراقبة المنتجات يدوياً
// Manual Product Monitoring Test
// ===================================

const { createClient } = require('@supabase/supabase-js');
const InventoryMonitorService = require('./inventory_monitor_service');
require('dotenv').config();

async function testManualMonitoring() {
  console.log('🔍 === اختبار مراقبة المنتجات يدوياً ===\n');

  try {
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // 1. جلب جميع المنتجات النشطة
    console.log('📦 جلب جميع المنتجات النشطة...');
    const { data: products, error } = await supabase
      .from('products')
      .select('id, name, available_quantity, is_active')
      .eq('is_active', true)
      .order('available_quantity', { ascending: true });

    if (error) {
      console.log('❌ خطأ في جلب المنتجات:', error.message);
      return;
    }

    console.log(`✅ تم جلب ${products.length} منتج نشط\n`);

    // 2. عرض المنتجات مع كمياتها
    console.log('📊 قائمة المنتجات والكميات:');
    products.forEach((product, index) => {
      const status = product.available_quantity === 0 ? '🚨 نفد' : 
                    product.available_quantity <= 5 ? '⚠️ منخفض' : '✅ طبيعي';
      console.log(`${index + 1}. ${product.name} - الكمية: ${product.available_quantity} ${status}`);
    });

    // 3. اختبار مراقبة المنتجات ذات الكميات المنخفضة
    console.log('\n🔍 اختبار مراقبة المنتجات ذات الكميات المنخفضة...');
    const inventoryMonitor = new InventoryMonitorService();
    
    const lowStockProducts = products.filter(p => p.available_quantity <= 5);
    
    if (lowStockProducts.length === 0) {
      console.log('📭 لا توجد منتجات بكميات منخفضة للاختبار');
      
      // إنشاء منتج تجريبي بكمية منخفضة
      console.log('\n📦 إنشاء منتج تجريبي بكمية منخفضة...');
      const testProduct = {
        name: 'منتج اختبار مراقبة يدوي',
        description: 'منتج تجريبي لاختبار المراقبة اليدوية',
        wholesale_price: 10.0,
        min_price: 12.0,
        max_price: 15.0,
        available_quantity: 3, // كمية منخفضة
        stock_quantity: 3,
        minimum_stock: 2,
        maximum_stock: 3,
        available_from: 2,
        available_to: 3,
        category: 'اختبار',
        is_active: true,
        smart_range_enabled: true
      };

      const { data: newProduct, error: createError } = await supabase
        .from('products')
        .insert(testProduct)
        .select()
        .single();

      if (createError) {
        console.log('❌ فشل إنشاء المنتج التجريبي:', createError.message);
        return;
      }

      console.log('✅ تم إنشاء المنتج التجريبي:', newProduct.name);
      lowStockProducts.push(newProduct);
    }

    // 4. مراقبة كل منتج منخفض الكمية
    console.log(`\n🔍 مراقبة ${lowStockProducts.length} منتج منخفض الكمية...`);
    
    for (const product of lowStockProducts) {
      console.log(`\n📦 مراقبة: ${product.name} (الكمية: ${product.available_quantity})`);
      
      const result = await inventoryMonitor.monitorProduct(product.id);
      
      if (result.success) {
        console.log(`✅ نجحت المراقبة - الحالة: ${result.product.status}`);
        
        if (result.alerts && result.alerts.length > 0) {
          result.alerts.forEach(alert => {
            console.log(`🚨 تنبيه: ${alert.type} - ${alert.sent ? 'تم الإرسال ✅' : 'فشل الإرسال ❌'}`);
          });
        } else {
          console.log('📭 لا توجد تنبيهات جديدة');
        }
      } else {
        console.log(`❌ فشلت المراقبة: ${result.error}`);
      }
    }

    // 5. اختبار مراقبة جميع المنتجات
    console.log('\n🔍 اختبار مراقبة جميع المنتجات...');
    const allResult = await inventoryMonitor.monitorAllProducts();
    
    if (allResult.success && allResult.results) {
      console.log('📊 نتائج المراقبة الشاملة:');
      console.log(`- إجمالي المنتجات: ${allResult.results.total}`);
      console.log(`- نفد المخزون: ${allResult.results.outOfStock}`);
      console.log(`- مخزون منخفض: ${allResult.results.lowStock}`);
      console.log(`- مخزون طبيعي: ${allResult.results.normal}`);
      console.log(`- إشعارات مرسلة: ${allResult.results.sentNotifications}`);
    }

    // 6. حذف المنتجات التجريبية
    console.log('\n🗑️ حذف المنتجات التجريبية...');
    const { error: deleteError } = await supabase
      .from('products')
      .delete()
      .like('name', '%اختبار%');

    if (deleteError) {
      console.log('⚠️ تحذير: فشل حذف بعض المنتجات التجريبية:', deleteError.message);
    } else {
      console.log('✅ تم حذف المنتجات التجريبية');
    }

    console.log('\n✅ === انتهى اختبار المراقبة اليدوية ===');

  } catch (error) {
    console.error('❌ خطأ في اختبار المراقبة اليدوية:', error.message);
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testManualMonitoring()
    .then(() => {
      console.log('\n🎯 تم الانتهاء من الاختبار');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ خطأ في تشغيل الاختبار:', error);
      process.exit(1);
    });
}

module.exports = { testManualMonitoring };
