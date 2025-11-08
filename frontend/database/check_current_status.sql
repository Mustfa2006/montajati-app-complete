-- فحص الحالات الحالية في قاعدة البيانات
-- Check Current Status Values in Database

-- 1. عرض جميع الحالات الموجودة حالياً
SELECT DISTINCT status, COUNT(*) as count 
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- 2. عرض عينة من الطلبات مع حالاتها
SELECT id, customer_name, status, created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 20;

-- 3. البحث عن أي قيم فارغة أو NULL
SELECT COUNT(*) as null_count
FROM orders 
WHERE status IS NULL OR status = '';

-- 4. التحقق من وجود القيم المطلوبة
SELECT 
  SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) as confirmed_count,
  SUM(CASE WHEN status = 'processing' THEN 1 ELSE 0 END) as processing_count,
  SUM(CASE WHEN status = 'shipped' THEN 1 ELSE 0 END) as shipped_count,
  COUNT(*) as total_count
FROM orders;

-- 5. البحث عن أي قيم غير متوقعة
SELECT DISTINCT status 
FROM orders 
WHERE status NOT IN ('confirmed', 'processing', 'shipped');
