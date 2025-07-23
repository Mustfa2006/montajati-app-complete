// ===================================
// نظام التسجيل الإنتاجي المتقدم
// Advanced Production Logging System
// ===================================

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const config = require('./config');

class ProductionLogger {
  constructor() {
    this.config = config.get('logging');
    this.supabase = createClient(
      config.get('database', 'supabase').url,
      config.get('database', 'supabase').serviceRoleKey
    );
    
    this.logLevels = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3,
      critical: 4
    };

    this.currentLevel = this.logLevels[this.config.level] || 1;
    this.initializeLogger();
    
    console.log('📝 تم تهيئة نظام التسجيل الإنتاجي');
  }

  initializeLogger() {
    // إنشاء مجلد السجلات إذا لم يكن موجوداً
    if (!fs.existsSync(this.config.logDirectory)) {
      fs.mkdirSync(this.config.logDirectory, { recursive: true });
    }

    // تنظيف السجلات القديمة
    this.cleanOldLogs();
  }

  // تسجيل رسالة
  async log(level, message, data = null, category = 'general') {
    const levelNum = this.logLevels[level] || 1;
    
    // تجاهل الرسائل أقل من المستوى المحدد
    if (levelNum < this.currentLevel) {
      return;
    }

    const logEntry = {
      timestamp: new Date().toISOString(),
      level: level.toUpperCase(),
      category,
      message,
      data: data ? JSON.stringify(data) : null,
      pid: process.pid,
      memory: process.memoryUsage().heapUsed,
      system: config.get('system', 'name')
    };

    // تسجيل في الكونسول
    if (this.config.enableConsole) {
      this.logToConsole(logEntry);
    }

    // تسجيل في الملف
    if (this.config.enableFile) {
      this.logToFile(logEntry);
    }

    // تسجيل في قاعدة البيانات
    if (this.config.enableDatabase && levelNum >= this.logLevels.warn) {
      await this.logToDatabase(logEntry);
    }
  }

  // تسجيل في الكونسول
  logToConsole(entry) {
    const colors = {
      DEBUG: '\x1b[36m',   // سماوي
      INFO: '\x1b[32m',    // أخضر
      WARN: '\x1b[33m',    // أصفر
      ERROR: '\x1b[31m',   // أحمر
      CRITICAL: '\x1b[35m' // بنفسجي
    };

    const reset = '\x1b[0m';
    const color = colors[entry.level] || '';
    
    const timestamp = new Date(entry.timestamp).toLocaleString('ar-IQ', {
      timeZone: config.get('system', 'timezone')
    });

    console.log(
      `${color}[${timestamp}] ${entry.level} [${entry.category}]${reset} ${entry.message}`
    );

    if (entry.data) {
      console.log(`${color}📊 البيانات:${reset}`, JSON.parse(entry.data));
    }
  }

  // تسجيل في الملف
  logToFile(entry) {
    try {
      const date = new Date().toISOString().split('T')[0];
      const filename = `${date}-${entry.level.toLowerCase()}.log`;
      const filepath = path.join(this.config.logDirectory, filename);
      
      const logLine = `${entry.timestamp} [${entry.level}] [${entry.category}] ${entry.message}`;
      const dataLine = entry.data ? `\n📊 البيانات: ${entry.data}` : '';
      const fullLine = `${logLine}${dataLine}\n`;

      fs.appendFileSync(filepath, fullLine);

      // تدوير السجلات إذا تجاوز الحد الأقصى
      this.rotateLogIfNeeded(filepath);
    } catch (error) {
      console.error('❌ خطأ في كتابة السجل:', error.message);
    }
  }

  // تسجيل في قاعدة البيانات
  async logToDatabase(entry) {
    try {
      await this.supabase
        .from('system_logs')
        .insert({
          timestamp: entry.timestamp,
          level: entry.level,
          category: entry.category,
          message: entry.message,
          data: entry.data,
          pid: entry.pid,
          memory_usage: entry.memory,
          system_name: entry.system
        });
    } catch (error) {
      console.error('❌ خطأ في تسجيل قاعدة البيانات:', error.message);
    }
  }

  // تدوير السجلات
  rotateLogIfNeeded(filepath) {
    if (!this.config.enableRotation) return;

    try {
      const stats = fs.statSync(filepath);
      const maxSize = this.parseSize(this.config.maxFileSize);

      if (stats.size > maxSize) {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const newPath = filepath.replace('.log', `-${timestamp}.log`);
        fs.renameSync(filepath, newPath);
        
        console.log(`🔄 تم تدوير السجل: ${path.basename(newPath)}`);
      }
    } catch (error) {
      console.error('❌ خطأ في تدوير السجل:', error.message);
    }
  }

  // تنظيف السجلات القديمة
  cleanOldLogs() {
    try {
      const files = fs.readdirSync(this.config.logDirectory);
      const maxAge = this.config.maxFiles * 24 * 60 * 60 * 1000; // بالميلي ثانية
      const now = Date.now();

      files.forEach(file => {
        const filepath = path.join(this.config.logDirectory, file);
        const stats = fs.statSync(filepath);
        
        if (now - stats.mtime.getTime() > maxAge) {
          fs.unlinkSync(filepath);
          console.log(`🗑️ تم حذف السجل القديم: ${file}`);
        }
      });
    } catch (error) {
      console.error('❌ خطأ في تنظيف السجلات:', error.message);
    }
  }

  // تحويل حجم النص إلى بايت
  parseSize(sizeStr) {
    const units = { B: 1, KB: 1024, MB: 1024 * 1024, GB: 1024 * 1024 * 1024 };
    const match = sizeStr.match(/^(\d+)(B|KB|MB|GB)$/i);
    
    if (!match) return 10 * 1024 * 1024; // 10MB افتراضي
    
    return parseInt(match[1]) * units[match[2].toUpperCase()];
  }

  // طرق مختصرة للتسجيل
  async debug(message, data = null, category = 'debug') {
    return this.log('debug', message, data, category);
  }

  async info(message, data = null, category = 'info') {
    return this.log('info', message, data, category);
  }

  async warn(message, data = null, category = 'warning') {
    return this.log('warn', message, data, category);
  }

  async error(message, data = null, category = 'error') {
    return this.log('error', message, data, category);
  }

  async critical(message, data = null, category = 'critical') {
    return this.log('critical', message, data, category);
  }

  // تسجيل بداية العملية
  async startOperation(operationName, data = null) {
    const operationId = `${operationName}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    await this.info(`🚀 بدء العملية: ${operationName}`, { operationId, ...data }, 'operation');
    return operationId;
  }

  // تسجيل انتهاء العملية
  async endOperation(operationId, operationName, success = true, data = null) {
    const level = success ? 'info' : 'error';
    const icon = success ? '✅' : '❌';
    const status = success ? 'نجحت' : 'فشلت';
    
    await this.log(level, `${icon} انتهاء العملية: ${operationName} - ${status}`, 
      { operationId, success, ...data }, 'operation');
  }

  // تسجيل إحصائيات الأداء
  async logPerformance(operation, duration, data = null) {
    await this.info(`⏱️ أداء العملية: ${operation} - ${duration}ms`, 
      { operation, duration, ...data }, 'performance');
  }

  // تسجيل أخطاء المزامنة
  async logSyncError(orderId, error, data = null) {
    await this.error(`🔄 خطأ في مزامنة الطلب ${orderId}: ${error}`, 
      { orderId, error, ...data }, 'sync');
  }

  // تسجيل نجاح المزامنة
  async logSyncSuccess(orderId, oldStatus, newStatus, data = null) {
    await this.info(`🔄 نجحت مزامنة الطلب ${orderId}: ${oldStatus} → ${newStatus}`, 
      { orderId, oldStatus, newStatus, ...data }, 'sync');
  }

  // الحصول على إحصائيات السجلات
  async getLogStats(hours = 24) {
    try {
      const since = new Date(Date.now() - hours * 60 * 60 * 1000).toISOString();
      
      const { data, error } = await this.supabase
        .from('system_logs')
        .select('level')
        .gte('timestamp', since);

      if (error) throw error;

      const stats = data.reduce((acc, log) => {
        acc[log.level] = (acc[log.level] || 0) + 1;
        return acc;
      }, {});

      return {
        period: `${hours} ساعة`,
        total: data.length,
        breakdown: stats
      };
    } catch (error) {
      console.error('❌ خطأ في جلب إحصائيات السجلات:', error.message);
      return null;
    }
  }

  // تصدير السجلات
  async exportLogs(startDate, endDate, format = 'json') {
    try {
      const { data, error } = await this.supabase
        .from('system_logs')
        .select('*')
        .gte('timestamp', startDate)
        .lte('timestamp', endDate)
        .order('timestamp', { ascending: false });

      if (error) throw error;

      const filename = `logs_${startDate}_${endDate}.${format}`;
      const filepath = path.join(this.config.logDirectory, filename);

      if (format === 'json') {
        fs.writeFileSync(filepath, JSON.stringify(data, null, 2));
      } else if (format === 'csv') {
        const csv = this.convertToCSV(data);
        fs.writeFileSync(filepath, csv);
      }

      await this.info(`📤 تم تصدير السجلات: ${filename}`, { count: data.length });
      return filepath;
    } catch (error) {
      await this.error('❌ خطأ في تصدير السجلات', { error: error.message });
      return null;
    }
  }

  // تحويل إلى CSV
  convertToCSV(data) {
    if (!data.length) return '';
    
    const headers = Object.keys(data[0]).join(',');
    const rows = data.map(row => 
      Object.values(row).map(value => 
        typeof value === 'string' ? `"${value.replace(/"/g, '""')}"` : value
      ).join(',')
    );
    
    return [headers, ...rows].join('\n');
  }
}

// إنشاء مثيل واحد للمسجل
const logger = new ProductionLogger();

module.exports = logger;
