// ===================================
// خدمة مراقبة المخزون
// ===================================

const { createClient } = require('@supabase/supabase-js');
const TelegramNotificationService = require('./telegram_notification_service');
require('dotenv').config();

class InventoryMonitorService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعداد خدمة التلغرام
    this.telegramService = new TelegramNotificationService();

    // إعدادات المراقبة
    this.thresholds = {
      outOfStock: 0,    // نفد المخزون
      lowStock: 5       // مخزون منخفض (فقط عند الكمية 5 بالضبط)
    };

    // تتبع الإشعارات المرسلة لتجنب التكرار
    this.sentAlerts = new Map();

    console.log('📦 تم تهيئة خدمة مراقبة المخزون');
    console.log(`🚨 حد نفاد المخزون: ${this.thresholds.outOfStock}`);
    console.log(`⚠️ حد المخزون المنخفض: ${this.thresholds.lowStock}`);
  }

  /**
   * مراقبة جميع المنتجات
   */
  async monitorAllProducts() {
    try {
      console.log('🔍 بدء مراقبة جميع المنتجات...');

      // جلب جميع المنتجات النشطة
      const { data: products, error } = await this.supabase
        .from('products')
        .select('id, name, available_quantity, image_url, is_active')
        .eq('is_active', true);

      if (error) {
        throw new Error(`خطأ في جلب المنتجات: ${error.message}`);
      }

      if (!products || products.length === 0) {
        return {
          success: true,
          message: 'لا توجد منتجات نشطة للمراقبة',
          results: {
            total: 0,
            outOfStock: 0,
            lowStock: 0,
            normal: 0,
            sentNotifications: 0
          }
        };
      }

      // إحصائيات المراقبة
      const stats = {
        total: products.length,
        outOfStock: 0,
        lowStock: 0,
        normal: 0,
        sentNotifications: 0
      };

      const alerts = [];

      // فحص كل منتج
      for (const product of products) {
        const quantity = product.available_quantity || 0;
        const productId = product.id;
        const productName = product.name;

        // تحديد حالة المخزون
        if (quantity <= this.thresholds.outOfStock) {
          stats.outOfStock++;

          // إرسال إشعار نفاد المخزون
          const alertSent = await this.sendOutOfStockAlert(product);
          if (alertSent.success) {
            stats.sentNotifications++;
          }

          alerts.push({
            productId,
            product_name: productName,
            type: 'نفد المخزون',
            quantity,
            sent: alertSent.success
          });

        } else if (quantity === this.thresholds.lowStock) {
          // إرسال إشعار مخزون منخفض فقط عند الكمية 5 بالضبط
          stats.lowStock++;

          const alertSent = await this.sendLowStockAlert(product);
          if (alertSent.success) {
            stats.sentNotifications++;
          }

          alerts.push({
            productId,
            product_name: productName,
            type: 'مخزون منخفض',
            quantity,
            sent: alertSent.success
          });

        } else {
          stats.normal++;

          // إزالة المنتج من قائمة الإشعارات المرسلة إذا كان المخزون طبيعي الآن
          this.clearAlertHistory(productId);
        }
      }

      console.log(`✅ انتهت مراقبة ${stats.total} منتج`);
      console.log(`📊 النتائج: نفد=${stats.outOfStock}, منخفض=${stats.lowStock}, طبيعي=${stats.normal}`);

      return {
        success: true,
        message: `تم فحص ${stats.total} منتج بنجاح`,
        results: stats,
        alerts: alerts.length > 0 ? alerts : null
      };

    } catch (error) {
      console.error('❌ خطأ في مراقبة المنتجات:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * مراقبة منتج واحد
   */
  async monitorProduct(productId) {
    try {
      console.log(`🔍 مراقبة المنتج: ${productId}`);

      // جلب بيانات المنتج
      const { data: product, error } = await this.supabase
        .from('products')
        .select('id, name, available_quantity, image_url, is_active')
        .eq('id', productId)
        .eq('is_active', true)
        .single();

      if (error) {
        throw new Error(`خطأ في جلب المنتج: ${error.message}`);
      }

      if (!product) {
        return {
          success: false,
          error: 'المنتج غير موجود أو غير نشط'
        };
      }

      const quantity = product.available_quantity || 0;
      const alerts = [];

      // فحص حالة المخزون
      if (quantity <= this.thresholds.outOfStock) {
        const alertSent = await this.sendOutOfStockAlert(product);
        alerts.push({
          productId: product.id,
          product_name: product.name,
          type: 'نفد المخزون',
          quantity,
          sent: alertSent.success
        });

      } else if (quantity === this.thresholds.lowStock) {
        // إرسال إشعار مخزون منخفض فقط عند الكمية 5 بالضبط
        const alertSent = await this.sendLowStockAlert(product);
        alerts.push({
          productId: product.id,
          product_name: product.name,
          type: 'مخزون منخفض',
          quantity,
          sent: alertSent.success
        });

      } else {
        // إزالة المنتج من قائمة الإشعارات المرسلة
        this.clearAlertHistory(productId);
      }

      return {
        success: true,
        product: {
          id: product.id,
          name: product.name,
          quantity: quantity,
          status: quantity <= this.thresholds.outOfStock ? 'نفد المخزون' : 
                  quantity <= this.thresholds.lowStock ? 'مخزون منخفض' : 'طبيعي'
        },
        alerts: alerts.length > 0 ? alerts : null
      };

    } catch (error) {
      console.error(`❌ خطأ في مراقبة المنتج ${productId}:`, error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال إشعار نفاد المخزون
   */
  async sendOutOfStockAlert(product) {
    try {
      const alertKey = `out_of_stock_${product.id}`;
      
      // تحقق من عدم إرسال نفس الإشعار مؤخراً (خلال ساعة واحدة)
      if (this.isAlertRecentlySent(alertKey, 60 * 60 * 1000)) {
        return {
          success: false,
          reason: 'تم إرسال الإشعار مؤخراً'
        };
      }

      const result = await this.telegramService.sendOutOfStockAlert({
        productId: product.id,
        productName: product.name,
        productImage: product.image_url
      });

      if (result.success) {
        this.markAlertSent(alertKey);
        console.log(`🚨 تم إرسال إشعار نفاد المخزون: ${product.name}`);
      }

      return result;

    } catch (error) {
      console.error(`❌ خطأ في إرسال إشعار نفاد المخزون: ${error.message}`);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال إشعار مخزون منخفض
   */
  async sendLowStockAlert(product) {
    try {
      const alertKey = `low_stock_${product.id}`;
      
      // تحقق من عدم إرسال نفس الإشعار مؤخراً (خلال 4 ساعات)
      if (this.isAlertRecentlySent(alertKey, 4 * 60 * 60 * 1000)) {
        return {
          success: false,
          reason: 'تم إرسال الإشعار مؤخراً'
        };
      }

      const result = await this.telegramService.sendLowStockAlert({
        productId: product.id,
        productName: product.name,
        currentStock: product.available_quantity,
        productImage: product.image_url
      });

      if (result.success) {
        this.markAlertSent(alertKey);
        console.log(`⚠️ تم إرسال إشعار مخزون منخفض: ${product.name}`);
      }

      return result;

    } catch (error) {
      console.error(`❌ خطأ في إرسال إشعار مخزون منخفض: ${error.message}`);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * تحقق من إرسال الإشعار مؤخراً
   */
  isAlertRecentlySent(alertKey, timeThreshold) {
    const lastSent = this.sentAlerts.get(alertKey);
    if (!lastSent) return false;
    
    return (Date.now() - lastSent) < timeThreshold;
  }

  /**
   * تسجيل إرسال الإشعار
   */
  markAlertSent(alertKey) {
    this.sentAlerts.set(alertKey, Date.now());
  }

  /**
   * مسح تاريخ الإشعارات للمنتج
   */
  clearAlertHistory(productId) {
    this.sentAlerts.delete(`out_of_stock_${productId}`);
    this.sentAlerts.delete(`low_stock_${productId}`);
  }

  /**
   * تنظيف الإشعارات القديمة (أكثر من 24 ساعة)
   */
  cleanupOldAlerts() {
    const oneDayAgo = Date.now() - (24 * 60 * 60 * 1000);
    
    for (const [key, timestamp] of this.sentAlerts.entries()) {
      if (timestamp < oneDayAgo) {
        this.sentAlerts.delete(key);
      }
    }
  }
}

module.exports = InventoryMonitorService;
