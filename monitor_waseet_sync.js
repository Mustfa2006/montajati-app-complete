const axios = require('axios');
require('dotenv').config();

/**
 * مراقب نظام المزامنة مع الوسيط
 * يمكن تشغيله محلياً لمراقبة النظام على Render
 */

const SERVER_URL = process.env.SERVER_URL || 'https://your-app.onrender.com';

async function monitorWaseetSync() {
  console.log('📊 === مراقب نظام المزامنة مع الوسيط ===\n');
  console.log(`🔗 الخادم: ${SERVER_URL}`);
  
  try {
    // جلب حالة النظام
    const response = await axios.get(`${SERVER_URL}/api/orders/waseet-sync-status`);
    
    if (response.data.success) {
      const stats = response.data.data;
      
      console.log('📊 === حالة النظام ===');
      console.log(`🔄 حالة النظام: ${stats.isRunning ? '🟢 يعمل' : '🔴 متوقف'}`);
      console.log(`⚡ المزامنة الحالية: ${stats.isCurrentlySyncing ? '🔄 قيد التنفيذ' : '⏸️ في انتظار'}`);
      console.log(`⏰ فترة المزامنة: كل ${stats.syncIntervalSeconds} ثانية`);
      console.log(`⏰ آخر مزامنة: ${stats.lastSyncTime ? new Date(stats.lastSyncTime).toLocaleString('ar-EG') : 'لم تتم بعد'}`);
      
      if (stats.nextSyncIn) {
        const nextSyncSeconds = Math.round(stats.nextSyncIn / 1000);
        console.log(`⏳ المزامنة التالية خلال: ${nextSyncSeconds} ثانية`);
      }
      
      console.log(`⏱️ مدة التشغيل: ${stats.uptime}`);
      
      console.log('\n📈 === الإحصائيات ===');
      console.log(`📊 إجمالي المزامنات: ${stats.totalSyncs}`);
      console.log(`✅ المزامنات الناجحة: ${stats.successfulSyncs}`);
      console.log(`❌ المزامنات الفاشلة: ${stats.failedSyncs}`);
      console.log(`🔄 الطلبات المحدثة: ${stats.ordersUpdated}`);
      
      if (stats.lastError) {
        console.log(`⚠️ آخر خطأ: ${stats.lastError}`);
      }
      
      // حساب معدل النجاح
      const successRate = stats.totalSyncs > 0 ? 
        ((stats.successfulSyncs / stats.totalSyncs) * 100).toFixed(1) : 0;
      console.log(`📊 معدل النجاح: ${successRate}%`);
      
    } else {
      console.log('❌ فشل جلب حالة النظام:', response.data.error);
    }
    
  } catch (error) {
    console.error('❌ خطأ في الاتصال بالخادم:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 تأكد من أن الخادم يعمل على Render');
    } else if (error.response?.status === 404) {
      console.log('💡 تأكد من أن API endpoint موجود');
    }
  }
}

async function forceSync() {
  console.log('⚡ تنفيذ مزامنة فورية...');
  
  try {
    const response = await axios.post(`${SERVER_URL}/api/orders/force-waseet-sync`);
    
    if (response.data.success) {
      console.log('✅ تم تنفيذ المزامنة الفورية بنجاح');
      console.log(`⏱️ المدة: ${response.data.duration}ms`);
      
      if (response.data.stats) {
        console.log(`🔄 الطلبات المحدثة: ${response.data.stats.ordersUpdated}`);
      }
    } else {
      console.log('❌ فشل المزامنة الفورية:', response.data.error);
    }
    
  } catch (error) {
    console.error('❌ خطأ في المزامنة الفورية:', error.message);
  }
}

async function restartSystem() {
  console.log('🔄 إعادة تشغيل النظام...');
  
  try {
    const response = await axios.post(`${SERVER_URL}/api/orders/restart-waseet-sync`);
    
    if (response.data.success) {
      console.log('✅ تم إعادة تشغيل النظام بنجاح');
    } else {
      console.log('❌ فشل إعادة تشغيل النظام:', response.data.error);
    }
    
  } catch (error) {
    console.error('❌ خطأ في إعادة تشغيل النظام:', error.message);
  }
}

// معالجة الأوامر
const command = process.argv[2];

switch (command) {
  case 'status':
  case undefined:
    monitorWaseetSync();
    break;
    
  case 'force':
    forceSync();
    break;
    
  case 'restart':
    restartSystem();
    break;
    
  case 'watch':
    console.log('👁️ مراقبة مستمرة - كل 30 ثانية (اضغط Ctrl+C للإيقاف)');
    monitorWaseetSync();
    setInterval(monitorWaseetSync, 30000);
    break;
    
  default:
    console.log('📋 الأوامر المتاحة:');
    console.log('  node monitor_waseet_sync.js status   - عرض حالة النظام');
    console.log('  node monitor_waseet_sync.js force    - تنفيذ مزامنة فورية');
    console.log('  node monitor_waseet_sync.js restart  - إعادة تشغيل النظام');
    console.log('  node monitor_waseet_sync.js watch    - مراقبة مستمرة');
}
