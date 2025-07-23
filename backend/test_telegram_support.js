// ===================================
// اختبار خدمة دعم التليجرام
// Test Telegram Support Service
// ===================================

const TelegramSupportService = require('./services/telegram_support_service');

async function testTelegramSupport() {
  console.log('🧪 اختبار خدمة دعم التليجرام...');
  console.log('='.repeat(50));

  const telegramService = new TelegramSupportService();

  try {
    // 1. اختبار الاتصال
    console.log('\n1️⃣ اختبار الاتصال بالتليجرام...');
    const connectionTest = await telegramService.testConnection();
    
    if (connectionTest.success) {
      console.log('✅ الاتصال بالتليجرام يعمل بنجاح');
      console.log(`🤖 اسم البوت: ${connectionTest.botInfo.first_name}`);
      console.log(`🆔 معرف البوت: ${connectionTest.botInfo.id}`);
    } else {
      console.log('❌ فشل الاتصال بالتليجرام:', connectionTest.error);
      return;
    }

    // 2. إرسال رسالة اختبار
    console.log('\n2️⃣ إرسال رسالة اختبار...');
    const testMessage = await telegramService.sendTestMessage();
    
    if (testMessage.success) {
      console.log('✅ تم إرسال رسالة الاختبار بنجاح');
    } else {
      console.log('❌ فشل إرسال رسالة الاختبار:', testMessage.error);
    }

    // 3. اختبار رسالة دعم كاملة
    console.log('\n3️⃣ اختبار رسالة دعم كاملة...');
    
    const testOrderData = {
      orderId: 12345,
      customerName: 'أحمد محمد علي',
      primaryPhone: '07901234567',
      alternativePhone: '07801234567',
      governorate: 'بغداد',
      address: 'حي الكرادة - شارع الرشيد - بناية رقم 123',
      orderStatus: 'لا يرد',
      notes: 'العميل لا يرد على الهاتف منذ 3 أيام. تم المحاولة عدة مرات في أوقات مختلفة.',
      orderDate: new Date().toLocaleDateString('ar-EG')
    };

    const supportResult = await telegramService.sendSupportMessage(testOrderData);
    
    if (supportResult.success) {
      console.log('✅ تم إرسال رسالة الدعم بنجاح');
      console.log(`📨 معرف الرسالة: ${supportResult.messageId}`);
    } else {
      console.log('❌ فشل إرسال رسالة الدعم:', supportResult.error);
    }

    console.log('\n🎉 انتهى اختبار خدمة التليجرام بنجاح!');

  } catch (error) {
    console.error('❌ خطأ في اختبار التليجرام:', error.message);
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testTelegramSupport()
    .then(() => {
      console.log('\n✅ انتهى الاختبار');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار:', error);
      process.exit(1);
    });
}

module.exports = { testTelegramSupport };
