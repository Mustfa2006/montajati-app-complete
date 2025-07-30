// ===================================
// اختبار منتج بكمية 5
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const InventoryMonitorService = require('./inventory_monitor_service');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testQuantity5() {
  console.log('🧪 اختبار منتج بكمية 5...');
  
  try {
    // إنشاء منتج تجريبي بكمية 5
    const { data: product, error: insertError } = await supabase
      .from('products')
      .insert({
        name: 'منتج اختبار كمية 5',
        available_quantity: 5,
        wholesale_price: 100,
        min_price: 100,
        max_price: 100,
        is_active: true,
        image_url: 'https://via.placeholder.com/300x300.png?text=Test+Product+5'
      })
      .select()
      .single();

    if (insertError) {
      console.error('❌ خطأ في إنشاء المنتج:', insertError);
      return;
    }

    console.log('✅ تم إنشاء المنتج:', product.name, 'بكمية:', product.available_quantity);

    // اختبار مراقبة المخزون
    const inventoryMonitor = new InventoryMonitorService();
    
    console.log('\n🔍 اختبار مراقبة المنتج...');
    const result = await inventoryMonitor.monitorProduct(product.id);
    
    console.log('النتيجة:', result.success ? 'نجح' : 'فشل');
    if (result.alerts && result.alerts.length > 0) {
      result.alerts.forEach(alert => {
        console.log(`🚨 تنبيه: ${alert.type} - مرسل: ${alert.sent}`);
      });
    } else {
      console.log('📊 لا توجد تنبيهات');
    }

    // حذف المنتج التجريبي
    console.log('\n🗑️ حذف المنتج التجريبي...');
    const { error: deleteError } = await supabase
      .from('products')
      .delete()
      .eq('id', product.id);

    if (deleteError) {
      console.error('⚠️ تحذير: فشل في حذف المنتج التجريبي:', deleteError);
    } else {
      console.log('✅ تم حذف المنتج التجريبي');
    }

    console.log('\n✅ انتهى الاختبار');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

// تشغيل الاختبار
testQuantity5();
