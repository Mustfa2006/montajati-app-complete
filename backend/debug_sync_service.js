// ===================================
// تشخيص مفصل لخدمة المزامنة
// Detailed Sync Service Diagnosis
// ===================================

require('dotenv').config();

async function debugSyncService() {
  console.log('🔍 تشخيص مفصل لخدمة المزامنة...');
  console.log('='.repeat(60));

  try {
    // المرحلة 1: فحص متغيرات البيئة
    console.log('\n📋 المرحلة 1: فحص متغيرات البيئة');
    console.log('='.repeat(40));
    
    console.log(`NODE_ENV: ${process.env.NODE_ENV || 'غير محدد'}`);
    console.log(`SUPABASE_URL: ${process.env.SUPABASE_URL ? '✅ موجود' : '❌ غير موجود'}`);
    console.log(`SUPABASE_SERVICE_ROLE_KEY: ${process.env.SUPABASE_SERVICE_ROLE_KEY ? '✅ موجود' : '❌ غير موجود'}`);
    console.log(`WASEET_USERNAME: ${process.env.WASEET_USERNAME ? '✅ موجود' : '❌ غير موجود'}`);
    console.log(`WASEET_PASSWORD: ${process.env.WASEET_PASSWORD ? '✅ موجود' : '❌ غير موجود'}`);

    // المرحلة 2: اختبار تحميل WaseetAPIClient
    console.log('\n🔧 المرحلة 2: اختبار تحميل WaseetAPIClient');
    console.log('='.repeat(40));
    
    try {
      console.log('📦 محاولة تحميل WaseetAPIClient...');
      const WaseetAPIClient = require('./services/waseet_api_client');
      console.log('✅ تم تحميل WaseetAPIClient بنجاح');
      
      console.log('🔧 محاولة إنشاء instance من WaseetAPIClient...');
      const waseetClient = new WaseetAPIClient();
      console.log('✅ تم إنشاء instance بنجاح');
      console.log(`🔧 حالة التهيئة: ${waseetClient.isConfigured ? '✅ مهيأ' : '❌ غير مهيأ'}`);
      
    } catch (error) {
      console.error('❌ خطأ في تحميل WaseetAPIClient:', error.message);
      console.error('📋 تفاصيل الخطأ:', error.stack);
      return false;
    }

    // المرحلة 3: اختبار تحميل OrderSyncService
    console.log('\n🔄 المرحلة 3: اختبار تحميل OrderSyncService');
    console.log('='.repeat(40));
    
    try {
      console.log('📦 محاولة تحميل OrderSyncService...');
      const OrderSyncService = require('./services/order_sync_service');
      console.log('✅ تم تحميل OrderSyncService بنجاح');
      
      console.log('🔧 محاولة إنشاء instance من OrderSyncService...');
      const syncService = new OrderSyncService();
      console.log('✅ تم إنشاء instance بنجاح');
      console.log(`🔧 حالة التهيئة: ${syncService.isInitialized ? '✅ مهيأ' : '❌ غير مهيأ'}`);
      
      if (syncService.waseetClient) {
        console.log(`🔧 عميل الوسيط: ${syncService.waseetClient.isConfigured ? '✅ مهيأ' : '❌ غير مهيأ'}`);
      } else {
        console.log('❌ عميل الوسيط غير موجود');
      }
      
      // اختبار الدوال
      console.log('\n🧪 اختبار الدوال المتاحة:');
      console.log(`sendOrderToWaseet: ${typeof syncService.sendOrderToWaseet === 'function' ? '✅ موجود' : '❌ غير موجود'}`);
      console.log(`retryFailedOrders: ${typeof syncService.retryFailedOrders === 'function' ? '✅ موجود' : '❌ غير موجود'}`);
      
    } catch (error) {
      console.error('❌ خطأ في تحميل OrderSyncService:', error.message);
      console.error('📋 تفاصيل الخطأ:', error.stack);
      return false;
    }

    // المرحلة 4: محاكاة تهيئة الخدمة كما في server.js
    console.log('\n🚀 المرحلة 4: محاكاة تهيئة الخدمة');
    console.log('='.repeat(40));
    
    try {
      console.log('🔄 بدء تهيئة خدمة مزامنة الطلبات مع الوسيط...');

      // استيراد خدمة المزامنة
      console.log('📦 استيراد OrderSyncService...');
      const OrderSyncService = require('./services/order_sync_service');
      console.log('✅ تم استيراد OrderSyncService بنجاح');

      // إنشاء instance من الخدمة
      console.log('🔧 إنشاء instance من OrderSyncService...');
      const syncService = new OrderSyncService();
      console.log('✅ تم إنشاء instance بنجاح');

      // التحقق من حالة التهيئة
      if (syncService.isInitialized === false) {
        console.warn('⚠️ خدمة المزامنة مهيأة لكن عميل الوسيط غير مهيأ (بيانات المصادقة ناقصة)');
        console.warn('💡 يرجى إضافة WASEET_USERNAME و WASEET_PASSWORD في متغيرات البيئة');
      } else {
        console.log('✅ خدمة المزامنة مهيأة بالكامل مع عميل الوسيط');
      }

      global.orderSyncService = syncService;
      console.log('✅ تم تهيئة خدمة مزامنة الطلبات مع الوسيط بنجاح');
      
      // فحص global.orderSyncService
      console.log('\n🔍 فحص global.orderSyncService:');
      console.log(`موجود: ${global.orderSyncService ? '✅ نعم' : '❌ لا'}`);
      if (global.orderSyncService) {
        console.log(`isInitialized: ${global.orderSyncService.isInitialized}`);
        console.log(`waseetClient: ${global.orderSyncService.waseetClient ? 'موجود' : 'غير موجود'}`);
        if (global.orderSyncService.waseetClient) {
          console.log(`waseetClient.isConfigured: ${global.orderSyncService.waseetClient.isConfigured}`);
        }
      }
      
      return true;

    } catch (error) {
      console.error('❌ خطأ في تهيئة خدمة مزامنة الطلبات مع الوسيط:', error.message);
      console.error('📋 تفاصيل الخطأ:', error.stack);

      // إنشاء خدمة مزامنة احتياطية
      console.log('🔧 إنشاء خدمة مزامنة احتياطية...');
      global.orderSyncService = {
        isInitialized: false,
        waseetClient: null,
        sendOrderToWaseet: async (orderId) => {
          console.log(`📦 محاولة إرسال الطلب ${orderId} للوسيط...`);
          console.error('❌ خدمة المزامنة غير متاحة:', error.message);
          return {
            success: false,
            error: `خطأ في خدمة المزامنة: ${error.message}`,
            needsConfiguration: true
          };
        }
      };

      console.log('⚠️ تم إنشاء خدمة مزامنة احتياطية');
      return false;
    }

  } catch (error) {
    console.error('❌ خطأ عام في التشخيص:', error);
    return false;
  }
}

// تشغيل التشخيص
debugSyncService()
  .then((result) => {
    console.log('\n🎯 النتيجة النهائية:');
    console.log('='.repeat(60));
    if (result) {
      console.log('🎉 جميع الاختبارات نجحت! خدمة المزامنة تعمل بشكل صحيح');
    } else {
      console.log('❌ هناك مشكلة في خدمة المزامنة - تحتاج إصلاح');
    }
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل التشخيص:', error);
  });
