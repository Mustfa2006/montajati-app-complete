-- ===================================
-- حماية قوية جداً لأعمدة الأرباح
-- منع التصفير أو النقصان إلا عند السحب المصرح
-- ===================================

-- 1. إنشاء جدول سجل العمليات على الأرباح
CREATE TABLE IF NOT EXISTS profit_operations_log (
    id BIGSERIAL PRIMARY KEY,
    user_phone TEXT NOT NULL,
    operation_type TEXT NOT NULL, -- 'ADD', 'WITHDRAW', 'RESET'
    old_achieved_profits DECIMAL(15,2),
    new_achieved_profits DECIMAL(15,2),
    old_expected_profits DECIMAL(15,2), 
    new_expected_profits DECIMAL(15,2),
    amount_changed DECIMAL(15,2),
    reason TEXT,
    authorized_by TEXT,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_authorized BOOLEAN DEFAULT FALSE
);

-- 2. دالة التحقق من صحة عملية تعديل الأرباح
CREATE OR REPLACE FUNCTION validate_profit_operation()
RETURNS TRIGGER AS $$
DECLARE
    old_achieved DECIMAL(15,2);
    old_expected DECIMAL(15,2);
    new_achieved DECIMAL(15,2);
    new_expected DECIMAL(15,2);
    operation_context TEXT;
BEGIN
    -- الحصول على القيم القديمة والجديدة
    old_achieved := COALESCE(OLD.achieved_profits, 0);
    old_expected := COALESCE(OLD.expected_profits, 0);
    new_achieved := COALESCE(NEW.achieved_profits, 0);
    new_expected := COALESCE(NEW.expected_profits, 0);
    
    -- الحصول على سياق العملية من متغير الجلسة
    SELECT current_setting('app.operation_context', true) INTO operation_context;
    
    -- 🛡️ RULE 1: منع التصفير المباشر
    IF (new_achieved = 0 AND old_achieved > 0) OR (new_expected = 0 AND old_expected > 0) THEN
        IF operation_context NOT IN ('AUTHORIZED_RESET', 'AUTHORIZED_WITHDRAWAL') THEN
            RAISE EXCEPTION 'PROFIT_PROTECTION: تصفير الأرباح غير مسموح بدون تصريح خاص';
        END IF;
    END IF;
    
    -- 🛡️ RULE 2: منع النقصان إلا عند السحب المصرح
    IF new_achieved < old_achieved THEN
        IF operation_context != 'AUTHORIZED_WITHDRAWAL' THEN
            RAISE EXCEPTION 'PROFIT_PROTECTION: تقليل الأرباح المحققة غير مسموح إلا عند السحب المصرح';
        END IF;
    END IF;
    
    -- 🛡️ RULE 3: منع الزيادة المشبوهة (أكثر من 1000000 دينار في مرة واحدة)
    IF (new_achieved - old_achieved) > 1000000 THEN
        RAISE EXCEPTION 'PROFIT_PROTECTION: زيادة مشبوهة في الأرباح المحققة: %', (new_achieved - old_achieved);
    END IF;
    
    IF (new_expected - old_expected) > 1000000 THEN
        RAISE EXCEPTION 'PROFIT_PROTECTION: زيادة مشبوهة في الأرباح المنتظرة: %', (new_expected - old_expected);
    END IF;
    
    -- 🛡️ RULE 4: منع القيم السالبة
    IF new_achieved < 0 OR new_expected < 0 THEN
        RAISE EXCEPTION 'PROFIT_PROTECTION: الأرباح لا يمكن أن تكون سالبة';
    END IF;
    
    -- تسجيل العملية في السجل
    INSERT INTO profit_operations_log (
        user_phone,
        operation_type,
        old_achieved_profits,
        new_achieved_profits,
        old_expected_profits,
        new_expected_profits,
        amount_changed,
        reason,
        authorized_by,
        is_authorized
    ) VALUES (
        NEW.phone,
        CASE 
            WHEN operation_context = 'AUTHORIZED_WITHDRAWAL' THEN 'WITHDRAW'
            WHEN operation_context = 'AUTHORIZED_RESET' THEN 'RESET'
            WHEN new_achieved > old_achieved OR new_expected > old_expected THEN 'ADD'
            ELSE 'UNKNOWN'
        END,
        old_achieved,
        new_achieved,
        old_expected,
        new_expected,
        GREATEST(ABS(new_achieved - old_achieved), ABS(new_expected - old_expected)),
        operation_context,
        current_setting('app.authorized_by', true),
        operation_context IN ('AUTHORIZED_WITHDRAWAL', 'AUTHORIZED_RESET')
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. إنشاء المحفز (Trigger) لحماية الأرباح
DROP TRIGGER IF EXISTS protect_profits_trigger ON users;
CREATE TRIGGER protect_profits_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    WHEN (OLD.achieved_profits IS DISTINCT FROM NEW.achieved_profits 
          OR OLD.expected_profits IS DISTINCT FROM NEW.expected_profits)
    EXECUTE FUNCTION validate_profit_operation();

-- 4. دالة آمنة لسحب الأرباح
CREATE OR REPLACE FUNCTION safe_withdraw_profits(
    p_user_phone TEXT,
    p_amount DECIMAL(15,2),
    p_authorized_by TEXT DEFAULT 'SYSTEM'
)
RETURNS JSON AS $$
DECLARE
    current_achieved DECIMAL(15,2);
    result JSON;
BEGIN
    -- التحقق من صحة المدخلات
    IF p_amount <= 0 THEN
        RETURN json_build_object('success', false, 'error', 'مبلغ السحب يجب أن يكون أكبر من صفر');
    END IF;
    
    -- الحصول على الرصيد الحالي
    SELECT achieved_profits INTO current_achieved 
    FROM users 
    WHERE phone = p_user_phone;
    
    IF current_achieved IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'المستخدم غير موجود');
    END IF;
    
    -- التحقق من كفاية الرصيد
    IF current_achieved < p_amount THEN
        RETURN json_build_object('success', false, 'error', 'الرصيد غير كافي للسحب');
    END IF;
    
    -- تعيين سياق العملية
    PERFORM set_config('app.operation_context', 'AUTHORIZED_WITHDRAWAL', true);
    PERFORM set_config('app.authorized_by', p_authorized_by, true);
    
    -- تنفيذ السحب
    UPDATE users 
    SET achieved_profits = achieved_profits - p_amount,
        updated_at = NOW()
    WHERE phone = p_user_phone;
    
    -- إرجاع النتيجة
    RETURN json_build_object(
        'success', true, 
        'old_balance', current_achieved,
        'withdrawn_amount', p_amount,
        'new_balance', current_achieved - p_amount
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- 5. دالة آمنة لإضافة الأرباح
CREATE OR REPLACE FUNCTION safe_add_profits(
    p_user_phone TEXT,
    p_achieved_amount DECIMAL(15,2) DEFAULT 0,
    p_expected_amount DECIMAL(15,2) DEFAULT 0,
    p_reason TEXT DEFAULT 'إضافة أرباح',
    p_authorized_by TEXT DEFAULT 'SYSTEM'
)
RETURNS JSON AS $$
BEGIN
    -- التحقق من صحة المدخلات
    IF p_achieved_amount < 0 OR p_expected_amount < 0 THEN
        RETURN json_build_object('success', false, 'error', 'مبالغ الأرباح لا يمكن أن تكون سالبة');
    END IF;
    
    -- تعيين سياق العملية
    PERFORM set_config('app.operation_context', 'AUTHORIZED_ADD', true);
    PERFORM set_config('app.authorized_by', p_authorized_by, true);
    
    -- تنفيذ الإضافة
    UPDATE users 
    SET achieved_profits = COALESCE(achieved_profits, 0) + p_achieved_amount,
        expected_profits = COALESCE(expected_profits, 0) + p_expected_amount,
        updated_at = NOW()
    WHERE phone = p_user_phone;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'المستخدم غير موجود');
    END IF;
    
    RETURN json_build_object('success', true, 'message', 'تم إضافة الأرباح بنجاح');
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- 6. دالة طوارئ لإعادة تعيين الأرباح (للمدير فقط)
CREATE OR REPLACE FUNCTION emergency_reset_profits(
    p_user_phone TEXT,
    p_new_achieved DECIMAL(15,2),
    p_new_expected DECIMAL(15,2),
    p_admin_password TEXT,
    p_reason TEXT
)
RETURNS JSON AS $$
BEGIN
    -- التحقق من كلمة مرور المدير
    IF p_admin_password != 'EMERGENCY_RESET_2024_SECURE' THEN
        RETURN json_build_object('success', false, 'error', 'كلمة مرور المدير غير صحيحة');
    END IF;
    
    -- تعيين سياق العملية
    PERFORM set_config('app.operation_context', 'AUTHORIZED_RESET', true);
    PERFORM set_config('app.authorized_by', 'EMERGENCY_ADMIN', true);
    
    -- تنفيذ إعادة التعيين
    UPDATE users 
    SET achieved_profits = p_new_achieved,
        expected_profits = p_new_expected,
        updated_at = NOW()
    WHERE phone = p_user_phone;
    
    RETURN json_build_object('success', true, 'message', 'تم إعادة تعيين الأرباح بنجاح');
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- 7. إنشاء فهارس للأداء
CREATE INDEX IF NOT EXISTS idx_profit_operations_log_user_phone ON profit_operations_log(user_phone);
CREATE INDEX IF NOT EXISTS idx_profit_operations_log_created_at ON profit_operations_log(created_at);
CREATE INDEX IF NOT EXISTS idx_profit_operations_log_operation_type ON profit_operations_log(operation_type);

-- 8. منح الصلاحيات
GRANT SELECT, INSERT ON profit_operations_log TO authenticated;
GRANT EXECUTE ON FUNCTION safe_withdraw_profits TO authenticated;
GRANT EXECUTE ON FUNCTION safe_add_profits TO authenticated;
GRANT EXECUTE ON FUNCTION emergency_reset_profits TO authenticated;
