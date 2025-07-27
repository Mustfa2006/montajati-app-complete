// ===================================
// مسارات API للإشعارات الفورية
// Notification API Routes
// ===================================

const express = require('express');
const router = express.Router();
const targetedNotificationService = require('../services/targeted_notification_service');
const tokenManagementService = require('../services/token_management_service');
const OfficialNotificationManager = require('../services/official_notification_manager');

// إنشاء instance من مدير الإشعارات
let notificationManager = null;

// دالة تهيئة مدير الإشعارات
async function initializeNotificationManager() {
  if (!notificationManager) {
    notificationManager = new OfficialNotificationManager();
    await notificationManager.initialize();
  }
  return notificationManager;
}

// تهيئة مدير الإشعارات
async function initializeNotificationManager() {
  if (!notificationManager) {
    notificationManager = new OfficialNotificationManager();
    await notificationManager.initialize();
  }
  return notificationManager;
}

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
        message: 'userPhone مطلوب'
      });
    }

    console.log('🧪 اختبار إرسال إشعار للمستخدم:', userPhone);

    // تهيئة مدير الإشعارات
    const manager = await initializeNotificationManager();

    // إرسال إشعار تجريبي
    const result = await manager.sendGeneralNotification({
      customerPhone: userPhone,
      title: '🧪 إشعار تجريبي',
      message: 'هذا إشعار تجريبي من نظام منتجاتي - إذا وصلك هذا الإشعار فالنظام يعمل بشكل صحيح!',
      additionalData: {
        type: 'test_notification',
        timestamp: new Date().toISOString(),
        source: 'admin_panel'
      }
    });

    if (result.success) {
      res.json({
        success: true,
        message: 'تم إرسال الإشعار التجريبي بنجاح',
        data: {
          sentTo: userPhone,
          timestamp: new Date().toISOString(),
          result: result
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
    console.error('❌ خطأ في إرسال الإشعار التجريبي:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في إرسال الإشعار التجريبي',
      error: error.message
    });
  }
});

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

// ===== إرسال إشعار لجميع المستخدمين =====
router.post('/send', async (req, res) => {
  try {
    console.log('📢 === طلب إرسال إشعار جماعي جديد ===');

    const {
      title,
      body,
      type = 'general',
      isScheduled = false,
      scheduledDateTime
    } = req.body;

    // التحقق من البيانات المطلوبة
    if (!title || !body) {
      return res.status(400).json({
        success: false,
        message: 'العنوان والمحتوى مطلوبان'
      });
    }

    console.log(`📝 العنوان: ${title}`);
    console.log(`📝 المحتوى: ${body}`);
    console.log(`📝 النوع: ${type}`);
    console.log(`📝 مجدول: ${isScheduled}`);

    // تهيئة مدير الإشعارات
    const manager = await initializeNotificationManager();

    // جلب جميع المستخدمين النشطين
    const activeUsers = await manager.getAllActiveUsers();
    const recipientsCount = activeUsers.length;

    console.log(`👥 عدد المستخدمين المستهدفين: ${recipientsCount}`);

    if (recipientsCount === 0) {
      return res.status(400).json({
        success: false,
        message: 'لا توجد مستخدمين نشطين لإرسال الإشعار إليهم'
      });
    }

    // إنشاء سجل الإشعار
    const notificationData = {
      title,
      body,
      type,
      isScheduled,
      scheduledDateTime,
      recipientsCount,
      createdAt: new Date().toISOString()
    };

    if (!isScheduled) {
      // إرسال فوري
      console.log('🚀 بدء إرسال الإشعارات الفورية...');

      const results = await manager.sendBulkNotification({
        title,
        body,
        data: {
          type,
          timestamp: Date.now().toString(),
          action: 'open_app'
        }
      }, activeUsers);

      // حفظ الإشعار في قاعدة البيانات
      await manager.saveNotificationRecord({
        ...notificationData,
        status: 'sent',
        sentAt: new Date().toISOString(),
        results
      });

      console.log(`✅ تم إرسال الإشعار لـ ${recipientsCount} مستخدم`);
      console.log(`📊 نتائج الإرسال:`, results);

      res.json({
        success: true,
        message: 'تم إرسال الإشعار بنجاح لجميع المستخدمين',
        data: {
          recipients_count: recipientsCount,
          results,
          notification_id: `bulk_${Date.now()}`
        }
      });
    } else {
      // إرسال مجدول
      console.log(`⏰ تم جدولة الإشعار للإرسال في: ${scheduledDateTime}`);

      // حفظ الإشعار المجدول
      await manager.saveNotificationRecord({
        ...notificationData,
        status: 'scheduled',
        scheduledFor: scheduledDateTime
      });

      res.json({
        success: true,
        message: 'تم جدولة الإشعار بنجاح',
        data: {
          recipients_count: recipientsCount,
          scheduled_time: scheduledDateTime,
          notification_id: `scheduled_${Date.now()}`
        }
      });
    }

  } catch (error) {
    console.error('❌ خطأ في إرسال الإشعار الجماعي:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في إرسال الإشعار',
      error: error.message
    });
  }
});

// ===== جلب إحصائيات الإشعارات =====
router.get('/stats', async (req, res) => {
  try {
    console.log('📊 طلب إحصائيات الإشعارات');

    const manager = await initializeNotificationManager();
    const stats = await manager.getNotificationStats();

    res.json({
      success: true,
      stats: stats || {
        total_sent: 0,
        total_delivered: 0,
        total_opened: 0,
        total_clicked: 0,
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب الإحصائيات:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب الإحصائيات',
      stats: {
        total_sent: 0,
        total_delivered: 0,
        total_opened: 0,
        total_clicked: 0,
      }
    });
  }
});

// ===== جلب تاريخ الإشعارات المرسلة =====
router.get('/history', async (req, res) => {
  try {
    console.log('📜 طلب تاريخ الإشعارات');

    const manager = await initializeNotificationManager();
    const notifications = await manager.getNotificationHistory();

    res.json({
      success: true,
      notifications: notifications || []
    });

  } catch (error) {
    console.error('❌ خطأ في جلب تاريخ الإشعارات:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب تاريخ الإشعارات',
      notifications: []
    });
  }
});

module.exports = router;
