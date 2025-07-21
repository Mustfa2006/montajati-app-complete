// ===================================
// مسارات API لحالات الوسيط
// Waseet Statuses API Routes
// ===================================

const express = require('express');
const router = express.Router();
const waseetStatusManager = require('../services/waseet_status_manager');

// ===================================
// الحصول على جميع الحالات المعتمدة
// ===================================
router.get('/approved', async (req, res) => {
  try {
    const statuses = waseetStatusManager.exportStatusesForApp();
    
    res.json({
      success: true,
      message: 'تم جلب الحالات المعتمدة بنجاح',
      data: statuses
    });

  } catch (error) {
    console.error('❌ خطأ في جلب الحالات المعتمدة:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب الحالات المعتمدة',
      error: error.message
    });
  }
});

// ===================================
// الحصول على الحالات حسب الفئة
// ===================================
router.get('/category/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const statuses = waseetStatusManager.getStatusesByCategory(category);
    
    res.json({
      success: true,
      message: `تم جلب حالات فئة ${category} بنجاح`,
      data: {
        category: category,
        count: statuses.length,
        statuses: statuses
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب حالات الفئة:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب حالات الفئة',
      error: error.message
    });
  }
});

// ===================================
// تحديث حالة طلب واحد
// ===================================
router.post('/update-order-status', async (req, res) => {
  try {
    const { orderId, waseetStatusId, waseetStatusText } = req.body;

    // التحقق من صحة البيانات
    const validation = waseetStatusManager.validateStatusUpdate(orderId, waseetStatusId, waseetStatusText);
    
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'بيانات غير صحيحة',
        errors: validation.errors
      });
    }

    // تحديث الحالة
    const result = await waseetStatusManager.updateOrderStatus(orderId, waseetStatusId, waseetStatusText);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'تم تحديث حالة الطلب بنجاح',
        data: result
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في تحديث حالة الطلب',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ خطأ في تحديث حالة الطلب:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في تحديث حالة الطلب',
      error: error.message
    });
  }
});

// ===================================
// تحديث حالات متعددة
// ===================================
router.post('/update-multiple-orders', async (req, res) => {
  try {
    const { updates } = req.body;

    if (!Array.isArray(updates) || updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'قائمة التحديثات مطلوبة ويجب أن تحتوي على عنصر واحد على الأقل'
      });
    }

    // التحقق من صحة جميع التحديثات
    const validationErrors = [];
    updates.forEach((update, index) => {
      const validation = waseetStatusManager.validateStatusUpdate(
        update.orderId, 
        update.waseetStatusId, 
        update.waseetStatusText
      );
      
      if (!validation.isValid) {
        validationErrors.push({
          index: index,
          orderId: update.orderId,
          errors: validation.errors
        });
      }
    });

    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'توجد أخطاء في بعض التحديثات',
        errors: validationErrors
      });
    }

    // تنفيذ التحديثات
    const results = await waseetStatusManager.updateMultipleOrderStatuses(updates);
    
    const successCount = results.filter(r => r.success).length;
    const failureCount = results.filter(r => !r.success).length;

    res.json({
      success: true,
      message: `تم تحديث ${successCount} طلب بنجاح، فشل في ${failureCount} طلب`,
      data: {
        total: results.length,
        successful: successCount,
        failed: failureCount,
        results: results
      }
    });

  } catch (error) {
    console.error('❌ خطأ في تحديث الحالات المتعددة:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في تحديث الحالات المتعددة',
      error: error.message
    });
  }
});

// ===================================
// الحصول على إحصائيات الحالات
// ===================================
router.get('/statistics', async (req, res) => {
  try {
    const stats = await waseetStatusManager.getStatusStatistics();
    
    res.json({
      success: true,
      message: 'تم جلب إحصائيات الحالات بنجاح',
      data: {
        totalStatuses: stats.length,
        statistics: stats
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب إحصائيات الحالات:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب إحصائيات الحالات',
      error: error.message
    });
  }
});

// ===================================
// مزامنة الحالات مع قاعدة البيانات
// ===================================
router.post('/sync', async (req, res) => {
  try {
    const result = await waseetStatusManager.syncStatusesToDatabase();
    
    if (result) {
      res.json({
        success: true,
        message: 'تم مزامنة الحالات مع قاعدة البيانات بنجاح'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'فشل في مزامنة الحالات'
      });
    }

  } catch (error) {
    console.error('❌ خطأ في مزامنة الحالات:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في مزامنة الحالات',
      error: error.message
    });
  }
});

// ===================================
// التحقق من صحة حالة
// ===================================
router.post('/validate', async (req, res) => {
  try {
    const { waseetStatusId } = req.body;
    
    const isValid = waseetStatusManager.isValidWaseetStatus(waseetStatusId);
    const statusInfo = waseetStatusManager.getStatusById(waseetStatusId);
    
    res.json({
      success: true,
      data: {
        isValid: isValid,
        statusInfo: statusInfo,
        message: isValid ? 'الحالة صحيحة ومعتمدة' : 'الحالة غير معتمدة'
      }
    });

  } catch (error) {
    console.error('❌ خطأ في التحقق من الحالة:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في التحقق من الحالة',
      error: error.message
    });
  }
});

// ===================================
// الحصول على معلومات حالة محددة
// ===================================
router.get('/status/:statusId', async (req, res) => {
  try {
    const { statusId } = req.params;
    const statusInfo = waseetStatusManager.getStatusById(parseInt(statusId));
    
    if (statusInfo) {
      res.json({
        success: true,
        message: 'تم جلب معلومات الحالة بنجاح',
        data: statusInfo
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'الحالة غير موجودة أو غير معتمدة'
      });
    }

  } catch (error) {
    console.error('❌ خطأ في جلب معلومات الحالة:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب معلومات الحالة',
      error: error.message
    });
  }
});

module.exports = router;
