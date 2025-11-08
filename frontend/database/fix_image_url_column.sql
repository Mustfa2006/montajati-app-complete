-- إصلاح عمود image_url في جدول المنتجات
-- تاريخ: 2025-06-19

-- التحقق من وجود العمود وإضافته إذا لم يكن موجوداً
DO $$
BEGIN
    -- إضافة image_url إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'image_url'
    ) THEN
        ALTER TABLE products ADD COLUMN image_url TEXT;
        RAISE NOTICE 'تم إضافة العمود image_url';
    ELSE
        RAISE NOTICE 'العمود image_url موجود بالفعل';
    END IF;

    -- إضافة available_quantity إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'available_quantity'
    ) THEN
        ALTER TABLE products ADD COLUMN available_quantity INTEGER DEFAULT 100;
        RAISE NOTICE 'تم إضافة العمود available_quantity';
    ELSE
        RAISE NOTICE 'العمود available_quantity موجود بالفعل';
    END IF;

    -- إضافة wholesale_price إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'wholesale_price'
    ) THEN
        ALTER TABLE products ADD COLUMN wholesale_price DECIMAL(10,2);
        RAISE NOTICE 'تم إضافة العمود wholesale_price';
    ELSE
        RAISE NOTICE 'العمود wholesale_price موجود بالفعل';
    END IF;

    -- إضافة min_price إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'min_price'
    ) THEN
        ALTER TABLE products ADD COLUMN min_price DECIMAL(10,2);
        RAISE NOTICE 'تم إضافة العمود min_price';
    ELSE
        RAISE NOTICE 'العمود min_price موجود بالفعل';
    END IF;

    -- إضافة max_price إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'max_price'
    ) THEN
        ALTER TABLE products ADD COLUMN max_price DECIMAL(10,2);
        RAISE NOTICE 'تم إضافة العمود max_price';
    ELSE
        RAISE NOTICE 'العمود max_price موجود بالفعل';
    END IF;
END $$;

-- تحديث البيانات الموجودة
UPDATE products 
SET 
    available_quantity = COALESCE(available_quantity, 100),
    image_url = COALESCE(image_url, 'https://via.placeholder.com/300x300'),
    wholesale_price = COALESCE(wholesale_price, price * 0.8),
    min_price = COALESCE(min_price, price * 0.9),
    max_price = COALESCE(max_price, price * 1.2)
WHERE available_quantity IS NULL 
   OR image_url IS NULL 
   OR wholesale_price IS NULL
   OR min_price IS NULL
   OR max_price IS NULL;

-- عرض هيكل الجدول للتأكد
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- عرض عينة من البيانات
SELECT 
    id,
    name,
    image_url,
    wholesale_price,
    min_price,
    max_price,
    available_quantity,
    created_at
FROM products
ORDER BY created_at DESC
LIMIT 5;

COMMIT;
