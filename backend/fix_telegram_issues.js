// ===================================
// إصلاح مشاكل إشعارات التلغرام
// Fix Telegram Notification Issues
// ===================================

const axios = require('axios');
require('dotenv').config();

class TelegramIssueFixer {
  constructor() {
    this.botToken = process.env.TELEGRAM_BOT_TOKEN;
    this.chatId = process.env.TELEGRAM_CHAT_ID;
    
    console.log('🔧 مُصلح مشاكل التلغرام');
    console.log(`🤖 البوت: ${this.botToken ? 'موجود' : 'غير موجود'}`);
    console.log(`💬 الكروب: ${this.chatId}`);
  }

  // فحص إعدادات التلغرام
  async checkTelegramSettings() {
    console.log('\n🔍 فحص إعدادات التلغرام...');
    
    const issues = [];
    
    // فحص وجود التوكن
    if (!this.botToken) {
      issues.push('❌ TELEGRAM_BOT_TOKEN غير موجود في ملف .env');
    } else if (!this.botToken.includes(':')) {
      issues.push('❌ TELEGRAM_BOT_TOKEN غير صحيح (يجب أن يحتوي على :)');
    }
    
    // فحص وجود معرف الكروب
    if (!this.chatId) {
      issues.push('❌ TELEGRAM_CHAT_ID غير موجود في ملف .env');
    } else if (!this.chatId.startsWith('-')) {
      issues.push('⚠️ TELEGRAM_CHAT_ID يجب أن يبدأ بـ - للكروبات');
    }
    
    if (issues.length === 0) {
      console.log('✅ إعدادات التلغرام تبدو صحيحة');
      return true;
    } else {
      console.log('❌ مشاكل في إعدادات التلغرام:');
      issues.forEach(issue => console.log(`  ${issue}`));
      return false;
    }
  }

  // اختبار اتصال البوت
  async testBotConnection() {
    console.log('\n🤖 اختبار اتصال البوت...');
    
    try {
      const response = await axios.get(`https://api.telegram.org/bot${this.botToken}/getMe`);
      
      if (response.data.ok) {
        const bot = response.data.result;
        console.log('✅ البوت متصل بنجاح');
        console.log(`📋 اسم البوت: ${bot.first_name}`);
        console.log(`🆔 معرف البوت: @${bot.username}`);
        console.log(`🔢 رقم البوت: ${bot.id}`);
        return true;
      } else {
        console.log('❌ فشل الاتصال بالبوت:', response.data.description);
        return false;
      }
    } catch (error) {
      console.log('❌ خطأ في الاتصال بالبوت:', error.message);
      if (error.response) {
        console.log('📋 تفاصيل الخطأ:', error.response.data);
      }
      return false;
    }
  }

  // اختبار إرسال رسالة للكروب
  async testGroupMessage() {
    console.log('\n💬 اختبار إرسال رسالة للكروب...');
    
    const testMessage = `🧪 اختبار إشعارات المخزون

⏰ الوقت: ${new Date().toLocaleString('ar-EG')}
🔧 حالة النظام: يعمل بنجاح
📊 هذه رسالة اختبار لتأكيد وصول الإشعارات`;

    try {
      const response = await axios.post(`https://api.telegram.org/bot${this.botToken}/sendMessage`, {
        chat_id: this.chatId,
        text: testMessage,
        parse_mode: 'HTML'
      });

      if (response.data.ok) {
        console.log('✅ تم إرسال الرسالة للكروب بنجاح');
        console.log(`📨 معرف الرسالة: ${response.data.result.message_id}`);
        return true;
      } else {
        console.log('❌ فشل إرسال الرسالة:', response.data.description);
        return false;
      }
    } catch (error) {
      console.log('❌ خطأ في إرسال الرسالة:', error.message);
      if (error.response) {
        console.log('📋 تفاصيل الخطأ:', error.response.data);
        
        // تحليل أخطاء شائعة
        const errorDesc = error.response.data.description;
        if (errorDesc.includes('chat not found')) {
          console.log('💡 الحل: تأكد من أن البوت مضاف للكروب وله صلاحيات الإرسال');
        } else if (errorDesc.includes('bot was blocked')) {
          console.log('💡 الحل: قم بإلغاء حظر البوت من الكروب');
        } else if (errorDesc.includes('not enough rights')) {
          console.log('💡 الحل: امنح البوت صلاحيات الإرسال في الكروب');
        }
      }
      return false;
    }
  }

  // اختبار إرسال إشعار نفاد مخزون
  async testOutOfStockAlert() {
    console.log('\n🚨 اختبار إشعار نفاد المخزون...');
    
    const alertMessage = `🚨 تنبيه نفاد المخزون

عذراً أعزائنا التجار، المنتج "منتج اختبار" نفد من المخزون

📦 اسم المنتج: منتج اختبار
⚠️ المنتج غير متاح حالياً للطلب
🔄 سيتم إعادة توفيره قريباً إن شاء الله

🧪 هذه رسالة اختبار`;

    try {
      const response = await axios.post(`https://api.telegram.org/bot${this.botToken}/sendMessage`, {
        chat_id: this.chatId,
        text: alertMessage,
        parse_mode: 'HTML'
      });

      if (response.data.ok) {
        console.log('✅ تم إرسال إشعار نفاد المخزون بنجاح');
        return true;
      } else {
        console.log('❌ فشل إرسال إشعار نفاد المخزون:', response.data.description);
        return false;
      }
    } catch (error) {
      console.log('❌ خطأ في إرسال إشعار نفاد المخزون:', error.message);
      return false;
    }
  }

  // اختبار إرسال إشعار مخزون منخفض
  async testLowStockAlert() {
    console.log('\n⚠️ اختبار إشعار مخزون منخفض...');
    
    const alertMessage = `⚠️ تحذير: انخفاض المخزون ⚠️

📦 المنتج: منتج اختبار
📊 الكمية الحالية: 5
💡 الكمية منخفضة - يرجى الانتباه

🧪 هذه رسالة اختبار`;

    try {
      const response = await axios.post(`https://api.telegram.org/bot${this.botToken}/sendMessage`, {
        chat_id: this.chatId,
        text: alertMessage,
        parse_mode: 'HTML'
      });

      if (response.data.ok) {
        console.log('✅ تم إرسال إشعار المخزون المنخفض بنجاح');
        return true;
      } else {
        console.log('❌ فشل إرسال إشعار المخزون المنخفض:', response.data.description);
        return false;
      }
    } catch (error) {
      console.log('❌ خطأ في إرسال إشعار المخزون المنخفض:', error.message);
      return false;
    }
  }

  // فحص صلاحيات البوت في الكروب
  async checkBotPermissions() {
    console.log('\n🔐 فحص صلاحيات البوت في الكروب...');
    
    try {
      const response = await axios.post(`https://api.telegram.org/bot${this.botToken}/getChatMember`, {
        chat_id: this.chatId,
        user_id: this.botToken.split(':')[0] // استخراج معرف البوت من التوكن
      });

      if (response.data.ok) {
        const member = response.data.result;
        console.log('✅ البوت موجود في الكروب');
        console.log(`📋 حالة البوت: ${member.status}`);
        
        if (member.status === 'administrator') {
          console.log('👑 البوت مدير في الكروب');
          console.log('🔐 الصلاحيات:', member.can_post_messages ? 'يمكن الإرسال ✅' : 'لا يمكن الإرسال ❌');
        } else if (member.status === 'member') {
          console.log('👤 البوت عضو عادي في الكروب');
        }
        
        return true;
      } else {
        console.log('❌ فشل فحص صلاحيات البوت:', response.data.description);
        return false;
      }
    } catch (error) {
      console.log('❌ خطأ في فحص صلاحيات البوت:', error.message);
      return false;
    }
  }

  // تشغيل جميع الاختبارات
  async runAllTests() {
    console.log('🧪 === بدء فحص شامل لنظام التلغرام ===\n');
    
    const results = {
      settings: await this.checkTelegramSettings(),
      connection: false,
      groupMessage: false,
      outOfStockAlert: false,
      lowStockAlert: false,
      permissions: false
    };

    if (results.settings) {
      results.connection = await this.testBotConnection();
      
      if (results.connection) {
        results.permissions = await this.checkBotPermissions();
        results.groupMessage = await this.testGroupMessage();
        results.outOfStockAlert = await this.testOutOfStockAlert();
        results.lowStockAlert = await this.testLowStockAlert();
      }
    }

    console.log('\n📊 === ملخص نتائج الفحص ===');
    console.log(`🔧 الإعدادات: ${results.settings ? '✅' : '❌'}`);
    console.log(`🤖 الاتصال: ${results.connection ? '✅' : '❌'}`);
    console.log(`🔐 الصلاحيات: ${results.permissions ? '✅' : '❌'}`);
    console.log(`💬 الرسائل العادية: ${results.groupMessage ? '✅' : '❌'}`);
    console.log(`🚨 إشعار نفاد المخزون: ${results.outOfStockAlert ? '✅' : '❌'}`);
    console.log(`⚠️ إشعار مخزون منخفض: ${results.lowStockAlert ? '✅' : '❌'}`);

    const allWorking = Object.values(results).every(result => result === true);
    
    if (allWorking) {
      console.log('\n🎉 جميع اختبارات التلغرام نجحت! النظام يعمل بشكل صحيح.');
    } else {
      console.log('\n⚠️ هناك مشاكل في نظام التلغرام تحتاج إصلاح.');
      console.log('\n💡 خطوات الإصلاح المقترحة:');
      
      if (!results.settings) {
        console.log('1. تحقق من ملف .env وتأكد من وجود TELEGRAM_BOT_TOKEN و TELEGRAM_CHAT_ID');
      }
      if (!results.connection) {
        console.log('2. تحقق من صحة TELEGRAM_BOT_TOKEN');
      }
      if (!results.permissions) {
        console.log('3. تأكد من إضافة البوت للكروب ومنحه صلاحيات الإرسال');
      }
      if (!results.groupMessage) {
        console.log('4. تحقق من صحة TELEGRAM_CHAT_ID للكروب');
      }
    }

    return results;
  }
}

// تشغيل الفحص
if (require.main === module) {
  const fixer = new TelegramIssueFixer();
  fixer.runAllTests()
    .then(() => {
      console.log('\n🏁 انتهى فحص نظام التلغرام');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ خطأ في فحص نظام التلغرام:', error);
      process.exit(1);
    });
}

module.exports = TelegramIssueFixer;
