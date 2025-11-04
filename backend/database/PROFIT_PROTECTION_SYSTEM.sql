-- ═══════════════════════════════════════════════════════════════════════════════
-- 🛡️ نظام الحماية الشامل للأرباح (COMPREHENSIVE PROFIT PROTECTION SYSTEM)
-- ═══════════════════════════════════════════════════════════════════════════════
-- 
-- الهدف: حماية أرباح المستخدمين من التلاعب والتكرار
-- 
-- الحمايات المطبقة:
-- 1. منع تشغيل Trigger إذا لم تتغير الحالة فعلياً
-- 2. منع التكرار السريع (خلال ثانية واحدة)
-- 3. منع التعديل المباشر على الأرباح (فقط Triggers يمكنها التغيير)
-- 4. منع الزيادة المشبوهة (> 1,000,000 د.ع دفعة واحدة)
-- 5. منع القيم السالبة
-- 6. تسجيل جميع التغييرات في profit_transactions
-- 
-- تاريخ الإنشاء: 2025-11-04
-- آخر تحديث: 2025-11-04
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📊 PART 1: جدول سجل التنظيف (Audit Log)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS profit_protection_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL, -- 'DUPLICATE_PREVENTED', 'STATUS_UNCHANGED', 'SUSPICIOUS_INCREASE', etc.
    order_id TEXT,
    user_id UUID,
    old_status TEXT,
    new_status TEXT,
    profit_amount NUMERIC,
    context TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profit_protection_audit_created_at ON profit_protection_audit(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_profit_protection_audit_event_type ON profit_protection_audit(event_type);
CREATE INDEX IF NOT EXISTS idx_profit_protection_audit_order_id ON profit_protection_audit(order_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 PART 2: دالة التحقق من السماح بتحديث الأرباح
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION check_profit_update_allowed()
RETURNS BOOLEAN AS $$
DECLARE
    operation_context TEXT;
BEGIN
    SELECT current_setting('app.operation_context', true) INTO operation_context;
    
    IF operation_context IN ('AUTO_PROFIT_UPDATE', 'AUTHORIZED_WITHDRAWAL', 'AUTHORIZED_RESET', 'ADMIN_OVERRIDE') THEN
        RETURN TRUE;
    END IF;
    
    RAISE EXCEPTION 'PROFIT_PROTECTION: غير مسموح بتعديل الأرباح مباشرة! فقط قاعدة البيانات يمكنها التغيير.';
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🛡️ PART 3: Trigger الحماية الرئيسي (validate_profit_operation)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION validate_profit_operation()
RETURNS TRIGGER AS $$
DECLARE
    operation_context TEXT;
    authorized_by TEXT;
    old_expected NUMERIC;
    old_achieved NUMERIC;
    new_expected NUMERIC;
    new_achieved NUMERIC;
    expected_diff NUMERIC;
    achieved_diff NUMERIC;
BEGIN
    old_expected := COALESCE(OLD.expected_profits, 0);
    old_achieved := COALESCE(OLD.achieved_profits, 0);
    new_expected := COALESCE(NEW.expected_profits, 0);
    new_achieved := COALESCE(NEW.achieved_profits, 0);
    
    expected_diff := new_expected - old_expected;
    achieved_diff := new_achieved - old_achieved;
    
    SELECT current_setting('app.operation_context', true) INTO operation_context;
    SELECT current_setting('app.authorized_by', true) INTO authorized_by;
    
    -- 🛡️ RULE 1: منع التصفير المباشر
    IF (new_achieved = 0 AND old_achieved > 0) OR (new_expected = 0 AND old_expected > 0) THEN
        IF operation_context NOT IN ('AUTHORIZED_RESET', 'AUTHORIZED_WITHDRAWAL', 'AUTO_PROFIT_UPDATE') THEN
            RAISE EXCEPTION 'PROFIT_PROTECTION: تصفير الأرباح غير مسموح بدون تصريح خاص (Context: %)', COALESCE(operation_context, 'NULL');
        END IF;
    END IF;
    
    -- 🛡️ RULE 2: منع النقصان إلا في حالات مصرحة
    IF new_achieved < old_achieved THEN
        IF operation_context NOT IN ('AUTHORIZED_WITHDRAWAL', 'AUTO_PROFIT_UPDATE', 'AUTHORIZED_RESET') THEN
            RAISE EXCEPTION 'PROFIT_PROTECTION: تقليل الأرباح المحققة غير مسموح إلا عند السحب أو التحديث التلقائي (Context: %)', COALESCE(operation_context, 'NULL');
        END IF;
    END IF;
    
    IF new_expected < old_expected THEN
        IF operation_context NOT IN ('AUTHORIZED_WITHDRAWAL', 'AUTO_PROFIT_UPDATE', 'AUTHORIZED_RESET') THEN
            RAISE EXCEPTION 'PROFIT_PROTECTION: تقليل الأرباح المتوقعة غير مسموح إلا عند السحب أو التحديث التلقائي (Context: %)', COALESCE(operation_context, 'NULL');
        END IF;
    END IF;
    
    -- 🛡️ RULE 3: منع الزيادة المشبوهة (> 1,000,000 د.ع دفعة واحدة)
    IF (achieved_diff > 1000000) OR (expected_diff > 1000000) THEN
        IF operation_context NOT IN ('AUTHORIZED_BULK_UPDATE', 'ADMIN_OVERRIDE') THEN
            -- تسجيل في Audit Log
            INSERT INTO profit_protection_audit (event_type, user_id, profit_amount, context)
            VALUES ('SUSPICIOUS_INCREASE', NEW.id, GREATEST(achieved_diff, expected_diff), 
                    format('محاولة زيادة مشبوهة: %s د.ع للمحققة, %s د.ع للمتوقعة', achieved_diff, expected_diff));
            
            RAISE EXCEPTION 'PROFIT_PROTECTION: زيادة مشبوهة في الأرباح (% د.ع للمحققة, % د.ع للمتوقعة)', achieved_diff, expected_diff;
        END IF;
    END IF;
    
    -- 🛡️ RULE 4: منع القيم السالبة
    IF new_achieved < 0 OR new_expected < 0 THEN
        RAISE EXCEPTION 'PROFIT_PROTECTION: الأرباح لا يمكن أن تكون سالبة (محققة: %, متوقعة: %)', new_achieved, new_expected;
    END IF;
    
    -- ✅ تسجيل التغيير المصرح به
    IF operation_context IN ('AUTO_PROFIT_UPDATE', 'AUTHORIZED_WITHDRAWAL', 'AUTHORIZED_RESET') THEN
        RAISE NOTICE '✅ تغيير مصرح: % (محققة: % → %, متوقعة: % → %)', 
            operation_context, old_achieved, new_achieved, old_expected, new_expected;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إعادة إنشاء Trigger
DROP TRIGGER IF EXISTS protect_profits_trigger ON users;
CREATE TRIGGER protect_profits_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    WHEN (OLD.achieved_profits IS DISTINCT FROM NEW.achieved_profits 
          OR OLD.expected_profits IS DISTINCT FROM NEW.expected_profits)
    EXECUTE FUNCTION validate_profit_operation();

-- ═══════════════════════════════════════════════════════════════════════════════
-- 💰 PART 4: Trigger إدارة الأرباح الذكي (smart_profit_manager)
-- ═══════════════════════════════════════════════════════════════════════════════
-- هذا الـ Trigger تم تحديثه في ملف منفصل (automatic_profit_system.sql)
-- التحديثات الرئيسية:
-- 1. ✅ PROTECTION 1: منع تشغيل Trigger إذا لم تتغير الحالة فعلياً
-- 2. ✅ PROTECTION 2: منع التكرار السريع (خلال ثانية واحدة)
-- 3. ✅ تسجيل جميع التغييرات في profit_transactions
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📊 PART 5: دالة فحص صحة الأرباح (Profit Integrity Check)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION check_profit_integrity()
RETURNS TABLE (
    user_id UUID,
    user_phone TEXT,
    expected_profits NUMERIC,
    achieved_profits NUMERIC,
    calculated_expected NUMERIC,
    calculated_achieved NUMERIC,
    expected_diff NUMERIC,
    achieved_diff NUMERIC,
    has_discrepancy BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH user_profits AS (
        SELECT 
            u.id,
            u.phone,
            u.expected_profits,
            u.achieved_profits
        FROM users u
    ),
    calculated_profits AS (
        SELECT 
            o.user_id,
            SUM(CASE 
                WHEN o.status NOT IN ('رفض الطلب', 'الغاء الطلب', 'cancelled', 'rejected') 
                     AND o.status NOT IN ('delivered', 'تم التسليم للزبون')
                THEN COALESCE(o.profit_amount, o.profit, 0)
                ELSE 0
            END) as calc_expected,
            SUM(CASE 
                WHEN o.status IN ('delivered', 'تم التسليم للزبون')
                THEN COALESCE(o.profit_amount, o.profit, 0)
                ELSE 0
            END) as calc_achieved
        FROM orders o
        GROUP BY o.user_id
    )
    SELECT 
        up.id,
        up.phone,
        up.expected_profits,
        up.achieved_profits,
        COALESCE(cp.calc_expected, 0) as calculated_expected,
        COALESCE(cp.calc_achieved, 0) as calculated_achieved,
        up.expected_profits - COALESCE(cp.calc_expected, 0) as expected_diff,
        up.achieved_profits - COALESCE(cp.calc_achieved, 0) as achieved_diff,
        (ABS(up.expected_profits - COALESCE(cp.calc_expected, 0)) > 0.01 OR 
         ABS(up.achieved_profits - COALESCE(cp.calc_achieved, 0)) > 0.01) as has_discrepancy
    FROM user_profits up
    LEFT JOIN calculated_profits cp ON up.id = cp.user_id
    WHERE (ABS(up.expected_profits - COALESCE(cp.calc_expected, 0)) > 0.01 OR 
           ABS(up.achieved_profits - COALESCE(cp.calc_achieved, 0)) > 0.01)
    ORDER BY (ABS(up.expected_profits - COALESCE(cp.calc_expected, 0)) + 
              ABS(up.achieved_profits - COALESCE(cp.calc_achieved, 0))) DESC;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📝 PART 6: تعليمات الاستخدام
-- ═══════════════════════════════════════════════════════════════════════════════

COMMENT ON FUNCTION check_profit_integrity() IS 
'دالة فحص صحة الأرباح - تقارن الأرباح المخزنة مع الأرباح المحسوبة من الطلبات
الاستخدام: SELECT * FROM check_profit_integrity();';

COMMENT ON TABLE profit_protection_audit IS 
'جدول سجل الحماية - يسجل جميع محاولات التلاعب بالأرباح';

-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ نهاية ملف الحماية الشامل
-- ═══════════════════════════════════════════════════════════════════════════════

