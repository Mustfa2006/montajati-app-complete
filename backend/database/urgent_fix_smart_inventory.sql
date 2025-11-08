-- ===================================
-- إصلاح عاجل للنظام الذكي للمخزون
-- Urgent Fix for Smart Inventory System
-- ===================================

-- 1. حذف الدوال والـ triggers القديمة
DROP TRIGGER IF EXISTS trigger_update_smart_inventory_range ON products;
DROP FUNCTION IF EXISTS update_smart_inventory_range();
DROP FUNCTION IF EXISTS calculate_smart_inventory_range(INTEGER);

-- 2. التأكد من وجود الأعمدة المطلوبة بالنوع الصحيح
ALTER TABLE products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS minimum_stock INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS available_from INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS available_to INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS maximum_stock INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS smart_range_enabled BOOLEAN DEFAULT true;

-- 3. تحديث البيانات الموجودة بدون استخدام دوال معقدة
UPDATE products 
SET 
    stock_quantity = COALESCE(available_quantity, 0),
    available_from = CASE 
        WHEN available_quantity <= 10 THEN GREATEST(0, available_quantity - 2)
        WHEN available_quantity <= 50 THEN GREATEST(0, available_quantity - (available_quantity * 10 / 100))
        WHEN available_quantity <= 100 THEN GREATEST(0, available_quantity - (available_quantity * 5 / 100))
        ELSE GREATEST(0, available_quantity - (available_quantity * 3 / 100))
    END,
    available_to = available_quantity,
    maximum_stock = available_quantity,
    minimum_stock = CASE 
        WHEN available_quantity <= 10 THEN GREATEST(0, available_quantity - 2)
        WHEN available_quantity <= 50 THEN GREATEST(0, available_quantity - (available_quantity * 10 / 100))
        WHEN available_quantity <= 100 THEN GREATEST(0, available_quantity - (available_quantity * 5 / 100))
        ELSE GREATEST(0, available_quantity - (available_quantity * 3 / 100))
    END,
    smart_range_enabled = true
WHERE available_quantity IS NOT NULL;

-- 4. إضافة فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_products_stock_quantity ON products(stock_quantity);
CREATE INDEX IF NOT EXISTS idx_products_minimum_stock ON products(minimum_stock);
CREATE INDEX IF NOT EXISTS idx_products_available_from ON products(available_from);
CREATE INDEX IF NOT EXISTS idx_products_available_to ON products(available_to);
CREATE INDEX IF NOT EXISTS idx_products_maximum_stock ON products(maximum_stock);

-- 5. التحقق من النتائج
SELECT 
    'تم إصلاح النظام الذكي بنجاح' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN available_quantity = 0 THEN 1 END) as out_of_stock,
    COUNT(CASE WHEN available_quantity > 0 THEN 1 END) as in_stock,
    AVG(available_quantity) as avg_available,
    AVG(minimum_stock) as avg_min_stock,
    AVG(maximum_stock) as avg_max_stock
FROM products 
WHERE is_active = true;

COMMIT;
