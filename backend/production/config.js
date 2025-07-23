// ===================================
// ملف التكوين الرئيسي للنظام الإنتاجي
// Production System Configuration
// ===================================

const path = require('path');
const fs = require('fs');

// تحميل متغيرات البيئة (إذا كان ملف .env موجود)
const envPath = path.join(__dirname, '../.env');
if (fs.existsSync(envPath)) {
  require('dotenv').config({ path: envPath });
}

class ProductionConfig {
  constructor() {
    this.loadConfiguration();
    this.validateConfiguration();
    console.log('⚙️ تم تحميل تكوين النظام الإنتاجي بنجاح');
  }

  loadConfiguration() {
    // التكوين الأساسي للنظام
    this.system = {
      name: 'Montajati Status Sync System',
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'production',
      timezone: 'Asia/Baghdad',
      language: 'ar'
    };

    // تكوين قاعدة البيانات
    this.database = {
      supabase: {
        url: process.env.SUPABASE_URL,
        serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
        anonKey: process.env.SUPABASE_ANON_KEY
      },
      tables: {
        orders: 'orders',
        orderHistory: 'order_status_history',
        syncLogs: 'sync_logs',
        systemLogs: 'system_logs'
      }
    };

    // تكوين شركة الوسيط
    this.waseet = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD,
      timeout: 30000,
      retryAttempts: 3,
      retryDelay: 5000
    };

    // تكوين المزامنة
    this.sync = {
      enabled: true,
      interval: 5 * 60 * 1000, // 5 دقائق
      batchSize: 50,
      maxConcurrent: 5,
      enableInstantUpdate: true,
      enableBulkUpdate: true,
      enableSmartRetry: true
    };

    // تكوين التسجيل
    this.logging = {
      level: 'info', // debug, info, warn, error
      enableConsole: true,
      enableFile: true,
      enableDatabase: true,
      logDirectory: path.join(__dirname, '../logs'),
      maxFileSize: '10MB',
      maxFiles: 30,
      enableRotation: true
    };

    // تكوين المراقبة
    this.monitoring = {
      enabled: true,
      healthCheckInterval: 60000, // دقيقة واحدة
      performanceTracking: true,
      errorTracking: true,
      alerting: {
        enabled: true,
        email: process.env.ALERT_EMAIL,
        webhook: process.env.ALERT_WEBHOOK
      }
    };

    // تكوين الأمان
    this.security = {
      enableEncryption: true,
      enableBackup: true,
      backupInterval: 24 * 60 * 60 * 1000, // 24 ساعة
      backupRetention: 30, // 30 يوم
      enableRateLimit: true,
      maxRequestsPerMinute: 100
    };

    // تكوين الإشعارات
    this.notifications = {
      enabled: true,
      channels: {
        email: {
          enabled: false,
          smtp: {
            host: process.env.SMTP_HOST,
            port: process.env.SMTP_PORT,
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
          }
        },
        webhook: {
          enabled: true,
          url: process.env.WEBHOOK_URL
        },
        database: {
          enabled: true
        }
      }
    };

    // تكوين واجهة الإدارة
    this.admin = {
      enabled: true,
      port: process.env.ADMIN_PORT || 3001,
      username: process.env.ADMIN_USERNAME || 'admin',
      password: process.env.ADMIN_PASSWORD || 'admin123',
      enableAuth: true,
      enableSSL: false
    };

    // تكوين الحالات المدعومة
    this.supportedStatuses = {
      // حالات الوسيط → الحالات المحلية
      waseetToLocal: {
        // حالات نشطة
        '1': 'active',
        'فعال': 'active',
        '24': 'active', // تم تغيير محافظة الزبون
        '25': 'active', // لا يرد
        '26': 'active', // لا يرد بعد الاتفاق
        '27': 'active', // مغلق
        '28': 'active', // مغلق بعد الاتفاق
        '29': 'active', // مؤجل
        '30': 'active', // مؤجل لحين اعادة الطلب لاحقا
        '36': 'active', // الرقم غير معرف
        '37': 'active', // الرقم غير داخل في الخدمة
        '38': 'active', // العنوان غير دقيق
        '39': 'active', // لم يطلب
        '41': 'active', // لا يمكن الاتصال بالرقم
        '42': 'active', // تغيير المندوب

        // حالات التوصيل
        '3': 'in_delivery', // قيد التوصيل الى الزبون

        // حالات التسليم
        '35': 'delivered', // مستلم مسبقا

        // حالات الإلغاء
        '31': 'cancelled', // الغاء الطلب
        '32': 'cancelled', // رفض الطلب
        '33': 'cancelled', // مفصول عن الخدمة
        '34': 'cancelled', // طلب مكرر
        '40': 'cancelled'  // حظر المندوب
      },

      // أوصاف الحالات بالعربي
      descriptions: {
        '1': 'فعال',
        '3': 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        '24': 'تم تغيير محافظة الزبون',
        '25': 'لا يرد',
        '26': 'لا يرد بعد الاتفاق',
        '27': 'مغلق',
        '28': 'مغلق بعد الاتفاق',
        '29': 'مؤجل',
        '30': 'مؤجل لحين اعادة الطلب لاحقا',
        '31': 'الغاء الطلب',
        '32': 'رفض الطلب',
        '33': 'مفصول عن الخدمة',
        '34': 'طلب مكرر',
        '35': 'مستلم مسبقا',
        '36': 'الرقم غير معرف',
        '37': 'الرقم غير داخل في الخدمة',
        '38': 'العنوان غير دقيق',
        '39': 'لم يطلب',
        '40': 'حظر المندوب',
        '41': 'لا يمكن الاتصال بالرقم',
        '42': 'تغيير المندوب'
      }
    };
  }

  validateConfiguration() {
    const required = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'WASEET_USERNAME',
      'WASEET_PASSWORD'
    ];

    const missing = required.filter(key => !process.env[key]);
    
    if (missing.length > 0) {
      throw new Error(`متغيرات البيئة المطلوبة مفقودة: ${missing.join(', ')}`);
    }

    // التحقق من صحة URLs
    if (!this.database.supabase.url.startsWith('https://')) {
      throw new Error('SUPABASE_URL يجب أن يبدأ بـ https://');
    }

    if (!this.waseet.baseUrl.startsWith('https://')) {
      throw new Error('ALMASEET_BASE_URL يجب أن يبدأ بـ https://');
    }

    console.log('✅ تم التحقق من صحة التكوين');
  }

  // الحصول على تكوين محدد
  get(section, key = null) {
    if (key) {
      return this[section]?.[key];
    }
    return this[section];
  }

  // تحديث تكوين
  set(section, key, value) {
    if (!this[section]) {
      this[section] = {};
    }
    this[section][key] = value;
  }

  // حفظ التكوين
  save() {
    const configPath = path.join(__dirname, 'config.json');
    const config = {
      system: this.system,
      sync: this.sync,
      logging: this.logging,
      monitoring: this.monitoring,
      security: this.security,
      notifications: this.notifications,
      admin: this.admin
    };

    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    console.log('💾 تم حفظ التكوين');
  }

  // تحميل التكوين من ملف
  load() {
    const configPath = path.join(__dirname, 'config.json');
    if (fs.existsSync(configPath)) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      Object.assign(this, config);
      console.log('📂 تم تحميل التكوين من الملف');
    }
  }

  // إنشاء مجلدات مطلوبة
  createDirectories() {
    const directories = [
      this.logging.logDirectory,
      path.join(__dirname, '../backups'),
      path.join(__dirname, '../temp')
    ];

    directories.forEach(dir => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
        console.log(`📁 تم إنشاء مجلد: ${dir}`);
      }
    });
  }

  // معلومات النظام
  getSystemInfo() {
    return {
      name: this.system.name,
      version: this.system.version,
      environment: this.system.environment,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      platform: process.platform,
      nodeVersion: process.version,
      pid: process.pid
    };
  }
}

// إنشاء مثيل واحد للتكوين
const config = new ProductionConfig();

// إنشاء المجلدات المطلوبة
config.createDirectories();

module.exports = config;
