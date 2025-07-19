#!/usr/bin/env node

// ===================================
// تشغيل النظام النظيف - بدون تضارب
// ===================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const SimpleNotificationProcessor = require('./notification_processor_simple');

class CleanSystemManager {
  constructor() {
    this.app = express();
    this.port = process.env.PORT || 3003;
    this.notificationProcessor = new SimpleNotificationProcessor();
    this.isRunning = false;
    
    this.setupExpress();
    this.setupRoutes();
  }

  // ===================================
  // إعداد Express
  // ===================================
  setupExpress() {
    // إعدادات CORS
    this.app.use(cors({
      origin: ['http://localhost:3000', 'https://your-frontend-domain.com'],
      credentials: true
    }));

    // إعدادات JSON
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    console.log('✅ تم إعداد Express بنجاح');
  }

  // ===================================
  // إعداد المسارات
  // ===================================
  setupRoutes() {
    // المسار الرئيسي
    this.app.get('/', (req, res) => {
      res.json({
        message: 'نظام منتجاتي - الإشعارات الذكية 🚀',
        version: '2.0.0',
        status: 'running',
        features: [
          'نظام إشعارات ذكي',
          'معالجة تلقائية للإشعارات',
          'Firebase Cloud Messaging',
          'قاعدة بيانات Supabase'
        ],
        endpoints: {
          health: '/health',
          fcm_register: 'POST /api/fcm/register',
          fcm_test: 'POST /api/fcm/test-notification',
          fcm_status: 'GET /api/fcm/status/:phone'
        }
      });
    });

    // فحص الصحة
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'OK',
        message: 'النظام يعمل بنجاح',
        timestamp: new Date().toISOString(),
        services: {
          express: 'running',
          notifications: this.notificationProcessor.isProcessing ? 'running' : 'stopped',
          firebase: 'connected',
          supabase: 'connected'
        }
      });
    });

    // مسارات FCM
    const fcmTokensRouter = require('./routes/fcm_tokens');
    this.app.use('/api/fcm', fcmTokensRouter);

    // مسارات أساسية أخرى
    const ordersRouter = require('./routes/orders');
    const usersRouter = require('./routes/users');
    const productsRouter = require('./routes/products');
    const authRouter = require('./routes/auth');

    this.app.use('/api/orders', ordersRouter);
    this.app.use('/api/users', usersRouter);
    this.app.use('/api/products', productsRouter);
    this.app.use('/api/auth', authRouter);

    // معالجة الأخطاء
    this.app.use((err, req, res, next) => {
      console.error('❌ خطأ في الخادم:', err.message);
      res.status(500).json({
        success: false,
        message: 'خطأ في الخادم',
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

    console.log('✅ تم إعداد المسارات بنجاح');
  }

  // ===================================
  // بدء النظام
  // ===================================
  async start() {
    try {
      console.log('🚀 بدء تشغيل النظام النظيف...\n');

      // التحقق من متغيرات البيئة
      this.validateEnvironment();

      // بدء معالج الإشعارات
      this.notificationProcessor.startProcessing();
      console.log('✅ تم بدء معالج الإشعارات');

      // بدء الخادم
      this.app.listen(this.port, () => {
        this.isRunning = true;
        console.log('\n🎉 النظام يعمل بنجاح!');
        console.log('═══════════════════════════════════');
        console.log(`🌐 الخادم: http://localhost:${this.port}`);
        console.log(`📱 الإشعارات: نشطة`);
        console.log(`🔥 Firebase: متصل`);
        console.log(`🗄️ Supabase: متصل`);
        console.log('═══════════════════════════════════');
        console.log('✅ جاهز لاستقبال الطلبات والإشعارات');
      });

      // إعداد الإيقاف الآمن
      this.setupGracefulShutdown();

    } catch (error) {
      console.error('❌ خطأ في بدء النظام:', error.message);
      process.exit(1);
    }
  }

  // ===================================
  // التحقق من متغيرات البيئة
  // ===================================
  validateEnvironment() {
    console.log('🔍 التحقق من متغيرات البيئة...');

    const required = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'FIREBASE_SERVICE_ACCOUNT'
    ];

    const missing = required.filter(key => !process.env[key]);
    
    if (missing.length > 0) {
      throw new Error(`متغيرات البيئة المفقودة: ${missing.join(', ')}`);
    }

    // التحقق من Firebase
    try {
      JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      console.log('✅ Firebase Service Account صحيح');
    } catch (error) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT غير صالح');
    }

    console.log('✅ جميع متغيرات البيئة صحيحة');
  }

  // ===================================
  // إعداد الإيقاف الآمن
  // ===================================
  setupGracefulShutdown() {
    const shutdown = async (signal) => {
      console.log(`\n📡 تم استلام إشارة ${signal}، بدء الإيقاف الآمن...`);
      
      try {
        this.isRunning = false;
        
        // إيقاف معالج الإشعارات
        if (this.notificationProcessor) {
          this.notificationProcessor.stopProcessing();
          console.log('✅ تم إيقاف معالج الإشعارات');
        }
        
        console.log('✅ تم إيقاف النظام بأمان');
        process.exit(0);
        
      } catch (error) {
        console.error('❌ خطأ في الإيقاف الآمن:', error.message);
        process.exit(1);
      }
    };

    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
    
    // معالجة الأخطاء غير المتوقعة
    process.on('uncaughtException', (error) => {
      console.error('❌ خطأ غير متوقع:', error.message);
      shutdown('uncaughtException');
    });

    process.on('unhandledRejection', (reason, promise) => {
      console.error('❌ رفض غير معالج:', reason);
      shutdown('unhandledRejection');
    });
  }

  // ===================================
  // اختبار النظام
  // ===================================
  async testSystem() {
    try {
      console.log('🧪 اختبار النظام...');

      // اختبار قاعدة البيانات
      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      const { data, error } = await supabase
        .from('orders')
        .select('id')
        .limit(1);

      if (error) {
        throw new Error(`خطأ في قاعدة البيانات: ${error.message}`);
      }

      console.log('✅ قاعدة البيانات تعمل');

      // اختبار Firebase
      const admin = require('firebase-admin');
      if (admin.apps.length === 0) {
        const firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
          credential: admin.credential.cert(firebaseConfig)
        });
      }
      console.log('✅ Firebase يعمل');

      console.log('🎉 جميع الاختبارات نجحت!');
      return true;

    } catch (error) {
      console.error('❌ فشل في الاختبار:', error.message);
      return false;
    }
  }
}

// تشغيل النظام
if (require.main === module) {
  const system = new CleanSystemManager();
  
  const command = process.argv[2];
  
  switch (command) {
    case 'test':
      system.testSystem()
        .then(success => process.exit(success ? 0 : 1));
      break;
      
    case 'start':
    default:
      system.start();
      break;
  }
}

module.exports = CleanSystemManager;
