-- ===================================
-- 🕵️ المحقق النهائي للأرباح
-- يكشف كل شيء بالتفصيل الممل!
-- ===================================

-- 1️⃣ تحديث دالة التحليل لتكون أكثر ذكاءً
CREATE OR REPLACE FUNCTION analyze_profit_change_source(
    p_query TEXT,
    p_app_name TEXT,
    p_client_addr INET
) RETURNS TABLE (
    source_type TEXT,
    source_detail TEXT,
    source_file TEXT,
    source_function TEXT,
    source_line_number TEXT,
    confidence INTEGER,
    full_analysis TEXT
) AS $$
DECLARE
    v_source_type TEXT := 'UNKNOWN';
    v_source_detail TEXT := 'غير محدد';
    v_source_file TEXT := NULL;
    v_source_function TEXT := NULL;
    v_source_line_number TEXT := NULL;
    v_confidence INTEGER := 0;
    v_full_analysis TEXT := '';
BEGIN
    v_full_analysis := '🔍 تحليل عميق للمصدر:' || E'\n';
    v_full_analysis := v_full_analysis || '📋 Query: ' || COALESCE(SUBSTRING(p_query, 1, 500), 'NULL') || E'\n';
    v_full_analysis := v_full_analysis || '📱 App Name: ' || COALESCE(p_app_name, 'NULL') || E'\n';
    v_full_analysis := v_full_analysis || '🌐 Client Addr: ' || COALESCE(p_client_addr::TEXT, 'NULL') || E'\n';
    
    -- ===================================
    -- 🔍 تحليل Database Triggers
    -- ===================================
    IF p_query ILIKE '%smart_profit_manager%' THEN
        v_source_type := 'DATABASE_TRIGGER';
        v_source_detail := 'smart_profit_manager() trigger';
        v_source_file := 'backend/database/smart_profit_manager.sql';
        v_source_function := 'smart_profit_manager()';
        v_source_line_number := 'Line 1-500';
        v_confidence := 100;
        v_full_analysis := v_full_analysis || '✅ مصدر مؤكد: Database Trigger (smart_profit_manager)' || E'\n';
    
    ELSIF p_query ILIKE '%validate_profit_operation%' THEN
        v_source_type := 'DATABASE_TRIGGER';
        v_source_detail := 'validate_profit_operation() trigger';
        v_source_file := 'backend/database/profit_protection.sql';
        v_source_function := 'validate_profit_operation()';
        v_confidence := 100;
        v_full_analysis := v_full_analysis || '✅ مصدر مؤكد: Database Trigger (validate_profit_operation)' || E'\n';
    
    -- ===================================
    -- 🔍 تحليل PostgREST (Supabase API)
    -- ===================================
    ELSIF p_query ILIKE '%pgrst%' OR p_app_name = 'postgrest' THEN
        v_source_type := 'SUPABASE_API';
        v_confidence := 90;
        v_full_analysis := v_full_analysis || '⚠️ تحديث من Supabase API (PostgREST)' || E'\n';
        
        -- تحليل أعمق للـ query
        IF p_query ILIKE '%UPDATE%users%expected_profits%' THEN
            v_full_analysis := v_full_analysis || '📝 نوع العملية: UPDATE على جدول users' || E'\n';
            v_full_analysis := v_full_analysis || '💰 الحقول المتأثرة: expected_profits' || E'\n';
        END IF;
        
        IF p_query ILIKE '%UPDATE%users%achieved_profits%' THEN
            v_full_analysis := v_full_analysis || '📝 نوع العملية: UPDATE على جدول users' || E'\n';
            v_full_analysis := v_full_analysis || '💰 الحقول المتأثرة: achieved_profits' || E'\n';
        END IF;
        
        -- تحليل Client Address
        IF p_client_addr IS NULL THEN
            v_source_detail := 'Supabase API - Internal Call (client_addr = NULL)';
            v_source_file := 'UNKNOWN - Internal Supabase Process';
            v_full_analysis := v_full_analysis || '🔴 تحذير: client_addr = NULL (عملية داخلية من Supabase!)' || E'\n';
            v_full_analysis := v_full_analysis || '🔴 هذا يعني أن العملية ليست من Frontend أو Backend مباشرة!' || E'\n';
            v_full_analysis := v_full_analysis || '🔴 الاحتمالات:' || E'\n';
            v_full_analysis := v_full_analysis || '   1. Supabase Edge Function' || E'\n';
            v_full_analysis := v_full_analysis || '   2. Supabase Database Webhook' || E'\n';
            v_full_analysis := v_full_analysis || '   3. Supabase Realtime Trigger' || E'\n';
            v_full_analysis := v_full_analysis || '   4. Multiple App Instances' || E'\n';
            v_full_analysis := v_full_analysis || '   5. Background Service' || E'\n';
            v_confidence := 50;
            
        ELSIF p_client_addr = '::1' OR p_client_addr = '127.0.0.1' THEN
            v_source_detail := 'Local API Call from localhost';
            v_full_analysis := v_full_analysis || '🟡 تحديث من localhost (::1 أو 127.0.0.1)' || E'\n';
            
            -- محاولة تحديد الملف من الـ query
            IF p_query ILIKE '%SmartProfitTransfer%' OR p_query ILIKE '%smart_profit_transfer%' THEN
                v_source_file := 'frontend/lib/services/smart_profit_transfer.dart';
                v_source_function := 'SmartProfitTransfer.transferOrderProfit()';
                v_source_line_number := 'Lines 118-127';
                v_confidence := 80;
                v_full_analysis := v_full_analysis || '✅ مصدر محتمل: SmartProfitTransfer.transferOrderProfit()' || E'\n';
                
            ELSIF p_query ILIKE '%SmartProfitsManager%' OR p_query ILIKE '%smart_profits_manager%' THEN
                v_source_file := 'frontend/lib/services/smart_profits_manager.dart';
                v_source_function := 'SmartProfitsManager.smartRecalculateAndUpdate()';
                v_confidence := 80;
                v_full_analysis := v_full_analysis || '✅ مصدر محتمل: SmartProfitsManager' || E'\n';
                
            ELSIF p_query ILIKE '%ProfitsCalculatorService%' OR p_query ILIKE '%recalculateProfitsFromOrders%' THEN
                v_source_file := 'frontend/lib/services/profits_calculator_service.dart';
                v_source_function := 'ProfitsCalculatorService.recalculateProfitsFromOrders()';
                v_source_line_number := 'Lines 349-356';
                v_confidence := 80;
                v_full_analysis := v_full_analysis || '✅ مصدر محتمل: ProfitsCalculatorService.recalculateProfitsFromOrders()' || E'\n';
                
            ELSIF p_query ILIKE '%AdminService%' THEN
                v_source_file := 'frontend/lib/services/admin_service.dart';
                v_source_function := 'AdminService.updateOrderStatus()';
                v_confidence := 70;
                v_full_analysis := v_full_analysis || '🟡 مصدر محتمل: AdminService' || E'\n';
                
            ELSE
                v_source_file := 'UNKNOWN - Local Service';
                v_source_function := 'UNKNOWN';
                v_confidence := 40;
                v_full_analysis := v_full_analysis || '🔴 لم نستطع تحديد الملف المحدد!' || E'\n';
            END IF;
            
        ELSE
            v_source_detail := 'Remote API Call from ' || p_client_addr::TEXT;
            v_source_file := 'External Client: ' || p_client_addr::TEXT;
            v_full_analysis := v_full_analysis || '🌐 تحديث من عميل خارجي: ' || p_client_addr::TEXT || E'\n';
            v_confidence := 60;
        END IF;
    
    -- ===================================
    -- 🔍 تحليل Backend Direct
    -- ===================================
    ELSIF p_app_name ILIKE '%node%' OR p_app_name ILIKE '%backend%' THEN
        v_source_type := 'BACKEND_DIRECT';
        v_source_detail := 'Backend Service: ' || p_app_name;
        v_full_analysis := v_full_analysis || '🟢 تحديث من Backend مباشرة' || E'\n';
        
        IF p_query ILIKE '%integrated_waseet%' THEN
            v_source_file := 'backend/services/integrated_waseet_sync.js';
            v_source_function := 'IntegratedWaseetSync.syncOrders()';
            v_confidence := 85;
            v_full_analysis := v_full_analysis || '✅ مصدر محتمل: integrated_waseet_sync.js' || E'\n';
            
        ELSIF p_query ILIKE '%order_sync%' THEN
            v_source_file := 'backend/services/order_sync_service.js';
            v_source_function := 'OrderSyncService';
            v_confidence := 85;
            v_full_analysis := v_full_analysis || '✅ مصدر محتمل: order_sync_service.js' || E'\n';
            
        ELSE
            v_source_file := 'backend/unknown_service.js';
            v_source_function := 'UNKNOWN';
            v_confidence := 40;
            v_full_analysis := v_full_analysis || '🔴 لم نستطع تحديد الملف المحدد!' || E'\n';
        END IF;
    END IF;
    
    v_full_analysis := v_full_analysis || '📊 نسبة الثقة: ' || v_confidence || '%' || E'\n';
    
    RETURN QUERY SELECT 
        v_source_type, 
        v_source_detail, 
        v_source_file, 
        v_source_function,
        v_source_line_number,
        v_confidence,
        v_full_analysis;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2️⃣ تحديث دالة الرصد لتكون SECURITY DEFINER
DROP FUNCTION IF EXISTS advanced_monitor_profit_changes() CASCADE;

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
    v_full_query TEXT;
    v_all_sessions TEXT := '';
    v_session RECORD;
BEGIN
    -- حساب التغييرات
    v_expected_change := COALESCE(NEW.expected_profits, 0) - COALESCE(OLD.expected_profits, 0);
    v_achieved_change := COALESCE(NEW.achieved_profits, 0) - COALESCE(OLD.achieved_profits, 0);
    v_total_change := v_expected_change + v_achieved_change;
    
    -- الحصول على سياق الطلب
    v_order_id := current_setting('app.current_order_id', true);
    v_order_status := current_setting('app.current_order_status', true);
    
    -- 🔍 الحصول على معلومات الجلسة الكاملة مع الاستعلام الكامل
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
        query
    INTO v_session_info
    FROM pg_stat_activity
    WHERE pid = pg_backend_pid();
    
    v_full_query := v_session_info.query;
    
    -- 🔍 جمع معلومات عن جميع الجلسات النشطة
    FOR v_session IN 
        SELECT pid, application_name, client_addr, state, query
        FROM pg_stat_activity
        WHERE state = 'active' AND pid != pg_backend_pid()
    LOOP
        v_all_sessions := v_all_sessions || format(
            'PID: %s | App: %s | Client: %s | State: %s | Query: %s' || E'\n',
            v_session.pid,
            v_session.application_name,
            COALESCE(v_session.client_addr::TEXT, 'NULL'),
            v_session.state,
            SUBSTRING(v_session.query, 1, 200)
        );
    END LOOP;
    
    -- تحليل المصدر
    SELECT * INTO v_source_info
    FROM analyze_profit_change_source(
        v_full_query,
        v_session_info.application_name,
        v_session_info.client_addr
    );
    
    -- كشف التكرار
    SELECT * INTO v_duplicate_info
    FROM detect_profit_duplication(NEW.phone, v_expected_change, v_achieved_change, NOW());
    
    -- كشف العمليات المشبوهة
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
    
    -- بناء البيانات الخام
    v_raw_data := jsonb_build_object(
        'session', jsonb_build_object(
            'pid', v_session_info.pid,
            'app_name', v_session_info.application_name,
            'client', v_session_info.client_addr::TEXT,
            'full_query', v_full_query
        ),
        'profits', jsonb_build_object(
            'old_expected', OLD.expected_profits,
            'new_expected', NEW.expected_profits,
            'old_achieved', OLD.achieved_profits,
            'new_achieved', NEW.achieved_profits
        ),
        'context', jsonb_build_object(
            'order_id', v_order_id,
            'order_status', v_order_status
        ),
        'all_active_sessions', v_all_sessions,
        'source_analysis', v_source_info.full_analysis
    );
    
    -- إدراج سجل التدقيق
    INSERT INTO advanced_profit_audit (
        user_id, user_phone, order_id, order_status,
        old_expected_profits, new_expected_profits, expected_profits_change,
        old_achieved_profits, new_achieved_profits, achieved_profits_change,
        total_change,
        session_pid, session_application_name, session_client_addr, session_client_port,
        session_backend_start, session_xact_start, session_query_start,
        session_state, session_wait_event_type, session_wait_event,
        current_query, query_length,
        source_type, source_detail, source_file, source_confidence,
        operation_context, authorized_by, trigger_operation,
        is_suspicious, suspicious_reason,
        is_duplicate, duplicate_of,
        notes, raw_data
    ) VALUES (
        NEW.id, NEW.phone, v_order_id, v_order_status,
        OLD.expected_profits, NEW.expected_profits, v_expected_change,
        OLD.achieved_profits, NEW.achieved_profits, v_achieved_change,
        v_total_change,
        v_session_info.pid, v_session_info.application_name, v_session_info.client_addr, v_session_info.client_port,
        v_session_info.backend_start, v_session_info.xact_start, v_session_info.query_start,
        v_session_info.state, v_session_info.wait_event_type, v_session_info.wait_event,
        v_full_query, LENGTH(v_full_query),
        v_source_info.source_type, v_source_info.source_detail, v_source_info.source_file, v_source_info.confidence,
        current_setting('app.operation_context', true),
        current_setting('app.authorized_by', true),
        TG_OP,
        v_is_suspicious, v_suspicious_reason,
        v_duplicate_info.is_duplicate, v_duplicate_info.duplicate_of,
        format('Function: %s | Line: %s', v_source_info.source_function, v_source_info.source_line_number),
        v_raw_data
    );
    
    -- 🚨 طباعة تحذير مفصل للعمليات المشبوهة
    IF v_is_suspicious THEN
        RAISE WARNING E'🚨🚨🚨 عملية مشبوهة على أرباح المستخدم % 🚨🚨🚨\n%\n📋 الاستعلام الكامل:\n%\n🔍 التحليل الكامل:\n%\n📊 جميع الجلسات النشطة:\n%',
            NEW.phone,
            v_suspicious_reason,
            SUBSTRING(v_full_query, 1, 1000),
            v_source_info.full_analysis,
            v_all_sessions;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3️⃣ إعادة إنشاء الـ Trigger
DROP TRIGGER IF EXISTS trigger_advanced_profit_monitor ON users;

CREATE TRIGGER trigger_advanced_profit_monitor
    AFTER UPDATE OF expected_profits, achieved_profits ON users
    FOR EACH ROW
    EXECUTE FUNCTION advanced_monitor_profit_changes();

-- 4️⃣ منح الصلاحيات
GRANT EXECUTE ON FUNCTION analyze_profit_change_source TO postgres;
GRANT EXECUTE ON FUNCTION advanced_monitor_profit_changes TO postgres;

-- ===================================
-- ✅ تم التطبيق بنجاح!
-- ===================================

RAISE NOTICE '✅✅✅ تم تطبيق المحقق النهائي بنجاح! ✅✅✅';
RAISE NOTICE '🔍 الآن سيتم كشف كل شيء بالتفصيل الممل!';
RAISE NOTICE '📋 أضف طلب جديد وغير حالته لترى النتائج!';

