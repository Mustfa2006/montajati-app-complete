// ===================================
// خريطة تحويل حالات الطلبات
// تحويل حالات شركة الوسيط إلى الحالات المحلية
// ===================================

class StatusMapper {
  constructor() {
    // خريطة تحويل حالات شركة الوسيط إلى الحالات المحلية
    this.waseetToLocalMap = {
      // حالات الطلب الجديد والمؤكد
      'pending': 'active',
      'confirmed': 'active',
      'accepted': 'active',
      'processing': 'active',
      'prepared': 'active',

      // حالات شركة الوسيط بالعربي والـ ID
      'فعال': 'active',
      '1': 'active', // فعال
      'تم تغيير محافظة الزبون': 'active',
      '24': 'active', // تم تغيير محافظة الزبون
      'تغيير المندوب': 'active',
      '42': 'active', // تغيير المندوب
      'لا يرد': 'active',
      '25': 'active', // لا يرد
      'لا يرد بعد الاتفاق': 'active',
      '26': 'active', // لا يرد بعد الاتفاق
      'مغلق': 'active',
      '27': 'active', // مغلق
      'مغلق بعد الاتفاق': 'active',
      '28': 'active', // مغلق بعد الاتفاق
      'مؤجل': 'active',
      '29': 'active', // مؤجل
      'مؤجل لحين اعادة الطلب لاحقا': 'active',
      '30': 'active', // مؤجل لحين اعادة الطلب لاحقا
      'الرقم غير معرف': 'active',
      '36': 'active', // الرقم غير معرف
      'الرقم غير داخل في الخدمة': 'active',
      '37': 'active', // الرقم غير داخل في الخدمة
      'لا يمكن الاتصال بالرقم': 'active',
      '41': 'active', // لا يمكن الاتصال بالرقم
      'العنوان غير دقيق': 'active',
      '38': 'active', // العنوان غير دقيق
      'لم يطلب': 'active',
      '39': 'active', // لم يطلب

      // حالات التوصيل
      'shipped': 'in_delivery',
      'sent': 'in_delivery',        // ✅ إضافة حالة sent
      'in_transit': 'in_delivery',
      'out_for_delivery': 'in_delivery',
      'on_the_way': 'in_delivery',
      'dispatched': 'in_delivery',
      'picked_up': 'in_delivery',
      'قيد التوصيل الى الزبون (في عهدة المندوب)': 'in_delivery',
      '3': 'in_delivery', // قيد التوصيل الى الزبون

      // حالات التسليم
      'delivered': 'delivered',
      'completed': 'delivered',
      'success': 'delivered',
      'received': 'delivered',
      'مستلم مسبقا': 'delivered',
      '35': 'delivered', // مستلم مسبقا

      // حالات الإلغاء
      'cancelled': 'cancelled',
      'canceled': 'cancelled',
      'rejected': 'cancelled',
      'failed': 'cancelled',
      'returned': 'cancelled',
      'refunded': 'cancelled',
      'الغاء الطلب': 'cancelled',
      '31': 'cancelled', // الغاء الطلب
      'رفض الطلب': 'cancelled',
      '32': 'cancelled', // رفض الطلب
      'مفصول عن الخدمة': 'cancelled',
      '33': 'cancelled', // مفصول عن الخدمة
      'طلب مكرر': 'cancelled',
      '34': 'cancelled', // طلب مكرر
      'حظر المندوب': 'cancelled',
      '40': 'cancelled', // حظر المندوب
      'ارسال الى مخزن الارجاعات': 'cancelled',
      '23': 'cancelled' // ارسال الى مخزن الارجاعات
    };

    // خريطة عكسية للتحويل من المحلي إلى الوسيط
    this.localToWaseetMap = {
      'active': 'confirmed',
      'in_delivery': 'shipped',
      'delivered': 'delivered',
      'cancelled': 'cancelled'
    };

    // أوصاف الحالات باللغة العربية
    this.statusDescriptions = {
      'active': 'نشط - في انتظار التوصيل',
      'in_delivery': 'قيد التوصيل',
      'delivered': 'تم التسليم',
      'cancelled': 'ملغي'
    };

    // رسائل الإشعارات للعملاء
    this.notificationMessages = {
      'active': 'تم تأكيد طلبك وهو قيد المعالجة',
      'in_delivery': 'طلبك في الطريق إليك',
      'delivered': 'تم تسليم طلبك بنجاح',
      'cancelled': 'تم إلغاء طلبك'
    };

    console.log('🗺️ تم تهيئة خريطة تحويل حالات الطلبات');
  }

  // ===================================
  // تحويل حالة من الوسيط إلى المحلية
  // ===================================
  mapWaseetToLocal(waseetStatus) {
    if (!waseetStatus) {
      console.warn('⚠️ تحذير: حالة الوسيط فارغة، استخدام الحالة الافتراضية');
      return 'active';
    }

    // تحويل إلى أحرف صغيرة وإزالة المسافات
    const normalizedStatus = waseetStatus.toString().toLowerCase().trim();
    
    // البحث في الخريطة
    const localStatus = this.waseetToLocalMap[normalizedStatus];
    
    if (localStatus) {
      console.log(`🔄 تحويل الحالة: ${waseetStatus} → ${localStatus}`);
      return localStatus;
    } else {
      console.warn(`⚠️ تحذير: حالة غير معروفة من الوسيط: ${waseetStatus}, استخدام الحالة الافتراضية`);
      return 'active'; // الحالة الافتراضية
    }
  }

  // ===================================
  // تحويل حالة من المحلية إلى الوسيط
  // ===================================
  mapLocalToWaseet(localStatus) {
    if (!localStatus) {
      console.warn('⚠️ تحذير: الحالة المحلية فارغة');
      return 'confirmed';
    }

    const waseetStatus = this.localToWaseetMap[localStatus];
    
    if (waseetStatus) {
      return waseetStatus;
    } else {
      console.warn(`⚠️ تحذير: حالة محلية غير معروفة: ${localStatus}`);
      return 'confirmed'; // الحالة الافتراضية
    }
  }

  // ===================================
  // الحصول على وصف الحالة
  // ===================================
  getStatusDescription(localStatus) {
    return this.statusDescriptions[localStatus] || 'حالة غير معروفة';
  }

  // ===================================
  // الحصول على رسالة الإشعار
  // ===================================
  getNotificationMessage(localStatus) {
    return this.notificationMessages[localStatus] || 'تم تحديث حالة طلبك';
  }

  // ===================================
  // التحقق من صحة الحالة المحلية
  // ===================================
  isValidLocalStatus(status) {
    return ['active', 'in_delivery', 'delivered', 'cancelled'].includes(status);
  }

  // ===================================
  // التحقق من أن الحالة تحتاج مزامنة
  // ===================================
  needsSync(status) {
    // الحالات التي تحتاج مزامنة مستمرة
    return ['active', 'in_delivery'].includes(status);
  }

  // ===================================
  // التحقق من أن الحالة نهائية
  // ===================================
  isFinalStatus(status) {
    // الحالات النهائية التي لا تتغير
    return ['delivered', 'cancelled'].includes(status);
  }

  // ===================================
  // الحصول على لون الحالة للواجهة
  // ===================================
  getStatusColor(status) {
    const colors = {
      'active': '#FFA500',      // برتقالي
      'in_delivery': '#2196F3', // أزرق
      'delivered': '#4CAF50',   // أخضر
      'cancelled': '#F44336'    // أحمر
    };
    
    return colors[status] || '#9E9E9E'; // رمادي للحالات غير المعروفة
  }

  // ===================================
  // الحصول على أيقونة الحالة
  // ===================================
  getStatusIcon(status) {
    const icons = {
      'active': '⏳',
      'in_delivery': '🚚',
      'delivered': '✅',
      'cancelled': '❌'
    };
    
    return icons[status] || '❓';
  }

  // ===================================
  // إحصائيات الخريطة
  // ===================================
  getMapStats() {
    return {
      waseet_statuses: Object.keys(this.waseetToLocalMap).length,
      local_statuses: Object.keys(this.localToWaseetMap).length,
      supported_statuses: Object.keys(this.statusDescriptions),
      final_statuses: Object.keys(this.statusDescriptions).filter(status => this.isFinalStatus(status)),
      sync_statuses: Object.keys(this.statusDescriptions).filter(status => this.needsSync(status))
    };
  }

  // ===================================
  // إضافة حالة جديدة للخريطة
  // ===================================
  addWaseetStatus(waseetStatus, localStatus) {
    if (!this.isValidLocalStatus(localStatus)) {
      throw new Error(`حالة محلية غير صحيحة: ${localStatus}`);
    }

    const normalizedWaseetStatus = waseetStatus.toLowerCase().trim();
    this.waseetToLocalMap[normalizedWaseetStatus] = localStatus;
    
    console.log(`✅ تم إضافة حالة جديدة: ${waseetStatus} → ${localStatus}`);
  }

  // ===================================
  // الحصول على جميع الحالات المدعومة
  // ===================================
  getAllSupportedStatuses() {
    return {
      waseet_statuses: Object.keys(this.waseetToLocalMap),
      local_statuses: Object.keys(this.localToWaseetMap),
      descriptions: this.statusDescriptions,
      notifications: this.notificationMessages
    };
  }

  // ===================================
  // تصدير تقرير الخريطة
  // ===================================
  exportMapReport() {
    const report = {
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      statistics: this.getMapStats(),
      mappings: {
        waseet_to_local: this.waseetToLocalMap,
        local_to_waseet: this.localToWaseetMap
      },
      descriptions: this.statusDescriptions,
      notifications: this.notificationMessages
    };

    return report;
  }
}

// تصدير مثيل واحد من الخريطة (Singleton)
const statusMapper = new StatusMapper();

module.exports = statusMapper;
