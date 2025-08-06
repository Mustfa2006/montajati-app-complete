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

    // تتبع آخر كمية معروفة لكل منتج لاكتشاف التغييرات
    this.lastKnownQuantities = new Map();

    console.log('📦 تم تهيئة خدمة مراقبة المخزون');
    console.log(`🚨 حد نفاد المخزون: ${this.thresholds.outOfStock}`);
    console.log(`⚠️ حد المخزون المنخفض: ${this.thresholds.lowStock}`);

    // تنظيف دوري للإشعارات القديمة كل 6 ساعات
    setInterval(() => {
      this.cleanupOldAlerts();
    }, 6 * 60 * 60 * 1000);
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
        const lastQuantity = this.lastKnownQuantities.get(productId);

        // تحديث آخر كمية معروفة
        this.lastKnownQuantities.set(productId, quantity);

        // تحديد حالة المخزون
        if (quantity <= this.thresholds.outOfStock) {
          stats.outOfStock++;

          // إرسال إشعار نفاد المخزون فقط إذا:
          // 1. الكمية تغيرت من رقم أكبر إلى 0 (نفاد جديد)، أو
          // 2. لم يتم إرسال إشعار لهذا المنتج من قبل
          const isNewOutOfStock = lastQuantity !== undefined && lastQuantity > this.thresholds.outOfStock && quantity <= this.thresholds.outOfStock;
          const hasNeverSentAlert = !this.sentAlerts.has(`out_of_stock_${productId}`);

          if (isNewOutOfStock || hasNeverSentAlert) {
            const alertSent = await this.sendOutOfStockAlert(product);
            if (alertSent.success) {
              stats.sentNotifications++;
            }

            alerts.push({
              productId,
              product_name: productName,
              type: 'نفد المخزون',
              quantity,
              sent: alertSent.success,
              reason: isNewOutOfStock ? 'نفاد جديد' : 'إعادة إرسال'
            });
          }

        } else if (quantity === this.thresholds.lowStock) {
          stats.lowStock++;

          // إرسال إشعار مخزون منخفض فقط إذا:
          // 1. الكمية تغيرت من رقم أكبر إلى 5 (انخفاض جديد)، أو
          // 2. لم يتم إرسال إشعار لهذا المنتج من قبل
          const isNewLowStock = lastQuantity !== undefined && lastQuantity > this.thresholds.lowStock && quantity === this.thresholds.lowStock;
          const hasNeverSentLowStockAlert = !this.sentAlerts.has(`low_stock_${productId}`);

          if (isNewLowStock || hasNeverSentLowStockAlert) {
            const alertSent = await this.sendLowStockAlert(product);
            if (alertSent.success) {
              stats.sentNotifications++;
            }

            alerts.push({
              productId,
              product_name: productName,
              type: 'مخزون منخفض',
              quantity,
              sent: alertSent.success,
              reason: isNewLowStock ? 'انخفاض جديد' : 'إعادة إرسال'
            });
          }

        } else {
          stats.normal++;

          // إزالة المنتج من قائمة الإشعارات المرسلة إذا كان المخزون طبيعي الآن
          // ولكن فقط إذا كان منخفضاً أو نافداً من قبل (للسماح بإشعارات جديدة عند الانخفاض مرة أخرى)
          if (lastQuantity !== undefined && lastQuantity <= this.thresholds.lowStock) {
            this.clearAlertHistory(productId);
            console.log(`🔄 تم مسح تاريخ الإشعارات للمنتج: ${productName} (تم تجديد المخزون من ${lastQuantity} إلى ${quantity})`);
          }
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

      const productId = product.id;
      const quantity = product.available_quantity || 0;
      const lastQuantity = this.lastKnownQuantities.get(productId);
      const alerts = [];

      // تحديث آخر كمية معروفة
      this.lastKnownQuantities.set(productId, quantity);

      // فحص حالة المخزون
      if (quantity <= this.thresholds.outOfStock) {
        // إرسال إشعار فقط إذا كان نفاد جديد أو لم يتم إرسال إشعار من قبل
        const isNewOutOfStock = lastQuantity !== undefined && lastQuantity > this.thresholds.outOfStock;
        const hasNeverSentAlert = !this.sentAlerts.has(`out_of_stock_${productId}`);

        if (isNewOutOfStock || hasNeverSentAlert) {
          const alertSent = await this.sendOutOfStockAlert(product);
          alerts.push({
            productId: product.id,
            product_name: product.name,
            type: 'نفد المخزون',
            quantity,
            sent: alertSent.success,
            reason: isNewOutOfStock ? 'نفاد جديد' : 'إعادة إرسال'
          });
        }

      } else if (quantity === this.thresholds.lowStock) {
        // إرسال إشعار فقط إذا كان انخفاض جديد أو لم يتم إرسال إشعار من قبل
        const isNewLowStock = lastQuantity !== undefined && lastQuantity > this.thresholds.lowStock;
        const hasNeverSentLowStockAlert = !this.sentAlerts.has(`low_stock_${productId}`);

        if (isNewLowStock || hasNeverSentLowStockAlert) {
          const alertSent = await this.sendLowStockAlert(product);
          alerts.push({
            productId: product.id,
            product_name: product.name,
            type: 'مخزون منخفض',
            quantity,
            sent: alertSent.success,
            reason: isNewLowStock ? 'انخفاض جديد' : 'إعادة إرسال'
          });
        }

      } else {
        // إزالة المنتج من قائمة الإشعارات المرسلة فقط إذا كان منخفضاً أو نافداً من قبل
        if (lastQuantity !== undefined && lastQuantity <= this.thresholds.lowStock) {
          this.clearAlertHistory(productId);
          console.log(`🔄 تم مسح تاريخ الإشعارات للمنتج: ${product.name} (تم تجديد المخزون من ${lastQuantity} إلى ${quantity})`);
        }
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
      
      // تحقق من عدم إرسال نفس الإشعار من قبل
      if (this.sentAlerts.has(alertKey)) {
        return {
          success: false,
          reason: 'تم إرسال الإشعار من قبل'
        };
      }

      const result = await this.telegramService.sendOutOfStockAlert({
        productId: product.id,
        productName: product.name,
        productImage: product.image_url || product.image // ✅ استخدام صورة المنتج الحقيقية
      });

      if (result.success) {
        this.markAlertSent(alertKey);
        console.log(`🚨 تم إرسال إشعار نفاد المخزون: ${product.name} (الكمية: ${product.available_quantity})`);
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
      
      // تحقق من عدم إرسال نفس الإشعار من قبل
      if (this.sentAlerts.has(alertKey)) {
        return {
          success: false,
          reason: 'تم إرسال الإشعار من قبل'
        };
      }

      const result = await this.telegramService.sendLowStockAlert({
        productId: product.id,
        productName: product.name,
        currentStock: product.available_quantity,
        productImage: product.image_url || product.image // ✅ استخدام صورة المنتج الحقيقية
      });

      if (result.success) {
        this.markAlertSent(alertKey);
        console.log(`⚠️ تم إرسال إشعار مخزون منخفض: ${product.name} (الكمية: ${product.available_quantity})`);
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
    let cleanedCount = 0;

    for (const [key, timestamp] of this.sentAlerts.entries()) {
      if (timestamp < oneDayAgo) {
        this.sentAlerts.delete(key);
        cleanedCount++;
      }
    }

    if (cleanedCount > 0) {
      console.log(`🧹 تم تنظيف ${cleanedCount} إشعار قديم من الذاكرة`);
    }
  }
}

module.exports = InventoryMonitorService;
