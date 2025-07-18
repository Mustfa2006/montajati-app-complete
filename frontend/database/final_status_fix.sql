-- إصلاح نهائي لحالات الطلبات
-- Final Fix for Order Status Values

-- 1. عرض الحالة الحالية
SELECT 'Current Status Distribution' as info;
SELECT status, COUNT(*) as count 
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- 2. إصلاح جميع القيم إلى النظام الجديد
UPDATE orders SET status = 'confirmed' 
WHERE status IS NULL 
   OR status = '' 
   OR status = 'pending'
   OR status = 'active'
   OR status = 'نشط'
   OR status = '1'
   OR status = 'new'
   OR status = 'open';

UPDATE orders SET status = 'processing' 
WHERE status = 'in_delivery'
   OR status = 'قيد التوصيل'
   OR status = '2'
   OR status = 'shipping'
   OR status = 'in_transit';

UPDATE orders SET status = 'shipped' 
WHERE status = 'delivered'
   OR status = 'تم التوصيل'
   OR status = '3'
   OR status = 'completed'
   OR status = 'finished'
   OR status = 'done'
   OR status = 'closed';

-- 3. معالجة الحالات الملغية (تحويلها إلى confirmed لأن cancelled غير مدعوم)
UPDATE orders SET status = 'confirmed' 
WHERE status = 'cancelled'
   OR status = 'تم الإلغاء'
   OR status = '4'
   OR status = '5'
   OR status = 'rejected'
   OR status = 'cancel'
   OR status = 'reject'
   OR status = 'ملغي'
   OR status = 'مرفوض';

-- 4. التحقق من النتيجة النهائية
SELECT 'Final Status Distribution' as info;
SELECT status, COUNT(*) as count 
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- 5. التأكد من عدم وجود قيم غير صحيحة
SELECT 'Invalid Status Values' as info;
SELECT DISTINCT status 
FROM orders 
WHERE status NOT IN ('confirmed', 'processing', 'shipped');

-- 6. عرض عينة من الطلبات المحدثة
SELECT 'Sample Updated Orders' as info;
SELECT id, customer_name, status, created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;
