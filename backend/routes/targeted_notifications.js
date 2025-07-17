// ===================================
// API Routes للإشعارات المستهدفة
// Targeted Notifications API Routes
// ===================================

const express = require('express');
const router = express.Router();
const notificationMasterService = require('../services/notification_master_service');

// ===================================
// إدارة الخدمات
// ===================================

/**
 * بدء جميع خدمات الإشعارات
 * POST /api/notifications/start
 */
router.post('/start', async (req, res) => {
  try {
    console.log('🚀 طلب بدء خدمات الإشعارات...');
    
    const result = await notificationMasterService.startAllServices();
    
    if (result.success) {
      res.json({
        success: true,
        message: result.message,
        data: result.services
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ خطأ في API بدء الخدمات:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * إيقاف جميع خدمات الإشعارات
 * POST /api/notifications/stop
 */
router.post('/stop', async (req, res) => {
  try {
    console.log('🛑 طلب إيقاف خدمات الإشعارات...');
    
    const result = await notificationMasterService.stopAllServices();
    
    if (result.success) {
      res.json({
        success: true,
        message: result.message,
        data: result.services
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ خطأ في API إيقاف الخدمات:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * إعادة تشغيل جميع خدمات الإشعارات
 * POST /api/notifications/restart
 */
router.post('/restart', async (req, res) => {
  try {
    console.log('🔄 طلب إعادة تشغيل خدمات الإشعارات...');
    
    const result = await notificationMasterService.restartAllServices();
    
    if (result.success) {
      res.json({
        success: true,
        message: result.message,
        data: result.services
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ خطأ في API إعادة تشغيل الخدمات:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * الحصول على حالة جميع الخدمات
 * GET /api/notifications/status
 */
router.get('/status', async (req, res) => {
  try {
    const result = await notificationMasterService.getComprehensiveStats();
    
    if (result.success) {
      res.json({
        success: true,
        data: result.data
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ خطأ في API حالة الخدمات:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// إرسال الإشعارات يدوياً
// ===================================

/**
 * إرسال إشعار حالة طلب يدوياً
 * POST /api/notifications/order-status
 */
router.post('/order-status', async (req, res) => {
  try {
    const { orderId, userId, customerName, oldStatus, newStatus } = req.body;

    // التحقق من البيانات المطلوبة
    if (!orderId || !userId || !customerName || !newStatus) {
      return res.status(400).json({
        success: false,
        error: 'البيانات المطلوبة: orderId, userId, customerName, newStatus'
      });
    }

    console.log(`🔧 طلب إرسال إشعار حالة طلب يدوياً:`);
    console.log(`📦 الطلب: ${orderId}`);
    console.log(`👤 المستخدم: ${userId}`);
    console.log(`👥 العميل: ${customerName}`);
    console.log(`🔄 الحالة الجديدة: ${newStatus}`);

    const result = await notificationMasterService.sendOrderStatusNotification(
      orderId,
      userId,
      customerName,
      oldStatus || 'unknown',
      newStatus
    );

    if (result.success) {
      res.json({
        success: true,
        message: 'تم إرسال إشعار حالة الطلب بنجاح',
        data: result
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ خطأ في API إرسال إشعار حالة الطلب:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * إرسال إشعار حالة طلب سحب يدوياً
 * POST /api/notifications/withdrawal-status
 */
router.post('/withdrawal-status', async (req, res) => {
  try {
    const { userId, requestId, amount, status, reason } = req.body;

    // التحقق من البيانات المطلوبة
    if (!userId || !requestId || !amount || !status) {
      return res.status(400).json({
        success: false,
        error: 'البيانات المطلوبة: userId, requestId, amount, status'
      });
    }

    console.log(`🔧 طلب إرسال إشعار حالة طلب سحب يدوياً:`);
    console.log(`👤 المستخدم: ${userId}`);
    console.log(`📄 طلب السحب: ${requestId}`);
    console.log(`💵 المبلغ: ${amount}`);
    console.log(`📊 الحالة: ${status}`);

    const result = await notificationMasterService.sendWithdrawalStatusNotification(
      userId,
      requestId,
      amount,
      status,
      reason || ''
    );

    if (result.success) {
      res.json({
        success: true,
        message: 'تم إرسال إشعار حالة طلب السحب بنجاح',
        data: result
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ خطأ في API إرسال إشعار حالة طلب السحب:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * معالجة تحديث حالة طلب سحب من Admin Panel
 * POST /api/notifications/admin-withdrawal-update
 */
router.post('/admin-withdrawal-update', async (req, res) => {
  try {
    const { requestId, newStatus, adminNotes } = req.body;

    // التحقق من البيانات المطلوبة
    if (!requestId || !newStatus) {
      return res.status(400).json({
        success: false,
        error: 'البيانات المطلوبة: requestId, newStatus'
      });
    }

    console.log(`🔧 طلب تحديث حالة طلب سحب من Admin Panel:`);
    console.log(`📄 طلب السحب: ${requestId}`);
    console.log(`📊 الحالة الجديدة: ${newStatus}`);
    console.log(`📝 ملاحظات المدير: ${adminNotes || 'لا توجد'}`);

    const result = await notificationMasterService.handleAdminWithdrawalStatusUpdate(
      requestId,
      newStatus,
      adminNotes || ''
    );

    if (result.success) {
      res.json({
        success: true,
        message: 'تم تحديث حالة طلب السحب وإرسال الإشعار بنجاح',
        data: result
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ خطأ في API تحديث حالة طلب السحب من Admin Panel:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// اختبار الإشعارات
// ===================================

/**
 * إرسال إشعار تجريبي
 * POST /api/notifications/test
 */
router.post('/test', async (req, res) => {
  try {
    const { userId, type } = req.body;

    // التحقق من البيانات المطلوبة
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'معرف المستخدم مطلوب'
      });
    }

    console.log(`🧪 طلب إرسال إشعار تجريبي:`);
    console.log(`👤 المستخدم: ${userId}`);
    console.log(`📱 النوع: ${type || 'order'}`);

    const result = await notificationMasterService.sendTestNotification(
      userId,
      type || 'order'
    );

    if (result.success) {
      res.json({
        success: true,
        message: 'تم إرسال الإشعار التجريبي بنجاح',
        data: result
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ خطأ في API الإشعار التجريبي:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
