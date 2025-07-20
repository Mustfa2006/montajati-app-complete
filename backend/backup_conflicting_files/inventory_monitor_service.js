const { createClient } = require('@supabase/supabase-js');
const TelegramNotificationService = require('./telegram_notification_service');

class InventoryMonitorService {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    this.telegramService = new TelegramNotificationService();
    this.lowStockThreshold = parseInt(process.env.LOW_STOCK_THRESHOLD) || 5;

    // ✅ نظام ذكي لمنع تكرار الإشعارات مع تنظيف دوري
    this.sentNotifications = new Map(); // productId -> { type, timestamp, lastQuantity }
    this.notificationCooldown = 24 * 60 * 60 * 1000; // 24 ساعة بالميلي ثانية
    this.maxCacheSize = 1000; // ✅ حد أقصى لحجم الذاكرة المؤقتة

    // ✅ تنظيف دوري للذاكرة المؤقتة كل 6 ساعات
    this.cleanupInterval = setInterval(() => {
      this.cleanupOldNotifications();
    }, 6 * 60 * 60 * 1000);
  }

  /**
   * فحص إذا كان الإشعار تم إرساله مؤخراً (نظام منع التكرار الذكي)
   */
  canSendNotification(productId, notificationType, currentQuantity = null) {
    const key = `${productId}_${notificationType}`;
    const lastSent = this.sentNotifications.get(key);

    if (!lastSent) {
      return true; // لم يتم إرسال إشعار من قبل
    }

    // إذا تغيرت الكمية، يمكن إرسال إشعار جديد
    if (currentQuantity !== null && lastSent.lastQuantity !== currentQuantity) {
      console.log(`🔄 تغيرت الكمية للمنتج ${productId} من ${lastSent.lastQuantity} إلى ${currentQuantity} - يمكن إرسال إشعار جديد`);
      return true;
    }

    const now = Date.now();
    const timeDiff = now - lastSent.timestamp;

    if (timeDiff >= this.notificationCooldown) {
      return true; // مر وقت كافي منذ آخر إشعار (24 ساعة)
    }

    const hoursLeft = Math.round((this.notificationCooldown - timeDiff) / (1000 * 60 * 60));
    console.log(`⏰ تم تخطي إشعار ${notificationType} للمنتج ${productId} - يمكن الإرسال مرة أخرى بعد ${hoursLeft} ساعة`);
    return false; // لا يمكن الإرسال بعد
  }

  /**
   * تسجيل إرسال الإشعار مع الكمية
   */
  markNotificationSent(productId, notificationType, currentQuantity = null) {
    const key = `${productId}_${notificationType}`;
    this.sentNotifications.set(key, {
      type: notificationType,
      timestamp: Date.now(),
      lastQuantity: currentQuantity
    });

    console.log(`✅ تم تسجيل إرسال إشعار ${notificationType} للمنتج ${productId} - الكمية: ${currentQuantity}`);
  }

  /**
   * تنظيف الإشعارات القديمة (لتوفير الذاكرة)
   */
  cleanupOldNotifications() {
    const now = Date.now();
    const keysToDelete = [];

    for (const [key, notification] of this.sentNotifications.entries()) {
      if (now - notification.timestamp > this.notificationCooldown * 2) {
        keysToDelete.push(key);
      }
    }

    keysToDelete.forEach(key => this.sentNotifications.delete(key));

    if (keysToDelete.length > 0) {
      console.log(`🧹 تم تنظيف ${keysToDelete.length} إشعار قديم من الذاكرة`);
    }
  }

  /**
   * اختبار النظام
   */
  async testSystem() {
    try {
      // اختبار الاتصال بـ Supabase
      const { data, error } = await this.supabase
        .from('products')
        .select('id')
        .limit(1);

      if (error) {
        return {
          success: false,
          error: 'فشل في الاتصال بقاعدة البيانات: ' + error.message
        };
      }

      // اختبار خدمة التلغرام
      const telegramTest = await this.telegramService.testConnection();

      return {
        success: true,
        database_status: 'متصل',
        telegram_status: telegramTest.success ? 'متصل' : 'غير متصل',
        low_stock_threshold: this.lowStockThreshold,
        message: 'نظام مراقبة المخزون جاهز'
      };
    } catch (error) {
      console.error('❌ خطأ في اختبار نظام مراقبة المخزون:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * مراقبة منتج محدد
   */
  async monitorProduct(productId) {
    try {
      // جلب بيانات المنتج مع الصورة
      const { data: product, error } = await this.supabase
        .from('products')
        .select('id, name, available_quantity, image_url')
        .eq('id', productId)
        .single();

      if (error) {
        return {
          success: false,
          error: 'فشل في جلب بيانات المنتج: ' + error.message
        };
      }

      if (!product) {
        return {
          success: false,
          error: 'المنتج غير موجود'
        };
      }

      const currentStock = product.available_quantity || 0;
      const productName = product.name || 'منتج غير محدد';
      const productImage = product.image_url;

      let alerts = [];
      let status = 'normal';

      // فحص نفاد المخزون (عند 0 قطع بالضبط)
      if (currentStock === 0) {
        status = 'out_of_stock';

        // فحص إذا كان يمكن إرسال الإشعار (نظام منع التكرار الذكي)
        if (this.canSendNotification(productId, 'out_of_stock', currentStock)) {
          const alertResult = await this.telegramService.sendOutOfStockAlert({
            productId,
            productName,
            productImage
          });

          if (alertResult.success) {
            this.markNotificationSent(productId, 'out_of_stock', currentStock);
          }

          alerts.push({
            type: 'out_of_stock',
            sent: alertResult.success,
            message: alertResult.message || alertResult.error
          });
        } else {
          alerts.push({
            type: 'out_of_stock',
            sent: false,
            message: 'تم تخطي الإشعار - منع التكرار'
          });
        }
      }
      // فحص المخزون المنخفض (عند 5 قطع بالضبط فقط)
      else if (currentStock === 5) {
        status = 'low_stock';

        // فحص إذا كان يمكن إرسال الإشعار (نظام منع التكرار الذكي)
        if (this.canSendNotification(productId, 'low_stock', currentStock)) {
          const alertResult = await this.telegramService.sendLowStockAlert({
            productId,
            productName,
            currentStock,
            productImage
          });

          if (alertResult.success) {
            this.markNotificationSent(productId, 'low_stock', currentStock);
          }

          alerts.push({
            type: 'low_stock',
            sent: alertResult.success,
            message: alertResult.message || alertResult.error
          });
        } else {
          alerts.push({
            type: 'low_stock',
            sent: false,
            message: 'تم تخطي الإشعار - منع التكرار'
          });
        }
      }

      return {
        success: true,
        product: {
          id: productId,
          name: productName,
          current_stock: currentStock,
          threshold: this.lowStockThreshold,
          status
        },
        alerts,
        message: `تم فحص المنتج ${productName} - الحالة: ${status}`
      };
    } catch (error) {
      console.error('❌ خطأ في مراقبة المنتج:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * مراقبة جميع المنتجات
   */
  async monitorAllProducts() {
    try {
      console.log('🔄 بدء مراقبة جميع المنتجات...');

      // تنظيف الإشعارات القديمة أولاً
      this.cleanupOldNotifications();

      // جلب جميع المنتجات مع الصور
      console.log('📡 جلب المنتجات من قاعدة البيانات...');
      const { data: products, error } = await this.supabase
        .from('products')
        .select('id, name, available_quantity, image_url')
        .order('available_quantity', { ascending: true });

      if (error) {
        console.error('❌ خطأ في جلب المنتجات:', error);
        return {
          success: false,
          error: 'فشل في جلب المنتجات: ' + error.message
        };
      }

      console.log(`📦 تم جلب ${products?.length || 0} منتج`);

      if (!products || products.length === 0) {
        console.log('⚠️ لا توجد منتجات في قاعدة البيانات');
        return {
          success: true,
          results: {
            total: 0,
            outOfStock: 0,
            lowStock: 0,
            normal: 0,
            sentNotifications: 0
          },
          alerts: [],
          message: 'لا توجد منتجات للمراقبة'
        };
      }

      let outOfStockCount = 0;
      let lowStockCount = 0;
      let normalCount = 0;
      let alerts = [];
      let sentNotifications = 0;

      // فحص كل منتج
      for (const product of products) {
        const currentStock = product.available_quantity || 0;
        console.log(`🔍 فحص منتج: ${product.name} - الكمية: ${currentStock}`);

        if (currentStock === 0) {
          outOfStockCount++;

          // فحص إذا كان يمكن إرسال الإشعار (نظام منع التكرار)
          if (this.canSendNotification(product.id, 'out_of_stock')) {
            const alertResult = await this.telegramService.sendOutOfStockAlert({
              productId: product.id,
              productName: product.name,
              productImage: product.image_url
            });

            if (alertResult.success) {
              this.markNotificationSent(product.id, 'out_of_stock');
              sentNotifications++;
            }

            alerts.push({
              product_id: product.id,
              product_name: product.name,
              type: 'out_of_stock',
              sent: alertResult.success
            });
          }
        } else if (currentStock === 5) {
          lowStockCount++;

          // فحص إذا كان يمكن إرسال الإشعار (نظام منع التكرار)
          if (this.canSendNotification(product.id, 'low_stock')) {
            const alertResult = await this.telegramService.sendLowStockAlert({
              productId: product.id,
              productName: product.name,
              currentStock,
              productImage: product.image_url
            });

            if (alertResult.success) {
              this.markNotificationSent(product.id, 'low_stock');
              sentNotifications++;
            }

            alerts.push({
              product_id: product.id,
              product_name: product.name,
              type: 'low_stock',
              sent: alertResult.success
            });
          }
        } else {
          normalCount++;
        }
      }

      return {
        success: true,
        results: {
          total: products.length,
          outOfStock: outOfStockCount,
          lowStock: lowStockCount,
          normal: normalCount,
          sentNotifications: sentNotifications
        },
        alerts,
        message: `تم فحص ${products.length} منتج - نفد: ${outOfStockCount}, منخفض: ${lowStockCount}, طبيعي: ${normalCount}, إشعارات مرسلة: ${sentNotifications}`
      };
    } catch (error) {
      console.error('❌ خطأ في مراقبة جميع المنتجات:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال تقرير يومي
   */
  async sendDailyReport() {
    try {
      const monitorResult = await this.monitorAllProducts();

      if (!monitorResult.success) {
        return monitorResult;
      }

      const { results } = monitorResult;
      
      const reportMessage = `
📊 <b>التقرير اليومي للمخزون</b>

📦 <b>إجمالي المنتجات:</b> ${results.total}
✅ <b>مخزون طبيعي:</b> ${results.normal}
⚠️ <b>مخزون منخفض:</b> ${results.lowStock}
🔴 <b>نفد المخزون:</b> ${results.outOfStock}

📅 <b>التاريخ:</b> ${new Date().toLocaleDateString('ar-SA')}
⏰ <b>الوقت:</b> ${new Date().toLocaleTimeString('ar-SA')}

${results.outOfStock > 0 || results.lowStock > 0 ? 
  '🚨 <b>يرجى مراجعة المنتجات التي تحتاج إعادة تعبئة</b>' : 
  '✅ <b>جميع المنتجات في حالة جيدة</b>'
}
      `.trim();

      const sendResult = await this.telegramService.sendMessage(reportMessage);

      return {
        success: true,
        report: results,
        telegram_sent: sendResult.success,
        message: 'تم إرسال التقرير اليومي'
      };
    } catch (error) {
      console.error('❌ خطأ في إرسال التقرير اليومي:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * ✅ تنظيف الإشعارات القديمة من الذاكرة المؤقتة
   */
  cleanupOldNotifications() {
    try {
      const now = Date.now();
      const cutoffTime = now - (this.notificationCooldown * 2); // ضعف فترة التبريد
      let cleanedCount = 0;

      // حذف الإشعارات القديمة
      for (const [productId, notification] of this.sentNotifications.entries()) {
        if (notification.timestamp < cutoffTime) {
          this.sentNotifications.delete(productId);
          cleanedCount++;
        }
      }

      // إذا كان الحجم لا يزال كبيراً، احذف الأقدم
      if (this.sentNotifications.size > this.maxCacheSize) {
        const entries = Array.from(this.sentNotifications.entries())
          .sort((a, b) => a[1].timestamp - b[1].timestamp);

        const toDelete = entries.slice(0, entries.length - this.maxCacheSize);
        toDelete.forEach(([productId]) => {
          this.sentNotifications.delete(productId);
          cleanedCount++;
        });
      }

      if (cleanedCount > 0) {
        console.log(`🧹 تم تنظيف ${cleanedCount} إشعار قديم من الذاكرة المؤقتة`);
      }
    } catch (error) {
      console.error('❌ خطأ في تنظيف الذاكرة المؤقتة:', error);
    }
  }

  /**
   * ✅ إيقاف الخدمة وتنظيف الموارد
   */
  shutdown() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    this.sentNotifications.clear();
    console.log('✅ تم إيقاف خدمة مراقبة المخزون وتنظيف الموارد');
  }
}

module.exports = InventoryMonitorService;
