-- تحديث قاعدة البيانات لإضافة العمود المفقود وتحديث حالات الطلبات

-- إضافة الأعمدة المفقودة إلى جدول products
DO $$
BEGIN
    -- إضافة wholesale_price
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'wholesale_price'
    ) THEN
        ALTER TABLE products ADD COLUMN wholesale_price DECIMAL(10,2);
    END IF;

    -- إضافة min_price
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'min_price'
    ) THEN
        ALTER TABLE products ADD COLUMN min_price DECIMAL(10,2);
    END IF;

    -- إضافة max_price
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'max_price'
    ) THEN
        ALTER TABLE products ADD COLUMN max_price DECIMAL(10,2);
    END IF;

    -- إضافة image_url
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'image_url'
    ) THEN
        ALTER TABLE products ADD COLUMN image_url TEXT;
    END IF;

    -- إضافة available_quantity
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'available_quantity'
    ) THEN
        ALTER TABLE products ADD COLUMN available_quantity INTEGER DEFAULT 0;
    END IF;
END $$;

-- تحديث قيود حالات الطلبات
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE orders ADD CONSTRAINT orders_status_check 
CHECK (status IN ('active', 'shipping', 'delivered', 'rejected', 'cancelled'));

-- تحديث الطلبات الموجودة لتتوافق مع الحالات الجديدة
UPDATE orders SET status = 'active' WHERE status = 'pending';
UPDATE orders SET status = 'active' WHERE status = 'confirmed';
UPDATE orders SET status = 'active' WHERE status = 'processing';
UPDATE orders SET status = 'shipping' WHERE status = 'shipped';
UPDATE orders SET status = 'cancelled' WHERE status = 'cancelled';

-- إضافة بيانات تجريبية للمنتجات
INSERT INTO products (
    name,
    description,
    price,
    wholesale_price,
    min_price,
    max_price,
    cost_price,
    category,
    stock_quantity,
    available_quantity,
    image_url,
    is_active
) VALUES
(
    'هاتف ذكي سامسونج',
    'هاتف ذكي بمواصفات عالية',
    800.00,
    700.00,
    750.00,
    850.00,
    600.00,
    'إلكترونيات',
    50,
    50,
    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400',
    true
),
(
    'لابتوب ديل',
    'لابتوب للأعمال والدراسة',
    1200.00,
    1000.00,
    1100.00,
    1300.00,
    900.00,
    'إلكترونيات',
    25,
    25,
    'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
    true
),
(
    'قميص قطني',
    'قميص رجالي قطني عالي الجودة',
    45.00,
    35.00,
    40.00,
    50.00,
    25.00,
    'ملابس',
    100,
    100,
    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
    true
),
(
    'مقلاة تيفال',
    'مقلاة غير لاصقة حجم متوسط',
    85.00,
    70.00,
    75.00,
    90.00,
    50.00,
    'منزل ومطبخ',
    75,
    75,
    'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400',
    true
),
(
    'كتاب البرمجة',
    'كتاب تعليم البرمجة للمبتدئين',
    25.00,
    20.00,
    22.00,
    28.00,
    15.00,
    'كتب',
    200,
    200,
    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400',
    true
);

-- إضافة بيانات تجريبية للطلبات
INSERT INTO orders (
    order_number,
    status,
    total_amount,
    shipping_cost,
    payment_status,
    payment_method,
    notes
) VALUES 
(
    'ORD-001',
    'active',
    850.00,
    50.00,
    'paid',
    'cash',
    'طلب تجريبي نشط'
),
(
    'ORD-002',
    'shipping',
    1250.00,
    50.00,
    'paid',
    'card',
    'طلب تجريبي قيد التوصيل'
),
(
    'ORD-003',
    'delivered',
    130.00,
    50.00,
    'paid',
    'cash',
    'طلب تجريبي تم توصيله'
),
(
    'ORD-004',
    'rejected',
    45.00,
    50.00,
    'failed',
    'card',
    'طلب تجريبي مرفوض'
),
(
    'ORD-005',
    'cancelled',
    25.00,
    50.00,
    'refunded',
    'cash',
    'طلب تجريبي ملغي'
)
ON CONFLICT (order_number) DO NOTHING;

COMMIT;
