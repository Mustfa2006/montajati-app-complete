-- ============================================
-- 🚀 ORDER_PROFIT_ENGINE.sql
-- نظام أرباح مبسّط وذكي (Profit Engine)
-- ============================================

-- 1) جدول حالة ربح الطلب
CREATE TABLE IF NOT EXISTS order_profit_state (
    order_id        uuid PRIMARY KEY,
    user_id         uuid NOT NULL,
    user_phone      text NOT NULL,
    profit_amount   numeric(18,4) NOT NULL DEFAULT 0,
    profit_type     text NOT NULL DEFAULT 'none', -- expected | achieved | reversed
    is_processed    boolean NOT NULL DEFAULT false,
    processed_at    timestamptz,
    last_status     text,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

-- 2) دالة مساعدة لتسجيل الحالة
CREATE OR REPLACE FUNCTION ensure_order_profit_state(
    p_order_id uuid,
    p_user_id uuid,
    p_user_phone text,
    p_profit_amount numeric,
    p_status text
) RETURNS order_profit_state AS $$
DECLARE
    v_state order_profit_state;
BEGIN
    SELECT * INTO v_state
    FROM order_profit_state
    WHERE order_id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO order_profit_state(order_id, user_id, user_phone, profit_amount, last_status)
        VALUES (p_order_id, p_user_id, p_user_phone, COALESCE(p_profit_amount,0), p_status)
        RETURNING * INTO v_state;
    ELSE
        UPDATE order_profit_state
        SET profit_amount = COALESCE(v_state.profit_amount,0),
            last_status   = p_status,
            updated_at    = now()
        WHERE order_id = p_order_id
        RETURNING * INTO v_state;
    END IF;

    RETURN v_state;
END;
$$ LANGUAGE plpgsql;

-- 3) الدالة الأساسية: معالجة ربح الطلب
CREATE OR REPLACE FUNCTION process_order_profit(p_order orders)
RETURNS void AS $$
DECLARE
    v_user_id uuid;
    v_phone   text;
    v_profit  numeric(18,4);
    v_state   order_profit_state;
    v_is_delivered boolean;
BEGIN
    -- جلب بيانات أساسية من الطلب
    v_user_id := p_order.user_id;
    v_phone   := COALESCE(p_order.user_phone, '');
    v_profit  := COALESCE(p_order.profit_amount, p_order.profit, 0);

    IF v_user_id IS NULL OR v_phone = '' OR v_profit <= 0 THEN
        RETURN; -- لا يوجد ربح صالح
    END IF;

    -- تحديد حالة التسليم
    v_is_delivered := p_order.status IN ('delivered', 'تم التسليم للزبون');

    -- ضمان وجود سجل في order_profit_state
    v_state := ensure_order_profit_state(p_order.id, v_user_id, v_phone, v_profit, p_order.status);

    -- لو تم معالجة هذا الطلب سابقاً لا نعيد شيء (idempotent)
    IF v_state.is_processed THEN
        RETURN;
    END IF;

    -- لا نحسب ربح إلا عند أول مرة يصل فيها الطلب إلى حالة التسليم النهائي
    IF NOT v_is_delivered THEN
        RETURN;
    END IF;

    -- قفل صف المستخدم
    PERFORM 1 FROM users WHERE id = v_user_id FOR UPDATE;

    -- تحديث أرباح المستخدم مرة واحدة فقط لهذا الطلب
    UPDATE users
    SET achieved_profits = COALESCE(achieved_profits,0) + v_profit,
        expected_profits = GREATEST(0, COALESCE(expected_profits,0) - v_profit),
        updated_at       = now()
    WHERE id = v_user_id;

    -- تحديث حالة الربح للطلب
    UPDATE order_profit_state
    SET is_processed = true,
        profit_type  = 'achieved',
        processed_at = now(),
        last_status  = p_order.status,
        updated_at   = now()
    WHERE order_id = p_order.id;
END;
$$ LANGUAGE plpgsql;

-- 4) تريغر مبسّط على orders يستخدم المحرك الجديد
CREATE OR REPLACE FUNCTION orders_profit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- نعتمد فقط على الصف الجديد
    PERFORM process_order_profit(NEW);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS smart_profit_trigger ON orders;

CREATE TRIGGER smart_profit_trigger
AFTER INSERT OR UPDATE OF status ON orders
FOR EACH ROW
EXECUTE FUNCTION orders_profit_trigger();

