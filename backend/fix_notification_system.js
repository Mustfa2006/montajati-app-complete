#!/usr/bin/env node

// ===================================
// إصلاح نظام الإشعارات الكامل
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function fixNotificationSystem() {
  console.log('🔧 إصلاح نظام الإشعارات...\n');

  // 1. إنشاء جدول fcm_tokens إذا لم يكن موجوداً
  console.log('📊 إنشاء جدول fcm_tokens...');
  try {
    const { error } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS fcm_tokens (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_phone VARCHAR(20) NOT NULL,
          token TEXT NOT NULL,
          platform VARCHAR(20) DEFAULT 'android',
          device_info JSONB,
          is_active BOOLEAN DEFAULT true,
          last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_phone ON fcm_tokens(user_phone);
        CREATE INDEX IF NOT EXISTS idx_fcm_tokens_active ON fcm_tokens(is_active);
        CREATE UNIQUE INDEX IF NOT EXISTS idx_fcm_tokens_unique ON fcm_tokens(user_phone, token);
      `
    });

    if (error) {
      console.log(`❌ خطأ في إنشاء جدول fcm_tokens: ${error.message}`);
    } else {
      console.log('✅ تم إنشاء جدول fcm_tokens');
    }
  } catch (e) {
    console.log(`❌ خطأ في إنشاء جدول fcm_tokens: ${e.message}`);
  }

  // 2. إنشاء جدول notification_queue
  console.log('\n📬 إنشاء جدول notification_queue...');
  try {
    const { error } = await supabase.rpc('exec_sql', {
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
        CREATE INDEX IF NOT EXISTS idx_notification_queue_user_phone ON notification_queue(user_phone);
        CREATE INDEX IF NOT EXISTS idx_notification_queue_order_id ON notification_queue(order_id);
      `
    });

    if (error) {
      console.log(`❌ خطأ في إنشاء جدول notification_queue: ${error.message}`);
    } else {
      console.log('✅ تم إنشاء جدول notification_queue');
    }
  } catch (e) {
    console.log(`❌ خطأ في إنشاء جدول notification_queue: ${e.message}`);
  }

  // 3. إنشاء جدول notification_logs
  console.log('\n📝 إنشاء جدول notification_logs...');
  try {
    const { error } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS notification_logs (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          order_id VARCHAR(50),
          user_phone VARCHAR(20),
          notification_type VARCHAR(50),
          status_change VARCHAR(100),
          title VARCHAR(200),
          message TEXT,
          is_successful BOOLEAN DEFAULT false,
          error_message TEXT,
          firebase_response JSONB,
          sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_notification_logs_order_id ON notification_logs(order_id);
        CREATE INDEX IF NOT EXISTS idx_notification_logs_user_phone ON notification_logs(user_phone);
        CREATE INDEX IF NOT EXISTS idx_notification_logs_sent_at ON notification_logs(sent_at);
      `
    });

    if (error) {
      console.log(`❌ خطأ في إنشاء جدول notification_logs: ${error.message}`);
    } else {
      console.log('✅ تم إنشاء جدول notification_logs');
    }
  } catch (e) {
    console.log(`❌ خطأ في إنشاء جدول notification_logs: ${e.message}`);
  }

  // 4. تطبيق الـ trigger والدوال
  console.log('\n⚡ تطبيق الـ trigger والدوال...');
  try {
    const triggerPath = path.join(__dirname, 'database', 'smart_notification_trigger.sql');
    
    if (fs.existsSync(triggerPath)) {
      const triggerSQL = fs.readFileSync(triggerPath, 'utf8');
      const { error } = await supabase.rpc('exec_sql', { sql: triggerSQL });

      if (error) {
        console.log(`❌ خطأ في تطبيق الـ trigger: ${error.message}`);
      } else {
        console.log('✅ تم تطبيق الـ trigger والدوال');
      }
    } else {
      console.log('❌ ملف smart_notification_trigger.sql غير موجود');
    }
  } catch (e) {
    console.log(`❌ خطأ في تطبيق الـ trigger: ${e.message}`);
  }

  // 5. إضافة عمود user_phone لجدول orders إذا لم يكن موجوداً
  console.log('\n📦 فحص عمود user_phone في جدول orders...');
  try {
    const { error } = await supabase.rpc('exec_sql', {
      sql: `
        ALTER TABLE orders 
        ADD COLUMN IF NOT EXISTS user_phone VARCHAR(20);
        
        CREATE INDEX IF NOT EXISTS idx_orders_user_phone ON orders(user_phone);
      `
    });

    if (error) {
      console.log(`❌ خطأ في إضافة عمود user_phone: ${error.message}`);
    } else {
      console.log('✅ تم فحص/إضافة عمود user_phone');
    }
  } catch (e) {
    console.log(`❌ خطأ في فحص عمود user_phone: ${e.message}`);
  }

  console.log('\n✅ انتهى إصلاح نظام الإشعارات');
  console.log('\n📋 الخطوات التالية:');
  console.log('1. تشغيل: node check_notification_system.js');
  console.log('2. تشغيل: node test_notification_flow.js');
  console.log('3. التأكد من تسجيل FCM tokens من التطبيق');
}

// تشغيل الإصلاح
fixNotificationSystem().catch(console.error);
