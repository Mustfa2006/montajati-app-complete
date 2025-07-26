// ===================================
// مسارات معالجة طلبات الدعم
// Order Support Routes
// ===================================

const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const TelegramSupportService = require('../services/telegram_support_service');

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// إنشاء خدمة التليجرام
const telegramService = new TelegramSupportService();

/**
 * إرسال طلب دعم للتليجرام
 */
router.post('/send-support-request', async (req, res) => {
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

    // التحقق من البيانات المطلوبة
    if (!orderId || !customerName || !primaryPhone || !orderStatus) {
      return res.status(400).json({
        success: false,
        message: 'البيانات المطلوبة مفقودة'
      });
    }

    // الحصول على معلومات الطلب من قاعدة البيانات
    const { data: orderData, error: orderError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', orderId)
      .single();

    if (orderError || !orderData) {
      return res.status(404).json({
        success: false,
        message: 'الطلب غير موجود'
      });
    }

    // تحضير بيانات الرسالة
    const supportData = {
      orderId,
      customerName,
      primaryPhone,
      alternativePhone,
      governorate,
      address,
      orderStatus,
      notes,
      orderDate: new Date(orderData.created_at).toLocaleDateString('ar-EG')
    };

    // إرسال الرسالة للتليجرام
    const result = await telegramService.sendSupportMessage(supportData);

    if (result.success) {
      // تحديث حالة الطلب في قاعدة البيانات
      const { error: updateError } = await supabase
        .from('orders')
        .update({
          support_requested: true,
          support_requested_at: new Date().toISOString(),
          support_notes: notes
        })
        .eq('id', orderId);

      if (updateError) {
        console.error('خطأ في تحديث قاعدة البيانات:', updateError);
      }

      // تسجيل طلب الدعم
      await supabase
        .from('support_requests')
        .insert({
          order_id: orderId,
          customer_name: customerName,
          primary_phone: primaryPhone,
          alternative_phone: alternativePhone,
          governorate,
          address,
          order_status: orderStatus,
          notes,
          telegram_message_id: result.messageId,
          created_at: new Date().toISOString()
        });

      res.json({
        success: true,
        message: 'تم إرسال الطلب للدعم بنجاح',
        messageId: result.messageId
      });

    } else {
      res.status(500).json({
        success: false,
        message: result.message || 'فشل في إرسال الطلب للدعم'
      });
    }

  } catch (error) {
    console.error('خطأ في إرسال طلب الدعم:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
    });
  }
});

/**
 * التحقق من حالة طلب الدعم
 */
router.get('/support-status/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;

    const { data, error } = await supabase
      .from('orders')
      .select('support_requested, support_requested_at, support_notes')
      .eq('id', orderId)
      .single();

    if (error) {
      return res.status(404).json({
        success: false,
        message: 'الطلب غير موجود'
      });
    }

    res.json({
      success: true,
      supportRequested: data.support_requested || false,
      supportRequestedAt: data.support_requested_at,
      supportNotes: data.support_notes
    });

  } catch (error) {
    console.error('خطأ في التحقق من حالة الدعم:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
    });
  }
});

/**
 * تحديث حالة الدعم (عند إرسال الرسالة من المستخدم)
 */
router.post('/mark-support-sent', async (req, res) => {
  try {
    const { orderId, notes } = req.body;

    // التحقق من البيانات المطلوبة
    if (!orderId) {
      return res.status(400).json({
        success: false,
        message: 'معرف الطلب مطلوب'
      });
    }

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
      console.error('خطأ في تحديث قاعدة البيانات:', updateError);
      return res.status(500).json({
        success: false,
        message: 'فشل في تحديث حالة الدعم'
      });
    }

    // تسجيل طلب الدعم
    await supabase
      .from('support_requests')
      .insert({
        order_id: orderId,
        notes: notes || null,
        sent_via_user: true, // إشارة أن الرسالة أرسلت من المستخدم
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      message: 'تم تحديث حالة الدعم بنجاح'
    });

  } catch (error) {
    console.error('خطأ في تحديث حالة الدعم:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
    });
  }
});

/**
 * اختبار خدمة التليجرام
 */
router.post('/test-telegram', async (req, res) => {
  try {
    const connectionTest = await telegramService.testConnection();

    if (connectionTest.success) {
      const testMessage = await telegramService.sendTestMessage();

      res.json({
        success: true,
        message: 'تم اختبار التليجرام بنجاح',
        botInfo: connectionTest.botInfo,
        testResult: testMessage
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في الاتصال بالتليجرام',
        error: connectionTest.error
      });
    }

  } catch (error) {
    console.error('خطأ في اختبار التليجرام:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في اختبار التليجرام'
    });
  }
});

/**
 * الحصول على قائمة الطلبات التي تحتاج معالجة
 */
router.get('/orders-need-processing', async (req, res) => {
  try {
    // الحالات التي تحتاج معالجة
    const statusesNeedProcessing = [
      25, 26, 27, 28, 36, 37, 41, 29, 30, 33, 34, 35, 38, 39, 40
    ];

    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .in('status_id', statusesNeedProcessing)
      .eq('support_requested', false)
      .order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    res.json({
      success: true,
      orders: data,
      count: data.length
    });

  } catch (error) {
    console.error('خطأ في جلب الطلبات:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب الطلبات'
    });
  }
});

module.exports = router;
