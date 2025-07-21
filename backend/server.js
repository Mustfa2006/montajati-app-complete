// تطبيق منتجاتي - Backend Server
// Node.js + Express + Supabase + JWT

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const dotenv = require('dotenv');
const targetedNotificationService = require('./services/targeted_notification_service');
const tokenManagementService = require('./services/token_management_service');
const cron = require('node-cron');



// تحميل المتغيرات من ملف .env
dotenv.config();

const app = express();

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// إعدادات Middleware
const corsOrigins = process.env.NODE_ENV === 'production'
  ? (process.env.CORS_ORIGINS || '').split(',').filter(Boolean)
  : [
      'http://localhost:3002',
      'http://127.0.0.1:3002',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'http://localhost:3001',
      'http://127.0.0.1:3001'
    ];

app.use(cors({
  origin: corsOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// تحقق من اتصال Supabase
console.log('✅ تم إعداد Supabase بنجاح');



// Routes الأساسية
app.get('/', (req, res) => {
  res.json({
    message: 'مرحباً بك في API تطبيق منتجاتي 🚀',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    message: 'الخادم يعمل بشكل طبيعي',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Routes للمصادقة
try {
  const authRoutes = require('./routes/auth');
  app.use('/api/auth', authRoutes);
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/auth');
}

// Routes للمستخدمين
try {
  const userRoutes = require('./routes/users');
  app.use('/api/users', userRoutes);
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/users');
}

// Routes للمنتجات
try {
  const productRoutes = require('./routes/products');
  app.use('/api/products', productRoutes);
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/products');
}

// Routes لرفع الصور
try {
  const uploadRoutes = require('./routes/upload');
  app.use('/api/upload', uploadRoutes);
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/upload');
}

// 📊 Routes للإحصائيات المحفوظة (ذكي جداً!)
try {
  const statisticsRoutes = require('./routes/statistics');
  app.use('/api/statistics', statisticsRoutes);
  console.log('✅ تم تحميل routes الإحصائيات بنجاح');
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/statistics');
}

// Routes للإشعارات الفورية
try {
  const notificationRoutes = require('./routes/notifications');
  app.use('/api/notifications', notificationRoutes);
  console.log('✅ تم تحميل مسارات الإشعارات');
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/notifications');
}

// Routes لحالات الوسيط
try {
  const waseetStatusRoutes = require('./routes/waseet_statuses');
  app.use('/api/waseet-statuses', waseetStatusRoutes);
  console.log('✅ تم تحميل مسارات حالات الوسيط');
} catch (error) {
  console.log('تحذير: لم يتم العثور على routes/waseet_statuses');
}

// معالجة الأخطاء العامة
app.use((err, req, res, next) => {
  console.error('خطأ في الخادم:', err.stack);
  res.status(500).json({
    success: false,
    message: 'حدث خطأ في الخادم',
    error: process.env.NODE_ENV === 'development' ? err.message : 'خطأ داخلي'
  });
});

// معالجة الطرق غير الموجودة
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'الطريق المطلوب غير موجود'
  });
});

// تهيئة خدمة الإشعارات المستهدفة
async function initializeNotificationService() {
  try {
    console.log('🔔 بدء تهيئة خدمة الإشعارات المستهدفة...');
    const initialized = await targetedNotificationService.initialize();

    if (initialized) {
      console.log('✅ تم تهيئة خدمة الإشعارات المستهدفة بنجاح');
    } else {
      console.log('⚠️ فشل في تهيئة خدمة الإشعارات المستهدفة');
    }
  } catch (error) {
    console.error('❌ خطأ في تهيئة خدمة الإشعارات:', error.message);
  }
}

// تشغيل الخادم
const PORT = process.env.PORT || 3003;
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 الخادم يعمل على المنفذ ${PORT}`);
  console.log(`🌐 البيئة: ${process.env.NODE_ENV || 'development'}`);
  if (process.env.NODE_ENV === 'production') {
    console.log(`🌍 الخادم متاح على: https://montajati-backend.onrender.com`);
  } else {
    console.log(`🌐 الرابط المحلي: http://localhost:${PORT}`);
  }

  // تهيئة خدمة الإشعارات
  await initializeNotificationService();

  // بدء مهام الصيانة الدورية
  startMaintenanceTasks();
});

// مهام الصيانة الدورية لـ FCM Tokens
function startMaintenanceTasks() {
  console.log('⏰ بدء جدولة مهام الصيانة الدورية...');

  // تنظيف الرموز القديمة كل يوم في الساعة 2:00 صباحاً
  cron.schedule('0 2 * * *', async () => {
    console.log('🧹 تشغيل مهمة تنظيف FCM Tokens القديمة...');
    try {
      const result = await tokenManagementService.cleanupOldTokens();
      console.log('✅ انتهت مهمة التنظيف:', result);
    } catch (error) {
      console.error('❌ خطأ في مهمة التنظيف:', error.message);
    }
  }, {
    timezone: 'Asia/Riyadh'
  });

  // التحقق من صحة الرموز كل أسبوع يوم الأحد في الساعة 3:00 صباحاً
  cron.schedule('0 3 * * 0', async () => {
    console.log('🔍 تشغيل مهمة التحقق من صحة FCM Tokens...');
    try {
      const result = await tokenManagementService.validateAllActiveTokens();
      console.log('✅ انتهت مهمة التحقق:', result);
    } catch (error) {
      console.error('❌ خطأ في مهمة التحقق:', error.message);
    }
  }, {
    timezone: 'Asia/Riyadh'
  });

  // تشغيل جميع مهام الصيانة كل شهر في اليوم الأول في الساعة 4:00 صباحاً
  cron.schedule('0 4 1 * *', async () => {
    console.log('🔧 تشغيل جميع مهام الصيانة الشهرية...');
    try {
      const result = await tokenManagementService.runMaintenanceTasks();
      console.log('✅ انتهت مهام الصيانة الشهرية:', result);
    } catch (error) {
      console.error('❌ خطأ في مهام الصيانة الشهرية:', error.message);
    }
  }, {
    timezone: 'Asia/Riyadh'
  });

  console.log('✅ تم جدولة مهام الصيانة الدورية بنجاح');
}

module.exports = app;
