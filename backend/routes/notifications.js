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

// ❌ تم حذف نظام إرسال إشعارات الطلبات المكرر
// ✅ الإشعارات تُرسل الآن من:
// 1. routes/orders.js - للتحديث اليدوي
// 2. routes/waseet_statuses.js - للمزامنة مع الوسيط

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

// ===== إرسال إشعار لجميع المستخدمين مع تشخيص شامل =====
router.post('/send', async (req, res) => {
  const diagnostics = {
    timestamp: new Date().toISOString(),
    requestId: `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    step: 'بدء العملية',
    details: {},
    errors: [],
    warnings: [],
    performance: {
      startTime: Date.now(),
      steps: []
    }
  };

  try {
    console.log('📢 === [DIAGNOSTIC] طلب إرسال إشعار جماعي جديد ===');
    console.log('🔍 [DIAGNOSTIC] معرف الطلب:', diagnostics.requestId);

    diagnostics.step = 'تحليل البيانات الواردة';
    diagnostics.performance.steps.push({ step: 'بدء العملية', timestamp: Date.now() });

    const {
      title,
      body,
      type = 'general',
      isScheduled = false,
      scheduledDateTime
    } = req.body;

    diagnostics.details.requestData = { title, body, type, isScheduled, scheduledDateTime };
    console.log('📝 [DIAGNOSTIC] بيانات الطلب:', JSON.stringify(diagnostics.details.requestData, null, 2));

    // التحقق من البيانات المطلوبة
    if (!title || !body) {
      diagnostics.step = 'فشل التحقق من البيانات';
      diagnostics.errors.push('العنوان أو المحتوى مفقود');
      console.log('❌ [DIAGNOSTIC] بيانات مفقودة: العنوان أو المحتوى');

      return res.status(400).json({
        success: false,
        message: 'العنوان والمحتوى مطلوبان',
        diagnostics: diagnostics
      });
    }

    console.log(`📝 [DIAGNOSTIC] العنوان: ${title}`);
    console.log(`📝 [DIAGNOSTIC] المحتوى: ${body}`);
    console.log(`📝 [DIAGNOSTIC] النوع: ${type}`);
    console.log(`📝 [DIAGNOSTIC] مجدول: ${isScheduled}`);

    // تهيئة مدير الإشعارات
    diagnostics.step = 'تهيئة مدير الإشعارات';
    diagnostics.performance.steps.push({ step: 'تهيئة مدير الإشعارات', timestamp: Date.now() });
    console.log('🔧 [DIAGNOSTIC] تهيئة مدير الإشعارات...');

    const manager = await initializeNotificationManager();
    console.log('✅ [DIAGNOSTIC] تم تهيئة مدير الإشعارات بنجاح');

    // جلب جميع المستخدمين النشطين
    diagnostics.step = 'جلب المستخدمين النشطين';
    diagnostics.performance.steps.push({ step: 'جلب المستخدمين', timestamp: Date.now() });
    console.log('👥 [DIAGNOSTIC] جلب المستخدمين النشطين...');

    const activeUsers = await manager.getAllActiveUsers();
    const recipientsCount = activeUsers.length;

    diagnostics.details.activeUsers = {
      count: recipientsCount,
      sample: activeUsers.slice(0, 3).map(user => ({ phone: user.phone, hasToken: !!user.fcm_token }))
    };

    console.log(`👥 [DIAGNOSTIC] عدد المستخدمين المستهدفين: ${recipientsCount}`);
    console.log('👥 [DIAGNOSTIC] عينة من المستخدمين:', diagnostics.details.activeUsers.sample);

    if (recipientsCount === 0) {
      diagnostics.step = 'لا توجد مستخدمين نشطين';
      diagnostics.warnings.push('لا توجد مستخدمين نشطين');
      console.log('⚠️ [DIAGNOSTIC] لا توجد مستخدمين نشطين');

      return res.status(400).json({
        success: false,
        message: 'لا توجد مستخدمين نشطين لإرسال الإشعار إليهم',
        diagnostics: diagnostics
      });
    }

    // إنشاء سجل الإشعار
    diagnostics.step = 'إنشاء سجل الإشعار';
    diagnostics.performance.steps.push({ step: 'إنشاء سجل الإشعار', timestamp: Date.now() });

    const notificationData = {
      title,
      body,
      type,
      isScheduled,
      scheduledDateTime,
      recipientsCount,
      createdAt: new Date().toISOString()
    };

    diagnostics.details.notificationData = notificationData;
    console.log('📋 [DIAGNOSTIC] سجل الإشعار:', notificationData);

    if (!isScheduled) {
      // إرسال فوري
      diagnostics.step = 'إرسال الإشعارات الفورية';
      diagnostics.performance.steps.push({ step: 'بدء الإرسال الفوري', timestamp: Date.now() });
      console.log('🚀 [DIAGNOSTIC] بدء إرسال الإشعارات الفورية...');

      try {
        const notificationPayload = {
          title,
          body,
          data: {
            type,
            timestamp: Date.now().toString(),
            action: 'open_app'
          }
        };

        diagnostics.details.notificationPayload = notificationPayload;
        console.log('📦 [DIAGNOSTIC] حمولة الإشعار:', notificationPayload);

        const results = await manager.sendBulkNotification(notificationPayload, activeUsers);

        diagnostics.step = 'معالجة نتائج الإرسال';
        diagnostics.performance.steps.push({ step: 'انتهاء الإرسال', timestamp: Date.now() });
        diagnostics.details.sendResults = results;

        console.log(`📊 [DIAGNOSTIC] نتائج الإرسال:`, results);

        // حفظ الإشعار في قاعدة البيانات
        diagnostics.step = 'حفظ سجل الإشعار';
        console.log('💾 [DIAGNOSTIC] حفظ سجل الإشعار في قاعدة البيانات...');

        await manager.saveNotificationRecord({
          ...notificationData,
          status: 'sent',
          sentAt: new Date().toISOString(),
          results
        });

        diagnostics.step = 'اكتمال العملية بنجاح';
        diagnostics.performance.totalTime = Date.now() - diagnostics.performance.startTime;

        console.log(`✅ [DIAGNOSTIC] تم إرسال الإشعار لـ ${recipientsCount} مستخدم`);
        console.log(`⏱️ [DIAGNOSTIC] إجمالي الوقت: ${diagnostics.performance.totalTime}ms`);

        res.json({
          success: true,
          message: 'تم إرسال الإشعار بنجاح لجميع المستخدمين',
          data: {
            recipients_count: recipientsCount,
            results,
            notification_id: `bulk_${Date.now()}`
          },
          diagnostics: diagnostics
        });

      } catch (sendError) {
        diagnostics.step = 'خطأ في الإرسال';
        diagnostics.errors.push({
          type: 'send_error',
          message: sendError.message,
          stack: sendError.stack,
          timestamp: new Date().toISOString()
        });

        console.error('❌ [DIAGNOSTIC] خطأ في إرسال الإشعارات:', sendError);
        throw sendError;
      }
    } else {
      // إرسال مجدول
      diagnostics.step = 'جدولة الإشعار';
      diagnostics.performance.steps.push({ step: 'جدولة الإشعار', timestamp: Date.now() });
      console.log(`⏰ [DIAGNOSTIC] تم جدولة الإشعار للإرسال في: ${scheduledDateTime}`);

      // حفظ الإشعار المجدول
      await manager.saveNotificationRecord({
        ...notificationData,
        status: 'scheduled',
        scheduledFor: scheduledDateTime
      });

      diagnostics.step = 'اكتمال الجدولة';
      diagnostics.performance.totalTime = Date.now() - diagnostics.performance.startTime;

      res.json({
        success: true,
        message: 'تم جدولة الإشعار بنجاح',
        data: {
          recipients_count: recipientsCount,
          scheduled_time: scheduledDateTime,
          notification_id: `scheduled_${Date.now()}`
        },
        diagnostics: diagnostics
      });
    }

  } catch (error) {
    diagnostics.step = 'خطأ عام في العملية';
    diagnostics.performance.totalTime = Date.now() - diagnostics.performance.startTime;
    diagnostics.errors.push({
      type: 'general_error',
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
      step: diagnostics.step
    });

    console.error('❌ [DIAGNOSTIC] خطأ في إرسال الإشعار الجماعي:', error);
    console.error('📊 [DIAGNOSTIC] تشخيص شامل للخطأ:', JSON.stringify(diagnostics, null, 2));

    res.status(500).json({
      success: false,
      message: 'خطأ في إرسال الإشعار',
      error: error.message,
      diagnostics: diagnostics
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

// ===== إنشاء جداول قاعدة البيانات =====
router.post('/setup-database', async (req, res) => {
  try {
    console.log('🔧 إنشاء جداول قاعدة البيانات للإشعارات...');

    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إنشاء جدول الإشعارات
    const createNotificationsTable = `
      CREATE TABLE IF NOT EXISTS notifications (
          id SERIAL PRIMARY KEY,
          title VARCHAR(255) NOT NULL,
          body TEXT NOT NULL,
          type VARCHAR(50) DEFAULT 'general',
          status VARCHAR(50) DEFAULT 'sent',
          recipients_count INTEGER DEFAULT 0,
          delivery_rate INTEGER DEFAULT 0,
          sent_at TIMESTAMP WITH TIME ZONE,
          scheduled_for TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          notification_data JSONB,
          created_by VARCHAR(100)
      );
    `;

    // إنشاء جدول الإحصائيات
    const createStatsTable = `
      CREATE TABLE IF NOT EXISTS notification_stats (
          id SERIAL PRIMARY KEY,
          total_sent INTEGER DEFAULT 0,
          total_delivered INTEGER DEFAULT 0,
          total_opened INTEGER DEFAULT 0,
          total_clicked INTEGER DEFAULT 0,
          date DATE DEFAULT CURRENT_DATE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          UNIQUE(date)
      );
    `;

    // إنشاء دالة الإحصائيات
    const createStatsFunction = `
      CREATE OR REPLACE FUNCTION get_notification_statistics()
      RETURNS JSON AS $$
      DECLARE
          result JSON;
      BEGIN
          SELECT json_build_object(
              'total_sent', COALESCE(SUM(total_sent), 0),
              'total_delivered', COALESCE(SUM(total_delivered), 0),
              'total_opened', COALESCE(SUM(total_opened), 0),
              'total_clicked', COALESCE(SUM(total_clicked), 0),
              'last_updated', MAX(updated_at)
          ) INTO result
          FROM notification_stats;

          RETURN result;
      END;
      $$ LANGUAGE plpgsql;
    `;

    // إنشاء دالة التاريخ
    const createHistoryFunction = `
      CREATE OR REPLACE FUNCTION get_notification_history(limit_count INTEGER DEFAULT 50)
      RETURNS JSON AS $$
      DECLARE
          result JSON;
      BEGIN
          SELECT json_agg(
              json_build_object(
                  'id', id,
                  'title', title,
                  'body', body,
                  'type', type,
                  'status', status,
                  'recipients_count', recipients_count,
                  'delivery_rate', delivery_rate,
                  'sent_at', sent_at,
                  'created_at', created_at
              )
              ORDER BY created_at DESC
          ) INTO result
          FROM notifications
          LIMIT limit_count;

          RETURN COALESCE(result, '[]'::json);
      END;
      $$ LANGUAGE plpgsql;
    `;

    // تنفيذ الاستعلامات
    await supabase.rpc('exec_sql', { sql: createNotificationsTable });
    await supabase.rpc('exec_sql', { sql: createStatsTable });
    await supabase.rpc('exec_sql', { sql: createStatsFunction });
    await supabase.rpc('exec_sql', { sql: createHistoryFunction });

    // إدراج سجل إحصائيات أولي
    const { error: insertError } = await supabase
      .from('notification_stats')
      .insert([{ date: new Date().toISOString().split('T')[0] }])
      .select();

    console.log('✅ تم إنشاء جداول قاعدة البيانات بنجاح');

    res.json({
      success: true,
      message: 'تم إنشاء جداول قاعدة البيانات بنجاح',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ خطأ في إنشاء جداول قاعدة البيانات:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في إنشاء جداول قاعدة البيانات',
      error: error.message
    });
  }
});

// ===== اختبار النظام =====
router.post('/test-system', async (req, res) => {
  try {
    console.log('🧪 اختبار نظام الإشعارات...');

    const manager = await initializeNotificationManager();

    // اختبار جلب المستخدمين
    const users = await manager.getAllActiveUsers();
    console.log(`👥 عدد المستخدمين النشطين: ${users.length}`);

    // اختبار الإحصائيات
    const stats = await manager.getNotificationStats();
    console.log('📊 الإحصائيات:', stats);

    // اختبار التاريخ
    const history = await manager.getNotificationHistory();
    console.log(`📜 عدد الإشعارات في التاريخ: ${history.length}`);

    res.json({
      success: true,
      message: 'تم اختبار النظام بنجاح',
      data: {
        active_users_count: users.length,
        stats: stats,
        history_count: history.length,
        system_status: 'operational'
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ خطأ في اختبار النظام:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في اختبار النظام',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ===== اختبار شامل للنظام مع تشخيص =====
router.post('/system-test', async (req, res) => {
  const systemDiagnostics = {
    timestamp: new Date().toISOString(),
    testId: `test_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    step: 'بدء الاختبار الشامل',
    details: {},
    errors: [],
    warnings: [],
    performance: {
      startTime: Date.now(),
      steps: []
    }
  };

  try {
    console.log('🧪 [SYSTEM-TEST] بدء اختبار شامل لنظام الإشعارات...');
    console.log('🔍 [SYSTEM-TEST] معرف الاختبار:', systemDiagnostics.testId);

    // الخطوة 1: تهيئة مدير الإشعارات
    systemDiagnostics.step = 'تهيئة مدير الإشعارات';
    systemDiagnostics.performance.steps.push({ step: 'تهيئة المدير', timestamp: Date.now() });
    console.log('🔧 [SYSTEM-TEST] تهيئة مدير الإشعارات...');

    const manager = await initializeNotificationManager();
    console.log('✅ [SYSTEM-TEST] تم تهيئة مدير الإشعارات بنجاح');

    // الخطوة 2: فحص حالة Firebase
    systemDiagnostics.step = 'فحص حالة Firebase';
    systemDiagnostics.performance.steps.push({ step: 'فحص Firebase', timestamp: Date.now() });
    console.log('🔥 [SYSTEM-TEST] فحص حالة Firebase...');

    const firebaseStatus = manager.targetedService ? 'متصل' : 'غير متصل';
    systemDiagnostics.details.firebaseStatus = firebaseStatus;
    console.log(`🔥 [SYSTEM-TEST] حالة Firebase: ${firebaseStatus}`);

    // الخطوة 3: جلب المستخدمين النشطين
    systemDiagnostics.step = 'جلب المستخدمين النشطين';
    systemDiagnostics.performance.steps.push({ step: 'جلب المستخدمين', timestamp: Date.now() });
    console.log('👥 [SYSTEM-TEST] جلب المستخدمين النشطين...');

    const activeUsers = await manager.getAllActiveUsers();
    systemDiagnostics.details.activeUsersCount = activeUsers.length;
    systemDiagnostics.details.activeUsersSample = activeUsers.slice(0, 3).map(u => ({
      phone: u.phone,
      hasToken: !!u.fcm_token,
      tokenPreview: u.fcm_token ? u.fcm_token.substring(0, 20) + '...' : 'لا يوجد'
    }));

    console.log(`👥 [SYSTEM-TEST] عدد المستخدمين النشطين: ${activeUsers.length}`);

    // الخطوة 4: اختبار إرسال إشعار تجريبي
    if (activeUsers.length > 0) {
      systemDiagnostics.step = 'اختبار إرسال إشعار تجريبي';
      systemDiagnostics.performance.steps.push({ step: 'اختبار الإرسال', timestamp: Date.now() });
      console.log('📱 [SYSTEM-TEST] اختبار إرسال إشعار تجريبي...');

      const testUser = activeUsers[0];
      const testResult = await manager.sendGeneralNotification({
        userPhone: testUser.phone,
        title: '🧪 اختبار النظام',
        message: 'هذا إشعار تجريبي للتأكد من عمل النظام - تم إرساله من الاختبار الشامل',
        additionalData: {
          type: 'system_test',
          testId: systemDiagnostics.testId,
          timestamp: new Date().toISOString()
        }
      });

      systemDiagnostics.details.testResult = testResult;
      console.log(`📱 [SYSTEM-TEST] نتيجة الاختبار:`, testResult);
    } else {
      systemDiagnostics.warnings.push('لا توجد مستخدمين نشطين لاختبار الإرسال');
      console.log('⚠️ [SYSTEM-TEST] لا توجد مستخدمين نشطين لاختبار الإرسال');
    }

    // الخطوة 5: فحص قاعدة البيانات
    systemDiagnostics.step = 'فحص قاعدة البيانات';
    systemDiagnostics.performance.steps.push({ step: 'فحص قاعدة البيانات', timestamp: Date.now() });
    console.log('💾 [SYSTEM-TEST] فحص قاعدة البيانات...');

    try {
      const stats = await manager.getNotificationStats();
      systemDiagnostics.details.databaseStats = stats;
      console.log('💾 [SYSTEM-TEST] قاعدة البيانات تعمل بشكل صحيح');
    } catch (dbError) {
      systemDiagnostics.warnings.push(`مشكلة في قاعدة البيانات: ${dbError.message}`);
      console.log('⚠️ [SYSTEM-TEST] مشكلة في قاعدة البيانات:', dbError.message);
    }

    // الخطوة 6: تقييم النتائج
    systemDiagnostics.step = 'تقييم النتائج';
    systemDiagnostics.performance.endTime = Date.now();
    systemDiagnostics.performance.totalTime = systemDiagnostics.performance.endTime - systemDiagnostics.performance.startTime;

    const systemHealth = {
      overall: 'صحي',
      components: {
        manager: 'صحي',
        firebase: firebaseStatus === 'متصل' ? 'صحي' : 'مشكلة',
        database: systemDiagnostics.details.databaseStats ? 'صحي' : 'مشكلة',
        users: activeUsers.length > 0 ? 'صحي' : 'تحذير'
      }
    };

    if (systemDiagnostics.errors.length > 0) {
      systemHealth.overall = 'مشكلة';
    } else if (systemDiagnostics.warnings.length > 0) {
      systemHealth.overall = 'تحذير';
    }

    systemDiagnostics.details.systemHealth = systemHealth;

    console.log('✅ [SYSTEM-TEST] انتهى الاختبار الشامل');
    console.log(`⏱️ [SYSTEM-TEST] إجمالي الوقت: ${systemDiagnostics.performance.totalTime}ms`);
    console.log('🏥 [SYSTEM-TEST] حالة النظام:', systemHealth);

    res.json({
      success: true,
      message: 'تم إجراء الاختبار الشامل بنجاح',
      systemHealth: systemHealth,
      diagnostics: systemDiagnostics
    });

  } catch (error) {
    systemDiagnostics.step = 'خطأ في الاختبار الشامل';
    systemDiagnostics.performance.endTime = Date.now();
    systemDiagnostics.performance.totalTime = systemDiagnostics.performance.endTime - systemDiagnostics.performance.startTime;
    systemDiagnostics.errors.push({
      type: 'system_test_error',
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    });

    console.error('❌ [SYSTEM-TEST] خطأ في الاختبار الشامل:', error);
    console.error('📊 [SYSTEM-TEST] تشخيص شامل للخطأ:', JSON.stringify(systemDiagnostics, null, 2));

    res.status(500).json({
      success: false,
      message: 'خطأ في الاختبار الشامل',
      error: error.message,
      diagnostics: systemDiagnostics
    });
  }
});

// ===== اختبار endpoint جديد =====
router.get('/test-bulk', (req, res) => {
  res.json({
    success: true,
    message: 'endpoint /send-bulk متاح ويعمل',
    timestamp: new Date().toISOString()
  });
});

// ===== إرسال إشعار جماعي - مسار جديد لتجنب التداخل =====
router.post('/send-bulk', async (req, res) => {
  const diagnostics = {
    timestamp: new Date().toISOString(),
    requestId: `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    step: 'بدء العملية',
    details: {},
    errors: [],
    warnings: [],
    performance: {
      startTime: Date.now(),
      steps: []
    }
  };

  try {
    console.log('📢 === [SEND-BULK] طلب إرسال إشعار جماعي جديد ===');
    console.log('🔍 [SEND-BULK] معرف الطلب:', diagnostics.requestId);

    diagnostics.step = 'تحليل البيانات الواردة';
    diagnostics.performance.steps.push({ step: 'بدء العملية', timestamp: Date.now() });

    const {
      title,
      body,
      type = 'general',
      isScheduled = false,
      scheduledDateTime
    } = req.body;

    diagnostics.details.requestData = { title, body, type, isScheduled, scheduledDateTime };
    console.log('📝 [SEND-BULK] بيانات الطلب:', JSON.stringify(diagnostics.details.requestData, null, 2));

    // التحقق من البيانات المطلوبة
    if (!title || !body) {
      diagnostics.step = 'فشل التحقق من البيانات';
      diagnostics.errors.push('العنوان أو المحتوى مفقود');
      console.log('❌ [SEND-BULK] بيانات مفقودة: العنوان أو المحتوى');

      return res.status(400).json({
        success: false,
        message: 'العنوان والمحتوى مطلوبان',
        diagnostics: diagnostics
      });
    }

    console.log(`📝 [SEND-BULK] العنوان: ${title}`);
    console.log(`📝 [SEND-BULK] المحتوى: ${body}`);
    console.log(`📝 [SEND-BULK] النوع: ${type}`);
    console.log(`📝 [SEND-BULK] مجدول: ${isScheduled}`);

    // تهيئة مدير الإشعارات
    diagnostics.step = 'تهيئة مدير الإشعارات';
    diagnostics.performance.steps.push({ step: 'تهيئة مدير الإشعارات', timestamp: Date.now() });
    console.log('🔧 [SEND-BULK] تهيئة مدير الإشعارات...');

    const manager = await initializeNotificationManager();
    console.log('✅ [SEND-BULK] تم تهيئة مدير الإشعارات بنجاح');

    // جلب جميع المستخدمين النشطين
    diagnostics.step = 'جلب المستخدمين النشطين';
    diagnostics.performance.steps.push({ step: 'جلب المستخدمين', timestamp: Date.now() });
    console.log('👥 [SEND-BULK] جلب المستخدمين النشطين...');

    const activeUsers = await manager.getAllActiveUsers();
    const recipientsCount = activeUsers.length;

    diagnostics.details.activeUsers = {
      count: recipientsCount,
      sample: activeUsers.slice(0, 3).map(user => ({ phone: user.phone, hasToken: !!user.fcm_token }))
    };

    console.log(`👥 [SEND-BULK] عدد المستخدمين المستهدفين: ${recipientsCount}`);
    console.log('👥 [SEND-BULK] عينة من المستخدمين:', diagnostics.details.activeUsers.sample);

    if (recipientsCount === 0) {
      diagnostics.step = 'لا توجد مستخدمين نشطين';
      diagnostics.warnings.push('لا توجد مستخدمين نشطين');
      console.log('⚠️ [SEND-BULK] لا توجد مستخدمين نشطين');

      return res.status(400).json({
        success: false,
        message: 'لا توجد مستخدمين نشطين لإرسال الإشعار إليهم',
        diagnostics: diagnostics
      });
    }

    // إنشاء سجل الإشعار
    diagnostics.step = 'إنشاء سجل الإشعار';
    diagnostics.performance.steps.push({ step: 'إنشاء سجل الإشعار', timestamp: Date.now() });

    const notificationData = {
      title,
      body,
      type,
      isScheduled,
      scheduledDateTime,
      recipientsCount,
      createdAt: new Date().toISOString()
    };

    diagnostics.details.notificationData = notificationData;
    console.log('📋 [SEND-BULK] سجل الإشعار:', notificationData);

    if (!isScheduled) {
      // إرسال فوري - رد سريع ثم إرسال في الخلفية
      diagnostics.step = 'بدء الإرسال الفوري';
      diagnostics.performance.steps.push({ step: 'بدء الإرسال الفوري', timestamp: Date.now() });
      console.log('🚀 [SEND-BULK] بدء إرسال الإشعارات الفورية...');

      const notificationPayload = {
        title,
        body,
        data: {
          type,
          timestamp: Date.now().toString(),
          action: 'open_app'
        }
      };

      diagnostics.details.notificationPayload = notificationPayload;
      console.log('📦 [SEND-BULK] حمولة الإشعار:', notificationPayload);

      // رد سريع للتطبيق
      const notificationId = `bulk_${Date.now()}`;
      diagnostics.step = 'رد سريع للتطبيق';
      diagnostics.performance.totalTime = Date.now() - diagnostics.performance.startTime;

      console.log(`⚡ [SEND-BULK] رد سريع للتطبيق - سيتم الإرسال في الخلفية`);

      res.json({
        success: true,
        message: 'تم بدء إرسال الإشعار بنجاح - سيتم الإرسال في الخلفية',
        data: {
          recipients_count: recipientsCount,
          notification_id: notificationId,
          status: 'processing'
        },
        diagnostics: diagnostics
      });

      // إرسال الإشعارات في الخلفية (بدون انتظار)
      setImmediate(async () => {
        try {
          console.log('🔄 [SEND-BULK-BG] بدء الإرسال في الخلفية...');

          const results = await manager.sendBulkNotification(notificationPayload, activeUsers);

          console.log(`📊 [SEND-BULK-BG] نتائج الإرسال:`, results);

          // حفظ الإشعار في قاعدة البيانات
          console.log('💾 [SEND-BULK-BG] حفظ سجل الإشعار في قاعدة البيانات...');

          await manager.saveNotificationRecord({
            ...notificationData,
            status: 'sent',
            sentAt: new Date().toISOString(),
            results,
            notification_id: notificationId
          });

          console.log(`✅ [SEND-BULK-BG] تم إرسال الإشعار لـ ${recipientsCount} مستخدم بنجاح`);

        } catch (sendError) {
          console.error('❌ [SEND-BULK-BG] خطأ في إرسال الإشعارات في الخلفية:', sendError);

          // حفظ سجل الخطأ
          try {
            await manager.saveNotificationRecord({
              ...notificationData,
              status: 'failed',
              sentAt: new Date().toISOString(),
              error: sendError.message,
              notification_id: notificationId
            });
          } catch (saveError) {
            console.error('❌ [SEND-BULK-BG] خطأ في حفظ سجل الخطأ:', saveError);
          }
        }
      });
    } else {
      // إرسال مجدول
      diagnostics.step = 'جدولة الإشعار';
      diagnostics.performance.steps.push({ step: 'جدولة الإشعار', timestamp: Date.now() });
      console.log(`⏰ [SEND-BULK] تم جدولة الإشعار للإرسال في: ${scheduledDateTime}`);

      // حفظ الإشعار المجدول
      await manager.saveNotificationRecord({
        ...notificationData,
        status: 'scheduled',
        scheduledFor: scheduledDateTime
      });

      diagnostics.step = 'اكتمال الجدولة';
      diagnostics.performance.totalTime = Date.now() - diagnostics.performance.startTime;

      res.json({
        success: true,
        message: 'تم جدولة الإشعار بنجاح',
        data: {
          recipients_count: recipientsCount,
          scheduled_time: scheduledDateTime,
          notification_id: `scheduled_${Date.now()}`
        },
        diagnostics: diagnostics
      });
    }

  } catch (error) {
    diagnostics.step = 'خطأ عام في العملية';
    diagnostics.performance.totalTime = Date.now() - diagnostics.performance.startTime;
    diagnostics.errors.push({
      type: 'general_error',
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
      step: diagnostics.step
    });

    console.error('❌ [SEND-BULK] خطأ في إرسال الإشعار الجماعي:', error);
    console.error('📊 [SEND-BULK] تشخيص شامل للخطأ:', JSON.stringify(diagnostics, null, 2));

    res.status(500).json({
      success: false,
      message: 'خطأ في إرسال الإشعار',
      error: error.message,
      diagnostics: diagnostics
    });
  }
});

/**
 * API للتحقق من إصدار التطبيق
 * GET /api/app-version
 */
router.get('/app-version', (req, res) => {
  try {
    console.log('📱 طلب فحص إصدار التطبيق');

    // الإصدار الحالي للخادم
    const serverVersion = '3.7.0';
    const serverBuildNumber = 15;

    // الحصول على إصدار التطبيق من الطلب (إذا تم إرساله)
    const clientBuildNumber = parseInt(req.query.build_number || '0');

    // تحديد ما إذا كان التحديث إجباري
    const forceUpdate = serverBuildNumber > clientBuildNumber;

    console.log(`📊 إصدار الخادم: ${serverBuildNumber}, إصدار العميل: ${clientBuildNumber}, تحديث إجباري: ${forceUpdate}`);

    res.json({
      version: serverVersion,
      buildNumber: serverBuildNumber,
      downloadUrl: 'https://clownfish-app-krnk9.ondigitalocean.app/downloads/montajati-v3.7.0.apk',
      forceUpdate: forceUpdate,
      changelog: 'تحديث مهم: تحسينات الأداء وإصلاحات الأمان',
      releaseDate: new Date().toISOString(),
      fileSize: '26 MB',
      minAndroidVersion: '21'
    });

    console.log('✅ تم إرسال معلومات الإصدار');
  } catch (error) {
    console.error('❌ خطأ في API إصدار التطبيق:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
