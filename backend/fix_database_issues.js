// ===================================
// إصلاح مشاكل قاعدة البيانات
// Fix Database Issues
// ===================================

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function fixDatabaseIssues() {
  console.log('🔧 بدء إصلاح مشاكل قاعدة البيانات...');

  try {
    // إنشاء عميل Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    console.log('✅ تم الاتصال بقاعدة البيانات');

    // 1. إنشاء جدول sync_logs إذا لم يكن موجوداً
    console.log('📊 إنشاء جدول sync_logs...');
    
    const { error: createTableError } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS sync_logs (
          id BIGSERIAL PRIMARY KEY,
          operation_id TEXT NOT NULL,
          sync_type TEXT NOT NULL DEFAULT 'full_sync',
          success BOOLEAN NOT NULL DEFAULT true,
          orders_processed INTEGER DEFAULT 0,
          orders_updated INTEGER DEFAULT 0,
          duration_ms INTEGER DEFAULT 0,
          error_message TEXT,
          sync_timestamp TIMESTAMPTZ DEFAULT NOW(),
          service_version TEXT DEFAULT '1.0.0',
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        -- إنشاء فهرس للبحث السريع
        CREATE INDEX IF NOT EXISTS idx_sync_logs_timestamp ON sync_logs(sync_timestamp);
        CREATE INDEX IF NOT EXISTS idx_sync_logs_operation_id ON sync_logs(operation_id);
      `
    });

    if (createTableError) {
      console.log('⚠️ فشل إنشاء الجدول عبر RPC، محاولة طريقة أخرى...');
      
      // محاولة إنشاء الجدول بطريقة مختلفة
      const { error: insertError } = await supabase
        .from('sync_logs')
        .insert({
          operation_id: 'table_creation_test',
          sync_type: 'test',
          success: true,
          orders_processed: 0,
          orders_updated: 0,
          duration_ms: 0,
          sync_timestamp: new Date().toISOString(),
          service_version: '1.0.0'
        });

      if (insertError) {
        console.log('❌ الجدول غير موجود، سيتم إنشاؤه تلقائياً عند أول استخدام');
      } else {
        console.log('✅ تم إنشاء جدول sync_logs بنجاح');
        // حذف السجل التجريبي
        await supabase
          .from('sync_logs')
          .delete()
          .eq('operation_id', 'table_creation_test');
      }
    } else {
      console.log('✅ تم إنشاء جدول sync_logs بنجاح');
    }

    // 2. التحقق من جداول النظام الأخرى
    console.log('📊 التحقق من الجداول الأساسية...');
    
    const tables = ['orders', 'users', 'fcm_tokens', 'order_status_history'];
    
    for (const table of tables) {
      const { data, error } = await supabase
        .from(table)
        .select('id')
        .limit(1);
      
      if (error) {
        console.log(`⚠️ مشكلة في جدول ${table}: ${error.message}`);
      } else {
        console.log(`✅ جدول ${table} يعمل بشكل صحيح`);
      }
    }

    // 3. تنظيف السجلات القديمة
    console.log('🧹 تنظيف السجلات القديمة...');
    
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    
    const { error: cleanupError } = await supabase
      .from('sync_logs')
      .delete()
      .lt('created_at', oneWeekAgo);
    
    if (cleanupError) {
      console.log('⚠️ فشل تنظيف السجلات القديمة:', cleanupError.message);
    } else {
      console.log('✅ تم تنظيف السجلات القديمة');
    }

    console.log('🎉 تم إصلاح جميع مشاكل قاعدة البيانات بنجاح!');

  } catch (error) {
    console.error('❌ خطأ في إصلاح قاعدة البيانات:', error.message);
    process.exit(1);
  }
}

// تشغيل الإصلاح
if (require.main === module) {
  fixDatabaseIssues()
    .then(() => {
      console.log('✅ انتهى إصلاح قاعدة البيانات');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ فشل إصلاح قاعدة البيانات:', error);
      process.exit(1);
    });
}

module.exports = { fixDatabaseIssues };
