// اختبار إرسال رسائل الدعم لحساب @montajati_support
const axios = require('axios');
require('dotenv').config();

async function testMontajatiSupport() {
  console.log('🎯 === اختبار نظام الدعم لحساب @montajati_support ===\n');

  // إعدادات البوت
  const botToken = '7080610051:AAFdeYDMHDKkYgRrRNo_IBsdm0Qa5fezvRU';
  const supportChatId = '6698779959'; // Chat ID لحساب @montajati_support
  
  console.log(`🤖 البوت: ${botToken.substring(0, 20)}...`);
  console.log(`👤 حساب الدعم: ${supportChatId}\n`);

  // 1. اختبار اتصال البوت
  console.log('1️⃣ فحص اتصال البوت...');
  try {
    const botInfoUrl = `https://api.telegram.org/bot${botToken}/getMe`;
    const botResponse = await axios.get(botInfoUrl);
    
    if (botResponse.data.ok) {
      const botInfo = botResponse.data.result;
      console.log(`✅ البوت متصل: @${botInfo.username}`);
      console.log(`📝 اسم البوت: ${botInfo.first_name}`);
    } else {
      console.log('❌ فشل في الاتصال بالبوت');
      return;
    }
  } catch (error) {
    console.log('❌ خطأ في الاتصال بالبوت:', error.message);
    return;
  }

  // 2. اختبار إرسال رسالة مباشرة لحساب @montajati_support
  console.log('\n2️⃣ اختبار إرسال رسالة مباشرة...');
  
  const testMessage = `🧪 رسالة اختبار نظام الدعم
📅 التاريخ: ${new Date().toLocaleString('ar-SA')}
🎯 المرسل إلى: @montajati_support
✅ النظام يعمل بشكل صحيح!`;

  try {
    const telegramUrl = `https://api.telegram.org/bot${botToken}/sendMessage`;
    const telegramResponse = await axios.post(telegramUrl, {
      chat_id: supportChatId,
      text: testMessage,
      parse_mode: 'HTML'
    });

    if (telegramResponse.data.ok) {
      console.log('✅ تم إرسال الرسالة بنجاح لحساب @montajati_support!');
      console.log('📱 تحقق من حسابك في التلغرام');
    } else {
      console.log('❌ فشل في إرسال الرسالة:', telegramResponse.data.description);
      
      if (telegramResponse.data.description.includes('chat not found')) {
        console.log('\n🔧 الحل:');
        console.log('1. اذهب إلى حساب @montajati_support');
        console.log('2. ابحث عن البوت وأرسل له رسالة /start');
        console.log('3. شغل هذا الاختبار مرة أخرى');
      }
    }
  } catch (error) {
    console.log('❌ خطأ في إرسال الرسالة:', error.message);
    if (error.response) {
      console.log('📊 تفاصيل الخطأ:', error.response.data);
    }
  }

  // 3. اختبار عبر API الخادم
  console.log('\n3️⃣ اختبار عبر API الخادم...');
  
  const testSupportData = {
    orderId: 'SUPPORT_TEST_' + Date.now(),
    customerName: 'عميل تجريبي للدعم',
    primaryPhone: '07901234567',
    alternativePhone: '07801234567',
    governorate: 'بغداد',
    address: 'عنوان تجريبي لاختبار نظام الدعم',
    orderStatus: 'اختبار نظام الدعم',
    notes: 'هذه رسالة اختبار لنظام الدعم - يجب أن تصل لحساب @montajati_support',
    waseetOrderId: 'SUPPORT_WASEET_' + Date.now()
  };

  try {
    console.log('📤 إرسال طلب دعم عبر API...');
    
  const serverUrl = 'https://montajati-official-backend-production.up.railway.app';
    const supportResponse = await axios.post(
      `${serverUrl}/api/support/send-support-request`,
      testSupportData,
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000
      }
    );

    if (supportResponse.data.success) {
      console.log('✅ تم إرسال طلب الدعم عبر API بنجاح!');
      console.log('📱 تحقق من حساب @montajati_support في التلغرام');
    } else {
      console.log('❌ فشل في إرسال طلب الدعم:', supportResponse.data.message);
    }

  } catch (error) {
    console.log('❌ خطأ في اختبار API:', error.message);
    if (error.response) {
      console.log('📊 تفاصيل الخطأ:', error.response.data);
    }
  }

  console.log('\n🏁 انتهى الاختبار');
  console.log('\n📋 ملخص:');
  console.log('• البوت: نفس بوت تنبيهات المخزون');
  console.log('• المجموعة: -1002729717960 (تنبيهات المخزون)');
  console.log('• الدعم: @montajati_support (رسائل الدعم)');
  console.log('\n⚠️ تأكد من إرسال /start للبوت من حساب @montajati_support');
}

testMontajatiSupport().catch(console.error);
