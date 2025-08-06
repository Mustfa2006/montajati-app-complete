-- ===================================
-- إضافة حقل ترتيب العرض للمنتجات
-- Add Display Order Column for Products
-- ===================================

-- إضافة حقل display_order إلى جدول المنتجات
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 999;

-- إنشاء فهرس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_products_display_order 
ON products(display_order, created_at);

-- تحديث المنتجات الموجودة بترتيب افتراضي بناءً على تاريخ الإنشاء
-- استخدام CTE لتجنب خطأ window functions في UPDATE
WITH ranked_products AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY created_at DESC) as new_order
    FROM products
    WHERE display_order IS NULL OR display_order = 999
)
UPDATE products
SET display_order = ranked_products.new_order
FROM ranked_products
WHERE products.id = ranked_products.id;

-- إضافة تعليق على العمود
COMMENT ON COLUMN products.display_order IS 'ترتيب عرض المنتج في الصفحة الرئيسية (1 = أول منتج، 2 = ثاني منتج، إلخ)';

-- التحقق من النتيجة
SELECT 
    id,
    name,
    display_order,
    created_at
FROM products 
ORDER BY display_order ASC, created_at DESC
LIMIT 10;

-- إحصائيات سريعة
SELECT 
    COUNT(*) as total_products,
    MIN(display_order) as min_order,
    MAX(display_order) as max_order,
    COUNT(DISTINCT display_order) as unique_orders
FROM products 
WHERE is_active = true;
