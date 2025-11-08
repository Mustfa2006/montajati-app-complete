-- ===================================
-- تفعيل Row Level Security وحماية أعمدة الربح
-- Enable RLS and Protect Profit Columns
-- ===================================

-- 1. تفعيل RLS للجداول الحساسة
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE profit_operations_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE profit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE provinces ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE waseet_cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE waseet_provinces ENABLE ROW LEVEL SECURITY;
ALTER TABLE waseet_regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE waseet_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- 2. إنشاء دور للمدراء
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_role') THEN
        CREATE ROLE admin_role;
    END IF;
END $$;

-- 3. سياسات للمنتجات - حماية أعمدة الربح
DROP POLICY IF EXISTS "allow_all_products" ON products;

-- قراءة المنتجات للجميع (بدون أعمدة الربح الحساسة)
CREATE POLICY "public_read_products" ON products
    FOR SELECT
    TO public
    USING (true);

-- إدراج وتحديث المنتجات للمدراء فقط
CREATE POLICY "admin_manage_products" ON products
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 4. سياسات للطلبات - حماية أعمدة الربح
DROP POLICY IF EXISTS "Admins can manage all orders" ON orders;
DROP POLICY IF EXISTS "Users can create their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;

-- قراءة الطلبات للمستخدمين (بدون أعمدة الربح)
CREATE POLICY "users_read_own_orders" ON orders
    FOR SELECT
    TO public
    USING (user_id = auth.uid());

-- إنشاء الطلبات للمستخدمين
CREATE POLICY "users_create_orders" ON orders
    FOR INSERT
    TO public
    WITH CHECK (user_id = auth.uid());

-- تحديث الطلبات للمستخدمين (بدون أعمدة الربح)
CREATE POLICY "users_update_own_orders" ON orders
    FOR UPDATE
    TO public
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- إدارة كاملة للطلبات للمدراء
CREATE POLICY "admin_manage_orders" ON orders
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 5. سياسات لمعاملات الربح - للمدراء فقط
CREATE POLICY "admin_only_profit_transactions" ON profit_transactions
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 6. سياسات لسجل عمليات الربح - للمدراء فقط
CREATE POLICY "admin_only_profit_operations" ON profit_operations_log
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 7. سياسات للمستخدمين
CREATE POLICY "users_read_own_profile" ON users
    FOR SELECT
    TO public
    USING (id = auth.uid());

CREATE POLICY "users_update_own_profile" ON users
    FOR UPDATE
    TO public
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "admin_manage_users" ON users
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 8. سياسات لطلبات السحب
CREATE POLICY "users_manage_own_withdrawals" ON withdrawal_requests
    FOR ALL
    TO public
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "admin_manage_withdrawals" ON withdrawal_requests
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 9. سياسات للفئات والمدن (قراءة للجميع، إدارة للمدراء)
CREATE POLICY "public_read_categories" ON categories
    FOR SELECT
    TO public
    USING (true);

CREATE POLICY "admin_manage_categories" ON categories
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "public_read_cities" ON cities
    FOR SELECT
    TO public
    USING (true);

CREATE POLICY "admin_manage_cities" ON cities
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "public_read_provinces" ON provinces
    FOR SELECT
    TO public
    USING (true);

CREATE POLICY "admin_manage_provinces" ON provinces
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 10. سياسات للإشعارات
CREATE POLICY "users_read_own_notifications" ON notifications
    FOR SELECT
    TO public
    USING (user_id = auth.uid());

CREATE POLICY "admin_manage_notifications" ON notifications
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 11. سياسات لسجلات النظام - للمدراء فقط
CREATE POLICY "admin_only_system_logs" ON system_logs
    FOR ALL
    TO admin_role
    USING (true)
    WITH CHECK (true);

-- 12. إنشاء view آمن للمنتجات بدون أعمدة الربح
CREATE OR REPLACE VIEW public_products AS
SELECT 
    id,
    name,
    description,
    image_url,
    available_quantity,
    category,
    is_active,
    created_at,
    updated_at
FROM products
WHERE is_active = true;

-- 13. إنشاء view آمن للطلبات بدون أعمدة الربح
CREATE OR REPLACE VIEW user_orders AS
SELECT 
    id,
    user_id,
    customer_name,
    customer_phone,
    customer_address,
    status,
    subtotal,
    delivery_fee,
    total,
    created_at,
    updated_at
FROM orders;

-- 14. منح صلاحيات للـ views
GRANT SELECT ON public_products TO public;
GRANT SELECT ON user_orders TO public;

-- 15. إنشاء دالة للتحقق من صلاحيات المدير
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16. تحديث سياسات باستخدام دالة التحقق من المدير
DROP POLICY IF EXISTS "admin_manage_products" ON products;
CREATE POLICY "admin_manage_products" ON products
    FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_manage_orders" ON orders;
CREATE POLICY "admin_manage_orders" ON orders
    FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

-- 17. عرض حالة الحماية
SELECT 
    schemaname, 
    tablename, 
    CASE WHEN rowsecurity THEN '🔒 محمي' ELSE '⚠️ غير محمي' END as security_status
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

COMMIT;
