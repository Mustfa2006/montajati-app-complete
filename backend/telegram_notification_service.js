// ===================================
// خدمة إشعارات التلغرام
// ===================================

const axios = require('axios');
require('dotenv').config();

class TelegramNotificationService {
  constructor() {
    // إعدادات البوت للمخزون (نفس البوت المستخدم للمخزون)
    this.stockBotToken = process.env.TELEGRAM_BOT_TOKEN || '7080610051:AAFdeYDMHDKkYgRrRNo_IBsdm0Qa5fezvRU';
    this.stockChatId = process.env.TELEGRAM_CHAT_ID || '-1002729717960';
    
    // إعدادات البوت للدعم (نفس البوت لكن chat ID مختلف)
    this.supportBotToken = process.env.TELEGRAM_SUPPORT_BOT_TOKEN || this.stockBotToken;
    this.supportChatId = process.env.TELEGRAM_SUPPORT_CHAT_ID || '6698779959'; // @montajati_support
    
    console.log('📱 تم تهيئة خدمة التلغرام');
    console.log(`📦 بوت المخزون: ${this.stockBotToken ? 'موجود' : 'غير موجود'}`);
    console.log(`💬 كروب المخزون: ${this.stockChatId}`);
    console.log(`🆘 بوت الدعم: ${this.supportBotToken ? 'موجود' : 'غير موجود'}`);
    console.log(`💬 دعم الدردشة: ${this.supportChatId}`);
  }

  /**
   * اختبار الاتصال بالبوت
   */
  async testConnection() {
    try {
      if (!this.stockBotToken) {
        return {
          success: false,
          error: 'TELEGRAM_BOT_TOKEN غير موجود'
        };
      }

      const response = await axios.get(`https://api.telegram.org/bot${this.stockBotToken}/getMe`);
      
      if (response.data.ok) {
        return {
          success: true,
          botInfo: response.data.result,
          message: 'تم الاتصال بالبوت بنجاح'
        };
      } else {
        return {
          success: false,
          error: 'فشل في الاتصال بالبوت'
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال رسالة عامة للمخزون
   */
  async sendMessage(message, chatId = null) {
    try {
      const targetChatId = chatId || this.stockChatId;
      const botToken = this.stockBotToken;

      if (!botToken) {
        throw new Error('TELEGRAM_BOT_TOKEN غير موجود');
      }

      const response = await axios.post(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        chat_id: targetChatId,
        text: message,
        parse_mode: 'HTML'
      });

      if (response.data.ok) {
        return {
          success: true,
          messageId: response.data.result.message_id,
          message: 'تم إرسال الرسالة بنجاح'
        };
      } else {
        return {
          success: false,
          error: response.data.description || 'فشل في إرسال الرسالة'
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال صورة مع نص
   */
  async sendPhotoWithCaption(photoUrl, caption, chatId = null) {
    try {
      const targetChatId = chatId || this.stockChatId;
      const botToken = this.stockBotToken;

      if (!botToken) {
        throw new Error('TELEGRAM_BOT_TOKEN غير موجود');
      }

      const response = await axios.post(`https://api.telegram.org/bot${botToken}/sendPhoto`, {
        chat_id: targetChatId,
        photo: photoUrl,
        caption: caption,
        parse_mode: 'HTML'
      });

      if (response.data.ok) {
        return {
          success: true,
          messageId: response.data.result.message_id,
          message: 'تم إرسال الصورة والرسالة بنجاح'
        };
      } else {
        return {
          success: false,
          error: response.data.description || 'فشل في إرسال الصورة'
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال إشعار نفاد المخزون
   */
  async sendOutOfStockAlert(productData) {
    try {
      const message = `🚨 تنبيه نفاد المخزون

عذراً أعزائنا التجار، المنتج "${productData.productName}" نفد من المخزون

📦 اسم المنتج: ${productData.productName}

⚠️ المنتج غير متاح حالياً للطلب
🔄 سيتم إعادة توفيره قريباً إن شاء الله`;

      // إرسال مع صورة المنتج إذا كانت متوفرة
      if (productData.productImage) {
        return await this.sendPhotoWithCaption(productData.productImage, message, this.stockChatId);
      } else {
        return await this.sendMessage(message, this.stockChatId);
      }
    } catch (error) {
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
      const message = `⚠️ تحذير: انخفاض المخزون ⚠️

📦 المنتج: ${productData.productName}

📊 الكمية الحالية: ${productData.currentStock}

💡 الكمية منخفضة - يرجى الانتباه`;

      // إرسال مع صورة المنتج إذا كانت متوفرة
      if (productData.productImage) {
        return await this.sendPhotoWithCaption(productData.productImage, message, this.stockChatId);
      } else {
        return await this.sendMessage(message, this.stockChatId);
      }
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال رسالة دعم
   */
  async sendSupportMessage(supportData) {
    try {
      const message = `🆘 <b>طلب دعم جديد</b>

👤 <b>العميل:</b> ${supportData.customerName || 'غير محدد'}
📱 <b>الهاتف:</b> ${supportData.customerPhone || 'غير محدد'}
🆔 <b>رقم الطلب:</b> ${supportData.orderId}
💰 <b>المبلغ:</b> ${supportData.totalAmount || 'غير محدد'} د.ع
⏰ <b>الوقت:</b> ${new Date().toLocaleString('ar-SA')}

📝 <b>التفاصيل:</b>
${supportData.message || 'لا توجد تفاصيل إضافية'}

🔗 <b>رابط الطلب:</b> /order/${supportData.orderId}`;

      return await this.sendMessage(message, this.supportChatId);
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال تقرير يومي
   */
  async sendDailyReport(reportData) {
    try {
      const message = `📊 <b>التقرير اليومي</b>

📅 <b>التاريخ:</b> ${new Date().toLocaleDateString('ar-SA')}

📦 <b>إحصائيات المخزون:</b>
• المنتجات المتاحة: ${reportData.availableProducts || 0}
• المنتجات النافدة: ${reportData.outOfStockProducts || 0}
• المنتجات المنخفضة: ${reportData.lowStockProducts || 0}

📈 <b>إحصائيات الطلبات:</b>
• طلبات جديدة: ${reportData.newOrders || 0}
• طلبات مكتملة: ${reportData.completedOrders || 0}
• طلبات معلقة: ${reportData.pendingOrders || 0}

💰 <b>المبيعات:</b>
• إجمالي المبيعات: ${reportData.totalSales || 0} د.ع
• عدد المعاملات: ${reportData.totalTransactions || 0}

⏰ <b>وقت التقرير:</b> ${new Date().toLocaleString('ar-SA')}`;

      return await this.sendMessage(message, this.stockChatId);
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
}

module.exports = TelegramNotificationService;
