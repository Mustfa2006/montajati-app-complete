-- ===================================
-- إصلاح سريع للنظام الذكي
-- Quick Fix for Smart Inventory System
-- ===================================

-- إضافة الأعمدة المطلوبة
ALTER TABLE products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS minimum_stock INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS available_from INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS available_to INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS maximum_stock INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS smart_range_enabled BOOLEAN DEFAULT true;

-- تحديث البيانات الموجودة
UPDATE products 
SET stock_quantity = COALESCE(available_quantity, 0)
WHERE stock_quantity IS NULL OR stock_quantity = 0;

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
WHERE available_quantity IS NOT NULL;

-- إضافة فهارس
CREATE INDEX IF NOT EXISTS idx_products_stock_quantity ON products(stock_quantity);
CREATE INDEX IF NOT EXISTS idx_products_minimum_stock ON products(minimum_stock);
CREATE INDEX IF NOT EXISTS idx_products_available_from ON products(available_from);
CREATE INDEX IF NOT EXISTS idx_products_available_to ON products(available_to);
CREATE INDEX IF NOT EXISTS idx_products_maximum_stock ON products(maximum_stock);

-- التحقق من النتائج
SELECT 
    'تم إضافة الأعمدة بنجاح' as status,
    COUNT(*) as total_products,
    AVG(available_quantity) as avg_available,
    AVG(minimum_stock) as avg_min_stock,
    AVG(maximum_stock) as avg_max_stock
FROM products
WHERE is_active = true;
