// خادم منتجاتي - الإصدار المُصلح مع الإشعارات
// حل نهائي لمشكلة عدم وصول الإشعارات

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const dotenv = require('dotenv');

// تحميل المتغيرات
dotenv.config();

const app = express();
app.set('trust proxy', 1);

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// إعدادات CORS النهائية
const allowedOrigins = [
  'https://squid-app-t6xsl.ondigitalocean.app',
  'https://montajati-website.ondigitalocean.app',
  'https://montajati.ondigitalocean.app',
  'http://localhost:3000',
  'http://localhost:3001',
  'http://localhost:3002',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:3001',
  'http://127.0.0.1:3002'
];

// CORS Configuration
app.use(cors({
  origin: function (origin, callback) {
    console.log('🌐 CORS Request from:', origin);
    
    if (!origin) {
      console.log('✅ Allowing request without origin');
      return callback(null, true);
    }
    
    if (origin.includes('.ondigitalocean.app')) {
      console.log('✅ Allowing DigitalOcean domain:', origin);
      return callback(null, true);
    }
    
    if (allowedOrigins.includes(origin)) {
      console.log('✅ Allowing configured origin:', origin);
      return callback(null, true);
    }
    
    if (process.env.NODE_ENV !== 'production') {
      console.log('✅ Allowing in development mode:', origin);
      return callback(null, true);
    }
    
    console.log('❌ Blocking origin:', origin);
    return callback(null, false);
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

// Middleware إضافي لضمان CORS
app.use((req, res, next) => {
  const origin = req.headers.origin;
  
  if (origin && (allowedOrigins.includes(origin) || origin.includes('.ondigitalocean.app'))) {
    res.header('Access-Control-Allow-Origin', origin);
  } else {
    res.header('Access-Control-Allow-Origin', '*');
  }
  
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

// ===================================
// إعداد Firebase للإشعارات
// ===================================

let firebaseAdmin = null;
let notificationService = null;

async function initializeFirebase() {
  try {
    console.log('🔥 بدء تهيئة Firebase للإشعارات...');
    
    if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
      throw new Error('متغير FIREBASE_SERVICE_ACCOUNT مفقود');
    }

    const admin = require('firebase-admin');
    
    // حذف التهيئة السابقة إن وجدت
    if (admin.apps.length > 0) {
      admin.apps.forEach(app => app.delete());
    }

    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });

    firebaseAdmin = admin;
    console.log('✅ تم تهيئة Firebase بنجاح');
    console.log(`📋 Project ID: ${serviceAccount.project_id}`);
    
    return true;
  } catch (error) {
    console.error('❌ خطأ في تهيئة Firebase:', error.message);
    return false;
  }
}

// دالة إرسال الإشعار
async function sendNotificationToUser(userPhone, orderId, newStatus, customerName = 'عميل') {
  try {
    if (!firebaseAdmin) {
      console.log('⚠️ Firebase غير مُهيأ - لن يتم إرسال إشعار');
      return { success: false, error: 'Firebase غير مُهيأ' };
    }

    console.log(`📱 البحث عن FCM Token للمستخدم: ${userPhone}`);

    // البحث عن FCM Token للمستخدم
    const { data: tokens, error } = await supabase
      .from('fcm_tokens')
      .select('fcm_token')
      .eq('user_phone', userPhone)
      .eq('is_active', true);

    if (error) {
      console.error('❌ خطأ في البحث عن FCM Token:', error.message);
      return { success: false, error: error.message };
    }

    if (!tokens || tokens.length === 0) {
      console.log(`⚠️ لا يوجد FCM Token للمستخدم: ${userPhone}`);
      return { success: false, error: 'لا يوجد FCM Token للمستخدم' };
    }

    // إعداد رسالة الإشعار
    const notification = {
      title: '📦 تحديث حالة الطلب',
      body: `مرحباً ${customerName}، تم تحديث حالة طلبك إلى: ${newStatus}`
    };

    const data = {
      type: 'order_status_update',
      orderId: orderId,
      newStatus: newStatus,
      timestamp: new Date().toISOString()
    };

    // إرسال الإشعار لجميع أجهزة المستخدم
    let successCount = 0;
    let errorCount = 0;

    for (const tokenData of tokens) {
      try {
        const message = {
          token: tokenData.fcm_token,
          notification: notification,
          data: data,
          android: {
            notification: {
              channelId: 'montajati_notifications',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
              icon: '@mipmap/ic_launcher',
              color: '#FFD700'
            },
            priority: 'high'
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: notification.title,
                  body: notification.body
                },
                sound: 'default',
                badge: 1
              }
            }
          }
        };

        const response = await firebaseAdmin.messaging().send(message);
        console.log(`✅ تم إرسال إشعار بنجاح: ${response}`);
        successCount++;

        // تحديث آخر استخدام للـ token
        await supabase
          .from('fcm_tokens')
          .update({ last_used_at: new Date().toISOString() })
          .eq('fcm_token', tokenData.fcm_token);

      } catch (sendError) {
        console.error(`❌ فشل في إرسال إشعار للرمز ${tokenData.fcm_token.substring(0, 20)}...:`, sendError.message);
        errorCount++;

        // إذا كان الرمز غير صالح، قم بإلغاء تفعيله
        if (sendError.code === 'messaging/registration-token-not-registered') {
          await supabase
            .from('fcm_tokens')
            .update({ is_active: false })
            .eq('fcm_token', tokenData.fcm_token);
          console.log(`🗑️ تم إلغاء تفعيل رمز FCM غير صالح`);
        }
      }
    }

    console.log(`📊 نتائج الإرسال: ${successCount} نجح، ${errorCount} فشل`);
    
    return {
      success: successCount > 0,
      successCount: successCount,
      errorCount: errorCount,
      totalTokens: tokens.length
    };

  } catch (error) {
    console.error('❌ خطأ عام في إرسال الإشعار:', error.message);
    return { success: false, error: error.message };
  }
}

// ===================================
// المسارات
// ===================================

// مسارات الصحة والاختبار
app.get('/api/web/health', (req, res) => {
  res.json({
    success: true,
    message: 'الخادم يعمل بشكل طبيعي - مع إصلاح الإشعارات',
    timestamp: new Date().toISOString(),
    cors: 'enabled',
    web_support: true,
    notifications: firebaseAdmin ? 'enabled' : 'disabled',
    version: 'FIXED-NOTIFICATIONS-1.0.0',
    allowed_origins: allowedOrigins
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

// مسار تحديث حالة الطلبات - مع إرسال الإشعارات
app.put('/api/orders/:orderId/status', async (req, res) => {
  try {
    console.log('🌐 طلب تحديث حالة الطلب من الويب:', req.params.orderId);
    console.log('📊 البيانات المستلمة:', req.body);
    console.log('🌍 Origin:', req.headers.origin);
    
    const orderId = req.params.orderId;
    const { status, reason, changedBy } = req.body;
    
    // التحقق من البيانات المطلوبة
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
        updated_at: new Date().toISOString(),
        status_history: supabase.raw(`
          COALESCE(status_history, '[]'::jsonb) || 
          jsonb_build_object(
            'status', '${status}',
            'timestamp', '${new Date().toISOString()}',
            'reason', '${reason || 'تم التحديث من الويب'}',
            'changed_by', '${changedBy || 'web_user'}'
          )::jsonb
        `)
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
    
    console.log('✅ تم تحديث حالة الطلب بنجاح من الويب');
    
    // 🔔 إرسال إشعار للمستخدم - الإصلاح الأساسي
    const updatedOrder = data[0];
    const userPhone = updatedOrder.customer_phone || updatedOrder.user_phone;
    const customerName = updatedOrder.customer_name || 'عميل';
    
    if (userPhone) {
      console.log(`📤 إرسال إشعار للمستخدم: ${userPhone}`);
      
      const notificationResult = await sendNotificationToUser(
        userPhone,
        updatedOrder.id,
        status,
        customerName
      );
      
      if (notificationResult.success) {
        console.log('✅ تم إرسال الإشعار بنجاح');
      } else {
        console.log('⚠️ فشل في إرسال الإشعار:', notificationResult.error);
      }
    } else {
      console.log('⚠️ رقم هاتف المستخدم غير متوفر');
    }
    
    res.json({
      success: true,
      message: 'تم تحديث حالة الطلب بنجاح',
      data: data[0],
      timestamp: new Date().toISOString(),
      notification_sent: userPhone ? true : false
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

// مسار الجذر
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'خادم منتجاتي - مع إصلاح الإشعارات',
    version: 'FIXED-NOTIFICATIONS-1.0.0',
    cors: 'enabled',
    web_support: true,
    notifications: firebaseAdmin ? 'enabled' : 'disabled',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/api/web/health',
      cors_test: '/api/web/cors-test',
      update_order: '/api/orders/{id}/status'
    }
  });
});

// تشغيل الخادم
const PORT = process.env.PORT || 3003;
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 خادم منتجاتي - مع إصلاح الإشعارات`);
  console.log(`🌐 المنفذ: ${PORT}`);
  console.log(`🕐 وقت البدء: ${new Date().toISOString()}`);
  console.log(`🔧 إصدار الإصلاح: FIXED-NOTIFICATIONS-1.0.0`);
  console.log(`🌍 النطاقات المسموحة:`, allowedOrigins);
  
  // تهيئة Firebase
  const firebaseInitialized = await initializeFirebase();
  if (firebaseInitialized) {
    console.log(`🔔 نظام الإشعارات: مُفعل`);
  } else {
    console.log(`⚠️ نظام الإشعارات: معطل`);
  }
  
  console.log(`✅ جاهز لاستقبال طلبات الموقع والتطبيق`);
});

module.exports = app;
