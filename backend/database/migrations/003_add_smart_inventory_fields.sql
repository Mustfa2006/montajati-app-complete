-- ===================================
-- Migration: إضافة حقول النظام الذكي للمخزون
-- Smart Inventory System Fields Migration
-- تاريخ الإنشاء: 2025-01-28
-- ===================================

-- إضافة عمود available_from إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' 
        AND column_name = 'available_from'
    ) THEN
        ALTER TABLE products ADD COLUMN available_from INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود available_from بنجاح';
    ELSE
        RAISE NOTICE 'عمود available_from موجود مسبقاً';
    END IF;
END $$;

-- إضافة عمود available_to إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' 
        AND column_name = 'available_to'
    ) THEN
        ALTER TABLE products ADD COLUMN available_to INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود available_to بنجاح';
    ELSE
        RAISE NOTICE 'عمود available_to موجود مسبقاً';
    END IF;
END $$;

-- إضافة عمود maximum_stock إذا لم يكن موجوداً
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' 
        AND column_name = 'maximum_stock'
    ) THEN
        ALTER TABLE products ADD COLUMN maximum_stock INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود maximum_stock بنجاح';
    ELSE
        RAISE NOTICE 'عمود maximum_stock موجود مسبقاً';
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
        ALTER TABLE products ADD COLUMN minimum_stock INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود minimum_stock بنجاح';
    ELSE
        RAISE NOTICE 'عمود minimum_stock موجود مسبقاً';
    END IF;
END $$;

-- إضافة عمود stock_quantity إذا لم يكن موجوداً
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'stock_quantity'
    ) THEN
        ALTER TABLE products ADD COLUMN stock_quantity INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود stock_quantity بنجاح';
    ELSE
        RAISE NOTICE 'عمود stock_quantity موجود مسبقاً';
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
        ALTER TABLE products ADD COLUMN minimum_stock INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود minimum_stock بنجاح';
    ELSE
        RAISE NOTICE 'عمود minimum_stock موجود مسبقاً';
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
        ALTER TABLE products ADD COLUMN minimum_stock INTEGER DEFAULT 0;
        RAISE NOTICE 'تم إضافة عمود minimum_stock بنجاح';
    ELSE
        RAISE NOTICE 'عمود minimum_stock موجود مسبقاً';
    END IF;
END $$;

-- إضافة عمود smart_range_enabled إذا لم يكن موجوداً
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'smart_range_enabled'
    ) THEN
        ALTER TABLE products ADD COLUMN smart_range_enabled BOOLEAN DEFAULT true;
        RAISE NOTICE 'تم إضافة عمود smart_range_enabled بنجاح';
    ELSE
        RAISE NOTICE 'عمود smart_range_enabled موجود مسبقاً';
    END IF;
END $$;

-- تحديث stock_quantity ليساوي available_quantity إذا كان فارغاً
UPDATE products
SET stock_quantity = COALESCE(available_quantity, 0)
WHERE stock_quantity IS NULL OR stock_quantity = 0;

-- تحديث البيانات الموجودة بالنطاق الذكي
UPDATE products
SET
    available_from = CASE
        WHEN available_quantity <= 10 THEN GREATEST(0, available_quantity - 2)
        WHEN available_quantity <= 50 THEN GREATEST(0, available_quantity - ROUND(available_quantity * 0.1))
        WHEN available_quantity <= 100 THEN GREATEST(0, available_quantity - ROUND(available_quantity * 0.05))
        ELSE GREATEST(0, available_quantity - ROUND(available_quantity * 0.03))
    END,
    available_to = available_quantity,
    maximum_stock = available_quantity,
    minimum_stock = CASE
        WHEN available_quantity <= 10 THEN GREATEST(0, available_quantity - 2)
        WHEN available_quantity <= 50 THEN GREATEST(0, available_quantity - ROUND(available_quantity * 0.1))
        WHEN available_quantity <= 100 THEN GREATEST(0, available_quantity - ROUND(available_quantity * 0.05))
        ELSE GREATEST(0, available_quantity - ROUND(available_quantity * 0.03))
    END,
    smart_range_enabled = true
WHERE (available_from IS NULL OR available_from = 0)
   OR (available_to IS NULL OR available_to = 0)
   OR (maximum_stock IS NULL OR maximum_stock = 0)
   OR (minimum_stock IS NULL OR minimum_stock = 0);

-- إضافة فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_products_stock_quantity ON products(stock_quantity);
CREATE INDEX IF NOT EXISTS idx_products_available_from ON products(available_from);
CREATE INDEX IF NOT EXISTS idx_products_available_to ON products(available_to);
CREATE INDEX IF NOT EXISTS idx_products_minimum_stock ON products(minimum_stock);
CREATE INDEX IF NOT EXISTS idx_products_maximum_stock ON products(maximum_stock);
CREATE INDEX IF NOT EXISTS idx_products_smart_range_enabled ON products(smart_range_enabled);

-- إضافة constraints للتأكد من صحة البيانات
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'chk_stock_quantity_positive'
    ) THEN
        ALTER TABLE products ADD CONSTRAINT chk_stock_quantity_positive
        CHECK (stock_quantity >= 0);
        RAISE NOTICE 'تم إضافة constraint chk_stock_quantity_positive';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'chk_minimum_stock_positive'
    ) THEN
        ALTER TABLE products ADD CONSTRAINT chk_minimum_stock_positive
        CHECK (minimum_stock >= 0);
        RAISE NOTICE 'تم إضافة constraint chk_minimum_stock_positive';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'chk_available_from_positive'
    ) THEN
        ALTER TABLE products ADD CONSTRAINT chk_available_from_positive
        CHECK (available_from >= 0);
        RAISE NOTICE 'تم إضافة constraint chk_available_from_positive';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'chk_available_to_positive'
    ) THEN
        ALTER TABLE products ADD CONSTRAINT chk_available_to_positive
        CHECK (available_to >= 0);
        RAISE NOTICE 'تم إضافة constraint chk_available_to_positive';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'chk_maximum_stock_positive'
    ) THEN
        ALTER TABLE products ADD CONSTRAINT chk_maximum_stock_positive
        CHECK (maximum_stock >= 0);
        RAISE NOTICE 'تم إضافة constraint chk_maximum_stock_positive';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'chk_available_range_valid'
    ) THEN
        ALTER TABLE products ADD CONSTRAINT chk_available_range_valid
        CHECK (available_to >= available_from);
        RAISE NOTICE 'تم إضافة constraint chk_available_range_valid';
    END IF;
END $$;

-- إنشاء دالة لحساب النطاق الذكي
CREATE OR REPLACE FUNCTION calculate_smart_inventory_range(total_quantity INTEGER)
RETURNS TABLE(min_range INTEGER, max_range INTEGER) AS $$
BEGIN
    IF total_quantity <= 0 THEN
        RETURN QUERY SELECT 0, 0;
    ELSIF total_quantity <= 10 THEN
        RETURN QUERY SELECT GREATEST(0, total_quantity - 2), total_quantity;
    ELSIF total_quantity <= 50 THEN
        RETURN QUERY SELECT GREATEST(0, total_quantity - ROUND(total_quantity * 0.1)), total_quantity;
    ELSIF total_quantity <= 100 THEN
        RETURN QUERY SELECT GREATEST(0, total_quantity - ROUND(total_quantity * 0.05)), total_quantity;
    ELSE
        RETURN QUERY SELECT GREATEST(0, total_quantity - ROUND(total_quantity * 0.03)), total_quantity;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger لتحديث النطاق الذكي تلقائياً
CREATE OR REPLACE FUNCTION update_smart_inventory_range()
RETURNS TRIGGER AS $$
DECLARE
    smart_range RECORD;
BEGIN
    -- حساب النطاق الذكي الجديد عند تغيير available_quantity
    IF NEW.available_quantity != OLD.available_quantity AND NEW.smart_range_enabled = true THEN
        SELECT * INTO smart_range FROM calculate_smart_inventory_range(NEW.available_quantity);
        
        NEW.available_from = smart_range.min_range;
        NEW.available_to = smart_range.max_range;
        NEW.minimum_stock = smart_range.min_range;
        NEW.maximum_stock = smart_range.max_range;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger
DROP TRIGGER IF EXISTS trigger_update_smart_inventory_range ON products;
CREATE TRIGGER trigger_update_smart_inventory_range
    BEFORE UPDATE OF available_quantity ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_smart_inventory_range();

-- إنشاء view محدث لعرض حالة المخزون الذكي
CREATE OR REPLACE VIEW smart_inventory_dashboard AS
SELECT 
    id,
    name,
    stock_quantity,
    available_quantity,
    available_from,
    available_to,
    minimum_stock,
    maximum_stock,
    smart_range_enabled,
    CASE 
        WHEN available_quantity = 0 THEN 'نفد المخزون'
        WHEN available_quantity <= minimum_stock THEN 'مخزون منخفض'
        WHEN available_quantity >= maximum_stock * 0.8 THEN 'مخزون جيد'
        ELSE 'مخزون متوسط'
    END as stock_status,
    ROUND((available_quantity::DECIMAL / NULLIF(maximum_stock, 0)) * 100, 2) as stock_percentage,
    (available_to - available_from) as range_width,
    created_at,
    updated_at
FROM products
WHERE is_active = true
ORDER BY 
    CASE 
        WHEN available_quantity = 0 THEN 1
        WHEN available_quantity <= minimum_stock THEN 2
        ELSE 3
    END,
    available_quantity ASC;

-- إنشاء دالة لإحصائيات المخزون الذكي
CREATE OR REPLACE FUNCTION get_smart_inventory_stats()
RETURNS TABLE(
    total_products INTEGER,
    out_of_stock INTEGER,
    low_stock INTEGER,
    normal_stock INTEGER,
    good_stock INTEGER,
    total_stock_value BIGINT,
    avg_stock_percentage DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_products,
        COUNT(CASE WHEN available_quantity = 0 THEN 1 END)::INTEGER as out_of_stock,
        COUNT(CASE WHEN available_quantity > 0 AND available_quantity <= minimum_stock THEN 1 END)::INTEGER as low_stock,
        COUNT(CASE WHEN available_quantity > minimum_stock AND available_quantity < maximum_stock * 0.8 THEN 1 END)::INTEGER as normal_stock,
        COUNT(CASE WHEN available_quantity >= maximum_stock * 0.8 THEN 1 END)::INTEGER as good_stock,
        SUM(available_quantity)::BIGINT as total_stock_value,
        AVG(CASE WHEN maximum_stock > 0 THEN (available_quantity::DECIMAL / maximum_stock) * 100 ELSE 0 END) as avg_stock_percentage
    FROM products
    WHERE is_active = true;
END;
$$ LANGUAGE plpgsql;

COMMIT;
