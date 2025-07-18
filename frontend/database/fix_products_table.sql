-- إصلاح جدول المنتجات - إضافة العمود المفقود
-- تاريخ: 2025-06-19

-- التحقق من وجود العمود وإضافته إذا لم يكن موجوداً
DO $$
BEGIN
    -- إضافة available_quantity إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'available_quantity'
    ) THEN
        ALTER TABLE products ADD COLUMN available_quantity INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة العمود available_quantity';
    ELSE
        RAISE NOTICE 'العمود available_quantity موجود بالفعل';
    END IF;

    -- إضافة stock_quantity إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'stock_quantity'
    ) THEN
        ALTER TABLE products ADD COLUMN stock_quantity INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة العمود stock_quantity';
    ELSE
        RAISE NOTICE 'العمود stock_quantity موجود بالفعل';
    END IF;

    -- إضافة price إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'price'
    ) THEN
        ALTER TABLE products ADD COLUMN price DECIMAL(10,2);
        RAISE NOTICE 'تم إضافة العمود price';
    ELSE
        RAISE NOTICE 'العمود price موجود بالفعل';
    END IF;
END $$;

-- تحديث البيانات الموجودة
UPDATE products 
SET 
    available_quantity = COALESCE(available_quantity, 0),
    stock_quantity = COALESCE(stock_quantity, available_quantity, 0),
    price = COALESCE(price, wholesale_price)
WHERE available_quantity IS NULL 
   OR stock_quantity IS NULL 
   OR price IS NULL;

-- عرض هيكل الجدول للتأكد
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- عرض عدد المنتجات
SELECT COUNT(*) as total_products FROM products;

COMMIT;
