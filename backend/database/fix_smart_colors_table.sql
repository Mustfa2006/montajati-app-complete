-- ===================================
-- 🔧 إصلاح جدول الألوان الذكية
-- Fix Smart Colors Table
-- ===================================

-- 1. حذف الجدول القديم smart_colors إذا كان موجوداً
DROP TABLE IF EXISTS smart_colors CASCADE;

-- 2. التأكد من وجود جدول product_colors الصحيح
-- (هذا الجدول موجود بالفعل في smart_colors_system.sql)

-- 3. التحقق من البيانات
SELECT 
    'product_colors' as table_name,
    COUNT(*) as total_colors,
    COUNT(DISTINCT product_id) as total_products
FROM product_colors;

-- 4. عرض عينة من البيانات
SELECT 
    id,
    product_id,
    color_arabic_name,
    color_code,
    total_quantity,
    available_quantity
FROM product_colors
LIMIT 10;

