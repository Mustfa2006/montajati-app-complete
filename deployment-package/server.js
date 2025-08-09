// تطبيق منتجاتي - Backend Server المحدث
// إصلاح شامل لمشكلة CORS

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const dotenv = require('dotenv');

// تحميل المتغيرات من ملف .env
dotenv.config();

const app = express();

// إعداد trust proxy
app.set('trust proxy', 1);

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// إعدادات CORS شاملة - الحل النهائي
app.use(cors({
  origin: function (origin, callback) {
    console.log('🌐 CORS Request from origin:', origin);
    
    // السماح لجميع الطلبات (حل مؤقت للاختبار)
    return callback(null, true);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD'],
  allowedHeaders: [
    'Content-Type', 
    'Authorization', 
    'Accept', 
    'Origin', 
    'X-Requested-With',
    'Access-Control-Allow-Origin',
    'Access-Control-Allow-Headers',
    'Access-Control-Allow-Methods',
    'Access-Control-Allow-Credentials',
    'Cache-Control',
    'Pragma'
  ],
  exposedHeaders: ['Content-Length', 'Content-Type', 'Authorization'],
  preflightContinue: false,
  optionsSuccessStatus: 200,
  maxAge: 86400
}));

// Middleware إضافي لحل مشاكل CORS
app.use((req, res, next) => {
  const origin = req.headers.origin;
  
  // إعداد headers شامل
  res.header('Access-Control-Allow-Origin', origin || '*');
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS,PATCH,HEAD');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With, Accept, Origin, Cache-Control, Pragma');
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Max-Age', '86400');
  
  // headers للأمان
  res.header('X-Content-Type-Options', 'nosniff');
  res.header('X-Frame-Options', 'DENY');
  res.header('X-XSS-Protection', '1; mode=block');
  
  // تسجيل الطلبات
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path} from ${origin || 'unknown'}`);
  
  // التعامل مع preflight requests
  if (req.method === 'OPTIONS') {
    console.log('✅ Handling OPTIONS preflight request');
    res.status(200).end();
    return;
  }
  
  next();
});

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// خدمة الملفات الثابتة للموقع
app.use(express.static('public', {
  maxAge: '1d',
  etag: false
}));

// مسارات خاصة للويب - حل مشكلة CORS
app.get('/api/web/health', (req, res) => {
  res.json({
    success: true,
    message: 'الخادم يعمل بشكل طبيعي - CORS محدث',
    timestamp: new Date().toISOString(),
    cors: 'enabled',
    web_support: true,
    version: '2.0.0'
  });
});

app.get('/api/web/cors-test', (req, res) => {
  res.json({
    success: true,
    message: 'CORS يعمل بشكل صحيح',
    origin: req.headers.origin,
    method: req.method,
    timestamp: new Date().toISOString(),
    headers: req.headers
  });
});

// مسار محدث لتحديث حالة الطلبات - يعمل مع الويب
app.put('/api/orders/:orderId/status', async (req, res) => {
  try {
    console.log('🌐 طلب تحديث حالة الطلب:', req.params.orderId);
    console.log('📊 البيانات:', req.body);
    console.log('🌍 Origin:', req.headers.origin);
    
    const orderId = req.params.orderId;
    const { status, reason, changedBy } = req.body;
    
    // التحقق من وجود البيانات المطلوبة
    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'حالة الطلب مطلوبة'
      });
    }
    
    // تحديث في قاعدة البيانات
    const { data, error } = await supabase
      .from('orders')
      .update({
        status: status,
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId)
      .select();
    
    if (error) {
      console.error('❌ خطأ في تحديث قاعدة البيانات:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في تحديث قاعدة البيانات',
        error: error.message
      });
    }
    
    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'الطلب غير موجود'
      });
    }
    
    console.log('✅ تم تحديث حالة الطلب بنجاح');
    res.json({
      success: true,
      message: 'تم تحديث حالة الطلب بنجاح',
      data: data[0],
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ خطأ في تحديث حالة الطلب:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// مسار عام لجميع طلبات API الأخرى
app.all('/api/*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'المسار غير موجود',
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

// خدمة الموقع - الصفحة الرئيسية
app.get('/', (req, res) => {
  res.sendFile('index.html', { root: 'public' }, (err) => {
    if (err) {
      console.log('❌ خطأ في إرسال index.html:', err);
      res.json({
        success: true,
        message: 'خادم منتجاتي يعمل بشكل طبيعي',
        version: '2.0.0',
        cors: 'enabled',
        timestamp: new Date().toISOString(),
        note: 'الموقع غير متاح - ملفات الموقع مفقودة'
      });
    }
  });
});

// مسار لجميع الصفحات الأخرى (SPA routing)
app.get('*', (req, res, next) => {
  // إذا كان الطلب لـ API، تجاهل
  if (req.path.startsWith('/api/')) {
    return next();
  }

  // إرسال index.html لجميع المسارات الأخرى
  res.sendFile('index.html', { root: 'public' }, (err) => {
    if (err) {
      console.log('❌ خطأ في إرسال index.html للمسار:', req.path);
      res.status(404).json({
        success: false,
        message: 'الصفحة غير موجودة',
        path: req.path
      });
    }
  });
});

// تشغيل الخادم
const PORT = process.env.PORT || 3003;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 الخادم يعمل على المنفذ ${PORT}`);
  console.log(`🌐 البيئة: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🕐 وقت البدء: ${new Date().toISOString()}`);
  console.log(`🔧 إصدار CORS المحدث: v2.0.0`);
  console.log(`🌍 CORS مفعل لجميع النطاقات`);
});

module.exports = app;
