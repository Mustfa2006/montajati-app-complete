-- تحديث جدول الطلبات لإضافة الحقول المطلوبة

-- إضافة حقول معلومات العميل
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS customer_phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS customer_alternate_phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS customer_province VARCHAR(100),
ADD COLUMN IF NOT EXISTS customer_city VARCHAR(100),
ADD COLUMN IF NOT EXISTS customer_address TEXT,
ADD COLUMN IF NOT EXISTS customer_notes TEXT;

-- إضافة حقول الأسعار التفصيلية
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS delivery_cost DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS profit_amount DECIMAL(10,2) DEFAULT 0;

-- تحديث قيود حالة الطلب لتشمل الحالات الصحيحة
ALTER TABLE orders 
DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE orders 
ADD CONSTRAINT orders_status_check 
CHECK (status IN ('active', 'in_delivery', 'delivered', 'rejected', 'cancelled'));

-- إضافة حقول إضافية لعناصر الطلب
ALTER TABLE order_items 
ADD COLUMN IF NOT EXISTS wholesale_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS customer_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS min_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS max_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS profit_per_item DECIMAL(10,2);

-- إنشاء فهارس إضافية للأداء
CREATE INDEX IF NOT EXISTS idx_orders_customer_phone ON orders (customer_phone);
CREATE INDEX IF NOT EXISTS idx_orders_customer_name ON orders (customer_name);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders (created_at);

-- تحديث البيانات الموجودة لتتوافق مع الحالات الجديدة
UPDATE orders SET status = 'in_delivery' WHERE status = 'shipping';

-- إضافة بيانات تجريبية للاختبار
INSERT INTO orders (
    order_number, 
    customer_name, 
    customer_phone, 
    customer_alternate_phone,
    customer_province,
    customer_city,
    customer_address,
    customer_notes,
    status, 
    total_amount, 
    delivery_cost,
    profit_amount,
    created_at
) VALUES 
(
    'ORD-' || EXTRACT(EPOCH FROM NOW())::bigint || '-' || FLOOR(RANDOM() * 10000)::text,
    'أحمد محمد علي',
    '07501234567',
    '07709876543',
    'بغداد',
    'الكرادة',
    'شارع الكرادة الداخلية، بناية رقم 15، الطابق الثالث',
    'يرجى الاتصال قبل التوصيل',
    'active',
    125000,
    5000,
    15000,
    NOW() - INTERVAL '2 hours'
),
(
    'ORD-' || EXTRACT(EPOCH FROM NOW())::bigint || '-' || FLOOR(RANDOM() * 10000)::text,
    'فاطمة حسن محمود',
    '07701234567',
    '07801234567',
    'البصرة',
    'المعقل',
    'حي الجمهورية، شارع الأطباء، منزل رقم 42',
    'التوصيل بعد الساعة 4 عصراً',
    'in_delivery',
    89500,
    3000,
    12000,
    NOW() - INTERVAL '1 day'
),
(
    'ORD-' || EXTRACT(EPOCH FROM NOW())::bigint || '-' || FLOOR(RANDOM() * 10000)::text,
    'محمد عبد الله سالم',
    '07801234567',
    NULL,
    'أربيل',
    'عنكاوا',
    'منطقة عنكاوا، شارع الكنائس، بيت رقم 28',
    NULL,
    'delivered',
    67800,
    4000,
    8500,
    NOW() - INTERVAL '3 days'
),
(
    'ORD-' || EXTRACT(EPOCH FROM NOW())::bigint || '-' || FLOOR(RANDOM() * 10000)::text,
    'زينب علي حسين',
    '07901234567',
    '07501234567',
    'النجف',
    'الكوفة',
    'حي الأطباء، شارع المستشفى، منزل رقم 67',
    'يفضل التوصيل صباحاً',
    'active',
    156700,
    6000,
    22000,
    NOW() - INTERVAL '5 hours'
),
(
    'ORD-' || EXTRACT(EPOCH FROM NOW())::bigint || '-' || FLOOR(RANDOM() * 10000)::text,
    'عمر خالد إبراهيم',
    '07601234567',
    '07701234567',
    'كربلاء',
    'الحر',
    'حي الحر، شارع الإمام الحسين، بناية السلام، شقة 12',
    'الرجاء عدم الاتصال بعد الساعة 9 مساءً',
    'cancelled',
    45600,
    2500,
    0,
    NOW() - INTERVAL '1 week'
) ON CONFLICT (order_number) DO NOTHING;

-- إضافة عناصر الطلبات التجريبية
INSERT INTO order_items (
    order_id,
    product_name,
    product_price,
    wholesale_price,
    customer_price,
    min_price,
    max_price,
    quantity,
    total_price,
    profit_per_item
) 
SELECT 
    o.id,
    'هاتف ذكي سامسونج',
    450000,
    400000,
    450000,
    420000,
    480000,
    1,
    450000,
    50000
FROM orders o 
WHERE o.customer_name = 'أحمد محمد علي'
UNION ALL
SELECT 
    o.id,
    'سماعات بلوتوث',
    85000,
    70000,
    85000,
    75000,
    95000,
    2,
    170000,
    30000
FROM orders o 
WHERE o.customer_name = 'فاطمة حسن محمود'
UNION ALL
SELECT 
    o.id,
    'ساعة ذكية',
    220000,
    180000,
    220000,
    200000,
    250000,
    1,
    220000,
    40000
FROM orders o 
WHERE o.customer_name = 'محمد عبد الله سالم'
ON CONFLICT DO NOTHING;

-- إنشاء view لعرض تفاصيل الطلبات الكاملة
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
    u.name as user_name,
    u.phone as user_phone,
    COUNT(oi.id) as items_count,
    COALESCE(SUM(oi.profit_per_item * oi.quantity), 0) as calculated_profit
FROM orders o
LEFT JOIN users u ON o.user_phone = u.phone
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, u.name, u.phone
ORDER BY o.created_at DESC;

-- إنشاء دالة لحساب الإحصائيات
CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS TABLE(
    total_orders INTEGER,
    active_orders INTEGER,
    delivered_orders INTEGER,
    cancelled_orders INTEGER,
    shipping_orders INTEGER,
    total_users INTEGER,
    total_profits DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM orders),
        (SELECT COUNT(*)::INTEGER FROM orders WHERE status = 'active'),
        (SELECT COUNT(*)::INTEGER FROM orders WHERE status = 'delivered'),
        (SELECT COUNT(*)::INTEGER FROM orders WHERE status = 'cancelled'),
        (SELECT COUNT(*)::INTEGER FROM orders WHERE status = 'in_delivery'),
        (SELECT COUNT(*)::INTEGER FROM users WHERE role = 'user'),
        (SELECT COALESCE(SUM(profit_amount), 0) FROM orders WHERE status = 'delivered');
END;
$$ LANGUAGE plpgsql;
