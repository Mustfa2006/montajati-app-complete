-- 🔧 إصلاح Trigger smart_profit_manager
-- المشكلة: الربح يُضاف لكن لا ينقص من expected_profits
-- الحل: استخدام FOR UPDATE لقفل الصف وضمان دقة القيم

DROP TRIGGER IF EXISTS smart_profit_trigger ON orders;
DROP FUNCTION IF EXISTS smart_profit_manager();

CREATE OR REPLACE FUNCTION smart_profit_manager()
RETURNS TRIGGER AS $$
DECLARE
    profit_amount NUMERIC;
    user_uuid UUID;
    user_phone_number TEXT;
    current_expected NUMERIC;
    current_achieved NUMERIC;
    new_expected NUMERIC;
    new_achieved NUMERIC;
    is_cancelled_status BOOLEAN := FALSE;
    was_cancelled_status BOOLEAN := FALSE;
    delivery_paid_amount NUMERIC := 0;
    last_transaction_time TIMESTAMP;
    normalized_new_status TEXT;
    normalized_old_status TEXT;
BEGIN
    -- ⏭️ تخطي إذا لم تتغير الحالة
    IF TG_OP = 'UPDATE' AND OLD.status = NEW.status THEN
        RAISE NOTICE '⚠️ لم تتغير الحالة - تجاهل التحديث';
        RETURN NEW;
    END IF;

    -- 📊 استخراج الربح
    profit_amount := COALESCE(NEW.profit_amount, NEW.profit, 0);
    delivery_paid_amount := COALESCE(NEW.delivery_paid_from_profit, 0);

    -- تخطي إذا لم يكن هناك ربح
    IF profit_amount <= 0 THEN
        IF delivery_paid_amount > 0 THEN
            RAISE NOTICE 'ℹ️ طلب بربح 0 لكن تم دفع % د.ع من الربح للتوصيل: %', delivery_paid_amount, NEW.id;
        ELSE
            RAISE NOTICE 'ℹ️ طلب بربح 0: % - لا يؤثر على الأرباح', NEW.id;
        END IF;
        RETURN NEW;
    END IF;

    -- 👤 الحصول على معرف المستخدم
    user_uuid := NEW.user_id;
    user_phone_number := NEW.user_phone;

    IF user_uuid IS NULL AND user_phone_number IS NOT NULL THEN
        SELECT id INTO user_uuid FROM users WHERE phone = user_phone_number LIMIT 1;
        IF user_uuid IS NOT NULL THEN
            NEW.user_id := user_uuid;
        END IF;
    END IF;

    IF user_uuid IS NULL THEN
        RAISE NOTICE '⚠️ لا يمكن العثور على معرف المستخدم للطلب: %', NEW.id;
        RETURN NEW;
    END IF;

    -- 🧠 توحيد نصوص الحالات للتعامل مع null و الفراغ و الحالات غير المسموحة
    normalized_new_status := lower(btrim(COALESCE(NEW.status, '')));

    IF TG_OP = 'UPDATE' THEN
        normalized_old_status := lower(btrim(COALESCE(OLD.status, '')));
    ELSE
        normalized_old_status := NULL;
    END IF;

    -- 🛡️ حماية مطلقة: إذا كانت الحالة الجديدة غير معروفة/غير صالحة لا نغيّر أي أرباح
    IF normalized_new_status = '' OR normalized_new_status IN ('null', 'undefined', 'غير معروف', 'غير معروفة', 'unknown') THEN
        RAISE NOTICE '⚠️ smart_profit_manager: تجاهل تحديث بسبب حالة جديدة غير معروفة للطلب %: %', NEW.id, NEW.status;
        RETURN NEW;
    END IF;

    -- يمكن أن تكون الحالة القديمة null في INSERT، لذلك نفحص UPDATE فقط
    IF TG_OP = 'UPDATE' AND (normalized_old_status = '' OR normalized_old_status IN ('null', 'undefined', 'غير معروف', 'غير معروفة', 'unknown')) THEN
        RAISE NOTICE '⚠️ smart_profit_manager: تجاهل تحديث بسبب حالة سابقة غير معروفة للطلب %: %', NEW.id, OLD.status;
        RETURN NEW;
    END IF;

    -- 🛡️ التحقق من التكرار السريع
    SELECT MAX(created_at) INTO last_transaction_time
    FROM profit_transactions
    WHERE order_id = NEW.id AND user_id = user_uuid;

    IF last_transaction_time IS NOT NULL AND (EXTRACT(EPOCH FROM (NOW() - last_transaction_time)) < 300) THEN
        RAISE NOTICE '⚠️ 🛡️ PROTECTION: تكرار سريع للطلب % - تجاهل (آخر معاملة منذ % ثانية)',
            NEW.id, ROUND(EXTRACT(EPOCH FROM (NOW() - last_transaction_time))::NUMERIC, 2);
        RETURN NEW;
    END IF;

    -- 🔒 قفل الصف وجلب القيم الحالية (FOR UPDATE يضمن عدم التحديثات المتزامنة)
    SELECT expected_profits, achieved_profits
    INTO current_expected, current_achieved
    FROM users
    WHERE id = user_uuid
    FOR UPDATE;

    current_expected := COALESCE(current_expected, 0);
    current_achieved := COALESCE(current_achieved, 0);

    -- 🔍 تحديد حالات الطلب
    is_cancelled_status := NEW.status IN ('رفض الطلب', 'الغاء الطلب', 'cancelled', 'rejected');

    IF TG_OP = 'UPDATE' THEN
        was_cancelled_status := OLD.status IN ('رفض الطلب', 'الغاء الطلب', 'cancelled', 'rejected');
    END IF;

    -- 🎯 معالجة INSERT
    IF TG_OP = 'INSERT' THEN
        IF is_cancelled_status THEN
            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, 0, 'cancelled', NULL, NEW.status, 'طلب جديد ملغى - لا ربح');
            RAISE NOTICE '❌ طلب جديد ملغى: لا يوجد ربح';

        ELSIF NEW.status IN ('delivered', 'تم التسليم للزبون') THEN
            new_achieved := current_achieved + profit_amount;
            UPDATE users SET
                achieved_profits = new_achieved,
                updated_at = NOW()
            WHERE id = user_uuid;
            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, profit_amount, 'achieved', NULL, NEW.status, 'طلب جديد مُسلم - ربح محقق مباشرة');
            RAISE NOTICE '✅ طلب جديد مُسلم: أضيف % د.ع للأرباح المحققة', profit_amount;

        ELSE
            new_expected := current_expected + profit_amount;
            UPDATE users SET
                expected_profits = new_expected,
                updated_at = NOW()
            WHERE id = user_uuid;
            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, profit_amount, 'expected', NULL, NEW.status, 'طلب جديد - ربح متوقع');
            RAISE NOTICE '⏳ طلب جديد: أضيف % د.ع للأرباح المتوقعة', profit_amount;
        END IF;

    -- 🎯 معالجة UPDATE
    ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN

        -- ❌ من عادي إلى ملغى
        IF NOT was_cancelled_status AND is_cancelled_status THEN
            IF OLD.status IN ('delivered', 'تم التسليم للزبون') THEN
                new_achieved := GREATEST(current_achieved - profit_amount, 0);
                UPDATE users SET
                    achieved_profits = new_achieved,
                    updated_at = NOW()
                WHERE id = user_uuid;
                INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
                VALUES (user_uuid, NEW.id, profit_amount, 'cancelled_achieved', OLD.status, NEW.status, 'إلغاء طلب مُسلم - إزالة الربح');
                RAISE NOTICE '❌ إلغاء طلب مُسلم: إزالة % د.ع من المحققة', profit_amount;
            ELSE
                new_expected := GREATEST(current_expected - profit_amount, 0);
                UPDATE users SET
                    expected_profits = new_expected,
                    updated_at = NOW()
                WHERE id = user_uuid;
                INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
                VALUES (user_uuid, NEW.id, profit_amount, 'cancelled_expected', OLD.status, NEW.status, 'إلغاء طلب - إزالة الربح');
                RAISE NOTICE '❌ إلغاء طلب: إزالة % د.ع من المتوقعة', profit_amount;
            END IF;

        -- ✅ من ملغى إلى عادي
        ELSIF was_cancelled_status AND NOT is_cancelled_status THEN
            IF NEW.status IN ('delivered', 'تم التسليم للزبون') THEN
                new_achieved := current_achieved + profit_amount;
                UPDATE users SET
                    achieved_profits = new_achieved,
                    updated_at = NOW()
                WHERE id = user_uuid;
                INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
                VALUES (user_uuid, NEW.id, profit_amount, 'restored_achieved', OLD.status, NEW.status, 'إعادة تفعيل طلب مُسلم');
                RAISE NOTICE '✅ إعادة تفعيل طلب مُسلم: إضافة % د.ع للمحققة', profit_amount;
            ELSE
                new_expected := current_expected + profit_amount;
                UPDATE users SET
                    expected_profits = new_expected,
                    updated_at = NOW()
                WHERE id = user_uuid;
                INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
                VALUES (user_uuid, NEW.id, profit_amount, 'restored_expected', OLD.status, NEW.status, 'إعادة تفعيل طلب');
                RAISE NOTICE '✅ إعادة تفعيل طلب: إضافة % د.ع للمتوقعة', profit_amount;
            END IF;

        -- 💰 من عادي إلى مسلم (المشكلة الأساسية - الحل هنا!)
        ELSIF NOT was_cancelled_status AND NOT is_cancelled_status
              AND NEW.status IN ('delivered', 'تم التسليم للزبون')
              AND OLD.status NOT IN ('delivered', 'تم التسليم للزبون') THEN

            -- 🛡️ Idempotency guard: avoid double-adding achieved profit for the same order
            IF EXISTS (
                SELECT 1 FROM profit_transactions
                WHERE user_id = user_uuid AND order_id = NEW.id AND transaction_type = 'achieved'
            ) THEN
                RAISE NOTICE '🛡️ Idempotency: achieved transaction already exists for order %, skipping.', NEW.id;
                RETURN NEW;
            END IF;

            new_expected := GREATEST(current_expected - profit_amount, 0);
            new_achieved := current_achieved + profit_amount;

            UPDATE users SET
                expected_profits = new_expected,
                achieved_profits = new_achieved,
                updated_at = NOW()
            WHERE id = user_uuid;

            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, profit_amount, 'achieved', OLD.status, NEW.status, 'تم تسليم الطلب - نقل الربح');

            RAISE NOTICE '💰 تم التسليم: نقل % د.ع من المتوقعة (% → %) إلى المحققة (% → %)',
                profit_amount, current_expected, new_expected, current_achieved, new_achieved;

        -- 🔄 من مسلم إلى عادي
        ELSIF NOT was_cancelled_status AND NOT is_cancelled_status
              AND OLD.status IN ('delivered', 'تم التسليم للزبون')
              AND NEW.status NOT IN ('delivered', 'تم التسليم للزبون') THEN

            new_achieved := GREATEST(current_achieved - profit_amount, 0);
            new_expected := current_expected + profit_amount;

            UPDATE users SET
                achieved_profits = new_achieved,
                expected_profits = new_expected,
                updated_at = NOW()
            WHERE id = user_uuid;

            INSERT INTO profit_transactions (user_id, order_id, amount, transaction_type, old_status, new_status, notes)
            VALUES (user_uuid, NEW.id, profit_amount, 'reversed', OLD.status, NEW.status, 'إلغاء التسليم - إرجاع الربح');

            RAISE NOTICE '🔄 إلغاء التسليم: إرجاع % د.ع من المحققة (% → %) إلى المتوقعة (% → %)',
                profit_amount, current_achieved, new_achieved, current_expected, new_expected;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء الـ Trigger
CREATE TRIGGER smart_profit_trigger
    AFTER INSERT OR UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION smart_profit_manager();

