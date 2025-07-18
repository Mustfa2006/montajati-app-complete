// ===================================
// اختبار مستويات المخزون المحددة
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const InventoryMonitorService = require('./inventory_monitor_service');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testStockLevels() {
  console.log('🧪 اختبار مستويات المخزون المحددة...');
  
  try {
    const inventoryMonitor = new InventoryMonitorService();
    
    // إنشاء منتجات تجريبية بكميات مختلفة
    const testProducts = [
      { name: 'منتج تجريبي - كمية 0', quantity: 0 },
      { name: 'منتج تجريبي - كمية 1', quantity: 1 },
      { name: 'منتج تجريبي - كمية 2', quantity: 2 },
      { name: 'منتج تجريبي - كمية 3', quantity: 3 },
      { name: 'منتج تجريبي - كمية 4', quantity: 4 },
      { name: 'منتج تجريبي - كمية 5', quantity: 5 },
      { name: 'منتج تجريبي - كمية 6', quantity: 6 },
      { name: 'منتج تجريبي - كمية 10', quantity: 10 }
    ];
    
    console.log('📦 إنشاء منتجات تجريبية...');
    
    const createdProducts = [];
    
    for (const testProduct of testProducts) {
      const { data: product, error } = await supabase
        .from('products')
        .insert({
          name: testProduct.name,
          description: 'منتج تجريبي لاختبار مستويات المخزون',
          category: 'اختبار',
          available_quantity: testProduct.quantity,
          wholesale_price: 100,
          min_price: 120,
          max_price: 150,
          is_active: true,
          images: [],
          owner_id: '3879219d-7b4a-4d00-bca2-f49936bf72a4' // مستخدم موجود
        })
        .select()
        .single();
      
      if (error) {
        console.error(`❌ خطأ في إنشاء ${testProduct.name}:`, error.message);
      } else {
        console.log(`✅ تم إنشاء ${testProduct.name} - ID: ${product.id}`);
        createdProducts.push(product);
      }
    }
    
    console.log('\n🔍 اختبار مراقبة المخزون...');
    
    // اختبار كل منتج على حدة
    for (const product of createdProducts) {
      console.log(`\n--- اختبار ${product.name} (كمية: ${product.available_quantity}) ---`);
      
      const result = await inventoryMonitor.monitorProduct(product.id);
      
      console.log('النتيجة:', result.success ? 'نجح' : 'فشل');
      if (result.alerts && result.alerts.length > 0) {
        result.alerts.forEach(alert => {
          console.log(`🚨 تنبيه: ${alert.type} - مرسل: ${alert.sent}`);
        });
      } else {
        console.log('📊 لا توجد تنبيهات (طبيعي)');
      }
    }
    
    console.log('\n🧹 تنظيف المنتجات التجريبية...');
    
    // حذف المنتجات التجريبية
    for (const product of createdProducts) {
      const { error } = await supabase
        .from('products')
        .delete()
        .eq('id', product.id);
      
      if (error) {
        console.error(`❌ خطأ في حذف ${product.name}:`, error.message);
      } else {
        console.log(`🗑️ تم حذف ${product.name}`);
      }
    }
    
    console.log('\n✅ انتهى اختبار مستويات المخزون');
    
  } catch (error) {
    console.error('❌ خطأ في اختبار مستويات المخزون:', error.message);
    console.error('التفاصيل:', error);
  }
}

// تشغيل الاختبار
testStockLevels();
