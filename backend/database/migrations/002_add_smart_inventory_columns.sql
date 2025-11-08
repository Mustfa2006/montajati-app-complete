-- ===================================
-- Migration: إضافة أعمدة النظام الذكي للمخزون
-- Smart Inventory System Migration
-- تاريخ الإنشاء: 2025-01-28
-- ===================================

-- إضافة عمود maximum_stock للحد الأقصى الذكي
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

-- إضافة عمود smart_range_enabled لتفعيل/إلغاء النظام الذكي
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

-- إضافة عمود last_range_calculation لتتبع آخر حساب للنطاق
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' 
        AND column_name = 'last_range_calculation'
    ) THEN
        ALTER TABLE products ADD COLUMN last_range_calculation TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'تم إضافة عمود last_range_calculation بنجاح';
    ELSE
        RAISE NOTICE 'عمود last_range_calculation موجود مسبقاً';
    END IF;
END $$;

-- تحديث البيانات الموجودة بالنطاق الذكي
UPDATE products 
SET 
    maximum_stock = CASE 
        WHEN stock_quantity <= 10 THEN stock_quantity
        WHEN stock_quantity <= 50 THEN stock_quantity
        WHEN stock_quantity <= 100 THEN stock_quantity
        ELSE stock_quantity
    END,
    minimum_stock = CASE 
        WHEN stock_quantity <= 10 THEN GREATEST(0, stock_quantity - 2)
        WHEN stock_quantity <= 50 THEN GREATEST(0, stock_quantity - ROUND(stock_quantity * 0.1))
        WHEN stock_quantity <= 100 THEN GREATEST(0, stock_quantity - ROUND(stock_quantity * 0.05))
        ELSE GREATEST(0, stock_quantity - ROUND(stock_quantity * 0.03))
    END,
    smart_range_enabled = true,
    last_range_calculation = NOW()
WHERE maximum_stock IS NULL OR maximum_stock = 0;

-- إضافة فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_products_maximum_stock ON products(maximum_stock);
CREATE INDEX IF NOT EXISTS idx_products_smart_range_enabled ON products(smart_range_enabled);
CREATE INDEX IF NOT EXISTS idx_products_stock_range ON products(minimum_stock, maximum_stock);

-- إضافة constraint للتأكد من أن maximum_stock أكبر من أو يساوي minimum_stock
ALTER TABLE products ADD CONSTRAINT chk_maximum_stock_positive 
CHECK (maximum_stock >= 0);

ALTER TABLE products ADD CONSTRAINT chk_stock_range_valid 
CHECK (maximum_stock >= minimum_stock);

-- إنشاء دالة لحساب النطاق الذكي تلقائياً
CREATE OR REPLACE FUNCTION calculate_smart_range(total_quantity INTEGER)
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

-- إنشاء trigger لتحديث النطاق الذكي تلقائياً عند تغيير stock_quantity
CREATE OR REPLACE FUNCTION update_smart_range()
RETURNS TRIGGER AS $$
DECLARE
    smart_range RECORD;
BEGIN
    -- حساب النطاق الذكي الجديد
    SELECT * INTO smart_range FROM calculate_smart_range(NEW.stock_quantity);
    
    -- تحديث النطاق إذا كان النظام الذكي مفعل
    IF NEW.smart_range_enabled = true THEN
        NEW.minimum_stock = smart_range.min_range;
        NEW.maximum_stock = smart_range.max_range;
        NEW.last_range_calculation = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger
DROP TRIGGER IF EXISTS trigger_update_smart_range ON products;
CREATE TRIGGER trigger_update_smart_range
    BEFORE UPDATE OF stock_quantity ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_smart_range();

-- إنشاء view لعرض حالة المخزون الذكي
CREATE OR REPLACE VIEW smart_inventory_status AS
SELECT 
    id,
    name,
    stock_quantity,
    available_quantity,
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
    last_range_calculation
FROM products
WHERE is_active = true;

COMMIT;
