-- ===================================
-- 🚀 تطبيق النظام الجديد للأرباح التلقائية
-- ===================================
--
-- هذا الملف يطبق النظام الجديد بالكامل
-- يمكن تشغيله مباشرة في Supabase SQL Editor
--
-- ===================================

BEGIN;

-- 1️⃣ إنشاء دالة تحديد نوع الربح
CREATE OR REPLACE FUNCTION get_profit_type(order_status TEXT)
RETURNS TEXT AS $$
BEGIN
    -- 🟢 أرباح محققة (Achieved)
    IF order_status = 'تم التسليم للزبون' THEN
        RETURN 'achieved';
    
    -- 🔵 أرباح منتظرة (Expected)
    ELSIF order_status IN (
        'نشط',
        'تم تغيير محافظة الزبون',
        'تغيير المندوب',
        'قيد التوصيل الى الزبون (في عهدة المندوب)',
        'مؤجل',
        'مؤجل لحين اعادة الطلب لاحقا'
    ) THEN
        RETURN 'expected';
    
    -- 🔴 لا ربح (None)
    ELSE
        RETURN 'none';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 2️⃣ إنشاء دالة التحديث التلقائي
CREATE OR REPLACE FUNCTION auto_update_profits_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
    old_profit_type TEXT;
    new_profit_type TEXT;
    order_profit DECIMAL(15,2);
    user_phone_value TEXT;
    current_achieved DECIMAL(15,2);
    current_expected DECIMAL(15,2);
    new_achieved DECIMAL(15,2);
    new_expected DECIMAL(15,2);
BEGIN
    -- ✅ التحقق من تغيير الحالة فقط
    IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
        RETURN NEW;
    END IF;
    
    -- ✅ جلب بيانات الطلب
    order_profit := COALESCE(NEW.profit, 0);
    user_phone_value := NEW.user_phone;
    
    -- ✅ إذا لم يكن هناك ربح أو رقم هاتف، لا حاجة للتحديث
    IF order_profit <= 0 OR user_phone_value IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- ✅ تحديد نوع الربح للحالة القديمة والجديدة
    old_profit_type := get_profit_type(OLD.status);
    new_profit_type := get_profit_type(NEW.status);
    
    -- ✅ إذا لم يتغير نوع الربح، لا حاجة للتحديث
    IF old_profit_type = new_profit_type THEN
        RETURN NEW;
    END IF;
    
    -- ✅ جلب الأرباح الحالية للمستخدم
    SELECT 
        COALESCE(achieved_profits, 0),
        COALESCE(expected_profits, 0)
    INTO current_achieved, current_expected
    FROM users
    WHERE phone = user_phone_value;
    
    -- ✅ إذا لم يتم العثور على المستخدم، لا نفعل شيء
    IF NOT FOUND THEN
        RAISE WARNING 'المستخدم غير موجود: %', user_phone_value;
        RETURN NEW;
    END IF;
    
    -- ✅ حساب الأرباح الجديدة
    new_achieved := current_achieved;
    new_expected := current_expected;
    
    -- 📊 تطبيق التغييرات حسب نوع الربح
    IF old_profit_type = 'expected' AND new_profit_type = 'achieved' THEN
        new_expected := GREATEST(current_expected - order_profit, 0);
        new_achieved := current_achieved + order_profit;
        RAISE NOTICE '⬆️ نقل % د.ع من منتظر إلى محقق للمستخدم %', order_profit, user_phone_value;
    
    ELSIF old_profit_type = 'achieved' AND new_profit_type = 'expected' THEN
        new_achieved := GREATEST(current_achieved - order_profit, 0);
        new_expected := current_expected + order_profit;
        RAISE NOTICE '⬇️ نقل % د.ع من محقق إلى منتظر للمستخدم %', order_profit, user_phone_value;
    
    ELSIF old_profit_type = 'expected' AND new_profit_type = 'none' THEN
        new_expected := GREATEST(current_expected - order_profit, 0);
        RAISE NOTICE '➖ إزالة % د.ع من منتظر للمستخدم %', order_profit, user_phone_value;
    
    ELSIF old_profit_type = 'achieved' AND new_profit_type = 'none' THEN
        new_achieved := GREATEST(current_achieved - order_profit, 0);
        RAISE NOTICE '➖ إزالة % د.ع من محقق للمستخدم %', order_profit, user_phone_value;
    
    ELSIF old_profit_type = 'none' AND new_profit_type = 'expected' THEN
        new_expected := current_expected + order_profit;
        RAISE NOTICE '➕ إضافة % د.ع إلى منتظر للمستخدم %', order_profit, user_phone_value;
    
    ELSIF old_profit_type = 'none' AND new_profit_type = 'achieved' THEN
        new_achieved := current_achieved + order_profit;
        RAISE NOTICE '➕ إضافة % د.ع إلى محقق للمستخدم %', order_profit, user_phone_value;
    END IF;
    
    -- ✅ تحديث أرباح المستخدم
    PERFORM set_config('app.operation_context', 'AUTO_PROFIT_UPDATE', true);
    PERFORM set_config('app.authorized_by', 'DATABASE_TRIGGER', true);
    
    UPDATE users
    SET 
        achieved_profits = new_achieved,
        expected_profits = new_expected,
        updated_at = NOW()
    WHERE phone = user_phone_value;
    
    -- ✅ تسجيل العملية
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
        user_phone_value,
        'AUTO_UPDATE',
        current_achieved,
        new_achieved,
        current_expected,
        new_expected,
        order_profit,
        format('تغيير حالة الطلب %s من "%s" إلى "%s"', NEW.id, OLD.status, NEW.status),
        'DATABASE_TRIGGER',
        true
    );
    
    RAISE NOTICE '✅ تم تحديث أرباح المستخدم % تلقائياً', user_phone_value;
    RAISE NOTICE '   📈 محقق: % → % د.ع', current_achieved, new_achieved;
    RAISE NOTICE '   📊 منتظر: % → % د.ع', current_expected, new_expected;
    
    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'خطأ في تحديث الأرباح التلقائي: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3️⃣ إنشاء Trigger على جدول orders
DROP TRIGGER IF EXISTS trigger_auto_update_profits ON orders;

CREATE TRIGGER trigger_auto_update_profits
    AFTER UPDATE ON orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION auto_update_profits_on_status_change();

-- 4️⃣ تحديث دالة validate_profit_operation
CREATE OR REPLACE FUNCTION validate_profit_operation()
RETURNS TRIGGER AS $$
DECLARE
    old_achieved DECIMAL(15,2);
    old_expected DECIMAL(15,2);
    new_achieved DECIMAL(15,2);
    new_expected DECIMAL(15,2);
    operation_context TEXT;
BEGIN
    old_achieved := COALESCE(OLD.achieved_profits, 0);
    old_expected := COALESCE(OLD.expected_profits, 0);
    new_achieved := COALESCE(NEW.achieved_profits, 0);
    new_expected := COALESCE(NEW.expected_profits, 0);
    
    SELECT current_setting('app.operation_context', true) INTO operation_context;
    
    -- ✅ السماح بالتحديثات التلقائية من Database Trigger
    IF operation_context = 'AUTO_PROFIT_UPDATE' THEN
        RETURN NEW;
    END IF;
    
    -- 🛡️ RULE 1: منع التصفير المباشر
    IF (new_achieved = 0 AND old_achieved > 0) OR (new_expected = 0 AND old_expected > 0) THEN
        IF operation_context NOT IN ('AUTHORIZED_RESET', 'AUTHORIZED_WITHDRAWAL') THEN
            RAISE EXCEPTION 'PROFIT_PROTECTION: تصفير الأرباح غير مسموح بدون تصريح خاص';
        END IF;
    END IF;
    
    -- 🛡️ RULE 2: منع النقصان إلا عند السحب المصرح
    IF new_achieved < old_achieved THEN
        IF operation_context NOT IN ('AUTHORIZED_WITHDRAWAL', 'AUTHORIZED_RESET') THEN
            RAISE EXCEPTION 'PROFIT_PROTECTION: تقليل الأرباح المحققة غير مسموح إلا عند السحب المصرح';
        END IF;
    END IF;
    
    -- 🛡️ RULE 3: منع الزيادة المشبوهة
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
    
    -- تسجيل العملية
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

COMMIT;

-- ===================================
-- ✅ تم تطبيق النظام الجديد بنجاح!
-- ===================================

-- التحقق من التطبيق:
SELECT 
    'get_profit_type' as function_name,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_profit_type') 
        THEN '✅ موجودة' 
        ELSE '❌ غير موجودة' 
    END as status
UNION ALL
SELECT 
    'auto_update_profits_on_status_change',
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'auto_update_profits_on_status_change') 
        THEN '✅ موجودة' 
        ELSE '❌ غير موجودة' 
    END
UNION ALL
SELECT 
    'trigger_auto_update_profits',
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_auto_update_profits') 
        THEN '✅ موجود' 
        ELSE '❌ غير موجود' 
    END;

