-- تشغيل هذا الكود في Supabase SQL Editor
-- لإصلاح مشكلة قاعدة البيانات

-- 1. إضافة العمود المفقود (تجاهل الخطأ إذا كان موجوداً)
ALTER TABLE products ADD COLUMN available_quantity INTEGER DEFAULT 100;

-- 2. تحديث البيانات الموجودة
UPDATE products
SET available_quantity = 100
WHERE available_quantity IS NULL OR available_quantity = 0;

-- 3. التحقق من النتيجة
SELECT
    id,
    name,
    available_quantity,
    created_at
FROM products
ORDER BY created_at DESC;
