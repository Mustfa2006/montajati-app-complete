#!/usr/bin/env node

// ===================================
// فحص شامل لنظام الإشعارات
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkNotificationSystem() {
  console.log('🔍 فحص شامل لنظام الإشعارات...\n');

  // 1. فحص الجداول المطلوبة
  console.log('📊 فحص الجداول المطلوبة:');
  const requiredTables = [
    'orders',
    'notification_queue', 
    'notification_logs',
    'fcm_tokens',
    'user_fcm_tokens'
  ];

  for (const table of requiredTables) {
    try {
      const { data, error } = await supabase
        .from(table)
        .select('count')
        .limit(1);

      if (error) {
        console.log(`❌ جدول ${table}: غير موجود - ${error.message}`);
      } else {
        console.log(`✅ جدول ${table}: موجود`);
      }
    } catch (e) {
      console.log(`❌ جدول ${table}: خطأ في الفحص - ${e.message}`);
    }
  }

  // 2. فحص FCM Tokens
  console.log('\n🔑 فحص FCM Tokens:');
  try {
    const { data: tokens, error } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('is_active', true);

    if (error) {
      console.log(`❌ خطأ في جلب FCM Tokens: ${error.message}`);
    } else {
      console.log(`📱 عدد FCM Tokens النشطة: ${tokens?.length || 0}`);
      if (tokens && tokens.length > 0) {
        tokens.forEach(token => {
          console.log(`   - المستخدم: ${token.user_phone} | المنصة: ${token.platform || 'غير محدد'}`);
        });
      }
    }
  } catch (e) {
    console.log(`❌ خطأ في فحص FCM Tokens: ${e.message}`);
  }

  // 3. فحص user_fcm_tokens (الجدول البديل)
  console.log('\n🔑 فحص User FCM Tokens:');
  try {
    const { data: userTokens, error } = await supabase
      .from('user_fcm_tokens')
      .select('*')
      .eq('is_active', true);

    if (error) {
      console.log(`❌ خطأ في جلب User FCM Tokens: ${error.message}`);
    } else {
      console.log(`📱 عدد User FCM Tokens النشطة: ${userTokens?.length || 0}`);
      if (userTokens && userTokens.length > 0) {
        userTokens.forEach(token => {
          console.log(`   - المستخدم: ${token.user_phone} | المنصة: ${token.platform || 'غير محدد'}`);
        });
      }
    }
  } catch (e) {
    console.log(`❌ خطأ في فحص User FCM Tokens: ${e.message}`);
  }

  // 4. فحص قائمة انتظار الإشعارات
  console.log('\n📬 فحص قائمة انتظار الإشعارات:');
  try {
    const { data: queue, error } = await supabase
      .from('notification_queue')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10);

    if (error) {
      console.log(`❌ خطأ في جلب قائمة الانتظار: ${error.message}`);
    } else {
      console.log(`📋 عدد الإشعارات في القائمة: ${queue?.length || 0}`);
      if (queue && queue.length > 0) {
        queue.forEach(notification => {
          console.log(`   - الطلب: ${notification.order_id} | المستخدم: ${notification.user_phone} | الحالة: ${notification.status}`);
        });
      }
    }
  } catch (e) {
    console.log(`❌ خطأ في فحص قائمة الانتظار: ${e.message}`);
  }

  // 5. فحص سجل الإشعارات
  console.log('\n📝 فحص سجل الإشعارات:');
  try {
    const { data: logs, error } = await supabase
      .from('notification_logs')
      .select('*')
      .order('sent_at', { ascending: false })
      .limit(5);

    if (error) {
      console.log(`❌ خطأ في جلب سجل الإشعارات: ${error.message}`);
    } else {
      console.log(`📋 عدد الإشعارات المسجلة: ${logs?.length || 0}`);
      if (logs && logs.length > 0) {
        logs.forEach(log => {
          console.log(`   - الطلب: ${log.order_id} | المستخدم: ${log.user_phone} | نجح: ${log.is_successful ? 'نعم' : 'لا'}`);
        });
      }
    }
  } catch (e) {
    console.log(`❌ خطأ في فحص سجل الإشعارات: ${e.message}`);
  }

  // 6. فحص متغيرات البيئة
  console.log('\n🔧 فحص متغيرات البيئة:');
  const envVars = [
    'SUPABASE_URL',
    'SUPABASE_SERVICE_ROLE_KEY', 
    'FIREBASE_SERVICE_ACCOUNT'
  ];

  envVars.forEach(envVar => {
    if (process.env[envVar]) {
      console.log(`✅ ${envVar}: موجود`);
    } else {
      console.log(`❌ ${envVar}: مفقود`);
    }
  });

  // 7. فحص Firebase Config
  console.log('\n🔥 فحص إعدادات Firebase:');
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      console.log(`✅ Firebase Project ID: ${firebaseConfig.project_id}`);
      console.log(`✅ Firebase Client Email: ${firebaseConfig.client_email}`);
    } else {
      console.log('❌ إعدادات Firebase غير موجودة');
    }
  } catch (e) {
    console.log(`❌ خطأ في تحليل إعدادات Firebase: ${e.message}`);
  }

  console.log('\n✅ انتهى فحص نظام الإشعارات');
}

// تشغيل الفحص
checkNotificationSystem().catch(console.error);
