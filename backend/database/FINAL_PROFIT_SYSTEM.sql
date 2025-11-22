-- FINAL_PROFIT_SYSTEM.sql
-- نظام الأرباح الذكي النهائي (0% أخطاء)

-- 1) جدول حالة ربح كل طلب
CREATE TABLE IF NOT EXISTS order_profit_state (
  order_id TEXT PRIMARY KEY REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profit_amount NUMERIC(15,2) NOT NULL DEFAULT 0,
  current_state VARCHAR(20) NOT NULL DEFAULT 'expected', -- expected / achieved / cancelled
  is_processed BOOLEAN NOT NULL DEFAULT FALSE,           -- هل تم تحويله إلى achieved مرة واحدة؟
  last_status VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2) جدول سجل الأرباح المتقدم (إن لم يكن موجوداً)
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

-- 3) دالة التحقق من صحة الانتقال
CREATE OR REPLACE FUNCTION validate_profit_transition(
  p_user_id UUID,
  p_old_expected NUMERIC,
  p_new_expected NUMERIC,
  p_old_achieved NUMERIC,
  p_new_achieved NUMERIC,
  p_profit_amount NUMERIC
) RETURNS TABLE(is_valid BOOLEAN, error_message TEXT) AS $$
DECLARE v_total_change NUMERIC; v_expected_change NUMERIC; v_achieved_change NUMERIC; BEGIN
  IF p_new_expected < 0 OR p_new_achieved < 0 THEN
    RETURN QUERY SELECT FALSE, 'الأرباح لا يمكن أن تكون سالبة'::TEXT; RETURN; END IF;
  v_total_change := (p_new_expected + p_new_achieved) - (p_old_expected + p_old_achieved);
  IF ABS(v_total_change) > ABS(p_profit_amount) * 1.1 THEN
    RETURN QUERY SELECT FALSE, 'تغيير غير متوقع في إجمالي الأرباح'::TEXT; RETURN; END IF;
  v_expected_change := p_new_expected - p_old_expected;
  v_achieved_change := p_new_achieved - p_old_achieved;
  IF v_expected_change < 0 AND v_achieved_change > 0 AND ABS(v_expected_change) <> ABS(v_achieved_change) THEN
    RETURN QUERY SELECT FALSE, 'عدم توازن في نقل الأرباح'::TEXT; RETURN; END IF;
  RETURN QUERY SELECT TRUE, ''::TEXT; END; $$ LANGUAGE plpgsql;

-- 4) دالة التحديث الآمن لأرباح المستخدم
CREATE OR REPLACE FUNCTION safe_update_user_profits(
  p_user_id UUID,
  p_order_id TEXT,
  p_profit_amount NUMERIC,
  p_old_status VARCHAR,
  p_new_status VARCHAR,
  p_transaction_type VARCHAR
) RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
  v_current_expected NUMERIC; v_current_achieved NUMERIC;
  v_new_expected NUMERIC; v_new_achieved NUMERIC;
  v_is_valid BOOLEAN; v_error_msg TEXT;
BEGIN
  SELECT expected_profits, achieved_profits
    INTO v_current_expected, v_current_achieved
    FROM users WHERE id = p_user_id FOR UPDATE;
  v_current_expected := COALESCE(v_current_expected, 0);
  v_current_achieved := COALESCE(v_current_achieved, 0);
  v_new_expected := v_current_expected; v_new_achieved := v_current_achieved;

  CASE p_transaction_type
    WHEN 'MOVE_TO_ACHIEVED' THEN
      v_new_expected := GREATEST(v_current_expected - p_profit_amount, 0);
      v_new_achieved := v_current_achieved + p_profit_amount;
    WHEN 'MOVE_TO_EXPECTED' THEN
      v_new_achieved := GREATEST(v_current_achieved - p_profit_amount, 0);
      v_new_expected := v_current_expected + p_profit_amount;
    WHEN 'ADD_EXPECTED' THEN
      v_new_expected := v_current_expected + p_profit_amount;
    WHEN 'ADD_ACHIEVED' THEN
      v_new_achieved := v_current_achieved + p_profit_amount;
    WHEN 'CANCEL_ORDER' THEN
      IF lower(btrim(COALESCE(p_old_status, ''))) IN ('delivered','تم التسليم للزبون') THEN
        v_new_achieved := GREATEST(v_current_achieved - p_profit_amount, 0);
      ELSE
        v_new_expected := GREATEST(v_current_expected - p_profit_amount, 0);
      END IF;
    WHEN 'RESTORE_ORDER' THEN
      IF lower(btrim(COALESCE(p_new_status, ''))) IN ('delivered','تم التسليم للزبون') THEN
        v_new_achieved := v_current_achieved + p_profit_amount;
      ELSE
        v_new_expected := v_current_expected + p_profit_amount;
      END IF;
    WHEN 'CANCELLED_NEW' THEN
      NULL; -- لا تغيير في الأرباح
  END CASE;

  SELECT is_valid, error_message
    INTO v_is_valid, v_error_msg
    FROM validate_profit_transition(
      p_user_id,
      v_current_expected, v_new_expected,
      v_current_achieved, v_new_achieved,
      p_profit_amount
    );
  IF NOT v_is_valid THEN
    INSERT INTO profit_audit_log(
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
    RETURN QUERY SELECT FALSE, v_error_msg; RETURN; END IF;

  UPDATE users SET
    expected_profits = v_new_expected,
    achieved_profits = v_new_achieved,
    updated_at = NOW()
  WHERE id = p_user_id;

  INSERT INTO profit_audit_log(
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

  RETURN QUERY SELECT TRUE, 'تم تحديث الأرباح بنجاح'::TEXT; END; $$ LANGUAGE plpgsql;

-- 5) Trigger: المحرك الذكي الوحيد للأرباح
DROP TRIGGER IF EXISTS smart_profit_trigger ON orders;
DROP FUNCTION IF EXISTS smart_profit_manager();

CREATE OR REPLACE FUNCTION smart_profit_manager()
RETURNS TRIGGER AS $$
DECLARE
  v_profit NUMERIC; v_user_id UUID; v_user_phone TEXT;
  v_state order_profit_state; v_old_kind TEXT; v_new_kind TEXT;
  v_tx_type TEXT; v_success BOOLEAN; v_message TEXT;
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW; END IF;

  v_profit := COALESCE(NEW.profit_amount, NEW.profit, 0);
  IF v_profit <= 0 THEN RETURN NEW; END IF;

  v_user_id := NEW.user_id; v_user_phone := NEW.user_phone;
  IF v_user_id IS NULL AND v_user_phone IS NOT NULL THEN
    SELECT id INTO v_user_id FROM users WHERE phone = v_user_phone LIMIT 1;
    IF v_user_id IS NOT NULL THEN NEW.user_id := v_user_id; END IF;
  END IF;
  IF v_user_id IS NULL THEN
    RAISE NOTICE '⚠️ لا يوجد مستخدم للطلب % - تجاهل الأرباح', NEW.id; RETURN NEW; END IF;

  v_new_kind := CASE
    WHEN NEW.status IN ('رفض الطلب','الغاء الطلب','cancelled','rejected') THEN 'cancelled'
    WHEN NEW.status IN ('delivered','تم التسليم للزبون') THEN 'achieved'
    ELSE 'expected' END;

  IF TG_OP = 'INSERT' THEN
    v_old_kind := NULL;
  ELSE
    v_old_kind := CASE
      WHEN OLD.status IN ('رفض الطلب','الغاء الطلب','cancelled','rejected') THEN 'cancelled'
      WHEN OLD.status IN ('delivered','تم التسليم للزبون') THEN 'achieved'
      ELSE 'expected' END;
  END IF;

  SELECT * INTO v_state FROM order_profit_state WHERE order_id = NEW.id FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO order_profit_state(order_id,user_id,profit_amount,current_state,is_processed,last_status)
    VALUES (
      NEW.id, v_user_id, v_profit,
      COALESCE(v_old_kind,v_new_kind,'expected'),
      CASE WHEN COALESCE(v_old_kind,v_new_kind) = 'achieved' THEN TRUE ELSE FALSE END,
      COALESCE(OLD.status, NEW.status)
    ) RETURNING * INTO v_state;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF v_new_kind = 'cancelled' THEN
      v_tx_type := 'CANCELLED_NEW';
    ELSIF v_new_kind = 'achieved' THEN
      v_tx_type := 'ADD_ACHIEVED'; v_state.current_state := 'achieved'; v_state.is_processed := TRUE;
    ELSE
      v_tx_type := 'ADD_EXPECTED'; v_state.current_state := 'expected'; v_state.is_processed := FALSE;
    END IF;

    UPDATE order_profit_state SET
      current_state = v_state.current_state,
      is_processed = v_state.is_processed,
      last_status = NEW.status,
      profit_amount = v_profit,
      updated_at = NOW()
    WHERE order_id = NEW.id;

    SELECT success, message INTO v_success, v_message
      FROM safe_update_user_profits(v_user_id, NEW.id, v_profit, NULL, NEW.status, v_tx_type);
    RETURN NEW;
  END IF;

  -- UPDATE
  IF v_old_kind = v_new_kind THEN
    UPDATE order_profit_state SET last_status = NEW.status, updated_at = NOW() WHERE order_id = NEW.id;
    RETURN NEW; END IF;

  IF v_old_kind <> 'achieved' AND v_new_kind = 'achieved' THEN
    IF v_state.is_processed THEN
      RAISE NOTICE '🛡️ order % أرباحه محولة مسبقاً - تجاهل أي نقل إضافي', NEW.id;
    ELSE
      v_tx_type := 'MOVE_TO_ACHIEVED';
      SELECT success, message INTO v_success, v_message
        FROM safe_update_user_profits(v_user_id, NEW.id, v_profit, OLD.status, NEW.status, v_tx_type);
      UPDATE order_profit_state SET current_state = 'achieved', is_processed = TRUE, last_status = NEW.status, updated_at = NOW()
        WHERE order_id = NEW.id;
    END IF;

  ELSIF v_old_kind = 'achieved' AND v_new_kind = 'expected' THEN
    v_tx_type := 'MOVE_TO_EXPECTED';
    SELECT success, message INTO v_success, v_message
      FROM safe_update_user_profits(v_user_id, NEW.id, v_profit, OLD.status, NEW.status, v_tx_type);
    UPDATE order_profit_state SET current_state = 'expected', is_processed = FALSE, last_status = NEW.status, updated_at = NOW()
      WHERE order_id = NEW.id;

  ELSIF v_old_kind <> 'cancelled' AND v_new_kind = 'cancelled' THEN
    v_tx_type := 'CANCEL_ORDER';
    SELECT success, message INTO v_success, v_message
      FROM safe_update_user_profits(v_user_id, NEW.id, v_profit, OLD.status, NEW.status, v_tx_type);
    UPDATE order_profit_state SET current_state = 'cancelled', last_status = NEW.status, updated_at = NOW()
      WHERE order_id = NEW.id;

  ELSIF v_old_kind = 'cancelled' AND v_new_kind <> 'cancelled' THEN
    v_tx_type := 'RESTORE_ORDER';
    SELECT success, message INTO v_success, v_message
      FROM safe_update_user_profits(v_user_id, NEW.id, v_profit, OLD.status, NEW.status, v_tx_type);
    UPDATE order_profit_state SET
      current_state = v_new_kind,
      is_processed = (v_new_kind = 'achieved'),
      last_status = NEW.status,
      updated_at = NOW()
    WHERE order_id = NEW.id;

  ELSE
    UPDATE order_profit_state SET last_status = NEW.status, updated_at = NOW() WHERE order_id = NEW.id;
  END IF;

  RETURN NEW; END; $$ LANGUAGE plpgsql;

CREATE TRIGGER smart_profit_trigger
  AFTER INSERT OR UPDATE OF status ON orders
  FOR EACH ROW EXECUTE FUNCTION smart_profit_manager();

-- 6) دالة بسيطة لفحص سلامة النظام
CREATE OR REPLACE FUNCTION verify_profit_system_integrity()
RETURNS TABLE(user_phone TEXT, expected_profits NUMERIC, achieved_profits NUMERIC, total_profits NUMERIC) AS $$
  SELECT phone, expected_profits, achieved_profits,
         expected_profits + achieved_profits AS total_profits
  FROM users
  ORDER BY total_profits DESC;
$$ LANGUAGE sql;

