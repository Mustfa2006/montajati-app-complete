-- ===================================
-- تشغيل Migration للنظام الذكي
-- Run Smart Inventory Migration
-- ===================================

-- تشغيل migration النظام الذكي
\i migrations/003_add_smart_inventory_fields.sql

-- التحقق من النتائج
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'products'
    AND column_name IN ('available_from', 'available_to', 'maximum_stock', 'smart_range_enabled')
ORDER BY column_name;

-- عرض عينة من البيانات المحدثة
SELECT 
    id,
    name,
    available_quantity,
    available_from,
    available_to,
    minimum_stock,
    maximum_stock,
    smart_range_enabled
FROM products
WHERE is_active = true
LIMIT 5;

-- عرض إحصائيات النظام الذكي
SELECT * FROM get_smart_inventory_stats();

-- عرض حالة المخزون الذكي
SELECT * FROM smart_inventory_dashboard LIMIT 10;
