// اختبار تنسيق رسالة الدعم الجديد
const TelegramNotificationService = require('./telegram_notification_service');

async function testSupportMessageFormat() {
  console.log('🧪 اختبار تنسيق رسالة الدعم الجديد...\n');
  
  const telegramService = new TelegramNotificationService();
  
  // بيانات اختبار
  const testData = {
    orderId: 'order_1753582499894_7589',
    customerName: 'أحمد محمد علي',
    primaryPhone: '07503597589',
    alternativePhone: '', // فارغ لاختبار "غير متوفر"
    governorate: 'نينوى',
    address: 'وانة باب بيت',
    orderStatus: 'الرقم غير معرف',
    notes: '', // فارغ لاختبار "لا توجد ملاحظات إضافية"
    waseetOrderId: '' // فارغ لاختبار "لم يتم الإرسال للتوصيل بعد"
  };
  
  // تحضير الرسالة بنفس الطريقة المستخدمة في backend/routes/support.js
  const currentDate = new Date().toLocaleDateString('ar-EG');
  const message = `👤 معلومات الزبون:
📝 الاسم: ${testData.customerName}
📞 الهاتف الأساسي: ${testData.primaryPhone}
📱 الهاتف البديل: ${testData.alternativePhone || 'غير متوفر'}

📍 معلومات العنوان:
🏛️ المحافظة: ${testData.governorate || 'غير محدد'}
🏠 العنوان: ${testData.address || 'غير محدد'}

📦 معلومات الطلب:
🆔 رقم الطلب: ${testData.orderId}
📅 تاريخ الطلب: ${currentDate}
⚠️ حالة الطلب: ${testData.orderStatus}
🚚 رقم الطلب في التوصيل: ${testData.waseetOrderId || 'لم يتم الإرسال للتوصيل بعد'}

💬 ملاحظات المستخدم:
${testData.notes && testData.notes.trim() ? testData.notes.trim() : 'لا توجد ملاحظات إضافية'}`;

  console.log('📝 الرسالة المنسقة:');
  console.log('=' .repeat(50));
  console.log(message);
  console.log('=' .repeat(50));
  
  // إرسال الرسالة
  try {
    console.log('\n📤 إرسال الرسالة للدعم...');
    const result = await telegramService.sendMessage(message, telegramService.supportChatId);
    
    if (result.success) {
      console.log('✅ تم إرسال الرسالة بنجاح!');
      console.log(`📨 معرف الرسالة: ${result.messageId}`);
      console.log('📱 تحقق من حساب @montajati_support في التلغرام');
    } else {
      console.log('❌ فشل في إرسال الرسالة:', result.error);
    }
  } catch (error) {
    console.log('❌ خطأ في إرسال الرسالة:', error.message);
  }
}

testSupportMessageFormat();
