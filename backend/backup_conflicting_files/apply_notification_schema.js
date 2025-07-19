// ===================================
// تطبيق schema الإشعارات مباشرة على Supabase
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

class NotificationSchemaApplier {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  // ===================================
  // تطبيق Schema الإشعارات
  // ===================================
  async applyNotificationSchema() {
    try {
      console.log('🚀 تطبيق schema الإشعارات الذكي...\n');

      // 1. إنشاء جدول سجل الإشعارات
      await this.createNotificationLogsTable();

      // 2. إنشاء جدول قائمة انتظار الإشعارات
      await this.createNotificationQueueTable();

      // 3. إنشاء جدول FCM Tokens
      await this.createFCMTokensTable();

      // 4. إنشاء الدوال المساعدة
      await this.createHelperFunctions();

      // 5. إنشاء Trigger
      await this.createNotificationTrigger();

      console.log('\n✅ تم تطبيق schema الإشعارات بنجاح!');
      
      // اختبار الجداول
      await this.testTables();

    } catch (error) {
      console.error('❌ خطأ في تطبيق schema:', error.message);
      throw error;
    }
  }

  // ===================================
  // إنشاء جدول سجل الإشعارات
  // ===================================
  async createNotificationLogsTable() {
    try {
      console.log('📋 إنشاء جدول notification_logs...');

      const { error } = await this.supabase.rpc('exec_sql', {
        sql: `
          CREATE TABLE IF NOT EXISTS notification_logs (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            order_id VARCHAR(50) NOT NULL,
            user_phone VARCHAR(20) NOT NULL,
            notification_type VARCHAR(50) NOT NULL,
            status_change VARCHAR(100) NOT NULL,
            title VARCHAR(200) NOT NULL,
            message TEXT NOT NULL,
            fcm_token TEXT,
            firebase_response JSONB,
            sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            is_successful BOOLEAN DEFAULT false,
            error_message TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );

          CREATE INDEX IF NOT EXISTS idx_notification_logs_order_id ON notification_logs(order_id);
          CREATE INDEX IF NOT EXISTS idx_notification_logs_user_phone ON notification_logs(user_phone);
          CREATE INDEX IF NOT EXISTS idx_notification_logs_sent_at ON notification_logs(sent_at);
        `
      });

      if (error) {
        console.warn(`⚠️ تحذير في إنشاء notification_logs: ${error.message}`);
      } else {
        console.log('✅ تم إنشاء جدول notification_logs');
      }

    } catch (error) {
      console.error('❌ خطأ في إنشاء notification_logs:', error.message);
    }
  }

  // ===================================
  // إنشاء جدول قائمة انتظار الإشعارات
  // ===================================
  async createNotificationQueueTable() {
    try {
      console.log('📋 إنشاء جدول notification_queue...');

      const { error } = await this.supabase.rpc('exec_sql', {
        sql: `
          CREATE TABLE IF NOT EXISTS notification_queue (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            order_id VARCHAR(50) NOT NULL,
            user_phone VARCHAR(20) NOT NULL,
            customer_name VARCHAR(255) NOT NULL,
            old_status VARCHAR(50),
            new_status VARCHAR(50) NOT NULL,
            notification_data JSONB NOT NULL,
            priority INTEGER DEFAULT 1,
            max_retries INTEGER DEFAULT 3,
            retry_count INTEGER DEFAULT 0,
            status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'sent', 'failed')),
            scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            processed_at TIMESTAMP WITH TIME ZONE,
            error_message TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );

          CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_queue(status);
          CREATE INDEX IF NOT EXISTS idx_notification_queue_scheduled_at ON notification_queue(scheduled_at);
          CREATE INDEX IF NOT EXISTS idx_notification_queue_priority ON notification_queue(priority);
        `
      });

      if (error) {
        console.warn(`⚠️ تحذير في إنشاء notification_queue: ${error.message}`);
      } else {
        console.log('✅ تم إنشاء جدول notification_queue');
      }

    } catch (error) {
      console.error('❌ خطأ في إنشاء notification_queue:', error.message);
    }
  }

  // ===================================
  // إنشاء جدول FCM Tokens
  // ===================================
  async createFCMTokensTable() {
    try {
      console.log('📱 إنشاء جدول user_fcm_tokens...');

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
        console.warn(`⚠️ تحذير في إنشاء user_fcm_tokens: ${error.message}`);
      } else {
        console.log('✅ تم إنشاء جدول user_fcm_tokens');
      }

    } catch (error) {
      console.error('❌ خطأ في إنشاء user_fcm_tokens:', error.message);
    }
  }

  // ===================================
  // إنشاء الدوال المساعدة
  // ===================================
  async createHelperFunctions() {
    try {
      console.log('⚙️ إنشاء الدوال المساعدة...');

      // دالة إنشاء رسالة الإشعار
      const { error1 } = await this.supabase.rpc('exec_sql', {
        sql: `
          CREATE OR REPLACE FUNCTION generate_smart_notification_message(
            customer_name VARCHAR(255),
            old_status VARCHAR(50),
            new_status VARCHAR(50)
          ) RETURNS JSONB AS $$
          DECLARE
            notification_data JSONB;
            title TEXT;
            message TEXT;
            emoji TEXT;
            priority INTEGER;
          BEGIN
            CASE new_status
              WHEN 'in_delivery' THEN
                title := 'قيد التوصيل 🚗';
                message := customer_name || ' - قيد التوصيل 🚗';
                emoji := '🚗';
                priority := 2;
                
              WHEN 'delivered' THEN
                title := 'تم التوصيل 😊';
                message := customer_name || ' - تم التوصيل 😊';
                emoji := '😊';
                priority := 3;
                
              WHEN 'cancelled' THEN
                title := 'ملغي 😢';
                message := customer_name || ' - ملغي 😢';
                emoji := '😢';
                priority := 2;
                
              ELSE
                title := 'تحديث حالة الطلب';
                message := customer_name || ' - تم تحديث حالة الطلب إلى: ' || new_status;
                emoji := '📋';
                priority := 1;
            END CASE;
            
            notification_data := jsonb_build_object(
              'title', title,
              'message', message,
              'emoji', emoji,
              'priority', priority,
              'type', 'order_status_change',
              'old_status', old_status,
              'new_status', new_status,
              'customer_name', customer_name,
              'timestamp', EXTRACT(EPOCH FROM NOW())::bigint,
              'sound', 'default',
              'vibration', true
            );
            
            RETURN notification_data;
          END;
          $$ LANGUAGE plpgsql;
        `
      });

      // دالة الحصول على رقم هاتف المستخدم
      const { error2 } = await this.supabase.rpc('exec_sql', {
        sql: `
          CREATE OR REPLACE FUNCTION get_user_phone_from_order(order_record RECORD)
          RETURNS VARCHAR(20) AS $$
          DECLARE
            user_phone VARCHAR(20);
          BEGIN
            IF order_record.primary_phone IS NOT NULL THEN
              RETURN order_record.primary_phone;
            END IF;
            
            IF order_record.customer_phone IS NOT NULL THEN
              RETURN order_record.customer_phone;
            END IF;
            
            RETURN NULL;
          END;
          $$ LANGUAGE plpgsql;
        `
      });

      if (error1 || error2) {
        console.warn('⚠️ تحذير في إنشاء الدوال المساعدة');
      } else {
        console.log('✅ تم إنشاء الدوال المساعدة');
      }

    } catch (error) {
      console.error('❌ خطأ في إنشاء الدوال المساعدة:', error.message);
    }
  }

  // ===================================
  // إنشاء Trigger
  // ===================================
  async createNotificationTrigger() {
    try {
      console.log('🔔 إنشاء notification trigger...');

      const { error } = await this.supabase.rpc('exec_sql', {
        sql: `
          CREATE OR REPLACE FUNCTION queue_smart_notification()
          RETURNS TRIGGER AS $$
          DECLARE
            user_phone VARCHAR(20);
            notification_data JSONB;
            customer_name_safe VARCHAR(255);
          BEGIN
            IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
              RETURN NEW;
            END IF;
            
            user_phone := get_user_phone_from_order(NEW);
            
            IF user_phone IS NULL THEN
              RETURN NEW;
            END IF;
            
            customer_name_safe := COALESCE(NEW.customer_name, 'عميل غير محدد');
            
            notification_data := generate_smart_notification_message(
              customer_name_safe,
              OLD.status,
              NEW.status
            );
            
            INSERT INTO notification_queue (
              order_id,
              user_phone,
              customer_name,
              old_status,
              new_status,
              notification_data,
              priority,
              scheduled_at
            ) VALUES (
              NEW.id,
              user_phone,
              customer_name_safe,
              OLD.status,
              NEW.status,
              notification_data,
              (notification_data->>'priority')::INTEGER,
              NOW()
            );
            
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;

          DROP TRIGGER IF EXISTS smart_notification_trigger ON orders;

          CREATE TRIGGER smart_notification_trigger
            AFTER UPDATE ON orders
            FOR EACH ROW
            WHEN (OLD.status IS DISTINCT FROM NEW.status)
            EXECUTE FUNCTION queue_smart_notification();
        `
      });

      if (error) {
        console.warn(`⚠️ تحذير في إنشاء trigger: ${error.message}`);
      } else {
        console.log('✅ تم إنشاء notification trigger');
      }

    } catch (error) {
      console.error('❌ خطأ في إنشاء trigger:', error.message);
    }
  }

  // ===================================
  // اختبار الجداول
  // ===================================
  async testTables() {
    try {
      console.log('\n🧪 اختبار الجداول...');

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

    } catch (error) {
      console.error('❌ خطأ في اختبار الجداول:', error.message);
    }
  }
}

// ===================================
// تشغيل التطبيق
// ===================================
if (require.main === module) {
  const applier = new NotificationSchemaApplier();
  
  applier.applyNotificationSchema()
    .then(() => {
      console.log('\n🎉 تم إعداد نظام الإشعارات بنجاح!');
      console.log('📋 الخطوات التالية:');
      console.log('  npm run notification:start  - تشغيل معالج الإشعارات');
      console.log('  npm run notification:test <phone>  - اختبار الإشعارات');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ فشل في إعداد النظام:', error.message);
      process.exit(1);
    });
}

module.exports = NotificationSchemaApplier;
