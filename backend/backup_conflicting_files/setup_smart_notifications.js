// ===================================
// إعداد نظام الإشعارات الذكي في قاعدة البيانات
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

class SmartNotificationSetup {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  // ===================================
  // تطبيق SQL من ملف
  // ===================================
  async executeSQLFile(filePath) {
    try {
      console.log(`📄 تطبيق ملف SQL: ${filePath}`);
      
      const sqlContent = fs.readFileSync(filePath, 'utf8');
      
      // تقسيم SQL إلى statements منفصلة
      const statements = sqlContent
        .split(';')
        .map(stmt => stmt.trim())
        .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

      let successCount = 0;
      let errorCount = 0;

      for (const statement of statements) {
        try {
          if (statement.includes('RAISE NOTICE')) {
            // تجاهل RAISE NOTICE statements
            continue;
          }

          const { error } = await this.supabase.rpc('exec_sql', {
            sql: statement + ';'
          });

          if (error) {
            console.warn(`⚠️ تحذير في تنفيذ statement: ${error.message}`);
            errorCount++;
          } else {
            successCount++;
          }

        } catch (statementError) {
          console.warn(`⚠️ خطأ في statement: ${statementError.message}`);
          errorCount++;
        }
      }

      console.log(`✅ تم تطبيق ${successCount} statements بنجاح، ${errorCount} تحذيرات`);
      return { success: true, successCount, errorCount };

    } catch (error) {
      console.error(`❌ خطأ في تطبيق ملف SQL ${filePath}:`, error.message);
      return { success: false, error: error.message };
    }
  }

  // ===================================
  // إعداد نظام الإشعارات الكامل
  // ===================================
  async setupSmartNotifications() {
    try {
      console.log('🚀 بدء إعداد نظام الإشعارات الذكي...\n');

      // 1. تطبيق Database Trigger
      const triggerPath = path.join(__dirname, 'database', 'smart_notification_trigger.sql');
      const triggerResult = await this.executeSQLFile(triggerPath);
      
      if (!triggerResult.success) {
        throw new Error('فشل في إعداد Database Trigger');
      }

      // 2. التحقق من جدول FCM Tokens
      await this.ensureFCMTokensTable();

      // 3. اختبار النظام
      await this.testNotificationSystem();

      console.log('\n✅ تم إعداد نظام الإشعارات الذكي بنجاح!');
      console.log('📋 الخطوات التالية:');
      console.log('  1. تشغيل معالج الإشعارات: npm run notification:start');
      console.log('  2. مراقبة الإحصائيات: npm run notification:stats');
      console.log('  3. اختبار الإشعارات: npm run notification:test <رقم_الهاتف>');

    } catch (error) {
      console.error('❌ خطأ في إعداد نظام الإشعارات:', error.message);
      throw error;
    }
  }

  // ===================================
  // التأكد من وجود جدول FCM Tokens
  // ===================================
  async ensureFCMTokensTable() {
    try {
      console.log('📱 التحقق من جدول FCM Tokens...');

      const { error } = await this.supabase.rpc('exec_sql', {
        sql: `
          CREATE TABLE IF NOT EXISTS user_fcm_tokens (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_phone VARCHAR(20) NOT NULL,
            fcm_token TEXT NOT NULL,
            platform VARCHAR(20) DEFAULT 'android',
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );

          CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_phone ON user_fcm_tokens(user_phone);
          CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active ON user_fcm_tokens(is_active);

          ALTER TABLE user_fcm_tokens 
          ADD CONSTRAINT IF NOT EXISTS unique_user_phone_platform 
          UNIQUE (user_phone, platform);
        `
      });

      if (error) {
        console.warn(`⚠️ تحذير في إعداد جدول FCM Tokens: ${error.message}`);
      } else {
        console.log('✅ جدول FCM Tokens جاهز');
      }

    } catch (error) {
      console.error('❌ خطأ في إعداد جدول FCM Tokens:', error.message);
    }
  }

  // ===================================
  // اختبار النظام
  // ===================================
  async testNotificationSystem() {
    try {
      console.log('🧪 اختبار نظام الإشعارات...');

      // التحقق من وجود الجداول المطلوبة
      const tables = ['notification_queue', 'notification_logs', 'user_fcm_tokens'];
      
      for (const table of tables) {
        const { data, error } = await this.supabase
          .from(table)
          .select('*')
          .limit(1);

        if (error) {
          console.warn(`⚠️ مشكلة في جدول ${table}: ${error.message}`);
        } else {
          console.log(`✅ جدول ${table} يعمل بشكل صحيح`);
        }
      }

      // اختبار إدراج في قائمة الانتظار
      const testNotification = {
        order_id: 'TEST-' + Date.now(),
        user_phone: '07503597589',
        customer_name: 'اختبار النظام',
        old_status: 'active',
        new_status: 'test',
        notification_data: {
          title: 'اختبار النظام 🧪',
          message: 'اختبار النظام - اختبار النظام 🧪',
          type: 'test',
          priority: 1
        }
      };

      const { error: insertError } = await this.supabase
        .from('notification_queue')
        .insert(testNotification);

      if (insertError) {
        console.warn(`⚠️ مشكلة في اختبار قائمة الانتظار: ${insertError.message}`);
      } else {
        console.log('✅ اختبار قائمة الانتظار نجح');
        
        // حذف الاختبار
        await this.supabase
          .from('notification_queue')
          .delete()
          .eq('order_id', testNotification.order_id);
      }

    } catch (error) {
      console.error('❌ خطأ في اختبار النظام:', error.message);
    }
  }

  // ===================================
  // عرض إحصائيات النظام
  // ===================================
  async showSystemStats() {
    try {
      console.log('📊 إحصائيات نظام الإشعارات:\n');

      // إحصائيات قائمة الانتظار
      const { data: queueStats } = await this.supabase
        .from('notification_queue')
        .select('status')
        .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

      if (queueStats) {
        const pending = queueStats.filter(s => s.status === 'pending').length;
        const sent = queueStats.filter(s => s.status === 'sent').length;
        const failed = queueStats.filter(s => s.status === 'failed').length;
        
        console.log('📋 قائمة انتظار الإشعارات (آخر 24 ساعة):');
        console.log(`  معلقة: ${pending}`);
        console.log(`  مرسلة: ${sent}`);
        console.log(`  فاشلة: ${failed}`);
        console.log(`  المجموع: ${queueStats.length}\n`);
      }

      // إحصائيات FCM Tokens
      const { data: tokenStats } = await this.supabase
        .from('user_fcm_tokens')
        .select('platform, is_active');

      if (tokenStats) {
        const activeTokens = tokenStats.filter(t => t.is_active).length;
        const androidTokens = tokenStats.filter(t => t.platform === 'android').length;
        const iosTokens = tokenStats.filter(t => t.platform === 'ios').length;
        
        console.log('📱 إحصائيات FCM Tokens:');
        console.log(`  نشطة: ${activeTokens}`);
        console.log(`  Android: ${androidTokens}`);
        console.log(`  iOS: ${iosTokens}`);
        console.log(`  المجموع: ${tokenStats.length}\n`);
      }

      // إحصائيات سجل الإشعارات
      const { data: logStats } = await this.supabase
        .from('notification_logs')
        .select('is_successful')
        .gte('sent_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

      if (logStats) {
        const successful = logStats.filter(l => l.is_successful).length;
        const failed = logStats.filter(l => !l.is_successful).length;
        
        console.log('📈 سجل الإشعارات (آخر 24 ساعة):');
        console.log(`  ناجحة: ${successful}`);
        console.log(`  فاشلة: ${failed}`);
        console.log(`  المجموع: ${logStats.length}`);
        
        if (logStats.length > 0) {
          const successRate = ((successful / logStats.length) * 100).toFixed(1);
          console.log(`  معدل النجاح: ${successRate}%`);
        }
      }

    } catch (error) {
      console.error('❌ خطأ في عرض الإحصائيات:', error.message);
    }
  }
}

// ===================================
// تشغيل الإعداد
// ===================================
if (require.main === module) {
  const setup = new SmartNotificationSetup();
  const command = process.argv[2];

  switch (command) {
    case 'setup':
      setup.setupSmartNotifications()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'stats':
      setup.showSystemStats()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      console.log('📋 الأوامر المتاحة:');
      console.log('  node setup_smart_notifications.js setup  - إعداد النظام');
      console.log('  node setup_smart_notifications.js stats  - عرض الإحصائيات');
      process.exit(1);
  }
}

module.exports = SmartNotificationSetup;
