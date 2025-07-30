const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const TelegramNotificationService = require('../telegram_notification_service');

// تهيئة خدمة التلغرام
const telegramService = new TelegramNotificationService();

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

    // تحضير الرسالة بالتنسيق المطلوب بالضبط كما طلب المستخدم
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

    // إرسال الرسالة المنسقة مباشرة للدعم
    const telegramResult = await telegramService.sendMessage(message, telegramService.supportChatId);

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

// تم نقل وظائف التلغرام إلى TelegramNotificationService

module.exports = router;
