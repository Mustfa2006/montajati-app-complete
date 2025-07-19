// ===================================
// خادم الإنتاج - نظام الإشعارات الكامل
// ===================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cron = require('node-cron');

// استيراد الخدمات
const { firebaseConfig } = require('./config/firebase');
const SimpleNotificationProcessor = require('./notification_processor_simple');
const OrderStatusSyncService = require('./sync/order_status_sync_service');

class ProductionNotificationServer {
  constructor() {
    this.app = express();
    this.port = process.env.PORT || 3003;
    this.isRunning = false;
    
    // تهيئة معالج الإشعارات
    this.notificationProcessor = new SimpleNotificationProcessor();
    
    this.setupExpress();
    this.setupRoutes();
  }

  // ===================================
  // إعداد Express
  // ===================================
  setupExpress() {
    // إعدادات أساسية
    this.app.use(cors({
      origin: '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization']
    }));
    
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // تسجيل الطلبات
    this.app.use((req, res, next) => {
      console.log(`📡 ${new Date().toISOString()} - ${req.method} ${req.path}`);
      next();
    });
  }

  // ===================================
  // إعداد المسارات
  // ===================================
  setupRoutes() {
    // مسار الجذر
    this.app.get('/', (req, res) => {
      res.json({
        message: 'نظام منتجاتي - خادم الإشعارات 🚀',
        version: '2.0.0',
        status: 'running',
        timestamp: new Date().toISOString(),
        features: [
          'نظام إشعارات Firebase',
          'معالجة تلقائية للإشعارات',
          'مزامنة حالات الطلبات',
          'مراقبة مستمرة'
        ],
        endpoints: {
          health: '/health',
          fcm_register: 'POST /api/fcm/register',
          fcm_test: 'POST /api/fcm/test-notification',
          fcm_status: 'GET /api/fcm/status/:phone',
          order_update: 'PUT /api/orders/:id/status'
        }
      });
    });

    // مسار الصحة
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        services: {
          firebase: firebaseConfig.initialized ? 'active' : 'inactive',
          notifications: this.notificationProcessor ? 'active' : 'inactive',
          database: 'active'
        }
      });
    });

    // مسارات FCM
    const fcmTokensRouter = require('./routes/fcm_tokens');
    this.app.use('/api/fcm', fcmTokensRouter);

    // مسارات الطلبات
    const ordersRouter = require('./routes/orders');
    this.app.use('/api/orders', ordersRouter);

    // مسارات المستخدمين
    const usersRouter = require('./routes/users');
    this.app.use('/api/users', usersRouter);

    // مسارات المنتجات
    const productsRouter = require('./routes/products');
    this.app.use('/api/products', productsRouter);

    // مسارات المصادقة
    const authRouter = require('./routes/auth');
    this.app.use('/api/auth', authRouter);

    // مسار اختبار النظام الكامل
    this.app.post('/api/test/full-system', async (req, res) => {
      try {
        const { user_phone } = req.body;
        
        if (!user_phone) {
          return res.status(400).json({
            success: false,
            message: 'رقم الهاتف مطلوب'
          });
        }

        // اختبار شامل للنظام
        const testResult = await this.runFullSystemTest(user_phone);
        
        res.json({
          success: true,
          message: 'تم اختبار النظام بنجاح',
          results: testResult
        });
        
      } catch (error) {
        console.error('❌ خطأ في اختبار النظام:', error);
        res.status(500).json({
          success: false,
          message: 'خطأ في اختبار النظام',
          error: error.message
        });
      }
    });

    // معالجة الأخطاء
    this.app.use((err, req, res, next) => {
      console.error('❌ خطأ في الخادم:', err);
      res.status(500).json({
        success: false,
        message: 'خطأ داخلي في الخادم',
        error: process.env.NODE_ENV === 'development' ? err.message : 'خطأ داخلي'
      });
    });

    // معالجة المسارات غير الموجودة
    this.app.use('*', (req, res) => {
      res.status(404).json({
        success: false,
        message: 'المسار غير موجود',
        path: req.originalUrl
      });
    });
  }

  // ===================================
  // تهيئة الخدمات
  // ===================================
  async initializeServices() {
    try {
      console.log('🚀 تهيئة خدمات الإنتاج...');

      // 1. تهيئة Firebase
      console.log('🔥 تهيئة Firebase...');
      await firebaseConfig.initialize();
      console.log('✅ Firebase مهيأ بنجاح');

      // 2. بدء معالج الإشعارات
      console.log('🔔 بدء معالج الإشعارات...');
      this.notificationProcessor.startProcessing();
      console.log('✅ معالج الإشعارات نشط');

      // 3. تهيئة خدمة المزامنة
      console.log('🔄 تهيئة خدمة المزامنة...');
      this.syncService = new OrderStatusSyncService();
      await this.syncService.initialize();
      console.log('✅ خدمة المزامنة مهيأة');

      console.log('✅ تم تهيئة جميع الخدمات بنجاح');
      
    } catch (error) {
      console.error('❌ خطأ في تهيئة الخدمات:', error);
      throw error;
    }
  }

  // ===================================
  // بدء المزامنة التلقائية
  // ===================================
  startAutoSync() {
    // مزامنة كل 10 دقائق
    cron.schedule('*/10 * * * *', async () => {
      try {
        console.log('🔄 بدء المزامنة التلقائية...');
        if (this.syncService) {
          await this.syncService.syncOrderStatuses();
        }
        console.log('✅ انتهت المزامنة التلقائية');
      } catch (error) {
        console.error('❌ خطأ في المزامنة التلقائية:', error);
      }
    });

    console.log('✅ تم تفعيل المزامنة التلقائية (كل 10 دقائق)');
  }

  // ===================================
  // اختبار النظام الكامل
  // ===================================
  async runFullSystemTest(userPhone) {
    const results = {
      timestamp: new Date().toISOString(),
      tests: {}
    };

    try {
      // 1. اختبار Firebase
      results.tests.firebase = {
        status: firebaseConfig.initialized ? 'pass' : 'fail',
        message: firebaseConfig.initialized ? 'Firebase يعمل' : 'Firebase معطل'
      };

      // 2. اختبار قاعدة البيانات
      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      const { data, error } = await supabase
        .from('fcm_tokens')
        .select('count')
        .limit(1);

      results.tests.database = {
        status: error ? 'fail' : 'pass',
        message: error ? `خطأ في قاعدة البيانات: ${error.message}` : 'قاعدة البيانات تعمل'
      };

      // 3. اختبار FCM Token للمستخدم
      const { data: tokenData } = await supabase
        .from('fcm_tokens')
        .select('*')
        .eq('user_phone', userPhone)
        .eq('is_active', true);

      results.tests.fcm_token = {
        status: tokenData && tokenData.length > 0 ? 'pass' : 'fail',
        message: tokenData && tokenData.length > 0 
          ? `المستخدم لديه ${tokenData.length} FCM token نشط`
          : 'المستخدم لا يملك FCM token نشط'
      };

      return results;
      
    } catch (error) {
      results.error = error.message;
      return results;
    }
  }

  // ===================================
  // بدء الخادم
  // ===================================
  async start() {
    try {
      console.log('🚀 بدء تشغيل خادم الإنتاج...');
      console.log(`📊 البيئة: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🌐 المنفذ: ${this.port}`);

      // تهيئة الخدمات
      await this.initializeServices();

      // بدء المزامنة التلقائية
      this.startAutoSync();

      // بدء الخادم
      this.app.listen(this.port, () => {
        console.log('\n' + '='.repeat(60));
        console.log('🎉 خادم الإنتاج يعمل بنجاح!');
        console.log(`🌐 الرابط: http://localhost:${this.port}`);
        console.log(`🔗 فحص الصحة: http://localhost:${this.port}/health`);
        console.log(`📱 تسجيل FCM: POST http://localhost:${this.port}/api/fcm/register`);
        console.log(`🧪 اختبار النظام: POST http://localhost:${this.port}/api/test/full-system`);
        console.log('='.repeat(60));
        
        this.isRunning = true;
      });

      // معالجة إشارات الإغلاق
      process.on('SIGTERM', () => this.gracefulShutdown());
      process.on('SIGINT', () => this.gracefulShutdown());

    } catch (error) {
      console.error('❌ خطأ في بدء تشغيل الخادم:', error);
      process.exit(1);
    }
  }

  // ===================================
  // إغلاق آمن
  // ===================================
  async gracefulShutdown() {
    console.log('\n🛑 بدء إغلاق الخادم بأمان...');
    
    this.isRunning = false;
    
    // إيقاف معالج الإشعارات
    if (this.notificationProcessor) {
      this.notificationProcessor.stopProcessing();
    }
    
    console.log('✅ تم إغلاق الخادم بأمان');
    process.exit(0);
  }
}

// تشغيل الخادم
if (require.main === module) {
  const server = new ProductionNotificationServer();
  server.start().catch(console.error);
}

module.exports = ProductionNotificationServer;
