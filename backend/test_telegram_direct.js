// ===================================
// اختبار مباشر لخدمة التلغرام
// ===================================

require('dotenv').config();
const TelegramNotificationService = require('./telegram_notification_service');

async function testTelegramDirect() {
  console.log('🔧 اختبار مباشر لخدمة التلغرام...');
  
  try {
    const telegramService = new TelegramNotificationService();
    
    // اختبار الاتصال
    console.log('📡 اختبار الاتصال...');
    const connectionTest = await telegramService.testConnection();
    console.log('نتيجة الاتصال:', connectionTest);
    
    if (!connectionTest.success) {
      console.error('❌ فشل الاتصال:', connectionTest.error);
      return;
    }
    
    // اختبار إرسال رسالة عادية
    console.log('\n📤 اختبار إرسال رسالة عادية...');
    const messageTest = await telegramService.sendMessage('🧪 اختبار مباشر من النظام - ' + new Date().toLocaleString('ar-SA'));
    console.log('نتيجة الرسالة:', messageTest);
    
    // اختبار إشعار نفاد المخزون
    console.log('\n📦 اختبار إشعار نفاد المخزون...');
    const outOfStockTest = await telegramService.sendOutOfStockAlert({
      productId: 'test-123',
      productName: 'منتج تجريبي للاختبار',
      productImage: null
    });
    console.log('نتيجة نفاد المخزون:', outOfStockTest);
    
    // اختبار إشعار مخزون منخفض
    console.log('\n⚠️ اختبار إشعار مخزون منخفض...');
    const lowStockTest = await telegramService.sendLowStockAlert({
      productId: 'test-456',
      productName: 'منتج تجريبي للمخزون المنخفض',
      currentStock: 1,
      productImage: null
    });
    console.log('نتيجة المخزون المنخفض:', lowStockTest);
    
    console.log('\n✅ انتهى الاختبار المباشر');
    
  } catch (error) {
    console.error('❌ خطأ في الاختبار المباشر:', error.message);
    console.error('التفاصيل:', error);
  }
}

// تشغيل الاختبار
testTelegramDirect();
