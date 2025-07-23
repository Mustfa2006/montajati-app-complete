// ===================================
// خدمة إرسال رسائل الدعم للتليجرام
// Telegram Support Service
// ===================================

const axios = require('axios');

class TelegramSupportService {
  constructor() {
    // معرف البوت والقناة
    this.botToken = process.env.TELEGRAM_BOT_TOKEN || '7234567890:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxx';
    this.supportChatId = process.env.TELEGRAM_SUPPORT_CHAT_ID || '@montajati_support';
    this.baseUrl = `https://api.telegram.org/bot${this.botToken}`;
  }

  /**
   * إرسال رسالة دعم للتليجرام
   */
  async sendSupportMessage(orderData) {
    try {
      const message = this.formatSupportMessage(orderData);
      
      const response = await axios.post(`${this.baseUrl}/sendMessage`, {
        chat_id: this.supportChatId,
        text: message,
        parse_mode: 'HTML',
        disable_web_page_preview: true
      });

      if (response.data.ok) {
        console.log('✅ تم إرسال رسالة الدعم بنجاح');
        return {
          success: true,
          messageId: response.data.result.message_id,
          message: 'تم إرسال الطلب للدعم بنجاح'
        };
      } else {
        throw new Error('فشل في إرسال الرسالة');
      }

    } catch (error) {
      console.error('❌ خطأ في إرسال رسالة الدعم:', error.message);
      return {
        success: false,
        error: error.message,
        message: 'فشل في إرسال الطلب للدعم'
      };
    }
  }

  /**
   * تنسيق رسالة الدعم بشكل جميل
   */
  formatSupportMessage(orderData) {
    const {
      customerName,
      primaryPhone,
      alternativePhone,
      governorate,
      address,
      orderStatus,
      notes,
      orderId,
      orderDate
    } = orderData;

    const message = `
🚨 <b>طلب دعم جديد - منتجاتي</b> 🚨

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👤 <b>معلومات الزبون:</b>
📝 الاسم: <code>${customerName}</code>
📞 الهاتف الأساسي: <code>${primaryPhone}</code>
${alternativePhone ? `📱 الهاتف البديل: <code>${alternativePhone}</code>` : ''}

📍 <b>معلومات العنوان:</b>
🏛️ المحافظة: <code>${governorate}</code>
🏠 العنوان: <code>${address}</code>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 <b>معلومات الطلب:</b>
🆔 رقم الطلب: <code>#${orderId}</code>
📅 تاريخ الطلب: <code>${orderDate}</code>
⚠️ حالة الطلب: <code>${orderStatus}</code>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💬 <b>ملاحظات المستخدم:</b>
<blockquote>${notes || 'لا توجد ملاحظات إضافية'}</blockquote>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⏰ <b>وقت الإرسال:</b> ${new Date().toLocaleString('ar-EG', {
      timeZone: 'Asia/Baghdad',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })}

🔗 <b>المصدر:</b> تطبيق منتجاتي - نظام الدعم التلقائي

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚡ <b>يرجى المتابعة مع الزبون في أقرب وقت ممكن</b> ⚡`;

    return message;
  }

  /**
   * اختبار الاتصال بالتليجرام
   */
  async testConnection() {
    try {
      const response = await axios.get(`${this.baseUrl}/getMe`);
      
      if (response.data.ok) {
        console.log('✅ الاتصال بالتليجرام يعمل بنجاح');
        console.log(`🤖 اسم البوت: ${response.data.result.first_name}`);
        return { success: true, botInfo: response.data.result };
      } else {
        throw new Error('فشل في الاتصال بالبوت');
      }

    } catch (error) {
      console.error('❌ خطأ في اختبار الاتصال:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * إرسال رسالة اختبار
   */
  async sendTestMessage() {
    try {
      const testMessage = `
🧪 <b>رسالة اختبار - منتجاتي</b>

✅ نظام الدعم التلقائي يعمل بنجاح!

⏰ الوقت: ${new Date().toLocaleString('ar-EG', {
        timeZone: 'Asia/Baghdad'
      })}

🔧 هذه رسالة اختبار للتأكد من عمل النظام`;

      const response = await axios.post(`${this.baseUrl}/sendMessage`, {
        chat_id: this.supportChatId,
        text: testMessage,
        parse_mode: 'HTML'
      });

      if (response.data.ok) {
        console.log('✅ تم إرسال رسالة الاختبار بنجاح');
        return { success: true, message: 'تم إرسال رسالة الاختبار' };
      } else {
        throw new Error('فشل في إرسال رسالة الاختبار');
      }

    } catch (error) {
      console.error('❌ خطأ في إرسال رسالة الاختبار:', error.message);
      return { success: false, error: error.message };
    }
  }
}

module.exports = TelegramSupportService;
