// اختبار نظام التلغرام في DigitalOcean
const axios = require('axios');

async function testDigitalOceanTelegram() {
  console.log('🌊 === اختبار نظام التلغرام في DigitalOcean ===\n');

  // تحديد URL الخادم
  const serverUrl = 'https://montajati-official-backend-production.up.railway.app';
  
  console.log(`🔗 خادم DigitalOcean: ${serverUrl}`);

  // 1. اختبار صحة الخادم
  console.log('\n1️⃣ فحص صحة الخادم...');
  try {
    const healthResponse = await axios.get(`${serverUrl}/health`, { timeout: 10000 });
    console.log('✅ الخادم يعمل بشكل صحيح');
    console.log(`📊 الحالة: ${healthResponse.data.status}`);
  } catch (error) {
    console.log('❌ خطأ في الاتصال بالخادم:', error.message);
    console.log('🔍 تحقق من أن الخادم يعمل في DigitalOcean');
    return;
  }

  // 2. اختبار endpoint الدعم
  console.log('\n2️⃣ اختبار endpoint الدعم...');
  
  const testSupportData = {
    orderId: 'DO_TEST_' + Date.now(),
    customerName: 'عميل تجريبي - DigitalOcean',
    primaryPhone: '07901234567',
    alternativePhone: '07801234567',
    governorate: 'بغداد',
    address: 'عنوان تجريبي للاختبار في DigitalOcean',
    orderStatus: 'اختبار نظام DigitalOcean',
    notes: 'هذه رسالة اختبار لنظام الدعم في DigitalOcean',
    waseetOrderId: 'DO_WASEET_TEST_' + Date.now()
  };

  try {
    console.log('📤 إرسال طلب دعم تجريبي...');
    
    const supportResponse = await axios.post(
      `${serverUrl}/api/support/send-support-request`,
      testSupportData,
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000
      }
    );

    if (supportResponse.data.success) {
      console.log('✅ تم إرسال طلب الدعم بنجاح!');
      console.log('📱 يرجى التحقق من التلغرام للتأكد من وصول الرسالة');
      console.log(`📨 الرسالة: ${supportResponse.data.message}`);
    } else {
      console.log('❌ فشل في إرسال طلب الدعم:', supportResponse.data.message);
      
      // تحليل سبب الفشل
      if (supportResponse.data.message.includes('Bot token not configured')) {
        console.log('\n🔧 الحل: أضف TELEGRAM_BOT_TOKEN في DigitalOcean');
        console.log('1. اذهب إلى DigitalOcean App Platform');
        console.log('2. اختر تطبيقك');
        console.log('3. اذهب إلى Settings > Environment Variables');
        console.log('4. أضف TELEGRAM_BOT_TOKEN');
      }
    }

  } catch (error) {
    console.log('❌ خطأ في اختبار الدعم:', error.message);
    
    if (error.response) {
      console.log('📊 تفاصيل الخطأ:', error.response.data);
      
      // تحليل الأخطاء الشائعة
      if (error.response.status === 500) {
        console.log('\n🔍 سبب محتمل: متغيرات البيئة مفقودة');
        console.log('📝 تحقق من إضافة TELEGRAM_BOT_TOKEN في DigitalOcean');
      }
    }
  }

  // 3. اختبار مباشر للتلغرام (إذا كان BOT_TOKEN متوفر محلياً)
  console.log('\n3️⃣ اختبار مباشر للتلغرام...');
  
  // محاولة قراءة BOT_TOKEN من متغيرات البيئة المحلية
  const localBotToken = process.env.TELEGRAM_BOT_TOKEN;
  
  if (localBotToken) {
    console.log('🤖 تم العثور على BOT_TOKEN محلياً');
    
    try {
      // اختبار اتصال البوت
      const botInfoUrl = `https://api.telegram.org/bot${localBotToken}/getMe`;
      const botResponse = await axios.get(botInfoUrl);
      
      if (botResponse.data.ok) {
        const botInfo = botResponse.data.result;
        console.log(`✅ البوت متصل: @${botInfo.username}`);
        console.log(`📝 اسم البوت: ${botInfo.first_name}`);
        
        // اختبار الحصول على التحديثات
        const updatesUrl = `https://api.telegram.org/bot${localBotToken}/getUpdates`;
        const updatesResponse = await axios.get(updatesUrl);
        
        if (updatesResponse.data.ok) {
          const updates = updatesResponse.data.result;
          console.log(`📨 عدد التحديثات: ${updates.length}`);
          
          if (updates.length > 0) {
            const lastUpdate = updates[updates.length - 1];
            if (lastUpdate.message) {
              console.log(`💬 آخر محادثة: ${lastUpdate.message.chat.id}`);
              console.log(`👤 من: ${lastUpdate.message.from.first_name}`);
              console.log(`📋 استخدم هذا الرقم كـ TELEGRAM_CHAT_ID: ${lastUpdate.message.chat.id}`);
            }
          } else {
            console.log('⚠️ لا توجد رسائل. يجب إرسال /start للبوت أولاً');
          }
        }
      }
    } catch (error) {
      console.log('❌ خطأ في اختبار البوت:', error.message);
    }
  } else {
    console.log('⚠️ TELEGRAM_BOT_TOKEN غير متوفر محلياً');
    console.log('📝 لاختبار البوت، أضف TELEGRAM_BOT_TOKEN في ملف .env');
  }

  console.log('\n🏁 انتهى الاختبار');
  console.log('\n📋 الخطوات التالية لـ DigitalOcean:');
  console.log('1. اذهب إلى DigitalOcean App Platform');
  console.log('2. اختر تطبيق montajati-backend');
  console.log('3. اذهب إلى Settings > Environment Variables');
  console.log('4. أضف TELEGRAM_BOT_TOKEN و TELEGRAM_CHAT_ID');
  console.log('5. أعد نشر التطبيق');
  console.log('6. اختبر إرسال طلب دعم من التطبيق');
}

testDigitalOceanTelegram().catch(console.error);
