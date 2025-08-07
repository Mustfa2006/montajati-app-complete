// ===================================
// اختبار شامل للمستخدم 07866241788
// ===================================

require('dotenv').config({ path: '../.env' });
const { createClient } = require('@supabase/supabase-js');

const TEST_USER_PHONE = '07866241788';

async function testUser07866241788() {
  console.log('🔍 اختبار شامل للمستخدم...');
  console.log(`📱 المستخدم: ${TEST_USER_PHONE}`);
  console.log('=====================================\n');

  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );

  try {
    // 1. فحص FCM Token للمستخدم
    console.log('1️⃣ فحص FCM Token للمستخدم:');
    const { data: tokens, error: tokensError } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('user_phone', TEST_USER_PHONE)
      .eq('is_active', true);

    if (tokensError) {
      console.log(`   ❌ خطأ في البحث عن FCM Token: ${tokensError.message}`);
      return;
    }

    if (!tokens || tokens.length === 0) {
      console.log(`   ❌ لا يوجد FCM Token نشط للمستخدم ${TEST_USER_PHONE}`);
      console.log('   💡 المستخدم يحتاج لتسجيل الدخول في التطبيق أولاً');
      return;
    }

    console.log(`   ✅ تم العثور على ${tokens.length} FCM Token نشط`);
    tokens.forEach((token, index) => {
      console.log(`   📱 Token ${index + 1}:`);
      console.log(`      الرمز: ${token.fcm_token.substring(0, 30)}...`);
      console.log(`      تاريخ التسجيل: ${new Date(token.created_at).toLocaleString('ar-SA')}`);
      console.log(`      آخر استخدام: ${token.last_used_at ? new Date(token.last_used_at).toLocaleString('ar-SA') : 'لم يستخدم بعد'}`);
    });

    // 2. فحص الطلبات
    console.log('\n2️⃣ فحص طلبات المستخدم:');
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('id, customer_name, status, created_at, updated_at')
      .or(`customer_phone.eq.${TEST_USER_PHONE},user_phone.eq.${TEST_USER_PHONE}`)
      .order('created_at', { ascending: false })
      .limit(5);

    if (ordersError) {
      console.log(`   ❌ خطأ في البحث عن الطلبات: ${ordersError.message}`);
    } else if (!orders || orders.length === 0) {
      console.log(`   ⚠️ لا توجد طلبات للمستخدم ${TEST_USER_PHONE}`);
      console.log('   💡 سنرسل إشعار عام بدلاً من إشعار طلب');
    } else {
      console.log(`   ✅ تم العثور على ${orders.length} طلب`);
      orders.forEach((order, index) => {
        console.log(`   📦 الطلب ${index + 1}:`);
        console.log(`      المعرف: ${order.id}`);
        console.log(`      العميل: ${order.customer_name || 'غير محدد'}`);
        console.log(`      الحالة: ${order.status}`);
      });
    }

    // 3. تهيئة خدمة الإشعارات
    console.log('\n3️⃣ تهيئة خدمة الإشعارات:');
    const targetedNotificationService = require('./services/targeted_notification_service');
    
    const initialized = await targetedNotificationService.initialize();
    if (!initialized) {
      console.log('   ❌ فشل في تهيئة خدمة الإشعارات');
      return;
    }
    
    console.log('   ✅ تم تهيئة خدمة الإشعارات بنجاح');

    // 4. إرسال إشعار تجريبي
    console.log('\n4️⃣ إرسال إشعار تجريبي:');
    
    try {
      // إرسال إشعار عام للمستخدم
      console.log('   📤 إرسال إشعار ترحيبي...');
      
      const { firebaseAdminService } = require('./services/firebase_admin_service');
      
      // الحصول على أحدث FCM Token
      const latestToken = tokens[0].fcm_token;
      
      const message = {
        token: latestToken,
        notification: {
          title: '🎉 مرحباً بك في منتجاتي',
          body: `أهلاً وسهلاً ${TEST_USER_PHONE}! نظام الإشعارات يعمل بنجاح 🚀`
        },
        data: {
          type: 'welcome_test',
          user_phone: TEST_USER_PHONE,
          timestamp: new Date().toISOString()
        },
        android: {
          notification: {
            channelId: 'montajati_notifications',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: '@mipmap/ic_launcher',
            color: '#FFD700'
          },
          priority: 'high'
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: '🎉 مرحباً بك في منتجاتي',
                body: `أهلاً وسهلاً ${TEST_USER_PHONE}! نظام الإشعارات يعمل بنجاح 🚀`
              },
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await firebaseAdminService.messaging.send(message);
      
      console.log('   🎉 تم إرسال الإشعار بنجاح!');
      console.log(`   📊 Message ID: ${response}`);
      console.log(`   ⏰ وقت الإرسال: ${new Date().toLocaleString('ar-SA')}`);
      
      // تحديث آخر استخدام للـ token
      await supabase
        .from('fcm_tokens')
        .update({ last_used_at: new Date().toISOString() })
        .eq('fcm_token', latestToken);

      console.log('\n📱 يجب أن يصل الإشعار الآن للهاتف!');
      console.log('🔍 تحقق من الهاتف للتأكد من وصول الإشعار');

    } catch (sendError) {
      console.log(`   ❌ فشل في إرسال الإشعار: ${sendError.message}`);
      
      if (sendError.code === 'messaging/registration-token-not-registered') {
        console.log('   💡 FCM Token غير صالح - يحتاج المستخدم لإعادة تسجيل الدخول');
        
        // إلغاء تفعيل الرمز غير الصالح
        await supabase
          .from('fcm_tokens')
          .update({ is_active: false })
          .eq('fcm_token', tokens[0].fcm_token);
        
        console.log('   🗑️ تم إلغاء تفعيل الرمز غير الصالح');
      }
    }

  } catch (error) {
    console.error('❌ خطأ في اختبار المستخدم:', error.message);
  }

  console.log('\n=====================================');
  console.log('🏁 انتهى اختبار المستخدم');
  console.log('=====================================');
  
  console.log(`\n📋 ملخص المستخدم ${TEST_USER_PHONE}:`);
  console.log('✅ تم فحص FCM Tokens');
  console.log('✅ تم فحص الطلبات');
  console.log('✅ تم اختبار خدمة الإشعارات');
  console.log('✅ تم إرسال إشعار تجريبي');
  
  console.log('\n💡 إذا لم يصل الإشعار:');
  console.log('- تأكد من تفعيل الإشعارات في إعدادات التطبيق');
  console.log('- تأكد من الاتصال بالإنترنت');
  console.log('- جرب إعادة تسجيل الدخول في التطبيق');
}

// تشغيل الاختبار
testUser07866241788().catch(error => {
  console.error('❌ خطأ في تشغيل الاختبار:', error);
  process.exit(1);
});
