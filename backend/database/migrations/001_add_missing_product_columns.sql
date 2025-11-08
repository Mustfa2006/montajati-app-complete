-- ✅ Migration: إضافة الأعمدة المفقودة في جدول المنتجات
-- Migration 001: Add missing product columns
-- تاريخ الإنشاء: 2024-12-20

-- إضافة العمود المفقود available_quantity إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' 
        AND column_name = 'available_quantity'
    ) THEN
        ALTER TABLE products ADD COLUMN available_quantity INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود available_quantity بنجاح';
    ELSE
        RAISE NOTICE 'عمود available_quantity موجود مسبقاً';
    END IF;
END $$;

-- إضافة عمود reserved_quantity إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' 
        AND column_name = 'reserved_quantity'
    ) THEN
        ALTER TABLE products ADD COLUMN reserved_quantity INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود reserved_quantity بنجاح';
    ELSE
        RAISE NOTICE 'عمود reserved_quantity موجود مسبقاً';
    END IF;
END $$;

-- إضافة عمود minimum_stock إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' 
        AND column_name = 'minimum_stock'
    ) THEN
        ALTER TABLE products ADD COLUMN minimum_stock INTEGER DEFAULT 5;
        RAISE NOTICE 'تم إضافة عمود minimum_stock بنجاح';
    ELSE
        RAISE NOTICE 'عمود minimum_stock موجود مسبقاً';
    END IF;
END $$;

-- تحديث البيانات الموجودة
UPDATE products 
SET available_quantity = stock_quantity 
WHERE available_quantity IS NULL OR available_quantity = 0;

-- إضافة فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_products_available_quantity ON products(available_quantity);
CREATE INDEX IF NOT EXISTS idx_products_minimum_stock ON products(minimum_stock);
CREATE INDEX IF NOT EXISTS idx_products_category_active ON products(category, is_active);

-- إضافة constraint للتأكد من أن الكميات لا تكون سالبة
ALTER TABLE products ADD CONSTRAINT chk_available_quantity_positive 
CHECK (available_quantity >= 0);

ALTER TABLE products ADD CONSTRAINT chk_reserved_quantity_positive 
CHECK (reserved_quantity >= 0);

ALTER TABLE products ADD CONSTRAINT chk_stock_quantity_positive 
CHECK (stock_quantity >= 0);

COMMIT;
