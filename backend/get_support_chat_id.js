const axios = require('axios');
require('dotenv').config();

// استخدام نفس البوت الذي يرسل تنبيهات المخزون
const TELEGRAM_BOT_TOKEN = '7080610051:AAFdeYDMHDKkYgRrRNo_IBsdm0Qa5fezvRU';

async function getSupportChatId() {
    console.log('🔍 البحث عن chat ID لحساب @montajati_support...\n');
    
    if (!TELEGRAM_BOT_TOKEN) {
        console.log('❌ خطأ: TELEGRAM_BOT_TOKEN غير موجود');
        return;
    }

    try {
        // الحصول على التحديثات الأخيرة
        const response = await axios.get(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates`);
        
        if (response.data.ok && response.data.result.length > 0) {
            console.log('📋 التحديثات الأخيرة:');
            console.log('=====================================\n');
            
            response.data.result.forEach((update, index) => {
                if (update.message) {
                    const chat = update.message.chat;
                    const from = update.message.from;
                    
                    console.log(`📨 رسالة ${index + 1}:`);
                    console.log(`   👤 المرسل: ${from.first_name || ''} ${from.last_name || ''}`);
                    console.log(`   🆔 Username: @${from.username || 'غير متوفر'}`);
                    console.log(`   💬 Chat ID: ${chat.id}`);
                    console.log(`   📝 النوع: ${chat.type}`);
                    console.log(`   📄 النص: ${update.message.text || 'غير متوفر'}`);
                    console.log('   ─────────────────────────────────\n');
                }
            });
            
            // البحث عن @montajati_support
            const supportUpdate = response.data.result.find(update => 
                update.message && 
                update.message.from && 
                update.message.from.username === 'montajati_support'
            );
            
            if (supportUpdate) {
                const chatId = supportUpdate.message.chat.id;
                console.log('🎯 تم العثور على حساب @montajati_support!');
                console.log(`✅ Chat ID: ${chatId}`);
                console.log('\n📋 لتحديث المتغير في DigitalOcean:');
                console.log(`   TELEGRAM_CHAT_ID = ${chatId}`);
                
                return chatId;
            } else {
                console.log('⚠️ لم يتم العثور على @montajati_support في التحديثات الأخيرة');
                console.log('\n📝 للحصول على Chat ID:');
                console.log('1. أرسل رسالة من حساب @montajati_support للبوت');
                console.log('2. شغل هذا السكريبت مرة أخرى');
            }
        } else {
            console.log('⚠️ لا توجد تحديثات متاحة');
            console.log('\n📝 للحصول على Chat ID:');
            console.log('1. أرسل رسالة من حساب @montajati_support للبوت');
            console.log('2. شغل هذا السكريبت مرة أخرى');
        }
        
    } catch (error) {
        console.log('❌ خطأ في الاتصال بـ Telegram API:');
        console.log(error.response?.data || error.message);
    }
}

// اختبار إرسال رسالة لـ chat ID محدد
async function testSendToSupport(chatId) {
    if (!chatId) {
        console.log('❌ يجب توفير Chat ID للاختبار');
        return;
    }
    
    console.log(`\n🧪 اختبار إرسال رسالة لـ Chat ID: ${chatId}...`);
    
    try {
        const testMessage = `🧪 رسالة اختبار للدعم
📅 التاريخ: ${new Date().toLocaleString('ar-EG')}
✅ هذه رسالة اختبار للتأكد من وصول رسائل الدعم للمكان الصحيح`;

        const response = await axios.post(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
            chat_id: chatId,
            text: testMessage,
            parse_mode: 'HTML'
        });
        
        if (response.data.ok) {
            console.log('✅ تم إرسال رسالة الاختبار بنجاح!');
            console.log('🎯 Chat ID صحيح ويمكن استخدامه');
        } else {
            console.log('❌ فشل في إرسال رسالة الاختبار');
            console.log(response.data);
        }
        
    } catch (error) {
        console.log('❌ خطأ في إرسال رسالة الاختبار:');
        console.log(error.response?.data || error.message);
    }
}

// تشغيل السكريبت
async function main() {
    console.log('🤖 سكريبت الحصول على Chat ID لحساب الدعم');
    console.log('=====================================\n');
    
    const chatId = await getSupportChatId();
    
    // إذا تم العثور على Chat ID، اختبره
    if (chatId) {
        await testSendToSupport(chatId);
    }
    
    console.log('\n🔧 خطوات التحديث:');
    console.log('1. انسخ Chat ID الصحيح من أعلاه');
    console.log('2. اذهب إلى DigitalOcean → Apps → تطبيقك → Settings → Environment Variables');
    console.log('3. حدث TELEGRAM_CHAT_ID بالقيمة الجديدة');
    console.log('4. اضغط Save وانتظر إعادة تشغيل التطبيق');
}

main().catch(console.error);
