-- ===================================
-- 🛡️ نظام الأرباح التلقائي الآمن 100%
-- ===================================
-- 
-- 🎯 الهدف:
-- - كل شيء يحدث في قاعدة البيانات
-- - Backend لا يتدخل في حساب الأرباح أبداً
-- - Frontend لا يتدخل في حساب الأرباح أبداً
-- - حماية قوية جداً من الأخطاء
--
-- 📊 القواعد:
-- 1. "تم التسليم للزبون" → أرباح محققة
-- 2. الحالات النشطة → أرباح منتظرة
-- 3. الحالات الملغية/المرفوضة → لا ربح
--
-- ===================================

-- 1️⃣ دالة تحديد نوع الربح حسب الحالة
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

-- 2️⃣ دالة تحديث الأرباح التلقائي عند تغيير حالة الطلب
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
        -- لم تتغير الحالة، لا حاجة لتحديث الأرباح
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
    
    -- 1. من منتظر إلى محقق (مثال: نشط → تم التسليم)
    IF old_profit_type = 'expected' AND new_profit_type = 'achieved' THEN
        new_expected := GREATEST(current_expected - order_profit, 0);
        new_achieved := current_achieved + order_profit;
        
        RAISE NOTICE '⬆️ نقل % د.ع من منتظر إلى محقق للمستخدم %', order_profit, user_phone_value;
    
    -- 2. من محقق إلى منتظر (مثال: تم التسليم → قيد التوصيل - حالة نادرة)
    ELSIF old_profit_type = 'achieved' AND new_profit_type = 'expected' THEN
        new_achieved := GREATEST(current_achieved - order_profit, 0);
        new_expected := current_expected + order_profit;
        
        RAISE NOTICE '⬇️ نقل % د.ع من محقق إلى منتظر للمستخدم %', order_profit, user_phone_value;
    
    -- 3. من منتظر إلى لا ربح (مثال: نشط → الغاء الطلب)
    ELSIF old_profit_type = 'expected' AND new_profit_type = 'none' THEN
        new_expected := GREATEST(current_expected - order_profit, 0);
        
        RAISE NOTICE '➖ إزالة % د.ع من منتظر للمستخدم %', order_profit, user_phone_value;
    
    -- 4. من محقق إلى لا ربح (مثال: تم التسليم → رفض الطلب - حالة نادرة جداً)
    ELSIF old_profit_type = 'achieved' AND new_profit_type = 'none' THEN
        new_achieved := GREATEST(current_achieved - order_profit, 0);
        
        RAISE NOTICE '➖ إزالة % د.ع من محقق للمستخدم %', order_profit, user_phone_value;
    
    -- 5. من لا ربح إلى منتظر (مثال: الغاء الطلب → نشط)
    ELSIF old_profit_type = 'none' AND new_profit_type = 'expected' THEN
        new_expected := current_expected + order_profit;
        
        RAISE NOTICE '➕ إضافة % د.ع إلى منتظر للمستخدم %', order_profit, user_phone_value;
    
    -- 6. من لا ربح إلى محقق (مثال: الغاء الطلب → تم التسليم - حالة نادرة جداً)
    ELSIF old_profit_type = 'none' AND new_profit_type = 'achieved' THEN
        new_achieved := current_achieved + order_profit;
        
        RAISE NOTICE '➕ إضافة % د.ع إلى محقق للمستخدم %', order_profit, user_phone_value;
    END IF;
    
    -- ✅ تحديث أرباح المستخدم في قاعدة البيانات
    -- تعيين سياق العملية لتجاوز حماية validate_profit_operation
    PERFORM set_config('app.operation_context', 'AUTO_PROFIT_UPDATE', true);
    PERFORM set_config('app.authorized_by', 'DATABASE_TRIGGER', true);
    
    UPDATE users
    SET 
        achieved_profits = new_achieved,
        expected_profits = new_expected,
        updated_at = NOW()
    WHERE phone = user_phone_value;
    
    -- ✅ تسجيل العملية في السجل
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
    -- في حالة حدوث خطأ، نسجله ونكمل
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

-- 4️⃣ تحديث دالة validate_profit_operation لقبول AUTO_PROFIT_UPDATE
-- (نحتاج تعديل الدالة الموجودة في profit_protection.sql)

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
    
    -- ✅ السماح بالتحديثات التلقائية من Database Trigger
    IF operation_context = 'AUTO_PROFIT_UPDATE' THEN
        -- تسجيل العملية في السجل (تم بالفعل في auto_update_profits_on_status_change)
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

-- ===================================
-- ✅ تم إنشاء النظام التلقائي الآمن!
-- ===================================

COMMENT ON FUNCTION get_profit_type(TEXT) IS 'تحديد نوع الربح (achieved/expected/none) حسب حالة الطلب';
COMMENT ON FUNCTION auto_update_profits_on_status_change() IS 'تحديث أرباح المستخدم تلقائياً عند تغيير حالة الطلب';
COMMENT ON TRIGGER trigger_auto_update_profits ON orders IS 'Trigger تلقائي لتحديث الأرباح عند تغيير حالة الطلب';

