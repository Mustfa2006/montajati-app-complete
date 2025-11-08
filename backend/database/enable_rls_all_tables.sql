-- ===================================
-- تفعيل Row Level Security لجميع الجداول
-- Enable RLS for All Tables
-- ===================================

-- تفعيل RLS لجميع الجداول
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

-- إنشاء سياسات أساسية للوصول العام للجداول المرجعية
-- Categories
CREATE POLICY "public_read_categories" ON categories FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_categories" ON categories FOR ALL TO authenticated USING (true);

-- Cities
CREATE POLICY "public_read_cities" ON cities FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_cities" ON cities FOR ALL TO authenticated USING (true);

-- Provinces
CREATE POLICY "public_read_provinces" ON provinces FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_provinces" ON provinces FOR ALL TO authenticated USING (true);

-- Delivery Providers
CREATE POLICY "public_read_delivery_providers" ON delivery_providers FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_delivery_providers" ON delivery_providers FOR ALL TO authenticated USING (true);

-- Waseet Cities
CREATE POLICY "public_read_waseet_cities" ON waseet_cities FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_waseet_cities" ON waseet_cities FOR ALL TO authenticated USING (true);

-- Waseet Provinces
CREATE POLICY "public_read_waseet_provinces" ON waseet_provinces FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_waseet_provinces" ON waseet_provinces FOR ALL TO authenticated USING (true);

-- Waseet Regions
CREATE POLICY "public_read_waseet_regions" ON waseet_regions FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_waseet_regions" ON waseet_regions FOR ALL TO authenticated USING (true);

-- Waseet Statuses
CREATE POLICY "public_read_waseet_statuses" ON waseet_statuses FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_waseet_statuses" ON waseet_statuses FOR ALL TO authenticated USING (true);

-- Products
DROP POLICY IF EXISTS "allow_all_products" ON products;
CREATE POLICY "public_read_products" ON products FOR SELECT TO public USING (true);
CREATE POLICY "authenticated_manage_products" ON products FOR ALL TO authenticated USING (true);

-- Users - حماية خاصة
CREATE POLICY "users_read_own_profile" ON users FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "users_update_own_profile" ON users FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "service_role_manage_users" ON users FOR ALL TO service_role USING (true);

-- Orders - حماية بناءً على المستخدم
DROP POLICY IF EXISTS "Admins can manage all orders" ON orders;
DROP POLICY IF EXISTS "Users can create their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;

CREATE POLICY "users_read_own_orders" ON orders FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "users_create_orders" ON orders FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "users_update_own_orders" ON orders FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "service_role_manage_orders" ON orders FOR ALL TO service_role USING (true);

-- Order Items
CREATE POLICY "users_read_own_order_items" ON order_items 
FOR SELECT TO authenticated 
USING (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));

CREATE POLICY "users_manage_own_order_items" ON order_items 
FOR ALL TO authenticated 
USING (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));

CREATE POLICY "service_role_manage_order_items" ON order_items FOR ALL TO service_role USING (true);

-- Notifications
CREATE POLICY "users_read_own_notifications" ON notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "service_role_manage_notifications" ON notifications FOR ALL TO service_role USING (true);

-- FCM Tokens
CREATE POLICY "users_manage_own_tokens" ON fcm_tokens FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "service_role_manage_tokens" ON fcm_tokens FOR ALL TO service_role USING (true);

-- Withdrawal Requests
CREATE POLICY "users_manage_own_withdrawals" ON withdrawal_requests FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "service_role_manage_withdrawals" ON withdrawal_requests FOR ALL TO service_role USING (true);

-- Profit Transactions - للخدمة فقط
CREATE POLICY "service_role_only_profit_transactions" ON profit_transactions FOR ALL TO service_role USING (true);

-- Profit Operations Log - للخدمة فقط
CREATE POLICY "service_role_only_profit_operations" ON profit_operations_log FOR ALL TO service_role USING (true);

-- System Logs - للخدمة فقط
CREATE POLICY "service_role_only_system_logs" ON system_logs FOR ALL TO service_role USING (true);

-- Notification Logs - للخدمة فقط
CREATE POLICY "service_role_only_notification_logs" ON notification_logs FOR ALL TO service_role USING (true);

-- Notification Queue - للخدمة فقط
CREATE POLICY "service_role_only_notification_queue" ON notification_queue FOR ALL TO service_role USING (true);

-- عرض حالة RLS لجميع الجداول
SELECT 
    schemaname, 
    tablename, 
    CASE WHEN rowsecurity THEN '🔒 محمي' ELSE '⚠️ غير محمي' END as security_status
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
