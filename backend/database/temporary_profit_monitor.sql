-- ===================================
-- 🔍 نظام الرصد المؤقت للأرباح
-- ===================================
-- الهدف: اكتشاف مصدر مشكلة تضاعف الأرباح
-- مؤقت: سيتم حذفه بعد حل المشكلة
-- ===================================

-- ===================================
-- 1️⃣ جدول سجل التدقيق للأرباح
-- ===================================
CREATE TABLE IF NOT EXISTS profit_audit_log (
    id BIGSERIAL PRIMARY KEY,
    
    -- معلومات المستخدم
    user_id UUID NOT NULL,
    user_phone TEXT,
    
    -- معلومات الطلب (إن وجد)
    order_id TEXT,
    order_status TEXT,
    
    -- التغييرات على الأرباح المتوقعة
    old_expected_profits DECIMAL(10,2),
    new_expected_profits DECIMAL(10,2),
    expected_profits_change DECIMAL(10,2),
    
    -- التغييرات على الأرباح المحققة
    old_achieved_profits DECIMAL(10,2),
    new_achieved_profits DECIMAL(10,2),
    achieved_profits_change DECIMAL(10,2),
    
    -- معلومات التغيير
    change_source TEXT, -- 'smart_profit_manager', 'direct_update', 'unknown'
    trigger_operation TEXT, -- 'INSERT', 'UPDATE', 'DELETE'
    
    -- معلومات السياق
    session_user TEXT,
    current_user TEXT,
    application_name TEXT,
    client_addr INET,
    backend_pid INTEGER,
    
    -- Stack trace للتتبع
    pg_backend_pid INTEGER,
    pg_stat_activity_query TEXT,
    
    -- ملاحظات إضافية
    notes TEXT,
    
    -- الوقت
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- إنشاء فهارس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_profit_audit_user_id ON profit_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_profit_audit_order_id ON profit_audit_log(order_id);
CREATE INDEX IF NOT EXISTS idx_profit_audit_created_at ON profit_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_profit_audit_change_source ON profit_audit_log(change_source);

-- ===================================
-- 2️⃣ دالة الرصد الذكية
-- ===================================
CREATE OR REPLACE FUNCTION monitor_profit_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_order_id TEXT;
    v_order_status TEXT;
    v_change_source TEXT;
    v_current_query TEXT;
    v_notes TEXT;
BEGIN
    -- تحديد مصدر التغيير
    v_change_source := 'unknown';
    
    -- محاولة الحصول على معلومات السياق
    BEGIN
        v_current_query := current_query();
        
        -- تحديد المصدر بناءً على الاستعلام
        IF v_current_query ILIKE '%smart_profit_manager%' THEN
            v_change_source := 'smart_profit_manager_trigger';
        ELSIF v_current_query ILIKE '%UPDATE users%' THEN
            v_change_source := 'direct_update_on_users';
        ELSIF v_current_query ILIKE '%INSERT INTO users%' THEN
            v_change_source := 'insert_new_user';
        ELSE
            v_change_source := 'unknown_source';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_change_source := 'error_detecting_source';
    END;
    
    -- محاولة الحصول على معلومات الطلب من السياق
    BEGIN
        v_order_id := current_setting('app.current_order_id', true);
        v_order_status := current_setting('app.current_order_status', true);
    EXCEPTION WHEN OTHERS THEN
        v_order_id := NULL;
        v_order_status := NULL;
    END;
    
    -- بناء الملاحظات
    v_notes := '';
    
    IF TG_OP = 'UPDATE' THEN
        -- فحص إذا تغيرت الأرباح المتوقعة
        IF OLD.expected_profits IS DISTINCT FROM NEW.expected_profits THEN
            v_notes := v_notes || '✏️ تغيير في الأرباح المتوقعة: ' || 
                      COALESCE(OLD.expected_profits::TEXT, '0') || ' → ' || 
                      COALESCE(NEW.expected_profits::TEXT, '0') || ' | ';
        END IF;
        
        -- فحص إذا تغيرت الأرباح المحققة
        IF OLD.achieved_profits IS DISTINCT FROM NEW.achieved_profits THEN
            v_notes := v_notes || '✏️ تغيير في الأرباح المحققة: ' || 
                      COALESCE(OLD.achieved_profits::TEXT, '0') || ' → ' || 
                      COALESCE(NEW.achieved_profits::TEXT, '0') || ' | ';
        END IF;
    END IF;
    
    -- تسجيل التغيير في جدول التدقيق
    INSERT INTO profit_audit_log (
        user_id,
        user_phone,
        order_id,
        order_status,
        old_expected_profits,
        new_expected_profits,
        expected_profits_change,
        old_achieved_profits,
        new_achieved_profits,
        achieved_profits_change,
        change_source,
        trigger_operation,
        session_user,
        current_user,
        application_name,
        client_addr,
        backend_pid,
        pg_backend_pid,
        pg_stat_activity_query,
        notes
    ) VALUES (
        NEW.id,
        NEW.phone,
        v_order_id,
        v_order_status,
        COALESCE(OLD.expected_profits, 0),
        COALESCE(NEW.expected_profits, 0),
        COALESCE(NEW.expected_profits, 0) - COALESCE(OLD.expected_profits, 0),
        COALESCE(OLD.achieved_profits, 0),
        COALESCE(NEW.achieved_profits, 0),
        COALESCE(NEW.achieved_profits, 0) - COALESCE(OLD.achieved_profits, 0),
        v_change_source,
        TG_OP,
        session_user,
        current_user,
        current_setting('application_name', true),
        inet_client_addr(),
        pg_backend_pid(),
        pg_backend_pid(),
        v_current_query,
        v_notes
    );
    
    -- طباعة تحذير في السجلات
    IF TG_OP = 'UPDATE' AND (
        OLD.expected_profits IS DISTINCT FROM NEW.expected_profits OR
        OLD.achieved_profits IS DISTINCT FROM NEW.achieved_profits
    ) THEN
        RAISE NOTICE '🔍 PROFIT MONITOR: تغيير في أرباح المستخدم %', NEW.phone;
        RAISE NOTICE '   📊 الأرباح المتوقعة: % → % (تغيير: %)', 
            COALESCE(OLD.expected_profits, 0), 
            COALESCE(NEW.expected_profits, 0),
            COALESCE(NEW.expected_profits, 0) - COALESCE(OLD.expected_profits, 0);
        RAISE NOTICE '   💰 الأرباح المحققة: % → % (تغيير: %)', 
            COALESCE(OLD.achieved_profits, 0), 
            COALESCE(NEW.achieved_profits, 0),
            COALESCE(NEW.achieved_profits, 0) - COALESCE(OLD.achieved_profits, 0);
        RAISE NOTICE '   🔍 المصدر: %', v_change_source;
        RAISE NOTICE '   📝 الملاحظات: %', v_notes;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 3️⃣ تفعيل الرصد على جدول المستخدمين
-- ===================================
DROP TRIGGER IF EXISTS trigger_monitor_profit_changes ON users;

CREATE TRIGGER trigger_monitor_profit_changes
    AFTER INSERT OR UPDATE OF expected_profits, achieved_profits ON users
    FOR EACH ROW
    EXECUTE FUNCTION monitor_profit_changes();

-- ===================================
-- 4️⃣ تحديث smart_profit_manager لتسجيل السياق وزيادة الحماية
-- ===================================
-- ملاحظة: هذا التحديث سيتم تطبيقه بعد تفعيل نظام الرصد
-- ===================================

-- ===================================
-- 5️⃣ دالة مساعدة لعرض السجلات
-- ===================================
CREATE OR REPLACE FUNCTION get_profit_audit_summary(p_user_phone TEXT DEFAULT NULL, p_limit INT DEFAULT 50)
RETURNS TABLE (
    log_time TIMESTAMPTZ,
    user_phone TEXT,
    order_id TEXT,
    order_status TEXT,
    expected_change DECIMAL(10,2),
    achieved_change DECIMAL(10,2),
    change_source TEXT,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pal.created_at,
        pal.user_phone,
        pal.order_id,
        pal.order_status,
        pal.expected_profits_change,
        pal.achieved_profits_change,
        pal.change_source,
        pal.notes
    FROM profit_audit_log pal
    WHERE (p_user_phone IS NULL OR pal.user_phone = p_user_phone)
    ORDER BY pal.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- ✅ تم تفعيل نظام الرصد المؤقت
-- ===================================
-- الآن كل تغيير على الأرباح سيتم تسجيله بدقة شديدة!
-- 
-- لعرض السجلات:
-- SELECT * FROM get_profit_audit_summary('07566666666', 20);
-- 
-- لعرض كل السجلات:
-- SELECT * FROM profit_audit_log ORDER BY created_at DESC LIMIT 50;
-- ===================================

