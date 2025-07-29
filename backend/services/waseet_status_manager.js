// ===================================
// مدير حالات الوسيط
// Waseet Status Manager
// ===================================

const { createClient } = require('@supabase/supabase-js');

class WaseetStatusManager {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // الحالات الأساسية المعتمدة (22 حالة)
    this.approvedStatuses = [
      { id: 1, text: "نشط", category: "active", appStatus: "active" },
      { id: 4, text: "تم التسليم للزبون", category: "delivered", appStatus: "delivered" },
      { id: 24, text: "تم تغيير محافظة الزبون", category: "modified", appStatus: "active" },
      { id: 42, text: "تغيير المندوب", category: "modified", appStatus: "active" },
      { id: 25, text: "لا يرد", category: "contact_issue", appStatus: "active" },
      { id: 26, text: "لا يرد بعد الاتفاق", category: "contact_issue", appStatus: "active" },
      { id: 27, text: "مغلق", category: "contact_issue", appStatus: "active" },
      { id: 28, text: "مغلق بعد الاتفاق", category: "contact_issue", appStatus: "active" },
      { id: 3, text: "قيد التوصيل الى الزبون (في عهدة المندوب)", category: "in_delivery", appStatus: "in_delivery" },
      { id: 36, text: "الرقم غير معرف", category: "contact_issue", appStatus: "active" },
      { id: 37, text: "الرقم غير داخل في الخدمة", category: "contact_issue", appStatus: "active" },
      { id: 41, text: "لا يمكن الاتصال بالرقم", category: "contact_issue", appStatus: "active" },
      { id: 29, text: "مؤجل", category: "postponed", appStatus: "active" },
      { id: 30, text: "مؤجل لحين اعادة الطلب لاحقا", category: "postponed", appStatus: "active" },
      { id: 31, text: "الغاء الطلب", category: "cancelled", appStatus: "cancelled" },
      { id: 32, text: "رفض الطلب", category: "cancelled", appStatus: "cancelled" },
      { id: 33, text: "مفصول عن الخدمة", category: "cancelled", appStatus: "cancelled" },
      { id: 34, text: "طلب مكرر", category: "cancelled", appStatus: "cancelled" },
      { id: 35, text: "مستلم مسبقا", category: "cancelled", appStatus: "cancelled" },
      { id: 38, text: "العنوان غير دقيق", category: "address_issue", appStatus: "active" },
      { id: 39, text: "لم يطلب", category: "cancelled", appStatus: "cancelled" },
      { id: 40, text: "حظر المندوب", category: "cancelled", appStatus: "cancelled" },
      { id: 23, text: "ارسال الى مخزن الارجاعات", category: "cancelled", appStatus: "cancelled" }
    ];
  }

  // الحصول على جميع الحالات المعتمدة
  getApprovedStatuses() {
    return this.approvedStatuses;
  }

  // الحصول على حالة بواسطة ID
  getStatusById(statusId) {
    return this.approvedStatuses.find(status => status.id === parseInt(statusId));
  }

  // الحصول على حالة بواسطة النص
  getStatusByText(statusText) {
    return this.approvedStatuses.find(status => status.text === statusText);
  }

  // تحويل حالة الوسيط إلى حالة التطبيق
  mapWaseetStatusToAppStatus(waseetStatusId) {
    const status = this.getStatusById(waseetStatusId);
    return status ? status.appStatus : 'active';
  }

  // التحقق من صحة حالة الوسيط
  isValidWaseetStatus(statusId) {
    return this.approvedStatuses.some(status => status.id === parseInt(statusId));
  }

  // تحديث حالة الطلب
  async updateOrderStatus(orderId, waseetStatusId, waseetStatusText = null) {
    try {
      console.log(`🔄 تحديث حالة الطلب ${orderId} إلى ${waseetStatusId}`);

      // التحقق من صحة الحالة
      if (!this.isValidWaseetStatus(waseetStatusId)) {
        throw new Error(`حالة الوسيط ${waseetStatusId} غير معتمدة`);
      }

      const statusInfo = this.getStatusById(waseetStatusId);
      const statusText = waseetStatusText || statusInfo.text;

      // تحديث الطلب في قاعدة البيانات - حفظ النص الكامل في عمود status
      const { data, error } = await this.supabase
        .from('orders')
        .update({
          status: statusText,  // حفظ النص الكامل للحالة في عمود status
          waseet_status_id: waseetStatusId,
          waseet_status_text: statusText,
          status_updated_at: new Date().toISOString()
        })
        .eq('id', orderId)
        .select('*')
        .single();

      if (error) {
        throw new Error(`خطأ في تحديث قاعدة البيانات: ${error.message}`);
      }

      console.log(`✅ تم تحديث حالة الطلب ${orderId} بنجاح`);
      console.log(`   📊 حالة الطلب في قاعدة البيانات: ${statusText}`);
      console.log(`   📋 ID الحالة: ${waseetStatusId}`);

      return {
        success: true,
        order: data,
        oldStatus: data.status,
        newStatus: statusText,  // النص الكامل للحالة
        waseetStatus: statusText
      };

    } catch (error) {
      console.error(`❌ خطأ في تحديث حالة الطلب ${orderId}:`, error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // تحديث حالات متعددة
  async updateMultipleOrderStatuses(updates) {
    const results = [];
    
    for (const update of updates) {
      const result = await this.updateOrderStatus(
        update.orderId,
        update.waseetStatusId,
        update.waseetStatusText
      );
      results.push(result);
    }

    return results;
  }

  // الحصول على إحصائيات الحالات
  async getStatusStatistics() {
    try {
      const { data, error } = await this.supabase
        .from('orders')
        .select('waseet_status_id, waseet_status_text, status')
        .not('waseet_status_id', 'is', null);

      if (error) {
        throw new Error(`خطأ في جلب الإحصائيات: ${error.message}`);
      }

      const stats = {};
      
      data.forEach(order => {
        const statusId = order.waseet_status_id;
        if (!stats[statusId]) {
          stats[statusId] = {
            id: statusId,
            text: order.waseet_status_text,
            count: 0,
            appStatus: order.status
          };
        }
        stats[statusId].count++;
      });

      return Object.values(stats).sort((a, b) => b.count - a.count);

    } catch (error) {
      console.error('❌ خطأ في جلب إحصائيات الحالات:', error.message);
      return [];
    }
  }

  // مزامنة الحالات مع قاعدة البيانات
  async syncStatusesToDatabase() {
    try {
      console.log('🔄 مزامنة حالات الوسيط مع قاعدة البيانات...');

      for (const status of this.approvedStatuses) {
        const { error } = await this.supabase
          .from('waseet_statuses')
          .upsert({
            id: status.id,
            status_text: status.text,
            status_category: status.category,
            is_active: true,
            updated_at: new Date().toISOString()
          });

        if (error) {
          console.error(`❌ خطأ في مزامنة الحالة ${status.id}:`, error.message);
        }
      }

      console.log('✅ تم مزامنة جميع الحالات بنجاح');
      return true;

    } catch (error) {
      console.error('❌ خطأ في مزامنة الحالات:', error.message);
      return false;
    }
  }

  // الحصول على الحالات حسب الفئة
  getStatusesByCategory(category) {
    return this.approvedStatuses.filter(status => status.category === category);
  }

  // الحصول على جميع الفئات
  getCategories() {
    const categories = [...new Set(this.approvedStatuses.map(status => status.category))];
    return categories.map(category => ({
      name: category,
      statuses: this.getStatusesByCategory(category)
    }));
  }

  // تصدير الحالات للتطبيق
  exportStatusesForApp() {
    return {
      total: this.approvedStatuses.length,
      categories: this.getCategories(),
      statuses: this.approvedStatuses.map(status => ({
        id: status.id,
        text: status.text,
        category: status.category,
        appStatus: status.appStatus
      }))
    };
  }

  // التحقق من تطابق حالة مع الوسيط
  validateStatusUpdate(orderId, waseetStatusId, waseetStatusText) {
    const errors = [];

    if (!orderId) {
      errors.push('رقم الطلب مطلوب');
    }

    if (!waseetStatusId) {
      errors.push('رقم حالة الوسيط مطلوب');
    }

    if (!this.isValidWaseetStatus(waseetStatusId)) {
      errors.push(`حالة الوسيط ${waseetStatusId} غير معتمدة`);
    }

    const statusInfo = this.getStatusById(waseetStatusId);
    if (statusInfo && waseetStatusText && statusInfo.text !== waseetStatusText) {
      console.warn(`⚠️ تحذير: نص الحالة لا يطابق المتوقع`);
      console.warn(`   المتوقع: ${statusInfo.text}`);
      console.warn(`   المستلم: ${waseetStatusText}`);
    }

    return {
      isValid: errors.length === 0,
      errors: errors
    };
  }
}

// تصدير مثيل واحد من المدير (Singleton)
const waseetStatusManager = new WaseetStatusManager();

module.exports = waseetStatusManager;
