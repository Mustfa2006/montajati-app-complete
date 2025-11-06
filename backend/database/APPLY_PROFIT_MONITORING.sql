-- ===================================
-- 🚀 تطبيق نظام الرصد المؤقت للأرباح
-- ===================================
-- الهدف: اكتشاف مصدر مشكلة تضاعف الأرباح
-- التاريخ: 2025-11-06
-- ===================================

\echo '🔍 ===== بدء تطبيق نظام الرصد المؤقت للأرباح ====='
\echo ''

-- ===================================
-- الخطوة 1: تطبيق نظام الرصد
-- ===================================
\echo '📋 الخطوة 1: تطبيق نظام الرصد المؤقت...'
\i backend/database/temporary_profit_monitor.sql
\echo '✅ تم تطبيق نظام الرصد'
\echo ''

-- ===================================
-- الخطوة 2: تحديث smart_profit_manager
-- ===================================
\echo '📋 الخطوة 2: تحديث smart_profit_manager مع السياق والحماية...'
\i backend/database/update_smart_profit_with_context.sql
\echo '✅ تم تحديث smart_profit_manager'
\echo ''

-- ===================================
-- الخطوة 3: التحقق من التطبيق
-- ===================================
\echo '📋 الخطوة 3: التحقق من التطبيق...'

-- فحص وجود جدول profit_audit_log
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profit_audit_log') THEN
        RAISE NOTICE '✅ جدول profit_audit_log موجود';
    ELSE
        RAISE EXCEPTION '❌ جدول profit_audit_log غير موجود!';
    END IF;
END $$;

-- فحص وجود دالة monitor_profit_changes
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'monitor_profit_changes') THEN
        RAISE NOTICE '✅ دالة monitor_profit_changes موجودة';
    ELSE
        RAISE EXCEPTION '❌ دالة monitor_profit_changes غير موجودة!';
    END IF;
END $$;

-- فحص وجود trigger على users
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_monitor_profit_changes') THEN
        RAISE NOTICE '✅ Trigger trigger_monitor_profit_changes مفعل';
    ELSE
        RAISE EXCEPTION '❌ Trigger trigger_monitor_profit_changes غير مفعل!';
    END IF;
END $$;

-- فحص تحديث smart_profit_manager
DO $$
DECLARE
    func_def TEXT;
BEGIN
    SELECT pg_get_functiondef(oid) INTO func_def
    FROM pg_proc 
    WHERE proname = 'smart_profit_manager';
    
    IF func_def LIKE '%app.current_order_id%' THEN
        RAISE NOTICE '✅ smart_profit_manager محدث مع تسجيل السياق';
    ELSE
        RAISE WARNING '⚠️ smart_profit_manager قد لا يحتوي على تسجيل السياق';
    END IF;
    
    IF func_def LIKE '%300%' THEN
        RAISE NOTICE '✅ smart_profit_manager محدث مع حماية 5 دقائق';
    ELSE
        RAISE WARNING '⚠️ smart_profit_manager قد لا يحتوي على حماية 5 دقائق';
    END IF;
END $$;

\echo ''
\echo '✅ ===== تم تطبيق نظام الرصد بنجاح ====='
\echo ''
\echo '📊 كيفية استخدام نظام الرصد:'
\echo ''
\echo '1️⃣ لعرض آخر 20 تغيير لمستخدم معين:'
\echo '   SELECT * FROM get_profit_audit_summary(''07566666666'', 20);'
\echo ''
\echo '2️⃣ لعرض كل التغييرات:'
\echo '   SELECT * FROM profit_audit_log ORDER BY created_at DESC LIMIT 50;'
\echo ''
\echo '3️⃣ لعرض التغييرات لطلب معين:'
\echo '   SELECT * FROM profit_audit_log WHERE order_id = ''order_xxx'' ORDER BY created_at;'
\echo ''
\echo '4️⃣ لعرض التغييرات حسب المصدر:'
\echo '   SELECT change_source, COUNT(*) FROM profit_audit_log GROUP BY change_source;'
\echo ''
\echo '🔍 الآن قم بإنشاء طلب جديد وتغيير حالته لاكتشاف المشكلة!'
\echo ''

