-- ===================================
-- 🔍 نظام الرصد المتقدم للأرباح - الأقوى في العالم
-- Advanced Profit Monitoring System - The Most Powerful
-- ===================================

-- هذا النظام يرصد كل شيء بدقة عالية جداً:
-- ✅ من أين جاء التغيير (Backend/Frontend/Database)
-- ✅ أي ملف قام بالتغيير
-- ✅ أي كود بالضبط
-- ✅ كل معلومات الجلسة والاستعلام
-- ✅ تحليل ذكي للمصدر الحقيقي

-- ===================================
-- 1️⃣ جدول الرصد المتقدم
-- ===================================

DROP TABLE IF EXISTS advanced_profit_audit CASCADE;

CREATE TABLE advanced_profit_audit (
    -- معلومات أساسية
    id BIGSERIAL PRIMARY KEY,
    audit_timestamp TIMESTAMPTZ DEFAULT NOW(),
    
    -- معلومات المستخدم
    user_id UUID,
    user_phone TEXT,
    
    -- معلومات الطلب
    order_id TEXT,
    order_status TEXT,
    
    -- معلومات الأرباح
    old_expected_profits DECIMAL(15,2),
    new_expected_profits DECIMAL(15,2),
    expected_profits_change DECIMAL(15,2),
    old_achieved_profits DECIMAL(15,2),
    new_achieved_profits DECIMAL(15,2),
    achieved_profits_change DECIMAL(15,2),
    total_change DECIMAL(15,2),
    
    -- 🔍 معلومات الجلسة الكاملة
    session_pid INTEGER,
    session_application_name TEXT,
    session_client_addr INET,
    session_client_port INTEGER,
    session_backend_start TIMESTAMPTZ,
    session_xact_start TIMESTAMPTZ,
    session_query_start TIMESTAMPTZ,
    session_state TEXT,
    session_wait_event_type TEXT,
    session_wait_event TEXT,
    
    -- 🔍 معلومات الاستعلام
    current_query TEXT,
    previous_query TEXT,
    query_length INTEGER,
    
    -- 🔍 تحليل المصدر
    source_type TEXT, -- 'DATABASE_TRIGGER', 'BACKEND_API', 'FRONTEND_DIRECT', 'UNKNOWN'
    source_detail TEXT, -- اسم الـ function أو الـ route
    source_file TEXT, -- اسم الملف المتوقع
    source_confidence INTEGER, -- نسبة الثقة في تحديد المصدر (0-100)
    
    -- 🔍 معلومات السياق
    operation_context TEXT,
    authorized_by TEXT,
    trigger_operation TEXT, -- INSERT, UPDATE, DELETE
    
    -- 🔍 Stack Trace
    call_stack TEXT,
    
    -- 🔍 تحليل ذكي
    is_suspicious BOOLEAN DEFAULT FALSE,
    suspicious_reason TEXT,
    is_duplicate BOOLEAN DEFAULT FALSE,
    duplicate_of BIGINT,
    
    -- 🔍 معلومات إضافية
    notes TEXT,
    raw_data JSONB
);

-- إنشاء indexes للبحث السريع
CREATE INDEX idx_advanced_audit_timestamp ON advanced_profit_audit(audit_timestamp DESC);
CREATE INDEX idx_advanced_audit_user_phone ON advanced_profit_audit(user_phone);
CREATE INDEX idx_advanced_audit_order_id ON advanced_profit_audit(order_id);
CREATE INDEX idx_advanced_audit_source_type ON advanced_profit_audit(source_type);
CREATE INDEX idx_advanced_audit_suspicious ON advanced_profit_audit(is_suspicious) WHERE is_suspicious = TRUE;
CREATE INDEX idx_advanced_audit_duplicate ON advanced_profit_audit(is_duplicate) WHERE is_duplicate = TRUE;

-- ===================================
-- 2️⃣ دالة تحليل المصدر الذكية
-- ===================================

CREATE OR REPLACE FUNCTION analyze_profit_change_source(
    p_query TEXT,
    p_app_name TEXT,
    p_client_addr INET
) RETURNS TABLE (
    source_type TEXT,
    source_detail TEXT,
    source_file TEXT,
    confidence INTEGER
) AS $$
DECLARE
    v_source_type TEXT := 'UNKNOWN';
    v_source_detail TEXT := 'غير محدد';
    v_source_file TEXT := NULL;
    v_confidence INTEGER := 0;
BEGIN
    -- تحليل الاستعلام لتحديد المصدر
    
    -- 🔍 Case 1: Database Trigger
    IF p_query ILIKE '%smart_profit_manager%' THEN
        v_source_type := 'DATABASE_TRIGGER';
        v_source_detail := 'smart_profit_manager()';
        v_source_file := 'backend/database/smart_profit_manager.sql';
        v_confidence := 100;
        
    ELSIF p_query ILIKE '%validate_profit_operation%' THEN
        v_source_type := 'DATABASE_TRIGGER';
        v_source_detail := 'validate_profit_operation()';
        v_source_file := 'backend/database/profit_protection.sql';
        v_confidence := 100;
        
    ELSIF p_query ILIKE '%auto_update_profits%' THEN
        v_source_type := 'DATABASE_TRIGGER';
        v_source_detail := 'auto_update_profits_on_status_change()';
        v_source_file := 'backend/database/automatic_profit_system.sql';
        v_confidence := 100;
    
    -- 🔍 Case 2: PostgREST (Supabase API)
    ELSIF p_query ILIKE '%pgrst%' OR p_app_name = 'postgrest' THEN
        v_source_type := 'SUPABASE_API';
        v_confidence := 90;
        
        -- محاولة تحديد من أين جاء الطلب
        IF p_client_addr = '::1' OR p_client_addr = '127.0.0.1' THEN
            v_source_detail := 'Local API Call (Backend or Frontend on same machine)';
            
            -- تحليل الـ query لمعرفة المزيد
            IF p_query ILIKE '%SmartProfitTransfer%' OR p_query ILIKE '%smart_profit%' THEN
                v_source_file := 'frontend/lib/services/smart_profit_transfer.dart';
                v_confidence := 80;
            ELSIF p_query ILIKE '%SmartProfitsManager%' OR p_query ILIKE '%recalculate%' THEN
                v_source_file := 'frontend/lib/services/smart_profits_manager.dart';
                v_confidence := 80;
            ELSIF p_query ILIKE '%AdminService%' OR p_query ILIKE '%admin%' THEN
                v_source_file := 'frontend/lib/services/admin_service.dart';
                v_confidence := 70;
            ELSE
                v_source_file := 'Unknown Frontend or Backend Service';
                v_confidence := 50;
            END IF;
        ELSE
            v_source_detail := 'Remote API Call from ' || p_client_addr::TEXT;
            v_source_file := 'External Client';
            v_confidence := 60;
        END IF;
    
    -- 🔍 Case 3: Backend Direct
    ELSIF p_app_name ILIKE '%node%' OR p_app_name ILIKE '%backend%' THEN
        v_source_type := 'BACKEND_DIRECT';
        v_source_detail := 'Backend Service: ' || p_app_name;
        
        -- محاولة تحديد الملف من الـ query
        IF p_query ILIKE '%integrated_waseet%' THEN
            v_source_file := 'backend/services/integrated_waseet_sync.js';
            v_confidence := 85;
        ELSIF p_query ILIKE '%order_sync%' THEN
            v_source_file := 'backend/services/order_sync_service.js';
            v_confidence := 85;
        ELSIF p_query ILIKE '%admin%' THEN
            v_source_file := 'backend/routes/admin.js';
            v_confidence := 75;
        ELSE
            v_source_file := 'backend/unknown_service.js';
            v_confidence := 40;
        END IF;
    
    -- 🔍 Case 4: Frontend Direct (Supabase Client)
    ELSIF p_app_name ILIKE '%supabase%' OR p_app_name ILIKE '%flutter%' THEN
        v_source_type := 'FRONTEND_DIRECT';
        v_source_detail := 'Frontend Supabase Client';
        v_source_file := 'frontend/lib/services/supabase_service.dart';
        v_confidence := 70;
    
    END IF;
    
    RETURN QUERY SELECT v_source_type, v_source_detail, v_source_file, v_confidence;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 3️⃣ دالة كشف التكرار الذكية
-- ===================================

CREATE OR REPLACE FUNCTION detect_profit_duplication(
    p_user_phone TEXT,
    p_expected_change DECIMAL,
    p_achieved_change DECIMAL,
    p_timestamp TIMESTAMPTZ
) RETURNS TABLE (
    is_duplicate BOOLEAN,
    duplicate_of BIGINT,
    reason TEXT
) AS $$
DECLARE
    v_is_duplicate BOOLEAN := FALSE;
    v_duplicate_of BIGINT := NULL;
    v_reason TEXT := NULL;
    v_recent_record RECORD;
BEGIN
    -- البحث عن تغييرات مماثلة في آخر 10 ثواني
    SELECT id, audit_timestamp, expected_profits_change, achieved_profits_change
    INTO v_recent_record
    FROM advanced_profit_audit
    WHERE user_phone = p_user_phone
      AND ABS(expected_profits_change - p_expected_change) < 0.01
      AND ABS(achieved_profits_change - p_achieved_change) < 0.01
      AND audit_timestamp > (p_timestamp - INTERVAL '10 seconds')
      AND audit_timestamp < p_timestamp
    ORDER BY audit_timestamp DESC
    LIMIT 1;
    
    IF FOUND THEN
        v_is_duplicate := TRUE;
        v_duplicate_of := v_recent_record.id;
        v_reason := format(
            'تكرار لنفس التغيير (ID: %s) منذ %s ثانية',
            v_recent_record.id,
            ROUND(EXTRACT(EPOCH FROM (p_timestamp - v_recent_record.audit_timestamp))::NUMERIC, 2)
        );
    END IF;
    
    RETURN QUERY SELECT v_is_duplicate, v_duplicate_of, v_reason;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 4️⃣ Trigger Function المتقدم للرصد
-- ===================================

CREATE OR REPLACE FUNCTION advanced_monitor_profit_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_session_info RECORD;
    v_source_info RECORD;
    v_duplicate_info RECORD;
    v_order_id TEXT;
    v_order_status TEXT;
    v_expected_change DECIMAL;
    v_achieved_change DECIMAL;
    v_total_change DECIMAL;
    v_is_suspicious BOOLEAN := FALSE;
    v_suspicious_reason TEXT := NULL;
    v_raw_data JSONB;
BEGIN
    -- حساب التغييرات
    v_expected_change := COALESCE(NEW.expected_profits, 0) - COALESCE(OLD.expected_profits, 0);
    v_achieved_change := COALESCE(NEW.achieved_profits, 0) - COALESCE(OLD.achieved_profits, 0);
    v_total_change := v_expected_change + v_achieved_change;
    
    -- الحصول على معلومات الطلب من السياق
    v_order_id := current_setting('app.current_order_id', true);
    v_order_status := current_setting('app.current_order_status', true);
    
    -- 🔍 جمع معلومات الجلسة الكاملة من pg_stat_activity
    SELECT 
        pid,
        application_name,
        client_addr,
        client_port,
        backend_start,
        xact_start,
        query_start,
        state,
        wait_event_type,
        wait_event,
        query,
        COALESCE(
            LAG(query) OVER (PARTITION BY pid ORDER BY query_start),
            'N/A'
        ) as previous_query
    INTO v_session_info
    FROM pg_stat_activity
    WHERE pid = pg_backend_pid();
    
    -- 🔍 تحليل المصدر
    SELECT * INTO v_source_info
    FROM analyze_profit_change_source(
        v_session_info.query,
        v_session_info.application_name,
        v_session_info.client_addr
    );
    
    -- 🔍 كشف التكرار
    SELECT * INTO v_duplicate_info
    FROM detect_profit_duplication(
        NEW.phone,
        v_expected_change,
        v_achieved_change,
        NOW()
    );
    
    -- 🔍 كشف الحالات المشبوهة
    
    -- حالة 1: تغيير كبير جداً (أكثر من 500,000 دينار)
    IF ABS(v_total_change) > 500000 THEN
        v_is_suspicious := TRUE;
        v_suspicious_reason := format('تغيير كبير جداً: %s د.ع', v_total_change);
    END IF;
    
    -- حالة 2: تكرار في نفس الثانية
    IF v_duplicate_info.is_duplicate THEN
        v_is_suspicious := TRUE;
        v_suspicious_reason := COALESCE(v_suspicious_reason || ' | ', '') || v_duplicate_info.reason;
    END IF;
    
    -- حالة 3: مصدر غير معروف
    IF v_source_info.source_type = 'UNKNOWN' OR v_source_info.confidence < 50 THEN
        v_is_suspicious := TRUE;
        v_suspicious_reason := COALESCE(v_suspicious_reason || ' | ', '') || 'مصدر غير معروف أو ثقة منخفضة';
    END IF;
    
    -- حالة 4: تحديث من PostgREST بدون سياق
    IF v_source_info.source_type = 'SUPABASE_API' AND v_order_id IS NULL THEN
        v_is_suspicious := TRUE;
        v_suspicious_reason := COALESCE(v_suspicious_reason || ' | ', '') || 'تحديث من Supabase API بدون سياق طلب';
    END IF;
    
    -- 🔍 تجميع البيانات الخام في JSONB
    v_raw_data := jsonb_build_object(
        'session', jsonb_build_object(
            'pid', v_session_info.pid,
            'app_name', v_session_info.application_name,
            'client', v_session_info.client_addr::TEXT || ':' || v_session_info.client_port::TEXT,
            'backend_start', v_session_info.backend_start,
            'state', v_session_info.state
        ),
        'profits', jsonb_build_object(
            'old_expected', OLD.expected_profits,
            'new_expected', NEW.expected_profits,
            'old_achieved', OLD.achieved_profits,
            'new_achieved', NEW.achieved_profits
        ),
        'context', jsonb_build_object(
            'order_id', v_order_id,
            'order_status', v_order_status,
            'operation_context', current_setting('app.operation_context', true),
            'authorized_by', current_setting('app.authorized_by', true)
        )
    );
    
    -- 📝 إدراج سجل الرصد
    INSERT INTO advanced_profit_audit (
        user_id, user_phone,
        order_id, order_status,
        old_expected_profits, new_expected_profits, expected_profits_change,
        old_achieved_profits, new_achieved_profits, achieved_profits_change,
        total_change,
        session_pid, session_application_name, session_client_addr, session_client_port,
        session_backend_start, session_xact_start, session_query_start,
        session_state, session_wait_event_type, session_wait_event,
        current_query, previous_query, query_length,
        source_type, source_detail, source_file, source_confidence,
        operation_context, authorized_by, trigger_operation,
        is_suspicious, suspicious_reason,
        is_duplicate, duplicate_of,
        raw_data
    ) VALUES (
        NEW.id, NEW.phone,
        v_order_id, v_order_status,
        OLD.expected_profits, NEW.expected_profits, v_expected_change,
        OLD.achieved_profits, NEW.achieved_profits, v_achieved_change,
        v_total_change,
        v_session_info.pid, v_session_info.application_name, 
        v_session_info.client_addr, v_session_info.client_port,
        v_session_info.backend_start, v_session_info.xact_start, v_session_info.query_start,
        v_session_info.state, v_session_info.wait_event_type, v_session_info.wait_event,
        v_session_info.query, v_session_info.previous_query, LENGTH(v_session_info.query),
        v_source_info.source_type, v_source_info.source_detail, 
        v_source_info.source_file, v_source_info.confidence,
        current_setting('app.operation_context', true),
        current_setting('app.authorized_by', true),
        TG_OP,
        v_is_suspicious, v_suspicious_reason,
        v_duplicate_info.is_duplicate, v_duplicate_info.duplicate_of,
        v_raw_data
    );
    
    -- 🚨 إذا كانت العملية مشبوهة، أرسل تحذير
    IF v_is_suspicious THEN
        RAISE WARNING '🚨 عملية مشبوهة على أرباح المستخدم %: %', NEW.phone, v_suspicious_reason;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 5️⃣ إنشاء Trigger على جدول users
-- ===================================

DROP TRIGGER IF EXISTS trigger_advanced_profit_monitor ON users;

CREATE TRIGGER trigger_advanced_profit_monitor
    AFTER UPDATE OF expected_profits, achieved_profits ON users
    FOR EACH ROW
    EXECUTE FUNCTION advanced_monitor_profit_changes();

COMMENT ON TRIGGER trigger_advanced_profit_monitor ON users IS
'نظام الرصد المتقدم للأرباح - يرصد كل تغيير بدقة عالية';

-- ===================================
-- 6️⃣ دوال مساعدة للاستعلام والتحليل
-- ===================================

-- دالة عرض آخر التغييرات
CREATE OR REPLACE FUNCTION get_recent_profit_changes(
    p_limit INTEGER DEFAULT 20
) RETURNS TABLE (
    id BIGINT,
    timestamp TIMESTAMPTZ,
    user_phone TEXT,
    order_id TEXT,
    expected_change DECIMAL,
    achieved_change DECIMAL,
    source_type TEXT,
    source_file TEXT,
    is_suspicious BOOLEAN,
    suspicious_reason TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.audit_timestamp,
        a.user_phone,
        a.order_id,
        a.expected_profits_change,
        a.achieved_profits_change,
        a.source_type,
        a.source_file,
        a.is_suspicious,
        a.suspicious_reason
    FROM advanced_profit_audit a
    ORDER BY a.audit_timestamp DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- دالة عرض التغييرات المشبوهة فقط
CREATE OR REPLACE FUNCTION get_suspicious_profit_changes(
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    id BIGINT,
    timestamp TIMESTAMPTZ,
    user_phone TEXT,
    order_id TEXT,
    expected_change DECIMAL,
    achieved_change DECIMAL,
    source_type TEXT,
    source_file TEXT,
    suspicious_reason TEXT,
    query_preview TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.audit_timestamp,
        a.user_phone,
        a.order_id,
        a.expected_profits_change,
        a.achieved_profits_change,
        a.source_type,
        a.source_file,
        a.suspicious_reason,
        LEFT(a.current_query, 200) as query_preview
    FROM advanced_profit_audit a
    WHERE a.is_suspicious = TRUE
    ORDER BY a.audit_timestamp DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- دالة عرض التكرارات
CREATE OR REPLACE FUNCTION get_duplicate_profit_changes(
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    id BIGINT,
    timestamp TIMESTAMPTZ,
    user_phone TEXT,
    order_id TEXT,
    expected_change DECIMAL,
    achieved_change DECIMAL,
    duplicate_of BIGINT,
    source_type TEXT,
    source_file TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.audit_timestamp,
        a.user_phone,
        a.order_id,
        a.expected_profits_change,
        a.achieved_profits_change,
        a.duplicate_of,
        a.source_type,
        a.source_file
    FROM advanced_profit_audit a
    WHERE a.is_duplicate = TRUE
    ORDER BY a.audit_timestamp DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- دالة تحليل شامل لمستخدم معين
CREATE OR REPLACE FUNCTION analyze_user_profit_history(
    p_user_phone TEXT,
    p_hours INTEGER DEFAULT 24
) RETURNS TABLE (
    total_changes INTEGER,
    suspicious_changes INTEGER,
    duplicate_changes INTEGER,
    total_expected_change DECIMAL,
    total_achieved_change DECIMAL,
    sources_used TEXT[],
    most_common_source TEXT,
    timeline JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT
            COUNT(*) as total,
            COUNT(*) FILTER (WHERE is_suspicious) as suspicious,
            COUNT(*) FILTER (WHERE is_duplicate) as duplicates,
            SUM(expected_profits_change) as exp_change,
            SUM(achieved_profits_change) as ach_change,
            array_agg(DISTINCT source_type) as sources,
            mode() WITHIN GROUP (ORDER BY source_type) as common_source
        FROM advanced_profit_audit
        WHERE user_phone = p_user_phone
          AND audit_timestamp > NOW() - (p_hours || ' hours')::INTERVAL
    ),
    timeline_data AS (
        SELECT jsonb_agg(
            jsonb_build_object(
                'timestamp', audit_timestamp,
                'expected_change', expected_profits_change,
                'achieved_change', achieved_profits_change,
                'source', source_type,
                'file', source_file,
                'suspicious', is_suspicious
            ) ORDER BY audit_timestamp
        ) as timeline
        FROM advanced_profit_audit
        WHERE user_phone = p_user_phone
          AND audit_timestamp > NOW() - (p_hours || ' hours')::INTERVAL
    )
    SELECT
        s.total::INTEGER,
        s.suspicious::INTEGER,
        s.duplicates::INTEGER,
        s.exp_change,
        s.ach_change,
        s.sources,
        s.common_source,
        t.timeline
    FROM stats s, timeline_data t;
END;
$$ LANGUAGE plpgsql;

-- دالة عرض التفاصيل الكاملة لسجل معين
CREATE OR REPLACE FUNCTION get_audit_details(p_audit_id BIGINT)
RETURNS TABLE (
    detail_type TEXT,
    detail_value TEXT
) AS $$
DECLARE
    v_record RECORD;
BEGIN
    SELECT * INTO v_record FROM advanced_profit_audit WHERE id = p_audit_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'سجل الرصد % غير موجود', p_audit_id;
    END IF;

    RETURN QUERY
    SELECT 'ID'::TEXT, v_record.id::TEXT
    UNION ALL SELECT 'Timestamp', v_record.audit_timestamp::TEXT
    UNION ALL SELECT 'User Phone', v_record.user_phone
    UNION ALL SELECT 'Order ID', COALESCE(v_record.order_id, 'N/A')
    UNION ALL SELECT 'Order Status', COALESCE(v_record.order_status, 'N/A')
    UNION ALL SELECT '---', '---'
    UNION ALL SELECT 'Expected Profits (Old)', v_record.old_expected_profits::TEXT
    UNION ALL SELECT 'Expected Profits (New)', v_record.new_expected_profits::TEXT
    UNION ALL SELECT 'Expected Change', v_record.expected_profits_change::TEXT
    UNION ALL SELECT 'Achieved Profits (Old)', v_record.old_achieved_profits::TEXT
    UNION ALL SELECT 'Achieved Profits (New)', v_record.new_achieved_profits::TEXT
    UNION ALL SELECT 'Achieved Change', v_record.achieved_profits_change::TEXT
    UNION ALL SELECT 'Total Change', v_record.total_change::TEXT
    UNION ALL SELECT '---', '---'
    UNION ALL SELECT 'Source Type', v_record.source_type
    UNION ALL SELECT 'Source Detail', v_record.source_detail
    UNION ALL SELECT 'Source File', COALESCE(v_record.source_file, 'N/A')
    UNION ALL SELECT 'Source Confidence', v_record.source_confidence::TEXT || '%'
    UNION ALL SELECT '---', '---'
    UNION ALL SELECT 'Session PID', v_record.session_pid::TEXT
    UNION ALL SELECT 'Application Name', v_record.session_application_name
    UNION ALL SELECT 'Client Address', v_record.session_client_addr::TEXT
    UNION ALL SELECT 'Client Port', COALESCE(v_record.session_client_port::TEXT, 'N/A')
    UNION ALL SELECT 'Session State', v_record.session_state
    UNION ALL SELECT '---', '---'
    UNION ALL SELECT 'Is Suspicious', v_record.is_suspicious::TEXT
    UNION ALL SELECT 'Suspicious Reason', COALESCE(v_record.suspicious_reason, 'N/A')
    UNION ALL SELECT 'Is Duplicate', v_record.is_duplicate::TEXT
    UNION ALL SELECT 'Duplicate Of', COALESCE(v_record.duplicate_of::TEXT, 'N/A')
    UNION ALL SELECT '---', '---'
    UNION ALL SELECT 'Current Query', LEFT(v_record.current_query, 500)
    UNION ALL SELECT 'Previous Query', LEFT(COALESCE(v_record.previous_query, 'N/A'), 500);
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- ✅ تم إنشاء نظام الرصد المتقدم
-- ===================================

DO $$
BEGIN
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ تم إنشاء نظام الرصد المتقدم للأرباح';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 الجداول المنشأة:';
    RAISE NOTICE '   - advanced_profit_audit (جدول الرصد الرئيسي)';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 الدوال المنشأة:';
    RAISE NOTICE '   - analyze_profit_change_source() (تحليل المصدر)';
    RAISE NOTICE '   - detect_profit_duplication() (كشف التكرار)';
    RAISE NOTICE '   - advanced_monitor_profit_changes() (الرصد المتقدم)';
    RAISE NOTICE '   - get_recent_profit_changes() (عرض آخر التغييرات)';
    RAISE NOTICE '   - get_suspicious_profit_changes() (عرض المشبوهات)';
    RAISE NOTICE '   - get_duplicate_profit_changes() (عرض التكرارات)';
    RAISE NOTICE '   - analyze_user_profit_history() (تحليل شامل)';
    RAISE NOTICE '   - get_audit_details() (تفاصيل كاملة)';
    RAISE NOTICE '';
    RAISE NOTICE '⚡ Triggers المفعلة:';
    RAISE NOTICE '   - trigger_advanced_profit_monitor (على جدول users)';
    RAISE NOTICE '';
    RAISE NOTICE '📖 أمثلة الاستخدام:';
    RAISE NOTICE '   SELECT * FROM get_recent_profit_changes(20);';
    RAISE NOTICE '   SELECT * FROM get_suspicious_profit_changes(50);';
    RAISE NOTICE '   SELECT * FROM get_duplicate_profit_changes(50);';
    RAISE NOTICE '   SELECT * FROM analyze_user_profit_history(''07566666666'', 24);';
    RAISE NOTICE '   SELECT * FROM get_audit_details(1);';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 الآن يمكنك إضافة طلب وتغيير حالته لرؤية النظام يعمل!';
END $$;

