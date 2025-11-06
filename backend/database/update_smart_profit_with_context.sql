-- ===================================
-- تحديث smart_profit_manager مع تسجيل السياق وحماية 5 دقائق
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
    
    profit_amount := COALESCE(NEW.profit_amount, NEW.profit, 0);
    delivery_paid_amount := COALESCE(NEW.delivery_paid_from_profit, 0);
    
    IF profit_amount <= 0 THEN
        IF delivery_paid_amount > 0 THEN
            RAISE NOTICE 'ℹ️ طلب بربح 0 لكن تم دفع % د.ع من الربح للتوصيل: %', delivery_paid_amount, NEW.id;
        ELSE
            RAISE NOTICE 'ℹ️ طلب بربح 0: % - لا يؤثر على الأرباح', NEW.id;
        END IF;
        RETURN NEW;
    END IF;
    
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
    
    -- ✅ PROTECTION 2: منع التكرار السريع (خلال 5 دقائق = 300 ثانية)
    SELECT MAX(created_at) INTO last_transaction_time
    FROM profit_transactions
    WHERE order_id = NEW.id
      AND user_id = user_uuid;
    
    IF last_transaction_time IS NOT NULL AND 
       (EXTRACT(EPOCH FROM (NOW() - last_transaction_time)) < 300) THEN
        RAISE NOTICE '⚠️ 🛡️ PROTECTION: تكرار سريع للطلب % - تجاهل (آخر معاملة منذ % ثانية)', 
            NEW.id, 
            ROUND(EXTRACT(EPOCH FROM (NOW() - last_transaction_time))::NUMERIC, 2);
        RETURN NEW;
    END IF;
    
    SELECT expected_profits, achieved_profits 
    INTO current_expected, current_achieved
    FROM users WHERE id = user_uuid;
    
    current_expected := COALESCE(current_expected, 0);
    current_achieved := COALESCE(current_achieved, 0);
    
    is_cancelled_status := NEW.status IN ('رفض الطلب', 'الغاء الطلب', 'cancelled', 'rejected');
    
    IF TG_OP = 'UPDATE' THEN
        was_cancelled_status := OLD.status IN ('رفض الطلب', 'الغاء الطلب', 'cancelled', 'rejected');
    END IF;
    
    -- تعيين سياق العملية
    PERFORM set_config('app.operation_context', 'AUTO_PROFIT_UPDATE', true);
    PERFORM set_config('app.authorized_by', 'DATABASE_TRIGGER', true);
    
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
-- ✅ تم تحديث smart_profit_manager
-- ===================================
-- التغييرات:
-- 1. إضافة تسجيل السياق (app.current_order_id, app.current_order_status)
-- 2. زيادة الحماية من التكرار من 1 ثانية إلى 5 دقائق (300 ثانية)
-- 3. إضافة رسائل تفصيلية للحماية
-- ===================================

