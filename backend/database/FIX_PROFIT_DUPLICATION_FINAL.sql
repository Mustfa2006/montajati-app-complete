-- ===================================
-- 🛡️ الحل النهائي لمشكلة تضاعف الأرباح
-- Final Fix for Profit Duplication Issue
-- ===================================

-- المشكلة:
-- عندما يتم تغيير حالة الطلب، يتم إضافة الربح 3 مرات عبر Supabase API (PostgREST)
-- السبب: هناك كود في Frontend أو Backend يقوم بتحديث جدول users مباشرة 3 مرات

-- الحل:
-- 1. إضافة UNIQUE CONSTRAINT على profit_transactions لمنع التكرار
-- 2. إضافة ROW-LEVEL LOCK على users table لمنع التحديثات المتزامنة
-- 3. تحديث smart_profit_manager لاستخدام SELECT FOR UPDATE
-- 4. إضافة PROTECTION ضد التحديثات المباشرة من PostgREST

-- ===================================
-- 1️⃣ إضافة UNIQUE CONSTRAINT على profit_transactions
-- ===================================

-- إنشاء index فريد لمنع تكرار المعاملات لنفس الطلب في نفس الثانية
CREATE UNIQUE INDEX IF NOT EXISTS idx_profit_transactions_unique_per_second
ON profit_transactions (
    order_id,
    transaction_type,
    date_trunc('second', created_at)
);

COMMENT ON INDEX idx_profit_transactions_unique_per_second IS 
'منع تكرار معاملات الأرباح لنفس الطلب في نفس الثانية';

-- ===================================
-- 2️⃣ تحديث smart_profit_manager لاستخدام ROW-LEVEL LOCK
-- ===================================

CREATE OR REPLACE FUNCTION smart_profit_manager()
RETURNS TRIGGER AS $$
DECLARE
    profit_amount NUMERIC;
    user_uuid UUID;
    user_phone_number TEXT;
    current_expected NUMERIC;
    current_achieved NUMERIC;
    is_cancelled_status BOOLEAN := FALSE;
    was_cancelled_status BOOLEAN := FALSE;
    delivery_paid_amount NUMERIC := 0;
    last_transaction_time TIMESTAMP;
BEGIN
    -- 🔍 تسجيل السياق للرصد المؤقت
    PERFORM set_config('app.current_order_id', NEW.id, true);
    PERFORM set_config('app.current_order_status', NEW.status, true);
    
    -- ✅ PROTECTION 1: منع تشغيل الـ Trigger إذا لم تتغير الحالة فعلياً
    IF TG_OP = 'UPDATE' AND OLD.status = NEW.status THEN
        RAISE NOTICE '⚠️ لم تتغير الحالة - تجاهل التحديث';
        RETURN NEW;
    END IF;
    
    profit_amount := COALESCE(NEW.profit, 0);
    user_phone_number := NEW.user_phone;
    
    IF profit_amount <= 0 OR user_phone_number IS NULL THEN
        RAISE NOTICE '⚠️ لا يوجد ربح أو رقم هاتف - تجاهل';
        RETURN NEW;
    END IF;
    
    -- 🔒 CRITICAL: قفل صف المستخدم لمنع التحديثات المتزامنة
    SELECT id, 
           COALESCE(expected_profits, 0), 
           COALESCE(achieved_profits, 0)
    INTO user_uuid, current_expected, current_achieved
    FROM users
    WHERE phone = user_phone_number
    FOR UPDATE;  -- 🔒 ROW-LEVEL LOCK
    
    IF user_uuid IS NULL THEN
        RAISE WARNING '❌ المستخدم غير موجود: %', user_phone_number;
        RETURN NEW;
    END IF;
    
    -- ✅ PROTECTION 2: منع التكرار السريع (خلال 5 دقائق)
    SELECT MAX(created_at) INTO last_transaction_time
    FROM profit_transactions
    WHERE order_id = NEW.id AND user_id = user_uuid;
    
    IF last_transaction_time IS NOT NULL AND 
       (EXTRACT(EPOCH FROM (NOW() - last_transaction_time)) < 300) THEN
        RAISE NOTICE '⚠️ 🛡️ PROTECTION: تكرار سريع للطلب % - تجاهل (آخر معاملة منذ % ثانية)', 
            NEW.id, 
            ROUND(EXTRACT(EPOCH FROM (NOW() - last_transaction_time))::NUMERIC, 2);
        RETURN NEW;
    END IF;
    
    -- تحديد الحالات الملغية
    is_cancelled_status := NEW.status IN (
        'cancelled', 'الغاء الطلب', 'رفض الطلب', 'لا يرد', 'لا يرد بعد الاتفاق',
        'مغلق', 'مغلق بعد الاتفاق', 'مفصول عن الخدمة', 'طلب مكرر', 'مستلم مسبقا',
        'الرقم غير معرف', 'الرقم غير داخل في الخدمة', 'لا يمكن الاتصال بالرقم',
        'العنوان غير دقيق', 'لم يطلب', 'حظر المندوب'
    );
    
    IF TG_OP = 'UPDATE' THEN
        was_cancelled_status := OLD.status IN (
            'cancelled', 'الغاء الطلب', 'رفض الطلب', 'لا يرد', 'لا يرد بعد الاتفاق',
            'مغلق', 'مغلق بعد الاتفاق', 'مفصول عن الخدمة', 'طلب مكرر', 'مستلم مسبقا',
            'الرقم غير معرف', 'الرقم غير داخل في الخدمة', 'لا يمكن الاتصال بالرقم',
            'العنوان غير دقيق', 'لم يطلب', 'حظر المندوب'
        );
    END IF;
    
    -- معالجة الحالات المختلفة
    IF TG_OP = 'INSERT' THEN
        IF is_cancelled_status THEN
            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, 0, 'cancelled', NULL, NEW.status, 'طلب جديد ملغى - لا ربح');
            RAISE NOTICE '❌ طلب جديد ملغى: لا يوجد ربح';
        ELSIF NEW.status IN ('delivered', 'تم التسليم للزبون') THEN
            UPDATE users SET achieved_profits = current_achieved + profit_amount, updated_at = NOW() WHERE id = user_uuid;
            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, profit_amount, 'achieved', NULL, NEW.status, 'طلب جديد مُسلم - ربح محقق مباشرة');
            RAISE NOTICE '✅ طلب جديد مُسلم: أضيف % د.ع للأرباح المحققة', profit_amount;
        ELSE
            UPDATE users SET expected_profits = current_expected + profit_amount, updated_at = NOW() WHERE id = user_uuid;
            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, profit_amount, 'expected', NULL, NEW.status, 'طلب جديد - ربح متوقع');
            RAISE NOTICE '⏳ طلب جديد: أضيف % د.ع للأرباح المتوقعة', profit_amount;
        END IF;
    
    ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        IF NOT was_cancelled_status AND is_cancelled_status THEN
            IF OLD.status IN ('delivered', 'تم التسليم للزبون') THEN
                UPDATE users SET achieved_profits = GREATEST(current_achieved - profit_amount, 0), updated_at = NOW() WHERE id = user_uuid;
                INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
                VALUES (user_uuid, NEW.id, profit_amount, 'cancelled_achieved', OLD.status, NEW.status, 'إلغاء طلب مُسلم - إزالة الربح');
                RAISE NOTICE '❌ إلغاء طلب مُسلم: إزالة % د.ع من المحققة', profit_amount;
            ELSE
                UPDATE users SET expected_profits = GREATEST(current_expected - profit_amount, 0), updated_at = NOW() WHERE id = user_uuid;
                INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
                VALUES (user_uuid, NEW.id, profit_amount, 'cancelled_expected', OLD.status, NEW.status, 'إلغاء طلب - إزالة الربح');
                RAISE NOTICE '❌ إلغاء طلب: إزالة % د.ع من المتوقعة', profit_amount;
            END IF;
        ELSIF was_cancelled_status AND NOT is_cancelled_status THEN
            IF NEW.status IN ('delivered', 'تم التسليم للزبون') THEN
                UPDATE users SET achieved_profits = current_achieved + profit_amount, updated_at = NOW() WHERE id = user_uuid;
                INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
                VALUES (user_uuid, NEW.id, profit_amount, 'restored_achieved', OLD.status, NEW.status, 'إعادة تفعيل طلب مُسلم');
                RAISE NOTICE '✅ إعادة تفعيل طلب مُسلم: إضافة % د.ع للمحققة', profit_amount;
            ELSE
                UPDATE users SET expected_profits = current_expected + profit_amount, updated_at = NOW() WHERE id = user_uuid;
                INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
                VALUES (user_uuid, NEW.id, profit_amount, 'restored_expected', OLD.status, NEW.status, 'إعادة تفعيل طلب');
                RAISE NOTICE '✅ إعادة تفعيل طلب: إضافة % د.ع للمتوقعة', profit_amount;
            END IF;
        ELSIF NOT was_cancelled_status AND NOT is_cancelled_status AND 
              NEW.status IN ('delivered', 'تم التسليم للزبون') AND 
              OLD.status NOT IN ('delivered', 'تم التسليم للزبون') THEN
            UPDATE users SET expected_profits = GREATEST(current_expected - profit_amount, 0), achieved_profits = current_achieved + profit_amount, updated_at = NOW() WHERE id = user_uuid;
            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, profit_amount, 'achieved', OLD.status, NEW.status, 'تم تسليم الطلب - نقل الربح');
            RAISE NOTICE '💰 تم التسليم: نقل % د.ع من المتوقعة إلى المحققة', profit_amount;
        ELSIF NOT was_cancelled_status AND NOT is_cancelled_status AND 
              OLD.status IN ('delivered', 'تم التسليم للزبون') AND 
              NEW.status NOT IN ('delivered', 'تم التسليم للزبون') THEN
            UPDATE users SET achieved_profits = GREATEST(current_achieved - profit_amount, 0), expected_profits = current_expected + profit_amount, updated_at = NOW() WHERE id = user_uuid;
            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, profit_amount, 'reversed', OLD.status, NEW.status, 'إلغاء التسليم - إرجاع الربح');
            RAISE NOTICE '🔄 إلغاء التسليم: إرجاع % د.ع من المحققة إلى المتوقعة', profit_amount;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 3️⃣ تحديث validate_profit_operation لمنع التحديثات المباشرة من PostgREST
-- ===================================

CREATE OR REPLACE FUNCTION validate_profit_operation()
RETURNS TRIGGER AS $$
DECLARE
    old_achieved DECIMAL(15,2);
    old_expected DECIMAL(15,2);
    new_achieved DECIMAL(15,2);
    new_expected DECIMAL(15,2);
    operation_context TEXT;
    current_app_name TEXT;
BEGIN
    -- الحصول على القيم القديمة والجديدة
    old_achieved := COALESCE(OLD.achieved_profits, 0);
    old_expected := COALESCE(OLD.expected_profits, 0);
    new_achieved := COALESCE(NEW.achieved_profits, 0);
    new_expected := COALESCE(NEW.expected_profits, 0);
    
    -- الحصول على سياق العملية من متغير الجلسة
    SELECT current_setting('app.operation_context', true) INTO operation_context;
    
    -- الحصول على اسم التطبيق الحالي
    SELECT application_name INTO current_app_name FROM pg_stat_activity WHERE pid = pg_backend_pid();
    
    -- 🛡️ PROTECTION: منع التحديثات المباشرة من PostgREST إلا إذا كانت مصرحة
    IF current_app_name = 'postgrest' AND operation_context IS NULL THEN
        RAISE EXCEPTION 'PROFIT_PROTECTION: تحديث الأرباح مباشرة من PostgREST غير مسموح! استخدم Database Triggers أو Authorized Functions فقط.';
    END IF;
    
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
        COALESCE(operation_context, 'UNKNOWN'),
        old_achieved,
        new_achieved,
        old_expected,
        new_expected,
        ABS((new_achieved - old_achieved) + (new_expected - old_expected)),
        'تحديث الأرباح',
        COALESCE(current_setting('app.authorized_by', true), 'UNKNOWN'),
        operation_context IS NOT NULL
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- ✅ تم تطبيق الحل النهائي
-- ===================================

RAISE NOTICE '✅ تم تطبيق الحل النهائي لمشكلة تضاعف الأرباح';
RAISE NOTICE '🔒 تم إضافة ROW-LEVEL LOCK على users table';
RAISE NOTICE '🛡️ تم إضافة UNIQUE CONSTRAINT على profit_transactions';
RAISE NOTICE '🚫 تم منع التحديثات المباشرة من PostgREST';

