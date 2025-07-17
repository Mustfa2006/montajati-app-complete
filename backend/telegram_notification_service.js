const axios = require('axios');

class TelegramNotificationService {
  constructor() {
    this.botToken = process.env.TELEGRAM_BOT_TOKEN;
    this.chatId = process.env.TELEGRAM_CHAT_ID;
    this.baseUrl = `https://api.telegram.org/bot${this.botToken}`;
    
    if (!this.botToken || !this.chatId) {
      console.warn('⚠️ تحذير: TELEGRAM_BOT_TOKEN أو TELEGRAM_CHAT_ID غير محدد');
    }
  }

  /**
   * اختبار الاتصال بـ Telegram Bot
   */
  async testConnection() {
    try {
      if (!this.botToken || !this.chatId) {
        return {
          success: false,
          error: 'TELEGRAM_BOT_TOKEN أو TELEGRAM_CHAT_ID غير محدد'
        };
      }

      const response = await axios.get(`${this.baseUrl}/getMe`);
      
      if (response.data.ok) {
        return {
          success: true,
          bot_info: response.data.result,
          message: 'تم الاتصال بـ Telegram Bot بنجاح'
        };
      } else {
        return {
          success: false,
          error: 'فشل في الاتصال بـ Telegram Bot'
        };
      }
    } catch (error) {
      console.error('❌ خطأ في اختبار Telegram:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال رسالة إلى Telegram
   */
  async sendMessage(message, options = {}) {
    try {
      if (!this.botToken || !this.chatId) {
        return {
          success: false,
          error: 'TELEGRAM_BOT_TOKEN أو TELEGRAM_CHAT_ID غير محدد'
        };
      }

      const payload = {
        chat_id: this.chatId,
        text: message,
        parse_mode: options.parse_mode || 'HTML',
        disable_web_page_preview: options.disable_preview || true
      };

      const response = await axios.post(`${this.baseUrl}/sendMessage`, payload);

      if (response.data.ok) {
        return {
          success: true,
          message_id: response.data.result.message_id,
          message: 'تم إرسال الرسالة بنجاح'
        };
      } else {
        return {
          success: false,
          error: 'فشل في إرسال الرسالة'
        };
      }
    } catch (error) {
      console.error('❌ خطأ في إرسال رسالة Telegram:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال صورة مع نص إلى Telegram
   */
  async sendPhotoWithCaption(photoUrl, caption, options = {}) {
    try {
      if (!this.botToken || !this.chatId) {
        return {
          success: false,
          error: 'TELEGRAM_BOT_TOKEN أو TELEGRAM_CHAT_ID غير محدد'
        };
      }

      const payload = {
        chat_id: this.chatId,
        photo: photoUrl,
        caption: caption,
        parse_mode: options.parse_mode || 'HTML'
      };

      const response = await axios.post(`${this.baseUrl}/sendPhoto`, payload);

      if (response.data.ok) {
        return {
          success: true,
          message_id: response.data.result.message_id,
          message: 'تم إرسال الصورة والرسالة بنجاح'
        };
      } else {
        return {
          success: false,
          error: 'فشل في إرسال الصورة'
        };
      }
    } catch (error) {
      console.error('❌ خطأ في إرسال صورة Telegram:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال إشعار حالة الطلب - معطل (يرسل للهاتف فقط)
   */
  async sendOrderStatusNotification(orderData) {
    // إشعارات الطلبات لا ترسل للتلغرام، فقط للهاتف
    return {
      success: true,
      message: 'إشعارات الطلبات ترسل للهاتف وليس التلغرام'
    };
  }

  /**
   * إرسال إشعار حالة السحب
   */
  async sendWithdrawalStatusNotification(withdrawalData) {
    try {
      const { withdrawalId, status, amount, userId, method } = withdrawalData;
      
      let statusEmoji = '💰';
      let statusText = status;
      
      switch (status) {
        case 'pending':
          statusEmoji = '⏳';
          statusText = 'في الانتظار';
          break;
        case 'approved':
          statusEmoji = '✅';
          statusText = 'موافق عليه - تم التحويل';
          break;
        case 'rejected':
          statusEmoji = '❌';
          statusText = 'مرفوض';
          break;
        default:
          statusEmoji = '💰';
          statusText = status;
          break;
      }

      const message = `
${statusEmoji} <b>تحديث حالة السحب</b>

🆔 <b>رقم السحب:</b> ${withdrawalId}
👤 <b>المستخدم:</b> ${userId}
📊 <b>الحالة:</b> ${statusText}
💰 <b>المبلغ:</b> ${amount} ريال
🏦 <b>طريقة السحب:</b> ${method}

⏰ <b>الوقت:</b> ${new Date().toLocaleString('ar-SA')}
      `.trim();

      return await this.sendMessage(message);
    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار حالة السحب:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال إشعار مخزون منخفض
   */
  async sendLowStockAlert(productData) {
    try {
      const { productId, productName, currentStock, productImage } = productData;

      const message = `
⚠️ تحذير: انخفاض المخزون ⚠️

📦 المنتج: ${productName}

📊 الكمية الحالية: ${currentStock}

💡 الكمية منخفضة - يرجى الانتباه
      `.trim();

      // إرسال الرسالة مع الصورة إذا كانت متوفرة
      if (productImage) {
        return await this.sendPhotoWithCaption(productImage, message);
      } else {
        return await this.sendMessage(message);
      }
    } catch (error) {
      console.error('❌ خطأ في إرسال تنبيه المخزون:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال إشعار مخزون نفد
   */
  async sendOutOfStockAlert(productData) {
    try {
      const { productId, productName, productImage } = productData;

      const message = `
🚨 تنبيه نفاد المخزون

عذراً أعزائنا التجار، المنتج "${productName}" نفد من المخزون

📦 اسم المنتج: ${productName}

⚠️ المنتج غير متاح حالياً للطلب
🔄 سيتم إعادة توفيره قريباً إن شاء الله
      `.trim();

      // إرسال الرسالة مع الصورة إذا كانت متوفرة
      if (productImage) {
        return await this.sendPhotoWithCaption(productImage, message);
      } else {
        return await this.sendMessage(message);
      }
    } catch (error) {
      console.error('❌ خطأ في إرسال تنبيه نفاد المخزون:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال إشعار تحديث حالة الطلب من الوسيط
   */
  async sendWaseetOrderStatusNotification(orderData) {
    try {
      const { orderId, orderNumber, customerName, oldStatus, newStatus, waseetStatus } = orderData;

      let statusEmoji = '📦';
      let statusText = newStatus;

      switch (newStatus) {
        case 'active':
          statusEmoji = '⏳';
          statusText = 'نشط - في انتظار التوصيل';
          break;
        case 'in_delivery':
          statusEmoji = '🚚';
          statusText = 'قيد التوصيل';
          break;
        case 'delivered':
          statusEmoji = '✅';
          statusText = 'تم التسليم';
          break;
        case 'cancelled':
          statusEmoji = '❌';
          statusText = 'ملغي';
          break;
      }

      const message = `
${statusEmoji} <b>تحديث تلقائي من الوسيط</b>

🆔 <b>رقم الطلب:</b> ${orderNumber}
👤 <b>العميل:</b> ${customerName}
📊 <b>الحالة السابقة:</b> ${oldStatus}
🔄 <b>الحالة الجديدة:</b> ${statusText}
🏢 <b>حالة الوسيط:</b> ${waseetStatus}

⚡ <b>تم التحديث تلقائياً من نظام المزامنة</b>

⏰ <b>الوقت:</b> ${new Date().toLocaleString('ar-SA')}
      `.trim();

      return await this.sendMessage(message);
    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار تحديث الوسيط:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }
}

module.exports = TelegramNotificationService;
