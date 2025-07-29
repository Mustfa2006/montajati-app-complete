const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

/**
 * إرسال طلب دعم للتليجرام - نسخة مبسطة للاختبار
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
      notes,
      waseetOrderId
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
    const message = `👤 معلومات الزبون:
📝 الاسم: ${customerName}
📞 الهاتف الأساسي: ${primaryPhone}
📱 الهاتف البديل: ${alternativePhone || 'غير متوفر'}

📍 معلومات العنوان:
🏛️ المحافظة: ${governorate || 'غير محدد'}
🏠 العنوان: ${address || 'غير محدد'}

📦 معلومات الطلب:
🆔 رقم الطلب: ${orderId}
📅 تاريخ الطلب: ${currentDate}
⚠️ حالة الطلب: ${orderStatus}
🚚 رقم الطلب في التوصيل: ${waseetOrderId || 'لم يتم الإرسال للتوصيل بعد'}

💬 ملاحظات المستخدم:
${notes && notes.trim() ? notes.trim() : 'لا توجد ملاحظات إضافية'}`;

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
        support_notes: notes || null,
        support_status: 'pending',
        support_handled_at: null,
        support_handled_by: null
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
    // استخدام متغيرات الدعم المنفصلة
    const botToken = process.env.TELEGRAM_SUPPORT_BOT_TOKEN || process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_SUPPORT_CHAT_ID || process.env.TELEGRAM_CHAT_ID;

    if (!botToken) {
      console.log('❌ TELEGRAM_BOT_TOKEN غير موجود في متغيرات البيئة');
      return { success: false, error: 'Bot token not configured' };
    }

    console.log('📡 إرسال الرسالة للتلغرام...');
    console.log('🤖 Bot Token:', botToken ? 'موجود' : 'غير موجود');
    console.log('💬 Chat ID:', chatId ? 'موجود' : 'غير موجود');

    // تحديد معرف المحادثة
    let targetChatId = chatId;

    // إذا لم يكن Chat ID محدد، نحاول الحصول عليه من آخر الرسائل
    if (!targetChatId) {
      console.log('🔍 البحث عن معرف المحادثة من آخر الرسائل...');

      try {
        const getUpdatesUrl = `https://api.telegram.org/bot${botToken}/getUpdates`;
        const updatesResponse = await fetch(getUpdatesUrl);
        const updatesResult = await updatesResponse.json();

        console.log('📨 عدد التحديثات:', updatesResult.result ? updatesResult.result.length : 0);

        if (updatesResult.ok && updatesResult.result.length > 0) {
          // نأخذ آخر رسالة
          const lastUpdate = updatesResult.result[updatesResult.result.length - 1];
          if (lastUpdate.message) {
            targetChatId = lastUpdate.message.chat.id;
            console.log('✅ تم العثور على معرف المحادثة:', targetChatId);
          }
        }
      } catch (error) {
        console.log('⚠️ فشل في الحصول على التحديثات:', error.message);
      }
    }

    // إذا لم نجد chat_id، نستخدم username كـ fallback
    if (!targetChatId) {
      console.log('⚠️ لم يتم العثور على معرف المحادثة، سنستخدم username');
      targetChatId = '@montajati_support';
    }

    const telegramUrl = `https://api.telegram.org/bot${botToken}/sendMessage`;

    const response = await fetch(telegramUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        chat_id: targetChatId,
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
      console.log(`✅ تم إرسال الرسالة بنجاح إلى ${targetChatId}`);
      return { success: true, messageId: result.result.message_id };
    } else {
      console.log('❌ فشل في الإرسال:', result.description);

      // رسائل خطأ محسنة
      if (result.description && result.description.includes('chat not found')) {
        return {
          success: false,
          error: `المحادثة غير موجودة. يجب على المستخدم ${targetChatId} إرسال /start للبوت أولاً.`
        };
      }

      if (result.description && result.description.includes('bot was blocked')) {
        return {
          success: false,
          error: 'تم حظر البوت من قبل المستخدم. يجب إلغاء الحظر أولاً.'
        };
      }

      if (result.description && result.description.includes('Unauthorized')) {
        return {
          success: false,
          error: 'رمز البوت غير صحيح. يرجى التحقق من TELEGRAM_BOT_TOKEN.'
        };
      }

      return {
        success: false,
        error: result.description || 'خطأ غير معروف في إرسال الرسالة'
      };
    }

  } catch (error) {
    console.error('❌ خطأ في إرسال الرسالة للتلغرام:', error);

    // تحديد نوع الخطأ
    if (error.message.includes('fetch')) {
      return {
        success: false,
        error: 'فشل في الاتصال بخادم التلغرام. يرجى التحقق من الاتصال بالإنترنت.'
      };
    }

    if (error.message.includes('timeout')) {
      return {
        success: false,
        error: 'انتهت مهلة الاتصال مع التلغرام. يرجى المحاولة مرة أخرى.'
      };
    }

    return {
      success: false,
      error: `خطأ في إرسال الرسالة: ${error.message}`
    };
  }
}

module.exports = router;
