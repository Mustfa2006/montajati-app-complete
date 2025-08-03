// ===================================
// اختبار إرسال إشعار تجريبي
// Test Notification Script
// ===================================

const { firebaseAdminService } = require('./backend/services/firebase_admin_service');

async function sendTestNotification() {
  try {
    console.log('🔥 بدء اختبار الإشعار...');

    // تهيئة Firebase
    const initialized = await firebaseAdminService.initialize();
    if (!initialized) {
      throw new Error('فشل في تهيئة Firebase');
    }

    // ⚠️ ضع FCM Token الخاص بجهازك هنا
    // يمكنك الحصول عليه من التطبيق أو من قاعدة البيانات
    const testFCMToken = 'YOUR_FCM_TOKEN_HERE';

    // إعداد الإشعار التجريبي
    const notification = {
      title: '🎯 اختبار الصورة الجديدة',
      body: 'مرحباً! هذا اختبار لشعار منتجاتي الجديد 🚀'
    };

    const additionalData = {
      type: 'test',
      test_id: Date.now().toString()
    };

    // إرسال الإشعار
    console.log('📤 إرسال الإشعار التجريبي...');
    const result = await firebaseAdminService.sendNotificationToUser(
      testFCMToken,
      notification,
      additionalData
    );

    if (result.success) {
      console.log('✅ تم إرسال الإشعار بنجاح!');
      console.log('📋 Message ID:', result.messageId);
      console.log('🕐 الوقت:', result.timestamp);
      console.log('🖼️ الصورة: https://clownfish-app-krnk9.ondigitalocean.app/assets/montajati-logo.png');
    } else {
      console.error('❌ فشل في إرسال الإشعار:', result.error);
    }

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

// تشغيل الاختبار
sendTestNotification();
