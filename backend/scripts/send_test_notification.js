#!/usr/bin/env node

// ✅ إرسال إشعار تجريبي لاختبار النظام
// Send Test Notification Script
// تاريخ الإنشاء: 2024-12-20

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const FirebaseAdminService = require('../services/firebase_admin_service');

class TestNotificationSender {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    this.firebaseService = new FirebaseAdminService();
  }

  /**
   * إرسال إشعار تجريبي لمستخدم محدد
   */
  async sendTestNotification(userPhone, customMessage = null) {
    console.log('📤 بدء إرسال إشعار تجريبي...\n');

    try {
      // تهيئة Firebase
      console.log('🔥 تهيئة Firebase...');
      const initialized = await this.firebaseService.initialize();
      if (!initialized) {
        throw new Error('فشل في تهيئة Firebase');
      }
      console.log('✅ تم تهيئة Firebase بنجاح');

      // البحث عن FCM tokens للمستخدم
      console.log(`📱 البحث عن FCM tokens للمستخدم: ${userPhone}...`);
      const { data: tokens, error } = await this.supabase
        .from('fcm_tokens')
        .select('fcm_token, device_info, last_used_at')
        .eq('user_phone', userPhone)
        .eq('is_active', true)
        .order('last_used_at', { ascending: false });

      if (error) {
        throw new Error(`خطأ في البحث عن tokens: ${error.message}`);
      }

      if (!tokens || tokens.length === 0) {
        console.log('❌ لم يتم العثور على FCM tokens نشطة لهذا المستخدم');
        console.log('💡 تأكد من:');
        console.log('   - تسجيل المستخدم في التطبيق');
        console.log('   - تفعيل الإشعارات في التطبيق');
        console.log('   - اتصال التطبيق بالإنترنت');
        return false;
      }

      console.log(`✅ تم العثور على ${tokens.length} FCM token(s)`);

      // إعداد الإشعار
      const notification = {
        title: '🎉 إشعار تجريبي من منتجاتي',
        body: customMessage || `مرحباً! هذا إشعار تجريبي تم إرساله في ${new Date().toLocaleString('ar-SA')}`
      };

      const data = {
        type: 'test_notification',
        timestamp: new Date().toISOString(),
        sender: 'system_test',
        user_phone: userPhone
      };

      // إرسال الإشعار لجميع tokens
      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < tokens.length; i++) {
        const token = tokens[i];
        console.log(`\n📤 إرسال إشعار ${i + 1}/${tokens.length}...`);
        console.log(`   Token: ${token.fcm_token.substring(0, 20)}...`);
        console.log(`   Device: ${JSON.stringify(token.device_info)}`);

        try {
          const result = await this.firebaseService.sendNotificationToUser(
            token.fcm_token,
            notification,
            data
          );

          if (result.success) {
            console.log(`   ✅ تم الإرسال بنجاح - Message ID: ${result.messageId}`);
            successCount++;

            // تحديث آخر استخدام للـ token
            await this.supabase
              .from('fcm_tokens')
              .update({ last_used_at: new Date().toISOString() })
              .eq('fcm_token', token.fcm_token);

          } else {
            console.log(`   ❌ فشل الإرسال: ${result.error}`);
            failureCount++;

            // إذا كان الـ token غير صالح، قم بإلغاء تفعيله
            if (result.error && (
              result.error.includes('registration-token-not-registered') ||
              result.error.includes('invalid-registration-token')
            )) {
              console.log('   🔄 إلغاء تفعيل token غير صالح...');
              await this.supabase
                .from('fcm_tokens')
                .update({ is_active: false })
                .eq('fcm_token', token.fcm_token);
            }
          }

        } catch (sendError) {
          console.log(`   ❌ خطأ في الإرسال: ${sendError.message}`);
          failureCount++;
        }
      }

      // تقرير النتائج
      console.log('\n' + '='.repeat(50));
      console.log('📊 تقرير إرسال الإشعار التجريبي');
      console.log('='.repeat(50));
      console.log(`المستخدم: ${userPhone}`);
      console.log(`إجمالي Tokens: ${tokens.length}`);
      console.log(`نجح الإرسال: ${successCount}`);
      console.log(`فشل الإرسال: ${failureCount}`);
      console.log(`معدل النجاح: ${((successCount / tokens.length) * 100).toFixed(1)}%`);

      if (successCount > 0) {
        console.log('\n🎉 تم إرسال الإشعار التجريبي بنجاح!');
        console.log('📱 تحقق من التطبيق لرؤية الإشعار');
      } else {
        console.log('\n⚠️ لم يتم إرسال أي إشعار بنجاح');
        console.log('🔧 تحقق من صحة FCM tokens والإعدادات');
      }

      return successCount > 0;

    } catch (error) {
      console.error('\n❌ خطأ في إرسال الإشعار التجريبي:', error.message);
      return false;
    }
  }

  /**
   * إرسال إشعار لجميع المستخدمين النشطين
   */
  async sendBroadcastNotification(message) {
    console.log('📢 بدء إرسال إشعار جماعي...\n');

    try {
      // تهيئة Firebase
      await this.firebaseService.initialize();

      // الحصول على جميع tokens النشطة
      const { data: tokens, error } = await this.supabase
        .from('fcm_tokens')
        .select('fcm_token, user_phone')
        .eq('is_active', true)
        .order('last_used_at', { ascending: false });

      if (error) {
        throw new Error(`خطأ في الحصول على tokens: ${error.message}`);
      }

      if (!tokens || tokens.length === 0) {
        console.log('❌ لا توجد FCM tokens نشطة');
        return false;
      }

      console.log(`📱 تم العثور على ${tokens.length} token نشط`);

      const notification = {
        title: '📢 إعلان من منتجاتي',
        body: message
      };

      const data = {
        type: 'broadcast',
        timestamp: new Date().toISOString()
      };

      let successCount = 0;
      let failureCount = 0;

      // إرسال للجميع
      for (const token of tokens) {
        try {
          const result = await this.firebaseService.sendNotificationToUser(
            token.fcm_token,
            notification,
            data
          );

          if (result.success) {
            successCount++;
          } else {
            failureCount++;
          }

        } catch (error) {
          failureCount++;
        }
      }

      console.log(`\n📊 نتائج الإرسال الجماعي:`);
      console.log(`نجح: ${successCount}, فشل: ${failureCount}`);

      return successCount > 0;

    } catch (error) {
      console.error('❌ خطأ في الإرسال الجماعي:', error.message);
      return false;
    }
  }

  /**
   * عرض قائمة المستخدمين المتاحين
   */
  async listAvailableUsers() {
    try {
      const { data: users, error } = await this.supabase
        .from('fcm_tokens')
        .select('user_phone, COUNT(*) as token_count')
        .eq('is_active', true)
        .group('user_phone')
        .order('user_phone');

      if (error) {
        throw new Error(`خطأ في الحصول على المستخدمين: ${error.message}`);
      }

      if (!users || users.length === 0) {
        console.log('❌ لا يوجد مستخدمين مسجلين');
        return [];
      }

      console.log('👥 المستخدمين المتاحين:');
      users.forEach((user, index) => {
        console.log(`   ${index + 1}. ${user.user_phone} (${user.token_count} tokens)`);
      });

      return users;

    } catch (error) {
      console.error('❌ خطأ في عرض المستخدمين:', error.message);
      return [];
    }
  }
}

// تشغيل Script
async function main() {
  const sender = new TestNotificationSender();
  
  const args = process.argv.slice(2);
  const command = args[0];
  
  if (command === 'list') {
    // عرض قائمة المستخدمين
    await sender.listAvailableUsers();
    
  } else if (command === 'send') {
    // إرسال إشعار لمستخدم محدد
    const userPhone = args[1];
    const message = args[2];
    
    if (!userPhone) {
      console.error('❌ يجب تحديد رقم الهاتف');
      console.log('الاستخدام: node send_test_notification.js send +966500000000 "رسالة اختيارية"');
      process.exit(1);
    }
    
    await sender.sendTestNotification(userPhone, message);
    
  } else if (command === 'broadcast') {
    // إرسال إشعار جماعي
    const message = args[1];
    
    if (!message) {
      console.error('❌ يجب تحديد نص الرسالة');
      console.log('الاستخدام: node send_test_notification.js broadcast "نص الإعلان"');
      process.exit(1);
    }
    
    await sender.sendBroadcastNotification(message);
    
  } else {
    console.log(`
📤 أداة إرسال الإشعارات التجريبية

الاستخدام:
  node send_test_notification.js list                           # عرض المستخدمين المتاحين
  node send_test_notification.js send +966500000000            # إرسال إشعار تجريبي
  node send_test_notification.js send +966500000000 "رسالة"    # إرسال إشعار مخصص
  node send_test_notification.js broadcast "إعلان للجميع"      # إرسال إعلان جماعي

أمثلة:
  npm run test:notification list
  npm run test:notification send +966500000000
  npm run test:notification broadcast "عرض خاص اليوم!"
`);
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = TestNotificationSender;
