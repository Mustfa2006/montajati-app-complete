const express = require('express');
const router = express.Router();

/**
 * نظام تحديث التطبيق بدون APK جديد
 * App Update System without new APK
 */

// إعدادات التطبيق الحالية
let appConfig = {
  version: '1.0.0',
  build: 1,
  forceUpdate: false,
  maintenanceMode: false,
  
  // إعدادات المزامنة
  syncSettings: {
    intervalMinutes: 5,
    enableAutoSync: true,
    showWaseetStatus: true,
    statusDisplayMode: 'exact' // exact = عرض الحالة كما هي من الوسيط
  },
  
  // إعدادات الخادم
  serverSettings: {
    apiBaseUrl: 'https://clownfish-app-krnk9.ondigitalocean.app',
    enableNewFeatures: true,
    debugMode: false
  },
  
  // الحالات المدعومة من الوسيط
  supportedStatuses: [
    'تم التسليم للزبون',
    'لا يرد',
    'مغلق',
    'الغاء الطلب',
    'رفض الطلب',
    'قيد التوصيل الى الزبون (في عهدة المندوب)',
    'تم تغيير محافظة الزبون',
    'لا يرد بعد الاتفاق',
    'مغلق بعد الاتفاق',
    'مؤجل',
    'مؤجل لحين اعادة الطلب لاحقا',
    'مستلم مسبقا',
    'الرقم غير معرف',
    'الرقم غير داخل في الخدمة',
    'العنوان غير دقيق',
    'لم يطلب',
    'حظر المندوب',
    'لا يمكن الاتصال بالرقم',
    'تغيير المندوب'
  ],
  
  // رسائل للمستخدمين
  messages: {
    updateAvailable: 'يتوفر تحديث جديد للتطبيق',
    maintenanceMessage: 'التطبيق تحت الصيانة حالياً',
    newFeatureMessage: 'تم تحديث نظام عرض حالات الطلبات لتطابق الوسيط بدقة'
  },
  
  // آخر تحديث
  lastUpdated: new Date().toISOString()
};

// GET /api/app-config - جلب إعدادات التطبيق
router.get('/', (req, res) => {
  try {
    console.log('📱 طلب إعدادات التطبيق من:', req.ip);
    
    res.json({
      success: true,
      data: appConfig,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ خطأ في جلب إعدادات التطبيق:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في جلب الإعدادات'
    });
  }
});

// POST /api/app-config/update - تحديث إعدادات التطبيق
router.post('/update', (req, res) => {
  try {
    console.log('🔄 تحديث إعدادات التطبيق...');
    
    const updates = req.body;
    
    // دمج التحديثات مع الإعدادات الحالية
    appConfig = {
      ...appConfig,
      ...updates,
      lastUpdated: new Date().toISOString()
    };
    
    console.log('✅ تم تحديث إعدادات التطبيق');
    console.log('📋 الإعدادات الجديدة:', JSON.stringify(appConfig, null, 2));
    
    res.json({
      success: true,
      message: 'تم تحديث الإعدادات بنجاح',
      data: appConfig
    });
    
  } catch (error) {
    console.error('❌ خطأ في تحديث الإعدادات:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في تحديث الإعدادات'
    });
  }
});

// POST /api/app-config/force-update - فرض تحديث للمستخدمين
router.post('/force-update', (req, res) => {
  try {
    console.log('⚡ فرض تحديث للمستخدمين...');
    
    const { message, version } = req.body;
    
    appConfig.forceUpdate = true;
    appConfig.version = version || appConfig.version;
    appConfig.messages.updateAvailable = message || appConfig.messages.updateAvailable;
    appConfig.lastUpdated = new Date().toISOString();
    
    console.log('✅ تم تفعيل فرض التحديث');
    
    res.json({
      success: true,
      message: 'تم تفعيل فرض التحديث',
      data: appConfig
    });
    
  } catch (error) {
    console.error('❌ خطأ في فرض التحديث:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في فرض التحديث'
    });
  }
});

// POST /api/app-config/maintenance - تفعيل وضع الصيانة
router.post('/maintenance', (req, res) => {
  try {
    console.log('🔧 تفعيل وضع الصيانة...');
    
    const { enabled, message } = req.body;
    
    appConfig.maintenanceMode = enabled;
    if (message) {
      appConfig.messages.maintenanceMessage = message;
    }
    appConfig.lastUpdated = new Date().toISOString();
    
    console.log(`${enabled ? '✅ تم تفعيل' : '❌ تم إلغاء'} وضع الصيانة`);
    
    res.json({
      success: true,
      message: `تم ${enabled ? 'تفعيل' : 'إلغاء'} وضع الصيانة`,
      data: appConfig
    });
    
  } catch (error) {
    console.error('❌ خطأ في وضع الصيانة:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في وضع الصيانة'
    });
  }
});

// POST /api/app-config/sync-settings - تحديث إعدادات المزامنة
router.post('/sync-settings', (req, res) => {
  try {
    console.log('🔄 تحديث إعدادات المزامنة...');
    
    const { intervalMinutes, enableAutoSync, showWaseetStatus, statusDisplayMode } = req.body;
    
    if (intervalMinutes) appConfig.syncSettings.intervalMinutes = intervalMinutes;
    if (enableAutoSync !== undefined) appConfig.syncSettings.enableAutoSync = enableAutoSync;
    if (showWaseetStatus !== undefined) appConfig.syncSettings.showWaseetStatus = showWaseetStatus;
    if (statusDisplayMode) appConfig.syncSettings.statusDisplayMode = statusDisplayMode;
    
    appConfig.lastUpdated = new Date().toISOString();
    
    console.log('✅ تم تحديث إعدادات المزامنة');
    console.log('📋 الإعدادات الجديدة:', appConfig.syncSettings);
    
    res.json({
      success: true,
      message: 'تم تحديث إعدادات المزامنة',
      data: appConfig.syncSettings
    });
    
  } catch (error) {
    console.error('❌ خطأ في تحديث إعدادات المزامنة:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في تحديث إعدادات المزامنة'
    });
  }
});

// GET /api/app-config/status - حالة التطبيق
router.get('/status', (req, res) => {
  try {
    const status = {
      isOnline: true,
      maintenanceMode: appConfig.maintenanceMode,
      forceUpdate: appConfig.forceUpdate,
      version: appConfig.version,
      lastUpdated: appConfig.lastUpdated,
      serverTime: new Date().toISOString()
    };
    
    res.json({
      success: true,
      data: status
    });
    
  } catch (error) {
    console.error('❌ خطأ في جلب حالة التطبيق:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في جلب حالة التطبيق'
    });
  }
});

module.exports = router;
