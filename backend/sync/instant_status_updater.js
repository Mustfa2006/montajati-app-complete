// ===================================
// نظام التحديث الفوري والتلقائي للحالات
// Instant & Automatic Status Updater
// ===================================

const { createClient } = require('@supabase/supabase-js');
const statusMapper = require('./status_mapper');
require('dotenv').config();

class InstantStatusUpdater {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات التحديث الفوري
    this.config = {
      enableRealtime: true,
      enableNotifications: true,
      enableHistory: true,
      enableValidation: true
    };

    // إحصائيات التحديث
    this.stats = {
      totalUpdates: 0,
      successfulUpdates: 0,
      failedUpdates: 0,
      lastUpdateTime: null,
      averageUpdateTime: 0
    };

    // قائمة المستمعين للتحديثات
    this.updateListeners = new Set();

    console.log('⚡ تم تهيئة نظام التحديث الفوري للحالات');
  }

  // ===================================
  // تحديث حالة طلب واحد فورياً
  // ===================================
  async instantUpdateOrderStatus(orderId, newWaseetStatus, waseetData = null) {
    const startTime = Date.now();
    
    try {
      console.log(`⚡ بدء تحديث فوري للطلب ${orderId}...`);

      // 1. جلب الطلب الحالي
      const { data: currentOrder, error: fetchError } = await this.supabase
        .from('orders')
        .select('*')
        .eq('id', orderId)
        .single();

      if (fetchError) {
        throw new Error(`خطأ في جلب الطلب: ${fetchError.message}`);
      }

      if (!currentOrder) {
        throw new Error(`الطلب ${orderId} غير موجود`);
      }

      // 2. تحويل الحالة من الوسيط إلى المحلية
      const newLocalStatus = statusMapper.mapWaseetToLocal(newWaseetStatus);
      
      // 3. التحقق من تغيير الحالة
      const hasStatusChanged = newLocalStatus !== currentOrder.status;
      const hasWaseetStatusChanged = newWaseetStatus !== currentOrder.waseet_status;

      if (!hasStatusChanged && !hasWaseetStatusChanged) {
        console.log(`📊 الطلب ${orderId}: لا يوجد تغيير في الحالة`);
        return {
          success: true,
          changed: false,
          message: 'لا يوجد تغيير في الحالة'
        };
      }

      // 4. التحقق من صحة الحالة الجديدة
      if (this.config.enableValidation && !this.validateStatusTransition(currentOrder.status, newLocalStatus)) {
        throw new Error(`انتقال حالة غير صحيح: ${currentOrder.status} → ${newLocalStatus}`);
      }

      // 5. تحديث الطلب في قاعدة البيانات
      const updateData = {
        waseet_status: newWaseetStatus,
        last_status_check: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      // إضافة الحالة المحلية إذا تغيرت
      if (hasStatusChanged) {
        updateData.status = newLocalStatus;
        updateData.status_updated_at = new Date().toISOString();
      }

      // إضافة بيانات الوسيط إذا توفرت
      if (waseetData) {
        updateData.waseet_data = waseetData;
      }

      const { error: updateError } = await this.supabase
        .from('orders')
        .update(updateData)
        .eq('id', orderId);

      if (updateError) {
        throw new Error(`خطأ في تحديث الطلب: ${updateError.message}`);
      }

      // 6. إضافة سجل في تاريخ الحالات
      if (this.config.enableHistory && hasStatusChanged) {
        await this.addStatusHistory(currentOrder, newLocalStatus, newWaseetStatus, waseetData);
      }

      // 7. إرسال إشعارات
      if (this.config.enableNotifications && hasStatusChanged) {
        await this.sendStatusNotification(currentOrder, newLocalStatus);
      }

      // 8. تحديث الإحصائيات
      const updateTime = Date.now() - startTime;
      this.updateStats(true, updateTime);

      // 9. إشعار المستمعين
      this.notifyListeners({
        orderId,
        oldStatus: currentOrder.status,
        newStatus: newLocalStatus,
        oldWaseetStatus: currentOrder.waseet_status,
        newWaseetStatus,
        timestamp: new Date().toISOString(),
        updateTime
      });

      console.log(`✅ تم تحديث الطلب ${orderId} فورياً: ${currentOrder.status} → ${newLocalStatus} (${updateTime}ms)`);

      return {
        success: true,
        changed: true,
        oldStatus: currentOrder.status,
        newStatus: newLocalStatus,
        oldWaseetStatus: currentOrder.waseet_status,
        newWaseetStatus,
        updateTime,
        message: 'تم التحديث بنجاح'
      };

    } catch (error) {
      const updateTime = Date.now() - startTime;
      this.updateStats(false, updateTime);
      
      console.error(`❌ فشل في التحديث الفوري للطلب ${orderId}:`, error.message);
      
      return {
        success: false,
        error: error.message,
        updateTime
      };
    }
  }

  // ===================================
  // تحديث متعدد للطلبات فورياً
  // ===================================
  async batchInstantUpdate(updates) {
    console.log(`⚡ بدء تحديث فوري لـ ${updates.length} طلب...`);
    
    const results = [];
    const startTime = Date.now();

    // معالجة التحديثات بالتوازي (مع تحديد العدد)
    const batchSize = 10;
    for (let i = 0; i < updates.length; i += batchSize) {
      const batch = updates.slice(i, i + batchSize);
      
      const batchPromises = batch.map(update => 
        this.instantUpdateOrderStatus(
          update.orderId, 
          update.waseetStatus, 
          update.waseetData
        )
      );

      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);
    }

    const totalTime = Date.now() - startTime;
    const successCount = results.filter(r => r.success).length;
    const changedCount = results.filter(r => r.success && r.changed).length;

    console.log(`✅ انتهى التحديث المتعدد: ${successCount}/${updates.length} نجح، ${changedCount} تغيير (${totalTime}ms)`);

    return {
      success: true,
      totalUpdates: updates.length,
      successfulUpdates: successCount,
      changedUpdates: changedCount,
      totalTime,
      results
    };
  }

  // ===================================
  // التحقق من صحة انتقال الحالة
  // ===================================
  validateStatusTransition(currentStatus, newStatus) {
    // قواعد انتقال الحالات
    const validTransitions = {
      'active': ['in_delivery', 'delivered', 'cancelled'],
      'in_delivery': ['delivered', 'cancelled'],
      'delivered': [], // حالة نهائية
      'cancelled': [] // حالة نهائية
    };

    // السماح بالبقاء في نفس الحالة
    if (currentStatus === newStatus) {
      return true;
    }

    const allowedTransitions = validTransitions[currentStatus] || [];
    return allowedTransitions.includes(newStatus);
  }

  // ===================================
  // إضافة سجل في تاريخ الحالات
  // ===================================
  async addStatusHistory(order, newLocalStatus, newWaseetStatus, waseetData) {
    try {
      await this.supabase
        .from('order_status_history')
        .insert({
          order_id: order.id,
          old_status: order.status,
          new_status: newLocalStatus,
          changed_by: 'instant_status_updater',
          change_reason: `تحديث فوري من الوسيط: ${order.waseet_status} → ${newWaseetStatus}`,
          waseet_response: waseetData || { 
            old_waseet_status: order.waseet_status,
            new_waseet_status: newWaseetStatus,
            update_type: 'instant'
          }
        });
    } catch (error) {
      console.warn('⚠️ تحذير: فشل في إضافة سجل التاريخ:', error.message);
    }
  }

  // ===================================
  // إرسال إشعار تغيير الحالة
  // ===================================
  async sendStatusNotification(order, newStatus) {
    try {
      // يمكن إضافة منطق الإشعارات هنا
      // مثل إرسال إشعار للعميل أو التاجر
      console.log(`📱 إشعار: تغيرت حالة الطلب ${order.order_number} إلى ${newStatus}`);
    } catch (error) {
      console.warn('⚠️ تحذير: فشل في إرسال الإشعار:', error.message);
    }
  }

  // ===================================
  // تحديث الإحصائيات
  // ===================================
  updateStats(success, updateTime) {
    this.stats.totalUpdates++;
    this.stats.lastUpdateTime = new Date().toISOString();

    if (success) {
      this.stats.successfulUpdates++;
    } else {
      this.stats.failedUpdates++;
    }

    // حساب متوسط وقت التحديث
    this.stats.averageUpdateTime = (
      (this.stats.averageUpdateTime * (this.stats.totalUpdates - 1) + updateTime) / 
      this.stats.totalUpdates
    );
  }

  // ===================================
  // إضافة مستمع للتحديثات
  // ===================================
  addUpdateListener(listener) {
    this.updateListeners.add(listener);
    console.log(`👂 تم إضافة مستمع جديد (المجموع: ${this.updateListeners.size})`);
  }

  // ===================================
  // إزالة مستمع للتحديثات
  // ===================================
  removeUpdateListener(listener) {
    this.updateListeners.delete(listener);
    console.log(`👂 تم إزالة مستمع (المجموع: ${this.updateListeners.size})`);
  }

  // ===================================
  // إشعار جميع المستمعين
  // ===================================
  notifyListeners(updateData) {
    this.updateListeners.forEach(listener => {
      try {
        listener(updateData);
      } catch (error) {
        console.warn('⚠️ تحذير: خطأ في إشعار المستمع:', error.message);
      }
    });
  }

  // ===================================
  // الحصول على إحصائيات التحديث
  // ===================================
  getUpdateStats() {
    return {
      ...this.stats,
      successRate: this.stats.totalUpdates > 0 ? 
        (this.stats.successfulUpdates / this.stats.totalUpdates * 100).toFixed(2) : 0,
      listenersCount: this.updateListeners.size,
      config: this.config
    };
  }

  // ===================================
  // إعادة تعيين الإحصائيات
  // ===================================
  resetStats() {
    this.stats = {
      totalUpdates: 0,
      successfulUpdates: 0,
      failedUpdates: 0,
      lastUpdateTime: null,
      averageUpdateTime: 0
    };
    console.log('📊 تم إعادة تعيين إحصائيات التحديث');
  }
}

module.exports = InstantStatusUpdater;
