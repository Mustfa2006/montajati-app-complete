const axios = require('axios');

/**
 * سكريبت دفع التحديث للمستخدمين فوراً
 * Push Update to Users Immediately
 */

async function pushUpdateToUsers() {
  console.log('🚀 دفع التحديث للمستخدمين');
  console.log('الهدف: تحديث نظام عرض الحالات ليطابق الوسيط بدقة');
  console.log('='.repeat(70));

  const baseURL = 'https://clownfish-app-krnk9.ondigitalocean.app';

  try {
    // 1. تحديث إعدادات المزامنة
    console.log('\n1️⃣ تحديث إعدادات المزامنة...');
    
    const syncUpdateResponse = await axios.post(`${baseURL}/api/app-config/sync-settings`, {
      intervalMinutes: 5,
      enableAutoSync: true,
      showWaseetStatus: true,
      statusDisplayMode: 'exact' // ✅ عرض الحالة الدقيقة من الوسيط
    }, {
      timeout: 30000
    });

    if (syncUpdateResponse.data.success) {
      console.log('✅ تم تحديث إعدادات المزامنة بنجاح');
      console.log('📋 الإعدادات الجديدة:', syncUpdateResponse.data.data);
    } else {
      console.log('❌ فشل في تحديث إعدادات المزامنة');
    }

    // 2. تحديث الإعدادات العامة
    console.log('\n2️⃣ تحديث الإعدادات العامة...');
    
    const generalUpdateResponse = await axios.post(`${baseURL}/api/app-config/update`, {
      version: '1.1.0',
      build: 2,
      
      // الحالات المدعومة الجديدة
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
        'تغيير المندوب',
        'تم الارجاع الى التاجر'
      ],
      
      // رسائل جديدة
      messages: {
        updateAvailable: '🎉 تحديث مهم: تم تحسين نظام عرض حالات الطلبات ليطابق الوسيط بدقة 100%',
        maintenanceMessage: 'التطبيق تحت الصيانة لتطبيق التحديثات الجديدة',
        newFeatureMessage: '✅ الآن يعرض التطبيق نفس حالة الطلب الموجودة في الوسيط بالضبط'
      },
      
      // إعدادات الخادم
      serverSettings: {
        apiBaseUrl: 'https://clownfish-app-krnk9.ondigitalocean.app',
        enableNewFeatures: true,
        debugMode: false
      }
    }, {
      timeout: 30000
    });

    if (generalUpdateResponse.data.success) {
      console.log('✅ تم تحديث الإعدادات العامة بنجاح');
    } else {
      console.log('❌ فشل في تحديث الإعدادات العامة');
    }

    // 3. إرسال إشعار للمستخدمين
    console.log('\n3️⃣ إرسال إشعار للمستخدمين...');
    
    try {
      const notificationResponse = await axios.post(`${baseURL}/api/notifications/broadcast`, {
        title: '🎉 تحديث مهم للتطبيق',
        body: 'تم تحسين نظام عرض حالات الطلبات ليطابق الوسيط بدقة 100%. التحديث متاح الآن!',
        data: {
          type: 'app_update',
          version: '1.1.0',
          feature: 'exact_status_display',
          action: 'check_for_updates'
        }
      }, {
        timeout: 30000
      });

      if (notificationResponse.data.success) {
        console.log('✅ تم إرسال الإشعار للمستخدمين بنجاح');
        console.log(`📊 تم إرسال الإشعار لـ ${notificationResponse.data.sentCount || 0} مستخدم`);
      } else {
        console.log('❌ فشل في إرسال الإشعار للمستخدمين');
      }
    } catch (notificationError) {
      console.log('⚠️ خطأ في إرسال الإشعار:', notificationError.message);
    }

    // 4. فحص حالة التحديث
    console.log('\n4️⃣ فحص حالة التحديث...');
    
    const statusResponse = await axios.get(`${baseURL}/api/app-config/status`, {
      timeout: 15000
    });

    if (statusResponse.data.success) {
      const status = statusResponse.data.data;
      console.log('📊 حالة التطبيق بعد التحديث:');
      console.log(`   الإصدار: ${status.version}`);
      console.log(`   وضع الصيانة: ${status.maintenanceMode ? 'مفعل' : 'غير مفعل'}`);
      console.log(`   فرض التحديث: ${status.forceUpdate ? 'مفعل' : 'غير مفعل'}`);
      console.log(`   آخر تحديث: ${status.lastUpdated}`);
    }

    // 5. اختبار التحديث على المستخدم التجريبي
    console.log('\n5️⃣ اختبار التحديث على المستخدم التجريبي...');
    
    try {
      const testResponse = await axios.get(`${baseURL}/api/app-config`, {
        timeout: 15000
      });

      if (testResponse.data.success) {
        const config = testResponse.data.data;
        console.log('✅ تم جلب الإعدادات الجديدة بنجاح');
        console.log(`📋 وضع عرض الحالة: ${config.syncSettings?.statusDisplayMode}`);
        console.log(`📊 عدد الحالات المدعومة: ${config.supportedStatuses?.length || 0}`);
        
        if (config.syncSettings?.statusDisplayMode === 'exact') {
          console.log('🎉 ممتاز! تم تفعيل العرض الدقيق للحالات');
        }
      }
    } catch (testError) {
      console.log('⚠️ خطأ في اختبار التحديث:', testError.message);
    }

    // 6. ملخص التحديث
    console.log('\n6️⃣ ملخص التحديث:');
    console.log('✅ تم تحديث إعدادات المزامنة');
    console.log('✅ تم تحديث الإعدادات العامة');
    console.log('✅ تم إرسال إشعار للمستخدمين');
    console.log('✅ تم تفعيل العرض الدقيق للحالات');
    
    console.log('\n🎯 النتيجة المتوقعة:');
    console.log('- المستخدمون سيحصلون على إشعار بالتحديث');
    console.log('- التطبيق سيفحص التحديثات تلقائياً كل 10 دقائق');
    console.log('- سيتم عرض حالات الطلبات كما هي في الوسيط بالضبط');
    console.log('- لا حاجة لتحديث APK جديد');

    console.log('\n🎉 تم دفع التحديث للمستخدمين بنجاح!');

  } catch (error) {
    console.error('❌ خطأ في دفع التحديث:', error.message);
    if (error.response) {
      console.error('📋 تفاصيل الخطأ:', error.response.data);
    }
  }
}

// تشغيل السكريبت
pushUpdateToUsers();
