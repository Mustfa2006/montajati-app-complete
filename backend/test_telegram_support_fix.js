// اختبار إصلاح نظام التلغرام للدعم
const axios = require('axios');
require('dotenv').config();

async function testTelegramSupport() {
  console.log('🧪 === اختبار نظام التلغرام للدعم ===\n');

  // 1. التحقق من متغيرات البيئة
  console.log('1️⃣ فحص متغيرات البيئة...');
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;
  
  console.log(`🤖 TELEGRAM_BOT_TOKEN: ${botToken ? '✅ موجود' : '❌ مفقود'}`);
  console.log(`💬 TELEGRAM_CHAT_ID: ${chatId ? '✅ موجود' : '⚠️ مفقود (سيتم البحث تلقائياً)'}`);

  if (!botToken) {
    console.log('\n❌ لا يمكن المتابعة بدون TELEGRAM_BOT_TOKEN');
    console.log('📝 يرجى إضافة TELEGRAM_BOT_TOKEN في متغيرات البيئة');
    return;
  }

  // 2. اختبار اتصال البوت
  console.log('\n2️⃣ اختبار اتصال البوت...');
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

  // 3. اختبار الحصول على التحديثات
  console.log('\n3️⃣ فحص التحديثات الأخيرة...');
  try {
    const updatesUrl = `https://api.telegram.org/bot${botToken}/getUpdates`;
    const updatesResponse = await axios.get(updatesUrl);
    
    if (updatesResponse.data.ok) {
      const updates = updatesResponse.data.result;
      console.log(`📨 عدد التحديثات: ${updates.length}`);
      
      if (updates.length > 0) {
        const lastUpdate = updates[updates.length - 1];
        if (lastUpdate.message) {
          console.log(`💬 آخر محادثة: ${lastUpdate.message.chat.id}`);
          console.log(`👤 من: ${lastUpdate.message.from.first_name}`);
        }
      } else {
        console.log('⚠️ لا توجد رسائل. يجب إرسال /start للبوت أولاً');
      }
    }
  } catch (error) {
    console.log('⚠️ خطأ في الحصول على التحديثات:', error.message);
  }

  // 4. اختبار إرسال رسالة تجريبية
  console.log('\n4️⃣ اختبار إرسال رسالة تجريبية...');
  
  const testMessage = `🧪 رسالة اختبار من نظام منتجاتي
📅 التاريخ: ${new Date().toLocaleString('ar-SA')}
✅ النظام يعمل بشكل صحيح!`;

  try {
    const testData = {
      orderId: 'TEST_' + Date.now(),
      customerName: 'عميل تجريبي',
      primaryPhone: '07901234567',
      alternativePhone: '07801234567',
      governorate: 'بغداد',
      address: 'عنوان تجريبي للاختبار',
      orderStatus: 'اختبار النظام',
      notes: 'هذه رسالة اختبار لنظام الدعم',
      waseetOrderId: 'WASEET_TEST_123'
    };

    const response = await axios.post(
      'https://montajati-backend.onrender.com/api/support/send-support-request',
      testData,
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000
      }
    );

    if (response.data.success) {
      console.log('✅ تم إرسال رسالة الاختبار بنجاح!');
      console.log('📱 يرجى التحقق من التلغرام للتأكد من وصول الرسالة');
    } else {
      console.log('❌ فشل في إرسال رسالة الاختبار:', response.data.message);
    }

  } catch (error) {
    console.log('❌ خطأ في اختبار الإرسال:', error.message);
    if (error.response) {
      console.log('📊 تفاصيل الخطأ:', error.response.data);
    }
  }

  console.log('\n🏁 انتهى الاختبار');
  console.log('\n📋 الخطوات التالية:');
  console.log('1. تأكد من إضافة TELEGRAM_BOT_TOKEN في Render');
  console.log('2. أضف TELEGRAM_CHAT_ID إذا كان متوفراً');
  console.log('3. تأكد من إرسال /start للبوت');
  console.log('4. اختبر إرسال طلب دعم من التطبيق');
}

testTelegramSupport().catch(console.error);
