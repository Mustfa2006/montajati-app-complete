// ===================================
// خدمة الإشعارات التلقائية
// إرسال إشعارات Firebase عند تحديث حالات الطلبات
// ===================================

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class NotificationService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // تهيئة Firebase للإشعارات
    this.initialized = false;
    this.initializeFirebase();
  }

  // تهيئة Firebase Admin SDK
  initializeFirebase() {
    try {
      if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
        console.error('❌ متغير FIREBASE_SERVICE_ACCOUNT مفقود');
        return;
      }

      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

      // تهيئة Firebase Admin إذا لم يكن مُهيأ
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
      }

      this.initialized = true;
      console.log('✅ تم تهيئة Firebase Admin SDK للإشعارات');
    } catch (error) {
      console.error('❌ خطأ في تهيئة Firebase:', error.message);
      this.initialized = false;
    }
  }

  // إرسال إشعار تحديث حالة الطلب
  // ❌ تم تعطيل هذه الدالة - الإشعارات تُرسل من integrated_waseet_sync.js فقط
  async sendStatusUpdateNotification(order, newStatus) {
    console.log(`⏭️ تم تجاهل إشعار من notifier.js - الإشعارات تُرسل من integrated_waseet_sync.js فقط`);
    return;

// الكود القديم (معطل):
/*
if (!this.initialized) {
  console.log('⚠️ Firebase غير مُهيأ - لن يتم إرسال إشعار');
  return;
}

try {
  console.log(`📤 إرسال إشعار تحديث حالة الطلب ${order.id} إلى ${newStatus}`);

  // 🚫 تجاهل إشعار حالة "confirmed" (تثبيت الطلب)
  if (newStatus === 'confirmed' || newStatus === 'فعال') {
    console.log('🚫 تم تجاهل إشعار تثبيت الطلب');
    return;
  }

  // الحصول على FCM token للمستخدم
  const { data: fcmTokens, error } = await this.supabase
    .from('fcm_tokens')
    .select('fcm_token')
    .eq('user_phone', order.user_phone || order.customer_phone)
    .eq('is_active', true);

  if (error) {
    console.error('❌ خطأ في الحصول على FCM tokens:', error.message);
    return;
  }

  if (!fcmTokens || fcmTokens.length === 0) {
    console.log(`⚠️ لا توجد FCM tokens للمستخدم ${order.user_phone || order.customer_phone}`);
    return;
  }

  // رسائل الحالات الجديدة
  const customerName = order.customer_name || 'عزيزي العميل';

  let notification = {};

  if (newStatus === 'in_delivery') {
    notification = {
      title: '🚗 قيد التوصيل',
      body: `${customerName} - قيد التوصيل`
    };
  } else if (newStatus === 'delivered') {
    notification = {
      title: '😊 تم التوصيل',
      body: `${customerName} - تم التوصيل`
    };
  } else if (newStatus === 'cancelled') {
    notification = {
      title: '😢 ملغي',
      body: `${customerName} - ملغي`
    };
  } else {
    // للحالات الأخرى (pending, confirmed, etc.)
    const statusMessages = {
      'pending': 'في انتظار التأكيد',
      'confirmed': 'تم تأكيد الطلب'
    };
    const statusMessage = statusMessages[newStatus] || newStatus;
    notification = {
      title: '📦 تحديث حالة طلبك',
      body: `${customerName} - ${statusMessage}`
    };
  }

  const data = {
    type: 'order_status_update',
    orderId: order.id,
    newStatus: newStatus,
    orderNumber: order.order_number || order.id.substring(0, 8)
  };

  // إرسال الإشعار لجميع tokens المستخدم
  for (const tokenData of fcmTokens) {
    try {
      const message = {
        token: tokenData.fcm_token,
        notification: notification,
        data: data
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ تم إرسال إشعار بنجاح: ${response}`);

      // تحديث آخر استخدام للـ token
      await this.supabase
        .from('fcm_tokens')
        .update({ last_used_at: new Date().toISOString() })
        .eq('fcm_token', tokenData.fcm_token);

    } catch (sendError) {
      console.error(`❌ خطأ في إرسال الإشعار: ${sendError.message}`);

      // إذا كان Token غير صحيح، قم بتعطيله
      if (sendError.code === 'messaging/registration-token-not-registered' ||
          sendError.code === 'messaging/invalid-registration-token') {
        await this.supabase
          .from('fcm_tokens')
          .update({ is_active: false })
          .eq('fcm_token', tokenData.fcm_token);
      }
    }
  }

} catch (error) {
  console.error('❌ خطأ في إرسال إشعار تحديث الحالة:', error.message);
}
}
}



// تصدير مثيل واحد من الخدمة (Singleton)
const notifier = new NotificationService();

module.exports = notifier;


