// ===================================
// اختبار إرسال إشعار بسيط
// Simple Notification Test
// ===================================

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function testNotification() {
  try {
    console.log('🔥 تهيئة Firebase Admin...');
    
    // تهيئة Firebase
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });
      console.log('✅ تم تهيئة Firebase Admin بنجاح');
    }
    
    console.log('🗄️ الاتصال بقاعدة البيانات...');
    
    // جلب FCM tokens
    const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
    const { data: tokens, error } = await supabase
      .from('fcm_tokens')
      .select('fcm_token, user_phone, device_info')
      .eq('is_active', true)
      .order('created_at', { ascending: false });
    
    if (error) {
      console.log('❌ خطأ في جلب tokens:', error.message);
      return;
    }
    
    if (!tokens || tokens.length === 0) {
      console.log('❌ لا توجد FCM tokens في قاعدة البيانات');
      return;
    }
    
    console.log(`📊 تم العثور على ${tokens.length} FCM tokens`);
    
    // اختبار كل token
    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];
      console.log(`\n--- اختبار Token ${i + 1} ---`);
      console.log(`📱 المستخدم: ${token.user_phone}`);
      console.log(`🔑 Token: ${token.fcm_token.substring(0, 30)}...`);
      console.log(`📋 Device Info:`, token.device_info);
      
      // التحقق من صحة Token
      if (!token.fcm_token || token.fcm_token.length < 100) {
        console.log('⚠️ Token قصير جداً أو غير صحيح');
        continue;
      }
      
      try {
        const message = {
          token: token.fcm_token,
          notification: {
            title: '🧪 اختبار الإشعارات',
            body: `مرحباً! هذا إشعار تجريبي للمستخدم ${token.user_phone}`
          },
          data: {
            type: 'test',
            user_phone: token.user_phone,
            timestamp: new Date().toISOString()
          }
        };
        
        console.log('📤 إرسال الإشعار...');
        const response = await admin.messaging().send(message);
        console.log(`✅ تم إرسال الإشعار بنجاح: ${response}`);
        
        // تحديث آخر استخدام
        await supabase
          .from('fcm_tokens')
          .update({ last_used_at: new Date().toISOString() })
          .eq('fcm_token', token.fcm_token);
        
        console.log('✅ تم تحديث آخر استخدام للـ token');
        
      } catch (sendError) {
        console.log(`❌ خطأ في إرسال الإشعار: ${sendError.message}`);
        
        // إذا كان Token غير صحيح، قم بتعطيله
        if (sendError.code === 'messaging/registration-token-not-registered' || 
            sendError.code === 'messaging/invalid-registration-token') {
          console.log('🔄 تعطيل Token غير الصحيح...');
          await supabase
            .from('fcm_tokens')
            .update({ is_active: false })
            .eq('fcm_token', token.fcm_token);
          console.log('✅ تم تعطيل Token غير الصحيح');
        }
      }
      
      // تأخير قصير بين الإرسالات
      if (i < tokens.length - 1) {
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }
    
    console.log('\n✅ انتهى اختبار جميع الـ tokens');
    
  } catch (error) {
    console.log('❌ خطأ عام:', error.message);
  }
}

// تشغيل الاختبار
testNotification().catch(console.error);
