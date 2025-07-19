#!/usr/bin/env node

// ===================================
// اختبار شامل لنظام الإشعارات مع الإصلاح
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function completeNotificationTest() {
  console.log('🧪 اختبار شامل لنظام الإشعارات مع الإصلاح...\n');

  // 1. إصلاح قاعدة البيانات أولاً
  console.log('🔧 إصلاح قاعدة البيانات...');
  await fixDatabase();

  // 2. فحص النظام
  console.log('\n🔍 فحص النظام...');
  await checkSystem();

  // 3. اختبار تدفق الإشعارات
  console.log('\n🧪 اختبار تدفق الإشعارات...');
  await testNotificationFlow();

  console.log('\n✅ انتهى الاختبار الشامل');
}

async function fixDatabase() {
  try {
    // إنشاء جدول fcm_tokens
    console.log('📊 إنشاء جدول fcm_tokens...');
    const { error: fcmError } = await supabase.rpc('exec_sql', {
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

    if (fcmError) {
      console.log(`❌ خطأ في إنشاء جدول fcm_tokens: ${fcmError.message}`);
    } else {
      console.log('✅ تم إنشاء جدول fcm_tokens');
    }

    // إنشاء جدول notification_queue
    console.log('📬 إنشاء جدول notification_queue...');
    const { error: queueError } = await supabase.rpc('exec_sql', {
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
      `
    });

    if (queueError) {
      console.log(`❌ خطأ في إنشاء جدول notification_queue: ${queueError.message}`);
    } else {
      console.log('✅ تم إنشاء جدول notification_queue');
    }

    // إنشاء جدول notification_logs
    console.log('📝 إنشاء جدول notification_logs...');
    const { error: logsError } = await supabase.rpc('exec_sql', {
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
      `
    });

    if (logsError) {
      console.log(`❌ خطأ في إنشاء جدول notification_logs: ${logsError.message}`);
    } else {
      console.log('✅ تم إنشاء جدول notification_logs');
    }

    // إضافة عمود user_phone لجدول orders
    console.log('📦 إضافة عمود user_phone لجدول orders...');
    const { error: orderError } = await supabase.rpc('exec_sql', {
      sql: `
        ALTER TABLE orders 
        ADD COLUMN IF NOT EXISTS user_phone VARCHAR(20);
        
        CREATE INDEX IF NOT EXISTS idx_orders_user_phone ON orders(user_phone);
      `
    });

    if (orderError) {
      console.log(`❌ خطأ في إضافة عمود user_phone: ${orderError.message}`);
    } else {
      console.log('✅ تم إضافة عمود user_phone');
    }

  } catch (error) {
    console.error('❌ خطأ في إصلاح قاعدة البيانات:', error.message);
  }
}

async function checkSystem() {
  // فحص الجداول
  const tables = ['orders', 'notification_queue', 'notification_logs', 'fcm_tokens'];
  
  for (const table of tables) {
    try {
      const { data, error } = await supabase.from(table).select('count').limit(1);
      if (error) {
        console.log(`❌ جدول ${table}: غير موجود`);
      } else {
        console.log(`✅ جدول ${table}: موجود`);
      }
    } catch (e) {
      console.log(`❌ جدول ${table}: خطأ في الفحص`);
    }
  }

  // فحص FCM Tokens
  try {
    const { data: tokens } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('is_active', true);
    
    console.log(`📱 عدد FCM Tokens النشطة: ${tokens?.length || 0}`);
  } catch (e) {
    console.log('❌ خطأ في فحص FCM Tokens');
  }
}

async function testNotificationFlow() {
  const testOrderId = `TEST_ORDER_${Date.now()}`;
  const testUserPhone = '07503597589';

  try {
    // 1. إضافة FCM Token تجريبي
    console.log('🔑 إضافة FCM Token تجريبي...');
    await supabase.from('fcm_tokens').upsert({
      user_phone: testUserPhone,
      token: `test_token_${Date.now()}`,
      platform: 'android',
      device_info: { test: true },
      is_active: true
    });

    // 2. إنشاء طلب تجريبي
    console.log('📦 إنشاء طلب تجريبي...');
    await supabase.from('orders').insert({
      id: testOrderId,
      customer_name: 'عميل تجريبي',
      primary_phone: '07701234567',
      user_phone: testUserPhone,
      province: 'بغداد',
      city: 'الكرادة',
      subtotal: 50000,
      total: 55000,
      profit: 5000,
      status: 'pending'
    });

    // 3. تحديث حالة الطلب
    console.log('🔄 تحديث حالة الطلب...');
    await supabase.from('orders').update({ status: 'confirmed' }).eq('id', testOrderId);

    // 4. فحص قائمة الانتظار
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    const { data: notifications } = await supabase
      .from('notification_queue')
      .select('*')
      .eq('order_id', testOrderId);

    if (notifications && notifications.length > 0) {
      console.log(`✅ تم إنشاء ${notifications.length} إشعار في قائمة الانتظار`);
    } else {
      console.log('❌ لم يتم إنشاء أي إشعار - تحقق من الـ trigger');
    }

    // 5. تنظيف البيانات
    await supabase.from('notification_queue').delete().eq('order_id', testOrderId);
    await supabase.from('orders').delete().eq('id', testOrderId);
    await supabase.from('fcm_tokens').delete().eq('user_phone', testUserPhone);

  } catch (error) {
    console.error('❌ خطأ في اختبار التدفق:', error.message);
  }
}

// تشغيل الاختبار
completeNotificationTest().catch(console.error);
