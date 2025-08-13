-- إصلاح عرض معلومات التاجر في لوحة التحكم
-- Fix merchant info display in dashboard

-- 1. إضافة حقل user_id للطلبات لربط الطلب بالتاجر الذي أنشأه
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id);

-- 2. إضافة حقول اسم ورقم هاتف التاجر مباشرة في جدول الطلبات (للأداء)
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS user_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS user_phone VARCHAR(20);

-- 3. إنشاء فهرس للأداء
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders (user_id);

-- 4. تحديث الـ view لعرض معلومات التاجر الصحيحة
CREATE OR REPLACE VIEW order_details_view AS
SELECT 
    o.id,
    o.order_number,
    o.customer_name,
    o.customer_phone,
    o.customer_alternate_phone,
    o.customer_province,
    o.customer_city,
    o.customer_address,
    o.customer_notes,
    o.status,
    o.total_amount,
    o.delivery_cost,
    o.profit_amount,
    o.created_at,
    o.updated_at,
    -- معلومات التاجر (المستخدم الذي أنشأ الطلب)
    COALESCE(o.user_name, u.name, 'غير محدد') as user_name,
    COALESCE(o.user_phone, u.phone, 'غير محدد') as user_phone,
    COUNT(oi.id) as items_count,
    COALESCE(SUM(oi.profit_per_item * oi.quantity), 0) as calculated_profit
FROM orders o
LEFT JOIN users u ON o.user_id = u.id  -- ربط صحيح بالتاجر
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.user_name, o.user_phone, u.name, u.phone
ORDER BY o.created_at DESC;

-- 5. تحديث البيانات الموجودة - تعيين تاجر افتراضي للطلبات الموجودة
-- (يمكن تخصيص هذا حسب الحاجة)
UPDATE orders 
SET 
    user_name = 'تاجر افتراضي',
    user_phone = '07700000000'
WHERE user_name IS NULL OR user_name = '';

-- 6. إنشاء دالة لتحديث معلومات التاجر تلقائياً عند إنشاء طلب جديد
CREATE OR REPLACE FUNCTION update_order_user_info()
RETURNS TRIGGER AS $$
BEGIN
    -- إذا تم تحديد user_id، جلب معلومات المستخدم
    IF NEW.user_id IS NOT NULL THEN
        SELECT name, phone 
        INTO NEW.user_name, NEW.user_phone
        FROM users 
        WHERE id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. إنشاء trigger لتحديث معلومات التاجر تلقائياً
DROP TRIGGER IF EXISTS trigger_update_order_user_info ON orders;
CREATE TRIGGER trigger_update_order_user_info
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_order_user_info();

-- 8. إنشاء دالة مساعدة لجلب معلومات التاجر
CREATE OR REPLACE FUNCTION get_merchant_info(order_id_param VARCHAR)
RETURNS TABLE(
    merchant_name VARCHAR,
    merchant_phone VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(o.user_name, u.name, 'غير محدد')::VARCHAR as merchant_name,
        COALESCE(o.user_phone, u.phone, 'غير محدد')::VARCHAR as merchant_phone
    FROM orders o
    LEFT JOIN users u ON o.user_id = u.id
    WHERE o.id = order_id_param;
END;
$$ LANGUAGE plpgsql;
