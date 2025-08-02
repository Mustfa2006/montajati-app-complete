// ===================================
// خدمة Redis لتحسين أداء مشروع منتجاتي
// ===================================

const redis = require('redis');

class RedisService {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.retryAttempts = 0;
    this.maxRetries = 5;
  }

  // تهيئة الاتصال
  async initialize() {
    try {
      console.log('🔴 بدء تهيئة Redis...');
      
      // إعداد العميل
      this.client = redis.createClient({
        url: process.env.REDIS_URL || 'redis://localhost:6379',
        retry_strategy: (options) => {
          if (options.error && options.error.code === 'ECONNREFUSED') {
            console.log('❌ Redis server رفض الاتصال');
            return new Error('Redis server رفض الاتصال');
          }
          if (options.total_retry_time > 1000 * 60 * 60) {
            console.log('❌ انتهت مهلة إعادة المحاولة');
            return new Error('انتهت مهلة إعادة المحاولة');
          }
          if (options.attempt > this.maxRetries) {
            console.log('❌ تم تجاوز الحد الأقصى لإعادة المحاولة');
            return undefined;
          }
          return Math.min(options.attempt * 100, 3000);
        }
      });

      // معالجة الأحداث
      this.client.on('connect', () => {
        console.log('🔴 Redis متصل...');
      });

      this.client.on('ready', () => {
        console.log('✅ Redis جاهز للاستخدام');
        this.isConnected = true;
        this.retryAttempts = 0;
      });

      this.client.on('error', (err) => {
        console.error('❌ خطأ Redis:', err);
        this.isConnected = false;
      });

      this.client.on('end', () => {
        console.log('🔴 انتهى اتصال Redis');
        this.isConnected = false;
      });

      // الاتصال
      await this.client.connect();
      
      // اختبار الاتصال
      await this.client.ping();
      console.log('✅ تم تهيئة Redis بنجاح');
      
      return true;
    } catch (error) {
      console.error('❌ فشل في تهيئة Redis:', error);
      this.isConnected = false;
      return false;
    }
  }

  // تخزين مؤقت للطلبات
  async cacheOrder(orderId, orderData, ttl = 3600) {
    if (!this.isConnected) return false;
    
    try {
      const key = `order:${orderId}`;
      await this.client.setEx(key, ttl, JSON.stringify(orderData));
      console.log(`✅ تم تخزين الطلب ${orderId} في Redis`);
      return true;
    } catch (error) {
      console.error('❌ خطأ في تخزين الطلب:', error);
      return false;
    }
  }

  // جلب طلب من التخزين المؤقت
  async getCachedOrder(orderId) {
    if (!this.isConnected) return null;
    
    try {
      const key = `order:${orderId}`;
      const data = await this.client.get(key);
      
      if (data) {
        console.log(`✅ تم جلب الطلب ${orderId} من Redis`);
        return JSON.parse(data);
      }
      
      return null;
    } catch (error) {
      console.error('❌ خطأ في جلب الطلب:', error);
      return null;
    }
  }

  // تخزين بيانات الوسيط
  async cacheWaseetData(data, ttl = 300) {
    if (!this.isConnected) return false;
    
    try {
      const key = 'waseet:latest_data';
      await this.client.setEx(key, ttl, JSON.stringify(data));
      console.log('✅ تم تخزين بيانات الوسيط في Redis');
      return true;
    } catch (error) {
      console.error('❌ خطأ في تخزين بيانات الوسيط:', error);
      return false;
    }
  }

  // جلب بيانات الوسيط
  async getCachedWaseetData() {
    if (!this.isConnected) return null;
    
    try {
      const data = await this.client.get('waseet:latest_data');
      
      if (data) {
        console.log('✅ تم جلب بيانات الوسيط من Redis');
        return JSON.parse(data);
      }
      
      return null;
    } catch (error) {
      console.error('❌ خطأ في جلب بيانات الوسيط:', error);
      return null;
    }
  }

  // تخزين إحصائيات سريعة
  async cacheStats(stats, ttl = 1800) {
    if (!this.isConnected) return false;
    
    try {
      const key = 'stats:dashboard';
      await this.client.setEx(key, ttl, JSON.stringify(stats));
      console.log('✅ تم تخزين الإحصائيات في Redis');
      return true;
    } catch (error) {
      console.error('❌ خطأ في تخزين الإحصائيات:', error);
      return false;
    }
  }

  // جلب الإحصائيات
  async getCachedStats() {
    if (!this.isConnected) return null;
    
    try {
      const data = await this.client.get('stats:dashboard');
      
      if (data) {
        console.log('✅ تم جلب الإحصائيات من Redis');
        return JSON.parse(data);
      }
      
      return null;
    } catch (error) {
      console.error('❌ خطأ في جلب الإحصائيات:', error);
      return null;
    }
  }

  // حذف من التخزين المؤقت
  async deleteCache(key) {
    if (!this.isConnected) return false;
    
    try {
      await this.client.del(key);
      console.log(`✅ تم حذف ${key} من Redis`);
      return true;
    } catch (error) {
      console.error('❌ خطأ في حذف البيانات:', error);
      return false;
    }
  }

  // تنظيف التخزين المؤقت
  async clearCache(pattern = '*') {
    if (!this.isConnected) return false;
    
    try {
      const keys = await this.client.keys(pattern);
      if (keys.length > 0) {
        await this.client.del(keys);
        console.log(`✅ تم حذف ${keys.length} عنصر من Redis`);
      }
      return true;
    } catch (error) {
      console.error('❌ خطأ في تنظيف التخزين المؤقت:', error);
      return false;
    }
  }

  // إغلاق الاتصال
  async disconnect() {
    if (this.client && this.isConnected) {
      try {
        await this.client.quit();
        console.log('✅ تم إغلاق اتصال Redis');
      } catch (error) {
        console.error('❌ خطأ في إغلاق Redis:', error);
      }
    }
  }

  // فحص الحالة
  getStatus() {
    return {
      connected: this.isConnected,
      retryAttempts: this.retryAttempts,
      maxRetries: this.maxRetries
    };
  }
}

module.exports = new RedisService();
