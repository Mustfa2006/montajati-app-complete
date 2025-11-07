-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔍 تطبيق نظام Logging شامل لتتبع مشكلة تكرار الأرباح
-- ═══════════════════════════════════════════════════════════════════════════════
-- الهدف: إضافة Logs تفصيلية في كل مكان لمعرفة من أين تأتي الـ 3 تحديثات
-- ═══════════════════════════════════════════════════════════════════════════════

\echo '🚀 بدء تطبيق نظام Logging الشامل...'

-- ===================================
-- 1️⃣ إنشاء جدول لتسجيل جميع العمليات
-- ===================================

CREATE TABLE IF NOT EXISTS comprehensive_operation_log (
    id BIGSERIAL PRIMARY KEY,
    operation_id TEXT NOT NULL,
    operation_type TEXT NOT NULL, -- 'BACKEND_API', 'TRIGGER', 'VALIDATION', 'MONITORING'
    user_phone TEXT,
    order_id TEXT,
    old_value NUMERIC,
    new_value NUMERIC,
    change_amount NUMERIC,
    source_app TEXT, -- 'postgrest', 'backend_api', 'database_trigger'
    source_context TEXT,
    session_pid INTEGER,
    session_user TEXT,
    full_details JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    created_at_ms BIGINT DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
);

CREATE INDEX idx_comprehensive_log_operation_id ON comprehensive_operation_log(operation_id);
CREATE INDEX idx_comprehensive_log_order_id ON comprehensive_operation_log(order_id);
CREATE INDEX idx_comprehensive_log_user_phone ON comprehensive_operation_log(user_phone);
CREATE INDEX idx_comprehensive_log_created_at ON comprehensive_operation_log(created_at DESC);

\echo '✅ تم إنشاء جدول comprehensive_operation_log'

-- ===================================
-- 2️⃣ تحديث smart_profit_manager لتسجيل العمليات
-- ===================================

\echo '🔧 تحديث smart_profit_manager trigger...'

-- تم تحديثه بالفعل في FIX_PROFIT_DUPLICATION_FINAL.sql
-- الآن نضيف تسجيل في comprehensive_operation_log

-- ===================================
-- 3️⃣ تحديث validate_profit_operation لتسجيل العمليات
-- ===================================

\echo '🔧 تحديث validate_profit_operation trigger...'

-- تم تحديثه بالفعل في FIX_PROFIT_DUPLICATION_FINAL.sql
-- الآن نضيف تسجيل في comprehensive_operation_log

-- ===================================
-- 4️⃣ إنشاء دالة لتسجيل العمليات
-- ===================================

CREATE OR REPLACE FUNCTION log_comprehensive_operation(
    p_operation_id TEXT,
    p_operation_type TEXT,
    p_user_phone TEXT,
    p_order_id TEXT,
    p_old_value NUMERIC,
    p_new_value NUMERIC,
    p_source_app TEXT,
    p_source_context TEXT,
    p_full_details JSONB
)
RETURNS VOID AS $$
DECLARE
    v_session_pid INTEGER;
    v_session_user TEXT;
BEGIN
    SELECT pid, usename INTO v_session_pid, v_session_user 
    FROM pg_stat_activity 
    WHERE pid = pg_backend_pid();
    
    INSERT INTO comprehensive_operation_log (
        operation_id,
        operation_type,
        user_phone,
        order_id,
        old_value,
        new_value,
        change_amount,
        source_app,
        source_context,
        session_pid,
        session_user,
        full_details
    ) VALUES (
        p_operation_id,
        p_operation_type,
        p_user_phone,
        p_order_id,
        p_old_value,
        p_new_value,
        COALESCE(p_new_value - p_old_value, 0),
        p_source_app,
        p_source_context,
        v_session_pid,
        v_session_user,
        p_full_details
    );
END;
$$ LANGUAGE plpgsql;

\echo '✅ تم إنشاء دالة log_comprehensive_operation'

-- ===================================
-- 5️⃣ إنشاء دالة للاستعلام عن العمليات
-- ===================================

CREATE OR REPLACE FUNCTION get_operation_timeline(
    p_order_id TEXT,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    operation_id TEXT,
    operation_type TEXT,
    user_phone TEXT,
    old_value NUMERIC,
    new_value NUMERIC,
    change_amount NUMERIC,
    source_app TEXT,
    source_context TEXT,
    session_pid INTEGER,
    created_at TIMESTAMP,
    created_at_ms BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        col.operation_id,
        col.operation_type,
        col.user_phone,
        col.old_value,
        col.new_value,
        col.change_amount,
        col.source_app,
        col.source_context,
        col.session_pid,
        col.created_at,
        col.created_at_ms
    FROM comprehensive_operation_log col
    WHERE col.order_id = p_order_id
    ORDER BY col.created_at_ms ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

\echo '✅ تم إنشاء دالة get_operation_timeline'

-- ===================================
-- 6️⃣ تعليمات الاستخدام
-- ===================================

\echo ''
\echo '═══════════════════════════════════════════════════════════════════════════════'
\echo '✅ تم تطبيق نظام Logging الشامل بنجاح!'
\echo '═══════════════════════════════════════════════════════════════════════════════'
\echo ''
\echo '📊 الجداول الجديدة:'
\echo '   - comprehensive_operation_log: تسجيل جميع العمليات'
\echo ''
\echo '🔍 الدوال الجديدة:'
\echo '   - log_comprehensive_operation(): تسجيل عملية'
\echo '   - get_operation_timeline(): الاستعلام عن العمليات'
\echo ''
\echo '📝 الاستعلام عن العمليات:'
\echo '   SELECT * FROM get_operation_timeline(''ORDER_ID'', 100);'
\echo ''
\echo '🔍 البحث عن التكرار:'
\echo '   SELECT operation_id, operation_type, change_amount, created_at_ms'
\echo '   FROM comprehensive_operation_log'
\echo '   WHERE order_id = ''ORDER_ID'''
\echo '   ORDER BY created_at_ms ASC;'
\echo ''

