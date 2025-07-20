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
    // قائمة المواقع المسموحة
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:3001',
      'https://your-frontend-domain.com',
      process.env.FRONTEND_URL
    ].filter(Boolean);

    // السماح للطلبات بدون origin (مثل التطبيقات المحمولة)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('غير مسموح بواسطة CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
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
    handler: (req, res) => {
      console.warn(`⚠️ Rate limit exceeded for IP: ${req.ip}`);
      res.status(429).json({
        error: message,
        retryAfter: Math.ceil(windowMs / 1000)
      });
    }
  });
};

// Rate limits مختلفة للمسارات المختلفة
const generalRateLimit = createRateLimit(
  15 * 60 * 1000, // 15 دقيقة
  100, // 100 طلب
  'تم تجاوز الحد المسموح من الطلبات. حاول مرة أخرى لاحقاً.'
);

const authRateLimit = createRateLimit(
  15 * 60 * 1000, // 15 دقيقة
  5, // 5 محاولات تسجيل دخول
  'تم تجاوز محاولات تسجيل الدخول. حاول مرة أخرى بعد 15 دقيقة.'
);

const apiRateLimit = createRateLimit(
  1 * 60 * 1000, // دقيقة واحدة
  60, // 60 طلب
  'تم تجاوز حد طلبات API. حاول مرة أخرى بعد دقيقة.'
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
