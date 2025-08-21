// ✅ Middleware الأمان المحسن
// Enhanced Security Middleware
// تاريخ الإنشاء: 2024-12-20

const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');

/**
 * ✅ إعداد CORS آمن
 */
const corsOptions = {
  origin: function (origin, callback) {
    // قائمة المواقع المسموحة (ثابتة + من المتغيرات)
    const staticAllowed = [
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'http://localhost:3001',
      'http://127.0.0.1:3001',
      'http://localhost:3002',
      'http://127.0.0.1:3002',
      'https://muntgati.netlify.app',
      process.env.FRONTEND_URL
    ];
    const envAllowed = (process.env.CORS_ORIGINS || '')
      .split(',')
      .map(s => s.trim())
      .filter(Boolean);
    const allowedOrigins = [...staticAllowed, ...envAllowed].filter(Boolean);

    // السماح للطلبات بدون origin (مثل التطبيقات المحمولة/الـ curl)
    if (!origin) return callback(null, true);

    let hostname = '';
    try { hostname = new URL(origin).hostname; } catch (_) { hostname = origin; }

    const allow = (
      allowedOrigins.includes(origin) ||
      hostname === 'muntgati.netlify.app' ||
      hostname.endsWith('.netlify.app') ||
      hostname.endsWith('.vercel.app') ||
      hostname.includes('vercel.app') ||
      hostname.includes('montajati-web') ||
      hostname.endsWith('.ondigitalocean.app') ||
      hostname.endsWith('.up.railway.app') ||
      hostname === 'localhost' ||
      hostname.startsWith('localhost:') ||
      hostname === '127.0.0.1'
    );

    if (allow) {
      return callback(null, true);
    } else {
      console.warn(`❌ CORS blocked origin: ${origin} (host=${hostname})`);
      return callback(new Error('غير مسموح بواسطة CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin',
    'Access-Control-Allow-Origin'
  ],
  exposedHeaders: ['Content-Length', 'Content-Type', 'Authorization'],
  optionsSuccessStatus: 200
};

/**
 * ✅ إعداد Rate Limiting
 */
const createRateLimit = (windowMs, max, message) => {
  return rateLimit({
    windowMs,
    max,
    message: {
      error: message,
      retryAfter: Math.ceil(windowMs / 1000)
    },
    standardHeaders: true,
    legacyHeaders: false,
    // إعدادات trust proxy آمنة لـ Render
    trustProxy: true,
    keyGenerator: (req) => {
      // استخدام IP الحقيقي من Render
      return req.ip || req.connection.remoteAddress || 'unknown';
    },
    handler: (req, res) => {
      const retryAfterMinutes = Math.ceil(windowMs / 60000);
      console.warn(`⚠️ Rate limit exceeded for IP: ${req.ip}`);
      res.status(429).json({
        error: message,
        retryAfter: Math.ceil(windowMs / 1000),
        retryAfterMinutes: retryAfterMinutes,
        message_ar: `${message} (انتظر ${retryAfterMinutes} دقيقة)`
      });
    }
  });
};

// Rate limits مختلفة للمسارات المختلفة
const generalRateLimit = createRateLimit(
  15 * 60 * 1000, // 15 دقيقة
  500, // 500 طلب (زيادة من 100 إلى 500)
  'تجاوزت العدد المسموح من الطلبات. حاول مرة أخرى بعد 15 دقيقة.'
);

const authRateLimit = createRateLimit(
  15 * 60 * 1000, // 15 دقيقة
  5, // 5 محاولات تسجيل دخول
  'تجاوزت عدد محاولات تسجيل الدخول المسموح. حاول مرة أخرى بعد 15 دقيقة.'
);

const apiRateLimit = createRateLimit(
  1 * 60 * 1000, // دقيقة واحدة
  300, // 300 طلب (زيادة من 60 إلى 300)
  'تجاوزت العدد المسموح من الطلبات. حاول مرة أخرى بعد 1 دقيقة.'
);

/**
 * ✅ تنظيف وتعقيم المدخلات
 */
const sanitizeInput = (req, res, next) => {
  try {
    // تنظيف query parameters
    for (const key in req.query) {
      if (typeof req.query[key] === 'string') {
        req.query[key] = req.query[key].trim();
        // إزالة الأحرف الخطيرة
        req.query[key] = req.query[key].replace(/[<>\"'%;()&+]/g, '');
      }
    }

    // تنظيف body parameters
    if (req.body && typeof req.body === 'object') {
      sanitizeObject(req.body);
    }

    next();
  } catch (error) {
    console.error('❌ خطأ في تنظيف المدخلات:', error);
    res.status(400).json({ error: 'بيانات غير صالحة' });
  }
};

/**
 * تنظيف كائن بشكل تكراري
 */
function sanitizeObject(obj) {
  for (const key in obj) {
    if (typeof obj[key] === 'string') {
      obj[key] = obj[key].trim();
      // إزالة الأحرف الخطيرة من النصوص
      if (key !== 'password' && key !== 'token') {
        obj[key] = obj[key].replace(/[<>\"'%;()&+]/g, '');
      }
    } else if (typeof obj[key] === 'object' && obj[key] !== null) {
      sanitizeObject(obj[key]);
    }
  }
}

/**
 * ✅ التحقق من صحة Content-Type
 */
const validateContentType = (req, res, next) => {
  if (req.method === 'POST' || req.method === 'PUT' || req.method === 'PATCH') {
    const contentType = req.get('Content-Type');
    if (!contentType || !contentType.includes('application/json')) {
      return res.status(400).json({
        error: 'Content-Type يجب أن يكون application/json'
      });
    }
  }
  next();
};

/**
 * ✅ تسجيل الطلبات المشبوهة
 */
const logSuspiciousActivity = (req, res, next) => {
  const suspiciousPatterns = [
    /script/i,
    /javascript/i,
    /vbscript/i,
    /onload/i,
    /onerror/i,
    /<.*>/,
    /union.*select/i,
    /drop.*table/i
  ];

  const checkString = JSON.stringify(req.query) + JSON.stringify(req.body);
  
  for (const pattern of suspiciousPatterns) {
    if (pattern.test(checkString)) {
      console.warn(`🚨 نشاط مشبوه من IP: ${req.ip}, Pattern: ${pattern}, Data: ${checkString.substring(0, 200)}`);
      break;
    }
  }

  next();
};

module.exports = {
  corsOptions,
  generalRateLimit,
  authRateLimit,
  apiRateLimit,
  sanitizeInput,
  validateContentType,
  logSuspiciousActivity,
  helmet: helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'", "https://api.supabase.co", "https://firebase.googleapis.com"]
      }
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true
    }
  })
};
