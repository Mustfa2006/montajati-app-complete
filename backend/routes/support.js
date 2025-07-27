const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

/**
 * إرسال طلب دعم للتليجرام
 */
router.post('/send-support-request', async (req, res) => {
  console.log('🔥 === تم استلام طلب دعم جديد ===');
  
  try {
    const {
      orderId,
      customerName,
      primaryPhone,
      alternativePhone,
      governorate,
      address,
      orderStatus,
      notes
    } = req.body;

    console.log('📋 معلومات الطلب:', {
      orderId,
      customerName,
      primaryPhone,
      orderStatus
    });

    // التحقق من البيانات المطلوبة
    if (!orderId || !customerName || !primaryPhone || !orderStatus) {
      console.log('❌ البيانات المطلوبة مفقودة');
      return res.status(400).json({
        success: false,
        message: 'البيانات المطلوبة مفقودة'
      });
    }

    // تحضير الرسالة
    const currentDate = new Date().toLocaleDateString('ar-EG');
    const message = `🚨 طلب دعم جديد - منتجاتي 🚨

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👤 معلومات الزبون:
📝 الاسم: ${customerName}
📞 الهاتف الأساسي: ${primaryPhone}
📱 الهاتف البديل: ${alternativePhone || 'غير متوفر'}

📍 معلومات العنوان:
🏛️ المحافظة: ${governorate || 'غير محدد'}
🏠 العنوان: ${address || 'غير محدد'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 معلومات الطلب:
🆔 رقم الطلب: ${orderId}
📅 تاريخ الطلب: ${currentDate}
⚠️ حالة الطلب: ${orderStatus}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💬 ملاحظات المستخدم:
${notes && notes.trim() ? notes.trim() : 'لا توجد ملاحظات إضافية'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚡ يرجى المتابعة مع الزبون في أقرب وقت ممكن ⚡`;

    console.log('📝 تم تحضير الرسالة - الطول:', message.length);

    // إرسال الرسالة للتلغرام
    const telegramResult = await sendToTelegram(message);
    
    if (!telegramResult.success) {
      console.log('❌ فشل في إرسال الرسالة للتلغرام:', telegramResult.error);
      return res.status(500).json({
        success: false,
        message: 'فشل في إرسال الرسالة للتلغرام'
      });
    }

    console.log('✅ تم إرسال الرسالة للتلغرام بنجاح');

    // تحديث حالة الطلب في قاعدة البيانات
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        support_requested: true,
        support_requested_at: new Date().toISOString(),
        support_notes: notes || null
      })
      .eq('id', orderId);

    if (updateError) {
      console.log('⚠️ تحذير: فشل في تحديث قاعدة البيانات:', updateError);
    } else {
      console.log('✅ تم تحديث قاعدة البيانات بنجاح');
    }

    res.json({
      success: true,
      message: 'تم إرسال طلب الدعم بنجاح'
    });

  } catch (error) {
    console.error('❌ خطأ في إرسال طلب الدعم:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
    });
  }
});

/**
 * إرسال رسالة للتلغرام باستخدام Bot API
 */
async function sendToTelegram(message) {
  try {
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = '@montajati_support'; // معرف قناة الدعم
    
    if (!botToken) {
      console.log('❌ TELEGRAM_BOT_TOKEN غير موجود في متغيرات البيئة');
      return { success: false, error: 'Bot token not configured' };
    }

    console.log('📡 إرسال الرسالة للتلغرام...');
    console.log('🤖 Bot Token:', botToken ? 'موجود' : 'غير موجود');
    console.log('💬 Chat ID:', chatId);

    const telegramUrl = `https://api.telegram.org/bot${botToken}/sendMessage`;
    
    const response = await fetch(telegramUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        chat_id: chatId,
        text: message,
        parse_mode: 'HTML'
      }),
    });

    const result = await response.json();
    
    console.log('📡 استجابة التلغرام:', {
      status: response.status,
      ok: result.ok,
      description: result.description
    });

    if (result.ok) {
      return { success: true };
    } else {
      return { 
        success: false, 
        error: result.description || 'Unknown error' 
      };
    }

  } catch (error) {
    console.error('❌ خطأ في إرسال الرسالة للتلغرام:', error);
    return { 
      success: false, 
      error: error.message 
    };
  }
}

module.exports = router;
