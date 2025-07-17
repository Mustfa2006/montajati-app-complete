// تطبيق منتجاتي - Backend Server
// Node.js + Express + Supabase + JWT

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const dotenv = require('dotenv');

// استيراد نظام الإشعارات المستهدفة
const notificationMasterService = require('./services/notification_master_service');
const targetedNotificationsRouter = require('./routes/targeted_notifications');

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

// إضافة routes نظام الإشعارات المستهدفة
app.use('/api/notifications', targetedNotificationsRouter);

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

  // بدء نظام الإشعارات المستهدفة تلقائياً
  console.log('🎯 بدء نظام الإشعارات المستهدفة...');
  try {
    const result = await notificationMasterService.startAllServices();
    if (result.success) {
      console.log('✅ تم تشغيل نظام الإشعارات المستهدفة بنجاح');
      console.log('📱 الإشعارات ستصل للمستخدمين المحددين فقط');
    } else {
      console.log('⚠️ تحذير: فشل في تشغيل نظام الإشعارات');
    }
  } catch (error) {
    console.log('⚠️ تحذير: خطأ في تشغيل نظام الإشعارات:', error.message);
  }
});

module.exports = app;
