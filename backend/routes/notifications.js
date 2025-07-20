// ===================================
// مسارات API للإشعارات الفورية
// Notification API Routes
// ===================================

const express = require('express');
const router = express.Router();
const targetedNotificationService = require('../services/targeted_notification_service');
const tokenManagementService = require('../services/token_management_service');

/**
 * إرسال إشعار تحديث حالة الطلب
 * POST /api/notifications/order-status
 */
router.post('/order-status', async (req, res) => {
  try {
    const { userPhone, orderId, newStatus, customerName, notes } = req.body;

    // التحقق من البيانات المطلوبة
    if (!userPhone || !orderId || !newStatus) {
      return res.status(400).json({
        success: false,
        message: 'البيانات المطلوبة مفقودة: userPhone, orderId, newStatus'
      });
    }

    console.log(`📱 طلب إرسال إشعار تحديث الطلب:`, {
      userPhone,
      orderId,
      newStatus,
      customerName: customerName || 'غير محدد'
    });

    // إرسال الإشعار
    const result = await targetedNotificationService.sendOrderStatusNotification(
      userPhone,
      orderId,
      newStatus,
      customerName || '',
      notes || ''
    );

    if (result.success) {
      res.json({
        success: true,
        message: 'تم إرسال الإشعار بنجاح',
        data: {
          userPhone: result.userPhone,
          orderId: result.orderId,
          messageId: result.messageId
        }
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في إرسال الإشعار',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في API إرسال إشعار تحديث الطلب:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * إرسال إشعار تحديث طلب السحب
 * POST /api/notifications/withdrawal-status
 */
router.post('/withdrawal-status', async (req, res) => {
  try {
    const { userPhone, requestId, amount, status, reason } = req.body;

    // التحقق من البيانات المطلوبة
    if (!userPhone || !requestId || !amount || !status) {
      return res.status(400).json({
        success: false,
        message: 'البيانات المطلوبة مفقودة: userPhone, requestId, amount, status'
      });
    }

    console.log(`💰 طلب إرسال إشعار تحديث طلب السحب:`, {
      userPhone,
      requestId,
      amount,
      status
    });

    // إرسال الإشعار
    const result = await targetedNotificationService.sendWithdrawalStatusNotification(
      userPhone,
      requestId,
      amount,
      status,
      reason || ''
    );

    if (result.success) {
      res.json({
        success: true,
        message: 'تم إرسال الإشعار بنجاح',
        data: {
          userPhone: result.userPhone,
          requestId: result.requestId,
          messageId: result.messageId
        }
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في إرسال الإشعار',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في API إرسال إشعار تحديث طلب السحب:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * إرسال إشعار عام
 * POST /api/notifications/general
 */
router.post('/general', async (req, res) => {
  try {
    const { userPhone, title, message, additionalData } = req.body;

    // التحقق من البيانات المطلوبة
    if (!userPhone || !title || !message) {
      return res.status(400).json({
        success: false,
        message: 'البيانات المطلوبة مفقودة: userPhone, title, message'
      });
    }

    console.log(`📢 طلب إرسال إشعار عام:`, {
      userPhone,
      title,
      message: message.substring(0, 50) + '...'
    });

    // إرسال الإشعار
    const result = await targetedNotificationService.sendGeneralNotification(
      userPhone,
      title,
      message,
      additionalData || {}
    );

    if (result.success) {
      res.json({
        success: true,
        message: 'تم إرسال الإشعار بنجاح',
        data: {
          userPhone: result.userPhone,
          messageId: result.messageId
        }
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في إرسال الإشعار',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في API إرسال الإشعار العام:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * اختبار إرسال إشعار
 * POST /api/notifications/test
 */
router.post('/test', async (req, res) => {
  try {
    const { userPhone } = req.body;

    if (!userPhone) {
      return res.status(400).json({
        success: false,
        message: 'رقم الهاتف مطلوب'
      });
    }

    console.log(`🧪 اختبار إرسال إشعار للمستخدم: ${userPhone}`);

    // إرسال إشعار تجريبي
    const result = await targetedNotificationService.sendGeneralNotification(
      userPhone,
      '🧪 إشعار تجريبي',
      'هذا إشعار تجريبي للتأكد من عمل النظام بشكل صحيح',
      {
        type: 'test',
        timestamp: new Date().toISOString()
      }
    );

    if (result.success) {
      res.json({
        success: true,
        message: 'تم إرسال الإشعار التجريبي بنجاح',
        data: {
          userPhone: result.userPhone,
          messageId: result.messageId
        }
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في إرسال الإشعار التجريبي',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في اختبار الإشعار:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * الحصول على معلومات خدمة الإشعارات
 * GET /api/notifications/status
 */
router.get('/status', async (req, res) => {
  try {
    const serviceInfo = targetedNotificationService.getServiceInfo();
    
    res.json({
      success: true,
      message: 'معلومات خدمة الإشعارات',
      data: serviceInfo
    });

  } catch (error) {
    console.error('❌ خطأ في الحصول على معلومات الخدمة:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * الحصول على إحصائيات FCM Tokens
 * GET /api/notifications/tokens/stats
 */
router.get('/tokens/stats', async (req, res) => {
  try {
    const stats = await tokenManagementService.getTokenStatistics();

    if (stats.success) {
      res.json({
        success: true,
        message: 'إحصائيات FCM Tokens',
        data: stats.statistics
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في الحصول على الإحصائيات',
        error: stats.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في API إحصائيات الرموز:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * تنظيف FCM Tokens القديمة
 * POST /api/notifications/tokens/cleanup
 */
router.post('/tokens/cleanup', async (req, res) => {
  try {
    console.log('🧹 طلب تنظيف FCM Tokens القديمة');

    const result = await tokenManagementService.cleanupOldTokens();

    if (result.success) {
      res.json({
        success: true,
        message: `تم حذف ${result.deletedCount} رمز قديم`,
        data: {
          deletedCount: result.deletedCount,
          timestamp: result.timestamp
        }
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في تنظيف الرموز',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في API تنظيف الرموز:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * التحقق من صحة جميع FCM Tokens
 * POST /api/notifications/tokens/validate
 */
router.post('/tokens/validate', async (req, res) => {
  try {
    console.log('🔍 طلب التحقق من صحة جميع FCM Tokens');

    const result = await tokenManagementService.validateAllActiveTokens();

    if (result.success) {
      res.json({
        success: true,
        message: 'تم التحقق من جميع الرموز',
        data: {
          totalTokens: result.totalTokens,
          validTokens: result.validTokens,
          invalidTokens: result.invalidTokens,
          deactivatedTokens: result.deactivatedTokens,
          timestamp: result.timestamp
        }
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في التحقق من الرموز',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في API التحقق من الرموز:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * حذف رموز مستخدم معين
 * DELETE /api/notifications/tokens/user/:userPhone
 */
router.delete('/tokens/user/:userPhone', async (req, res) => {
  try {
    const { userPhone } = req.params;

    if (!userPhone) {
      return res.status(400).json({
        success: false,
        message: 'رقم الهاتف مطلوب'
      });
    }

    console.log(`🗑️ طلب حذف رموز المستخدم: ${userPhone}`);

    const result = await tokenManagementService.deleteUserTokens(userPhone);

    if (result.success) {
      res.json({
        success: true,
        message: `تم حذف جميع رموز المستخدم ${userPhone}`,
        data: {
          userPhone: result.userPhone,
          timestamp: result.timestamp
        }
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في حذف رموز المستخدم',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في API حذف رموز المستخدم:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * تشغيل جميع مهام الصيانة
 * POST /api/notifications/tokens/maintenance
 */
router.post('/tokens/maintenance', async (req, res) => {
  try {
    console.log('🔧 طلب تشغيل جميع مهام الصيانة');

    const result = await tokenManagementService.runMaintenanceTasks();

    if (result.success) {
      res.json({
        success: true,
        message: 'تم تشغيل جميع مهام الصيانة بنجاح',
        data: result.results
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في تشغيل مهام الصيانة',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في API مهام الصيانة:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

module.exports = router;
