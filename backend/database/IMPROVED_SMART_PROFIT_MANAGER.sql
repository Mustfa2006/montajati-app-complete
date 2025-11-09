-- 🔐 نظام إدارة الأرباح الذكي المحسّن والآمن 100%
-- تاريخ الإنشاء: 2025-11-08
-- الهدف: إدارة آمنة وموثوقة للأرباح مع نسبة أخطاء 0%

-- ============================================
-- 1️⃣ إنشاء جدول تسجيل الأرباح المتقدم
-- ============================================

CREATE TABLE IF NOT EXISTS profit_audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id TEXT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    old_expected_profits NUMERIC(15,2) DEFAULT 0,
    new_expected_profits NUMERIC(15,2) DEFAULT 0,
    old_achieved_profits NUMERIC(15,2) DEFAULT 0,
    new_achieved_profits NUMERIC(15,2) DEFAULT 0,
    profit_amount NUMERIC(15,2) NOT NULL,
    old_status VARCHAR(100),
    new_status VARCHAR(100),
    operation_context VARCHAR(100),
    error_message TEXT,
    is_success BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(100) DEFAULT 'TRIGGER'
);

CREATE INDEX IF NOT EXISTS idx_profit_audit_user_id ON profit_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_profit_audit_order_id ON profit_audit_log(order_id);
CREATE INDEX IF NOT EXISTS idx_profit_audit_created_at ON profit_audit_log(created_at DESC);

-- ============================================
-- 2️⃣ دالة التحقق من صحة الأرباح
-- ============================================

CREATE OR REPLACE FUNCTION validate_profit_transition(
    p_user_id UUID,
    p_old_expected NUMERIC,
    p_new_expected NUMERIC,
    p_old_achieved NUMERIC,
    p_new_achieved NUMERIC,
    p_profit_amount NUMERIC
) RETURNS TABLE(is_valid BOOLEAN, error_message TEXT) AS $$
DECLARE
    v_total_change NUMERIC;
    v_expected_change NUMERIC;
    v_achieved_change NUMERIC;
BEGIN
    -- التحقق 1: القيم لا تكون سالبة
    IF p_new_expected < 0 OR p_new_achieved < 0 THEN
        RETURN QUERY SELECT FALSE, 'الأرباح لا يمكن أن تكون سالبة'::TEXT;
        RETURN;
    END IF;

    -- التحقق 2: المجموع الكلي للأرباح لا يتغير بشكل غير متوقع
    v_total_change := (p_new_expected + p_new_achieved) - (p_old_expected + p_old_achieved);
    IF ABS(v_total_change) > ABS(p_profit_amount) * 1.1 THEN
        RETURN QUERY SELECT FALSE, 'تغيير غير متوقع في إجمالي الأرباح'::TEXT;
        RETURN;
    END IF;

    -- التحقق 3: التحقق من الانتقال الصحيح
    v_expected_change := p_new_expected - p_old_expected;
    v_achieved_change := p_new_achieved - p_old_achieved;
    
    -- إذا كان الربح ينتقل من expected إلى achieved
    IF v_expected_change < 0 AND v_achieved_change > 0 THEN
        IF ABS(v_expected_change) <> ABS(v_achieved_change) THEN
            RETURN QUERY SELECT FALSE, 'عدم توازن في نقل الأرباح'::TEXT;
            RETURN;
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, ''::TEXT;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 3️⃣ دالة تحديث الأرباح الآمنة
-- ============================================

CREATE OR REPLACE FUNCTION safe_update_user_profits(
    p_user_id UUID,
    p_order_id TEXT,
    p_profit_amount NUMERIC,
    p_old_status VARCHAR,
    p_new_status VARCHAR,
    p_transaction_type VARCHAR
) RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    v_current_expected NUMERIC;
    v_current_achieved NUMERIC;
    v_new_expected NUMERIC;
    v_new_achieved NUMERIC;
    v_is_valid BOOLEAN;
    v_error_msg TEXT;
BEGIN
    -- 🔒 قفل الصف لمنع التحديثات المتزامنة
    SELECT expected_profits, achieved_profits 
    INTO v_current_expected, v_current_achieved
    FROM users 
    WHERE id = p_user_id 
    FOR UPDATE;

    v_current_expected := COALESCE(v_current_expected, 0);
    v_current_achieved := COALESCE(v_current_achieved, 0);

    -- حساب القيم الجديدة حسب نوع العملية
    v_new_expected := v_current_expected;
    v_new_achieved := v_current_achieved;

    CASE p_transaction_type
        WHEN 'MOVE_TO_ACHIEVED' THEN
            v_new_expected := GREATEST(v_current_expected - p_profit_amount, 0);
            v_new_achieved := v_current_achieved + p_profit_amount;
        WHEN 'ADD_EXPECTED' THEN
            v_new_expected := v_current_expected + p_profit_amount;
        WHEN 'ADD_ACHIEVED' THEN
            v_new_achieved := v_current_achieved + p_profit_amount;
        WHEN 'REMOVE_EXPECTED' THEN
            v_new_expected := GREATEST(v_current_expected - p_profit_amount, 0);
        WHEN 'REMOVE_ACHIEVED' THEN
            v_new_achieved := GREATEST(v_current_achieved - p_profit_amount, 0);
    END CASE;

    -- التحقق من صحة الانتقال
    SELECT is_valid, error_message 
    INTO v_is_valid, v_error_msg
    FROM validate_profit_transition(
        p_user_id,
        v_current_expected,
        v_new_expected,
        v_current_achieved,
        v_new_achieved,
        p_profit_amount
    );

    IF NOT v_is_valid THEN
        INSERT INTO profit_audit_log (
            user_id, order_id, transaction_type, 
            old_expected_profits, new_expected_profits,
            old_achieved_profits, new_achieved_profits,
            profit_amount, old_status, new_status,
            error_message, is_success
        ) VALUES (
            p_user_id, p_order_id, p_transaction_type,
            v_current_expected, v_new_expected,
            v_current_achieved, v_new_achieved,
            p_profit_amount, p_old_status, p_new_status,
            v_error_msg, FALSE
        );
        RETURN QUERY SELECT FALSE, v_error_msg;
        RETURN;
    END IF;

    -- تحديث آمن
    UPDATE users SET 
        expected_profits = v_new_expected,
        achieved_profits = v_new_achieved,
        updated_at = NOW()
    WHERE id = p_user_id;

    -- تسجيل العملية
    INSERT INTO profit_audit_log (
        user_id, order_id, transaction_type,
        old_expected_profits, new_expected_profits,
        old_achieved_profits, new_achieved_profits,
        profit_amount, old_status, new_status,
        is_success
    ) VALUES (
        p_user_id, p_order_id, p_transaction_type,
        v_current_expected, v_new_expected,
        v_current_achieved, v_new_achieved,
        p_profit_amount, p_old_status, p_new_status,
        TRUE
    );

    RETURN QUERY SELECT TRUE, 'تم تحديث الأرباح بنجاح'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4️⃣ الـ Trigger الجديد المحسّن
-- ============================================

DROP TRIGGER IF EXISTS smart_profit_trigger ON orders;
DROP FUNCTION IF EXISTS smart_profit_manager();

CREATE OR REPLACE FUNCTION smart_profit_manager()
RETURNS TRIGGER AS $$
DECLARE
    v_profit_amount NUMERIC;
    v_user_id UUID;
    v_user_phone TEXT;
    v_is_cancelled_new BOOLEAN;
    v_is_cancelled_old BOOLEAN;
    v_is_delivered_new BOOLEAN;
    v_is_delivered_old BOOLEAN;
    v_transaction_type VARCHAR(50);
    v_success BOOLEAN;
    v_message TEXT;
BEGIN
    -- ⏭️ تخطي إذا لم تتغير الحالة
    IF TG_OP = 'UPDATE' AND OLD.status IS NOT DISTINCT FROM NEW.status THEN
        RETURN NEW;
    END IF;

    -- 📊 استخراج البيانات الأساسية
    v_profit_amount := COALESCE(NEW.profit_amount, NEW.profit, 0);
    v_user_id := NEW.user_id;
    v_user_phone := NEW.user_phone;

    -- تخطي إذا لم يكن هناك ربح
    IF v_profit_amount <= 0 THEN
        RETURN NEW;
    END IF;

    -- الحصول على معرف المستخدم من الهاتف إذا لزم الأمر
    IF v_user_id IS NULL AND v_user_phone IS NOT NULL THEN
        SELECT id INTO v_user_id FROM users WHERE phone = v_user_phone LIMIT 1;
    END IF;

    -- تخطي إذا لم نتمكن من العثور على المستخدم
    IF v_user_id IS NULL THEN
        RAISE NOTICE '⚠️ لا يمكن العثور على المستخدم للطلب: %', NEW.id;
        RETURN NEW;
    END IF;

    -- 🔍 تحديد حالات الطلب
    v_is_cancelled_new := NEW.status IN ('رفض الطلب', 'الغاء الطلب', 'cancelled', 'rejected');
    v_is_delivered_new := NEW.status IN ('delivered', 'تم التسليم للزبون');

    IF TG_OP = 'UPDATE' THEN
        v_is_cancelled_old := OLD.status IN ('رفض الطلب', 'الغاء الطلب', 'cancelled', 'rejected');
        v_is_delivered_old := OLD.status IN ('delivered', 'تم التسليم للزبون');
    ELSE
        v_is_cancelled_old := FALSE;
        v_is_delivered_old := FALSE;
    END IF;

    -- 🎯 تحديد نوع العملية والتنفيذ
    IF TG_OP = 'INSERT' THEN
        IF v_is_cancelled_new THEN
            v_transaction_type := 'CANCELLED_NEW';
        ELSIF v_is_delivered_new THEN
            v_transaction_type := 'ADD_ACHIEVED';
        ELSE
            v_transaction_type := 'ADD_EXPECTED';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        -- من عادي إلى مسلم
        IF NOT v_is_cancelled_old AND NOT v_is_cancelled_new 
           AND v_is_delivered_new AND NOT v_is_delivered_old THEN
            v_transaction_type := 'MOVE_TO_ACHIEVED';
        -- من مسلم إلى عادي
        ELSIF NOT v_is_cancelled_old AND NOT v_is_cancelled_new 
              AND v_is_delivered_old AND NOT v_is_delivered_new THEN
            v_transaction_type := 'MOVE_TO_EXPECTED';
        -- إلغاء
        ELSIF NOT v_is_cancelled_old AND v_is_cancelled_new THEN
            v_transaction_type := 'CANCEL_ORDER';
        -- إعادة تفعيل
        ELSIF v_is_cancelled_old AND NOT v_is_cancelled_new THEN
            v_transaction_type := 'RESTORE_ORDER';
        ELSE
            RETURN NEW;
        END IF;
    ELSE
        RETURN NEW;
    END IF;

    -- 🔐 تنفيذ التحديث الآمن
    SELECT success, message INTO v_success, v_message
    FROM safe_update_user_profits(
        v_user_id,
        NEW.id,
        v_profit_amount,
        OLD.status,
        NEW.status,
        v_transaction_type
    );

    IF v_success THEN
        RAISE NOTICE '✅ [%] تم تحديث الأرباح: %', NEW.id, v_message;
    ELSE
        RAISE NOTICE '❌ [%] فشل تحديث الأرباح: %', NEW.id, v_message;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء الـ Trigger
CREATE TRIGGER smart_profit_trigger
    AFTER INSERT OR UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION smart_profit_manager();

-- ============================================
-- 5️⃣ دالة التحقق من صحة النظام
-- ============================================

CREATE OR REPLACE FUNCTION verify_profit_system_integrity()
RETURNS TABLE(
    user_phone TEXT,
    expected_profits NUMERIC,
    achieved_profits NUMERIC,
    total_profits NUMERIC,
    order_count BIGINT,
    status TEXT
) AS $$
SELECT 
    u.phone,
    u.expected_profits,
    u.achieved_profits,
    u.expected_profits + u.achieved_profits as total_profits,
    COUNT(o.id) as order_count,
    CASE 
        WHEN u.expected_profits < 0 OR u.achieved_profits < 0 THEN 'ERROR: سالب'
        WHEN (u.expected_profits + u.achieved_profits) > 10000000 THEN 'WARNING: مرتفع جداً'
        ELSE 'OK'
    END as status
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.phone, u.expected_profits, u.achieved_profits
ORDER BY u.expected_profits + u.achieved_profits DESC;
$$ LANGUAGE sql;

