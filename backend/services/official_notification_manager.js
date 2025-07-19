// ===================================
// نظام إدارة الإشعارات الرسمي والمتكامل
// Official Notification Management System
// ===================================

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const EventEmitter = require('events');

class OfficialNotificationManager extends EventEmitter {
  constructor() {
    super();
    
    // إعدادات النظام
    this.config = {
      batchSize: 50,                    // عدد الإشعارات في الدفعة الواحدة
      processingInterval: 5000,         // فترة المعالجة (5 ثواني)
      maxRetries: 3,                    // عدد المحاولات القصوى
      retryDelay: 30000,               // تأخير إعادة المحاولة (30 ثانية)
      cleanupInterval: 3600000,        // تنظيف السجلات (ساعة واحدة)
      maxLogAge: 7 * 24 * 60 * 60 * 1000, // عمر السجلات القصوى (7 أيام)
    };

    // حالة النظام
    this.state = {
      isRunning: false,
      isInitialized: false,
      lastProcessedAt: null,
      totalProcessed: 0,
      totalSuccessful: 0,
      totalFailed: 0,
      currentBatch: 0,
    };

    // معرفات العمليات
    this.intervals = {
      processing: null,
      cleanup: null,
      healthCheck: null,
    };

    // إعداد قاعدة البيانات
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعداد Firebase
    this.firebase = null;
    
    this.setupEventHandlers();
  }

  // ===================================
  // تهيئة النظام
  // ===================================
  async initialize() {
    try {
      console.log('🚀 تهيئة نظام إدارة الإشعارات الرسمي...');

      // تهيئة Firebase
      await this.initializeFirebase();

      // التحقق من قاعدة البيانات
      await this.verifyDatabase();

      // إعداد الجداول المطلوبة
      await this.setupRequiredTables();

      // بدء خدمات النظام
      this.startServices();

      this.state.isInitialized = true;
      console.log('✅ تم تهيئة نظام الإشعارات بنجاح');

      this.emit('initialized');
      return true;

    } catch (error) {
      console.error('❌ خطأ في تهيئة نظام الإشعارات:', error);
      this.emit('error', error);
      throw error;
    }
  }

  // ===================================
  // تهيئة Firebase
  // ===================================
  async initializeFirebase() {
    try {
      // التحقق من وجود Firebase مهيأ مسبقاً
      if (admin.apps.length > 0) {
        this.firebase = admin.app();
        console.log('✅ استخدام Firebase المهيأ مسبقاً');
        return;
      }

      // تهيئة Firebase جديد
      const serviceAccount = this.getFirebaseServiceAccount();
      
      this.firebase = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });

      console.log('✅ تم تهيئة Firebase بنجاح');

    } catch (error) {
      console.error('❌ خطأ في تهيئة Firebase:', error);
      throw new Error(`فشل في تهيئة Firebase: ${error.message}`);
    }
  }

  // ===================================
  // الحصول على بيانات Firebase
  // ===================================
  getFirebaseServiceAccount() {
    try {
      // محاولة الحصول من متغير البيئة JSON
      if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      }

      // محاولة الحصول من متغيرات منفصلة
      if (process.env.FIREBASE_PROJECT_ID && 
          process.env.FIREBASE_PRIVATE_KEY && 
          process.env.FIREBASE_CLIENT_EMAIL) {
        
        return {
          type: "service_account",
          project_id: process.env.FIREBASE_PROJECT_ID,
          private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          client_email: process.env.FIREBASE_CLIENT_EMAIL,
        };
      }

      throw new Error('لا توجد بيانات Firebase صحيحة في متغيرات البيئة');

    } catch (error) {
      throw new Error(`خطأ في قراءة بيانات Firebase: ${error.message}`);
    }
  }

  // ===================================
  // التحقق من قاعدة البيانات
  // ===================================
  async verifyDatabase() {
    try {
      const { data, error } = await this.supabase
        .from('notification_queue')
        .select('count')
        .limit(1);

      if (error) {
        throw new Error(`خطأ في الاتصال بقاعدة البيانات: ${error.message}`);
      }

      console.log('✅ تم التحقق من قاعدة البيانات');

    } catch (error) {
      throw new Error(`فشل في التحقق من قاعدة البيانات: ${error.message}`);
    }
  }

  // ===================================
  // إعداد الجداول المطلوبة
  // ===================================
  async setupRequiredTables() {
    try {
      // التحقق من وجود الجداول المطلوبة
      const requiredTables = [
        'notification_queue',
        'notification_logs', 
        'fcm_tokens',
        'system_logs'
      ];

      for (const table of requiredTables) {
        const { data, error } = await this.supabase
          .from(table)
          .select('count')
          .limit(1);

        if (error) {
          console.warn(`⚠️ جدول ${table} غير موجود أو غير متاح`);
        } else {
          console.log(`✅ جدول ${table} متاح`);
        }
      }

    } catch (error) {
      console.warn('⚠️ تحذير في فحص الجداول:', error.message);
    }
  }

  // ===================================
  // بدء خدمات النظام
  // ===================================
  startServices() {
    // خدمة معالجة الإشعارات
    this.intervals.processing = setInterval(() => {
      this.processNotificationQueue();
    }, this.config.processingInterval);

    // خدمة تنظيف السجلات
    this.intervals.cleanup = setInterval(() => {
      this.cleanupOldLogs();
    }, this.config.cleanupInterval);

    // خدمة فحص صحة النظام
    this.intervals.healthCheck = setInterval(() => {
      this.performHealthCheck();
    }, 60000); // كل دقيقة

    this.state.isRunning = true;
    console.log('✅ تم بدء جميع خدمات النظام');
  }

  // ===================================
  // معالجة قائمة انتظار الإشعارات
  // ===================================
  async processNotificationQueue() {
    if (!this.state.isInitialized || !this.state.isRunning) {
      return;
    }

    try {
      // جلب الإشعارات المعلقة
      const { data: notifications, error } = await this.supabase
        .from('notification_queue')
        .select('*')
        .eq('status', 'pending')
        .order('priority', { ascending: false })
        .order('created_at', { ascending: true })
        .limit(this.config.batchSize);

      if (error) {
        throw new Error(`خطأ في جلب الإشعارات: ${error.message}`);
      }

      if (!notifications || notifications.length === 0) {
        return; // لا توجد إشعارات للمعالجة
      }

      console.log(`📱 معالجة ${notifications.length} إشعار...`);
      this.state.currentBatch++;

      // معالجة كل إشعار
      for (const notification of notifications) {
        await this.processNotification(notification);
      }

      this.state.lastProcessedAt = new Date();
      this.emit('batchProcessed', {
        count: notifications.length,
        batchNumber: this.state.currentBatch
      });

    } catch (error) {
      console.error('❌ خطأ في معالجة قائمة الإشعارات:', error);
      this.emit('processingError', error);
    }
  }

  // ===================================
  // معالجة إشعار واحد
  // ===================================
  async processNotification(notification) {
    try {
      // تحديث حالة الإشعار إلى "قيد المعالجة"
      await this.updateNotificationStatus(notification.id, 'processing');

      // الحصول على FCM Token
      const fcmToken = await this.getFCMToken(notification.user_phone);
      
      if (!fcmToken) {
        await this.handleNotificationFailure(notification, 'لا يوجد FCM Token للمستخدم');
        return;
      }

      // إرسال الإشعار
      const result = await this.sendFirebaseNotification(fcmToken, notification);

      if (result.success) {
        await this.handleNotificationSuccess(notification, result);
      } else {
        await this.handleNotificationFailure(notification, result.error);
      }

    } catch (error) {
      console.error(`❌ خطأ في معالجة الإشعار ${notification.id}:`, error);
      await this.handleNotificationFailure(notification, error.message);
    }
  }

  // ===================================
  // الحصول على FCM Token
  // ===================================
  async getFCMToken(userPhone) {
    try {
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .select('token')
        .eq('user_phone', userPhone)
        .eq('is_active', true)
        .order('last_used_at', { ascending: false })
        .limit(1);

      if (error || !data || data.length === 0) {
        return null;
      }

      return data[0].token;

    } catch (error) {
      console.error('❌ خطأ في جلب FCM Token:', error);
      return null;
    }
  }

  // ===================================
  // إرسال إشعار Firebase
  // ===================================
  async sendFirebaseNotification(fcmToken, notification) {
    try {
      const notificationData = notification.notification_data || {};
      
      const message = {
        token: fcmToken,
        notification: {
          title: notificationData.title || 'إشعار جديد',
          body: notificationData.message || 'لديك إشعار جديد'
        },
        data: {
          order_id: notification.order_id || '',
          type: notificationData.type || 'general',
          timestamp: new Date().toISOString()
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'montajati_notifications',
            sound: 'default',
            vibrationPattern: [1000, 500, 1000]
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      
      return {
        success: true,
        messageId: response,
        timestamp: new Date().toISOString()
      };

    } catch (error) {
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  // ===================================
  // معالجة نجاح الإشعار
  // ===================================
  async handleNotificationSuccess(notification, result) {
    try {
      // تحديث حالة الإشعار
      await this.updateNotificationStatus(notification.id, 'sent', result);

      // تسجيل النجاح
      await this.logNotificationEvent(notification, 'success', result);

      this.state.totalSuccessful++;
      this.emit('notificationSent', { notification, result });

    } catch (error) {
      console.error('❌ خطأ في معالجة نجاح الإشعار:', error);
    }
  }

  // ===================================
  // معالجة فشل الإشعار
  // ===================================
  async handleNotificationFailure(notification, errorMessage) {
    try {
      const attempts = (notification.attempts || 0) + 1;

      if (attempts < this.config.maxRetries) {
        // إعادة جدولة الإشعار
        await this.rescheduleNotification(notification, attempts, errorMessage);
      } else {
        // فشل نهائي
        await this.updateNotificationStatus(notification.id, 'failed', { error: errorMessage });
        await this.logNotificationEvent(notification, 'failed', { error: errorMessage });
        this.state.totalFailed++;
      }

    } catch (error) {
      console.error('❌ خطأ في معالجة فشل الإشعار:', error);
    }
  }

  // ===================================
  // إعادة جدولة الإشعار
  // ===================================
  async rescheduleNotification(notification, attempts, errorMessage) {
    try {
      const nextAttemptAt = new Date(Date.now() + this.config.retryDelay);

      await this.supabase
        .from('notification_queue')
        .update({
          status: 'pending',
          attempts: attempts,
          last_error: errorMessage,
          next_attempt_at: nextAttemptAt.toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', notification.id);

      console.log(`🔄 إعادة جدولة الإشعار ${notification.id} (محاولة ${attempts})`);

    } catch (error) {
      console.error('❌ خطأ في إعادة جدولة الإشعار:', error);
    }
  }

  // ===================================
  // تحديث حالة الإشعار
  // ===================================
  async updateNotificationStatus(notificationId, status, metadata = null) {
    try {
      const updateData = {
        status: status,
        updated_at: new Date().toISOString()
      };

      if (status === 'sent' && metadata) {
        updateData.sent_at = new Date().toISOString();
        updateData.firebase_response = metadata;
      }

      await this.supabase
        .from('notification_queue')
        .update(updateData)
        .eq('id', notificationId);

    } catch (error) {
      console.error('❌ خطأ في تحديث حالة الإشعار:', error);
    }
  }

  // ===================================
  // تسجيل أحداث الإشعارات
  // ===================================
  async logNotificationEvent(notification, eventType, metadata) {
    try {
      await this.supabase
        .from('notification_logs')
        .insert({
          notification_id: notification.id,
          order_id: notification.order_id,
          user_phone: notification.user_phone,
          event_type: eventType,
          metadata: metadata,
          created_at: new Date().toISOString()
        });

    } catch (error) {
      console.error('❌ خطأ في تسجيل حدث الإشعار:', error);
    }
  }

  // ===================================
  // إعداد معالجات الأحداث
  // ===================================
  setupEventHandlers() {
    this.on('error', (error) => {
      console.error('🚨 خطأ في نظام الإشعارات:', error);
    });

    this.on('notificationSent', (data) => {
      console.log(`✅ تم إرسال إشعار للطلب ${data.notification.order_id}`);
    });

    this.on('batchProcessed', (data) => {
      console.log(`📊 تم معالجة دفعة ${data.batchNumber} - ${data.count} إشعار`);
    });
  }

  // ===================================
  // تنظيف السجلات القديمة
  // ===================================
  async cleanupOldLogs() {
    try {
      const cutoffDate = new Date(Date.now() - this.config.maxLogAge);

      // حذف السجلات القديمة
      const { error } = await this.supabase
        .from('notification_logs')
        .delete()
        .lt('created_at', cutoffDate.toISOString());

      if (error) {
        console.error('❌ خطأ في تنظيف السجلات:', error);
      } else {
        console.log('🧹 تم تنظيف السجلات القديمة');
      }

    } catch (error) {
      console.error('❌ خطأ في عملية التنظيف:', error);
    }
  }

  // ===================================
  // فحص صحة النظام
  // ===================================
  async performHealthCheck() {
    try {
      const health = {
        timestamp: new Date().toISOString(),
        status: 'healthy',
        services: {
          firebase: this.firebase ? 'active' : 'inactive',
          database: 'unknown',
          processing: this.state.isRunning ? 'active' : 'inactive'
        },
        stats: {
          totalProcessed: this.state.totalProcessed,
          totalSuccessful: this.state.totalSuccessful,
          totalFailed: this.state.totalFailed,
          successRate: this.state.totalProcessed > 0 
            ? (this.state.totalSuccessful / this.state.totalProcessed * 100).toFixed(2) + '%'
            : '0%'
        }
      };

      // فحص قاعدة البيانات
      try {
        await this.supabase.from('notification_queue').select('count').limit(1);
        health.services.database = 'active';
      } catch (error) {
        health.services.database = 'error';
        health.status = 'degraded';
      }

      this.emit('healthCheck', health);

    } catch (error) {
      console.error('❌ خطأ في فحص صحة النظام:', error);
    }
  }

  // ===================================
  // إيقاف النظام
  // ===================================
  async shutdown() {
    try {
      console.log('🛑 إيقاف نظام الإشعارات...');

      this.state.isRunning = false;

      // إيقاف جميع الفترات الزمنية
      Object.values(this.intervals).forEach(interval => {
        if (interval) clearInterval(interval);
      });

      console.log('✅ تم إيقاف نظام الإشعارات بأمان');
      this.emit('shutdown');

    } catch (error) {
      console.error('❌ خطأ في إيقاف النظام:', error);
    }
  }

  // ===================================
  // الحصول على إحصائيات النظام
  // ===================================
  getStats() {
    return {
      state: { ...this.state },
      config: { ...this.config },
      uptime: this.state.lastProcessedAt
        ? Date.now() - new Date(this.state.lastProcessedAt).getTime()
        : 0
    };
  }

  // ===================================
  // إضافة إشعار جديد إلى القائمة
  // ===================================
  async addNotification(orderData, statusChange) {
    try {
      const notificationData = {
        order_id: orderData.id,
        user_phone: orderData.user_phone || orderData.primary_phone,
        customer_name: orderData.customer_name,
        old_status: statusChange.from,
        new_status: statusChange.to,
        notification_data: {
          title: this.generateNotificationTitle(statusChange.to),
          message: this.generateNotificationMessage(orderData, statusChange.to),
          type: 'order_status_change',
          priority: this.getNotificationPriority(statusChange.to)
        },
        priority: this.getNotificationPriority(statusChange.to),
        status: 'pending',
        attempts: 0,
        created_at: new Date().toISOString()
      };

      const { data, error } = await this.supabase
        .from('notification_queue')
        .insert(notificationData)
        .select()
        .single();

      if (error) {
        throw new Error(`خطأ في إضافة الإشعار: ${error.message}`);
      }

      console.log(`📝 تم إضافة إشعار جديد للطلب ${orderData.id}`);
      this.emit('notificationAdded', data);

      return data;

    } catch (error) {
      console.error('❌ خطأ في إضافة الإشعار:', error);
      throw error;
    }
  }

  // ===================================
  // توليد عنوان الإشعار
  // ===================================
  generateNotificationTitle(status) {
    const titles = {
      'confirmed': '✅ تم تأكيد طلبك',
      'processing': '⚙️ جاري تحضير طلبك',
      'shipped': '🚚 تم شحن طلبك',
      'in_delivery': '🚗 طلبك قيد التوصيل',
      'delivered': '😊 تم توصيل طلبك',
      'cancelled': '❌ تم إلغاء طلبك',
      'returned': '↩️ تم إرجاع طلبك'
    };

    return titles[status] || '📢 تحديث على طلبك';
  }

  // ===================================
  // توليد رسالة الإشعار
  // ===================================
  generateNotificationMessage(orderData, status) {
    const customerName = orderData.customer_name || 'عزيزي العميل';

    const messages = {
      'confirmed': `${customerName}، تم تأكيد طلبك رقم ${orderData.id} وسيتم تحضيره قريباً.`,
      'processing': `${customerName}، جاري تحضير طلبك رقم ${orderData.id}.`,
      'shipped': `${customerName}، تم شحن طلبك رقم ${orderData.id} وهو في الطريق إليك.`,
      'in_delivery': `${customerName}، طلبك رقم ${orderData.id} قيد التوصيل وسيصل قريباً.`,
      'delivered': `${customerName}، تم توصيل طلبك رقم ${orderData.id} بنجاح. شكراً لثقتك بنا!`,
      'cancelled': `${customerName}، تم إلغاء طلبك رقم ${orderData.id}. نعتذر عن الإزعاج.`,
      'returned': `${customerName}، تم إرجاع طلبك رقم ${orderData.id}. سيتم التواصل معك قريباً.`
    };

    return messages[status] || `${customerName}، هناك تحديث على طلبك رقم ${orderData.id}.`;
  }

  // ===================================
  // تحديد أولوية الإشعار
  // ===================================
  getNotificationPriority(status) {
    const priorities = {
      'delivered': 1,      // أعلى أولوية
      'in_delivery': 2,
      'cancelled': 2,
      'shipped': 3,
      'confirmed': 4,
      'processing': 5,
      'returned': 3
    };

    return priorities[status] || 5;
  }
}

module.exports = OfficialNotificationManager;
