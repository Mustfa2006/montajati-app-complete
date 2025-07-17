// ===================================
// تنظيف الطلبات التجريبية
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

async function cleanupTestOrders() {
  console.log('🧹 بدء تنظيف الطلبات التجريبية...');
  
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );

  try {
    // حذف الطلبات التجريبية
    const { data: deletedOrders, error } = await supabase
      .from('orders')
      .delete()
      .or('order_number.like.%TEST%,order_number.like.%test%,order_number.like.%Test%')
      .select();

    if (error) {
      console.error('❌ خطأ في حذف الطلبات التجريبية:', error.message);
      return;
    }

    console.log(`✅ تم حذف ${deletedOrders?.length || 0} طلب تجريبي`);
    
    if (deletedOrders && deletedOrders.length > 0) {
      console.log('📋 الطلبات المحذوفة:');
      deletedOrders.forEach(order => {
        console.log(`  - ${order.order_number} (${order.customer_name})`);
      });
    }

  } catch (error) {
    console.error('❌ خطأ في تنظيف الطلبات:', error.message);
  }
}

// تشغيل التنظيف
if (require.main === module) {
  cleanupTestOrders().then(() => {
    console.log('🎉 انتهى تنظيف الطلبات التجريبية');
    process.exit(0);
  });
}

module.exports = cleanupTestOrders;
