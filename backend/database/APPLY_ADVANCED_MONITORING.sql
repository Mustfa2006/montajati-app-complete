-- ===================================
-- 🚀 تطبيق نظام الرصد المتقدم على قاعدة البيانات
-- Apply Advanced Monitoring System to Database
-- ===================================

-- هذا الملف يطبق نظام الرصد المتقدم خطوة بخطوة

\echo '🔧 الخطوة 1: إنشاء دالة تحليل المصدر...'

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
    ELSIF p_query ILIKE '%pgrst%' OR p_app_name = 'postgrest' THEN
        v_source_type := 'SUPABASE_API';
        v_confidence := 90;
        IF p_client_addr = '::1' OR p_client_addr = '127.0.0.1' THEN
            v_source_detail := 'Local API Call';
            IF p_query ILIKE '%SmartProfitTransfer%' THEN
                v_source_file := 'frontend/lib/services/smart_profit_transfer.dart';
                v_confidence := 80;
            ELSIF p_query ILIKE '%SmartProfitsManager%' THEN
                v_source_file := 'frontend/lib/services/smart_profits_manager.dart';
                v_confidence := 80;
            ELSIF p_query ILIKE '%AdminService%' THEN
                v_source_file := 'frontend/lib/services/admin_service.dart';
                v_confidence := 70;
            ELSE
                v_source_file := 'Unknown Service';
                v_confidence := 50;
            END IF;
        ELSE
            v_source_detail := 'Remote API Call from ' || p_client_addr::TEXT;
            v_source_file := 'External Client';
            v_confidence := 60;
        END IF;
    ELSIF p_app_name ILIKE '%node%' OR p_app_name ILIKE '%backend%' THEN
        v_source_type := 'BACKEND_DIRECT';
        v_source_detail := 'Backend Service: ' || p_app_name;
        IF p_query ILIKE '%integrated_waseet%' THEN
            v_source_file := 'backend/services/integrated_waseet_sync.js';
            v_confidence := 85;
        ELSIF p_query ILIKE '%order_sync%' THEN
            v_source_file := 'backend/services/order_sync_service.js';
            v_confidence := 85;
        ELSE
            v_source_file := 'backend/unknown_service.js';
            v_confidence := 40;
        END IF;
    END IF;
    
    RETURN QUERY SELECT v_source_type, v_source_detail, v_source_file, v_confidence;
END;
$$ LANGUAGE plpgsql;

\echo '✅ تم إنشاء دالة analyze_profit_change_source'

\echo '🔧 الخطوة 2: إنشاء دالة كشف التكرار...'

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
    SELECT id, audit_timestamp
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

\echo '✅ تم إنشاء دالة detect_profit_duplication'

\echo '🔧 الخطوة 3: إنشاء Trigger Function المتقدم...'

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
    v_expected_change := COALESCE(NEW.expected_profits, 0) - COALESCE(OLD.expected_profits, 0);
    v_achieved_change := COALESCE(NEW.achieved_profits, 0) - COALESCE(OLD.achieved_profits, 0);
    v_total_change := v_expected_change + v_achieved_change;
    
    v_order_id := current_setting('app.current_order_id', true);
    v_order_status := current_setting('app.current_order_status', true);
    
    SELECT pid, application_name, client_addr, client_port, backend_start, xact_start, query_start, state, wait_event_type, wait_event, query
    INTO v_session_info
    FROM pg_stat_activity
    WHERE pid = pg_backend_pid();
    
    SELECT * INTO v_source_info
    FROM analyze_profit_change_source(v_session_info.query, v_session_info.application_name, v_session_info.client_addr);
    
    SELECT * INTO v_duplicate_info
    FROM detect_profit_duplication(NEW.phone, v_expected_change, v_achieved_change, NOW());
    
    IF ABS(v_total_change) > 500000 THEN
        v_is_suspicious := TRUE;
        v_suspicious_reason := format('تغيير كبير جداً: %s د.ع', v_total_change);
    END IF;
    
    IF v_duplicate_info.is_duplicate THEN
        v_is_suspicious := TRUE;
        v_suspicious_reason := COALESCE(v_suspicious_reason || ' | ', '') || v_duplicate_info.reason;
    END IF;
    
    IF v_source_info.source_type = 'UNKNOWN' OR v_source_info.confidence < 50 THEN
        v_is_suspicious := TRUE;
        v_suspicious_reason := COALESCE(v_suspicious_reason || ' | ', '') || 'مصدر غير معروف';
    END IF;
    
    IF v_source_info.source_type = 'SUPABASE_API' AND v_order_id IS NULL THEN
        v_is_suspicious := TRUE;
        v_suspicious_reason := COALESCE(v_suspicious_reason || ' | ', '') || 'تحديث من Supabase API بدون سياق';
    END IF;
    
    v_raw_data := jsonb_build_object(
        'session', jsonb_build_object('pid', v_session_info.pid, 'app_name', v_session_info.application_name, 'client', v_session_info.client_addr::TEXT),
        'profits', jsonb_build_object('old_expected', OLD.expected_profits, 'new_expected', NEW.expected_profits, 'old_achieved', OLD.achieved_profits, 'new_achieved', NEW.achieved_profits),
        'context', jsonb_build_object('order_id', v_order_id, 'order_status', v_order_status)
    );
    
    INSERT INTO advanced_profit_audit (
        user_id, user_phone, order_id, order_status,
        old_expected_profits, new_expected_profits, expected_profits_change,
        old_achieved_profits, new_achieved_profits, achieved_profits_change, total_change,
        session_pid, session_application_name, session_client_addr, session_client_port,
        session_backend_start, session_xact_start, session_query_start, session_state, session_wait_event_type, session_wait_event,
        current_query, query_length,
        source_type, source_detail, source_file, source_confidence,
        operation_context, authorized_by, trigger_operation,
        is_suspicious, suspicious_reason, is_duplicate, duplicate_of, raw_data
    ) VALUES (
        NEW.id, NEW.phone, v_order_id, v_order_status,
        OLD.expected_profits, NEW.expected_profits, v_expected_change,
        OLD.achieved_profits, NEW.achieved_profits, v_achieved_change, v_total_change,
        v_session_info.pid, v_session_info.application_name, v_session_info.client_addr, v_session_info.client_port,
        v_session_info.backend_start, v_session_info.xact_start, v_session_info.query_start, v_session_info.state, v_session_info.wait_event_type, v_session_info.wait_event,
        v_session_info.query, LENGTH(v_session_info.query),
        v_source_info.source_type, v_source_info.source_detail, v_source_info.source_file, v_source_info.confidence,
        current_setting('app.operation_context', true), current_setting('app.authorized_by', true), TG_OP,
        v_is_suspicious, v_suspicious_reason, v_duplicate_info.is_duplicate, v_duplicate_info.duplicate_of, v_raw_data
    );
    
    IF v_is_suspicious THEN
        RAISE WARNING '🚨 عملية مشبوهة على أرباح المستخدم %: %', NEW.phone, v_suspicious_reason;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

\echo '✅ تم إنشاء Trigger Function المتقدم'

\echo '🔧 الخطوة 4: تفعيل Trigger على جدول users...'

DROP TRIGGER IF EXISTS trigger_advanced_profit_monitor ON users;

CREATE TRIGGER trigger_advanced_profit_monitor
    AFTER UPDATE OF expected_profits, achieved_profits ON users
    FOR EACH ROW
    EXECUTE FUNCTION advanced_monitor_profit_changes();

\echo '✅ تم تفعيل Trigger على جدول users'

\echo '✅ ========================================'
\echo '✅ تم تطبيق نظام الرصد المتقدم بنجاح!'
\echo '✅ ========================================'
\echo ''
\echo '📖 الآن يمكنك:'
\echo '   1. إضافة طلب جديد'
\echo '   2. تغيير حالة الطلب'
\echo '   3. مراقبة النتائج في advanced_profit_audit'
\echo ''
\echo '📊 استعلامات مفيدة:'
\echo '   SELECT * FROM advanced_profit_audit ORDER BY audit_timestamp DESC LIMIT 20;'
\echo '   SELECT * FROM advanced_profit_audit WHERE is_suspicious = TRUE;'
\echo '   SELECT * FROM advanced_profit_audit WHERE is_duplicate = TRUE;'

