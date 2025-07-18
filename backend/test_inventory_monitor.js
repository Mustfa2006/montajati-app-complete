// ===================================
// اختبار مراقب المخزون المباشر
// ===================================

require('dotenv').config();
const InventoryMonitorService = require('./inventory_monitor_service');

async function testInventoryMonitor() {
  console.log('📦 اختبار مراقب المخزون المباشر...');
  
  try {
    const inventoryMonitor = new InventoryMonitorService();
    
    console.log('🔍 فحص جميع المنتجات...');
    const result = await inventoryMonitor.monitorAllProducts();
    
    console.log('\n📊 نتائج المراقبة:');
    console.log('النجاح:', result.success);
    console.log('الرسالة:', result.message);
    
    if (result.results) {
      console.log('\n📈 الإحصائيات:');
      console.log('- إجمالي المنتجات:', result.results.total);
      console.log('- نفد المخزون:', result.results.outOfStock);
      console.log('- مخزون منخفض:', result.results.lowStock);
      console.log('- مخزون طبيعي:', result.results.normal);
      console.log('- إشعارات مرسلة:', result.results.sentNotifications);
    }
    
    if (result.alerts && result.alerts.length > 0) {
      console.log('\n🚨 التنبيهات المرسلة:');
      result.alerts.forEach((alert, index) => {
        console.log(`${index + 1}. ${alert.product_name} - ${alert.type} - مرسل: ${alert.sent}`);
      });
    }
    
    console.log('\n✅ انتهى اختبار مراقب المخزون');
    
  } catch (error) {
    console.error('❌ خطأ في اختبار مراقب المخزون:', error.message);
    console.error('التفاصيل:', error);
  }
}

// تشغيل الاختبار
testInventoryMonitor();
