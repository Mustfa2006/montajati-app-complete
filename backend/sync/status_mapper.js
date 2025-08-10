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

      // حالات شركة الوسيط بالعربي والـ ID - تحويل إلى الحالات الصحيحة
      'فعال': 'active',
      '1': 'active', // فعال

      // حالات المعالجة - الاحتفاظ بالحالة الأصلية بدلاً من تحويلها إلى active
      'تم تغيير محافظة الزبون': 'تم تغيير محافظة الزبون',
      '24': 'تم تغيير محافظة الزبون',
      'تغيير المندوب': 'تغيير المندوب',
      '42': 'تغيير المندوب',
      'لا يرد': 'لا يرد',
      '25': 'لا يرد',
      'لا يرد بعد الاتفاق': 'لا يرد بعد الاتفاق',
      '26': 'لا يرد بعد الاتفاق',
      'مغلق': 'مغلق',
      '27': 'مغلق',
      'مغلق بعد الاتفاق': 'مغلق بعد الاتفاق',
      '28': 'مغلق بعد الاتفاق',
      'مؤجل': 'مؤجل',
      '29': 'مؤجل',
      'مؤجل لحين اعادة الطلب لاحقا': 'مؤجل لحين اعادة الطلب لاحقا',
      '30': 'مؤجل لحين اعادة الطلب لاحقا',
      'الرقم غير معرف': 'الرقم غير معرف',
      '36': 'الرقم غير معرف',
      'الرقم غير داخل في الخدمة': 'الرقم غير داخل في الخدمة',
      '37': 'الرقم غير داخل في الخدمة',
      'لا يمكن الاتصال بالرقم': 'لا يمكن الاتصال بالرقم',
      '41': 'لا يمكن الاتصال بالرقم',
      'العنوان غير دقيق': 'العنوان غير دقيق',
      '38': 'العنوان غير دقيق',
      'لم يطلب': 'لم يطلب',
      '39': 'لم يطلب',
      'حظر المندوب': 'حظر المندوب',
      '40': 'حظر المندوب',

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

      // ✅ إضافة الحالة المفقودة الأساسية
      '4': 'delivered', // تم التسليم للزبون
      'تم التسليم للزبون': 'delivered', // النص العربي الكامل

      // حالات الإلغاء - الاحتفاظ بالحالة الأصلية
      'cancelled': 'cancelled',
      'canceled': 'cancelled',
      'rejected': 'cancelled',
      'failed': 'cancelled',
      'returned': 'cancelled',
      'refunded': 'cancelled',
      'الغاء الطلب': 'الغاء الطلب',
      '31': 'الغاء الطلب',
      'رفض الطلب': 'رفض الطلب',
      '32': 'رفض الطلب',
      'مفصول عن الخدمة': 'مفصول عن الخدمة',
      '33': 'مفصول عن الخدمة',
      'تم الارجاع الى التاجر': 'تم الارجاع الى التاجر',
      '43': 'تم الارجاع الى التاجر',
      'طلب مكرر': 'طلب مكرر',
      '34': 'طلب مكرر',
      'مستلم مسبقا': 'مستلم مسبقا',
      '35': 'مستلم مسبقا',

      // ✅ إصلاح حالات الإرجاع والإلغاء - تحويل إلى "الغاء الطلب"
      'ارسال الى مخزن الارجاعات': 'cancelled',
      '23': 'cancelled', // ارسال الى مخزن الارجاعات → الغاء الطلب
      'ارسال الى مخزن الارجاع': 'cancelled', // نسخة مختصرة → الغاء الطلب
      'مخزن الارجاعات': 'cancelled', // نسخة مختصرة → الغاء الطلب
      'مخزن الارجاع': 'cancelled', // نسخة مختصرة → الغاء الطلب

      'تم الارجاع الى التاجر': 'cancelled',
      '17': 'cancelled' // تم الارجاع الى التاجر
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
    // ✅ قائمة موحدة للحالات النهائية (محلية + عربية)
    const finalStatuses = [
      // الحالات المحلية
      'delivered',
      'cancelled',

      // النصوص العربية الكاملة
      'تم التسليم للزبون',
      'الغاء الطلب', // ✅ هذا ما يظهر في التطبيق
      'رفض الطلب',
      'تم الارجاع الى التاجر',
      'مفصول عن الخدمة',
      'طلب مكرر',
      'حظر المندوب',
      'مستلم مسبقا'

      // ملاحظة: "ارسال الى مخزن الارجاعات" يتم تحويلها إلى "الغاء الطلب"
    ];

    return finalStatuses.includes(status);
  }

  // ===================================
  // الحصول على قائمة الحالات النهائية
  // ===================================
  getFinalStatuses() {
    return [
      // الحالات المحلية
      'delivered',
      'cancelled',

      // النصوص العربية الكاملة
      'تم التسليم للزبون',
      'الغاء الطلب', // ✅ هذا ما يظهر في التطبيق
      'رفض الطلب',
      'تم الارجاع الى التاجر',
      'مفصول عن الخدمة',
      'طلب مكرر',
      'حظر المندوب',
      'مستلم مسبقا'

      // ملاحظة: "ارسال الى مخزن الارجاعات" يتم تحويلها إلى "الغاء الطلب"
    ];
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
