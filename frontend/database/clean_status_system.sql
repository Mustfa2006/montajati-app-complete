-- تنظيف نظام حالات الطلبات بالكامل
-- Clean Order Status System Completely

-- 1. عرض الحالة الحالية قبل التنظيف
SELECT 'Current Status Distribution (Before Cleanup)' as info;
SELECT status, COUNT(*) as count 
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- 2. تنظيف جميع القيم إلى النظام الجديد المبسط
-- النظام الجديد يدعم فقط: confirmed, processing, shipped

-- تحويل جميع الحالات "النشطة" إلى confirmed
UPDATE orders SET status = 'confirmed' 
WHERE status IS NULL 
   OR status = '' 
   OR status = 'pending'
   OR status = 'active'
   OR status = 'نشط'
   OR status = '1'
   OR status = 'new'
   OR status = 'open'
   OR status = 'cancelled'  -- تحويل الملغي إلى نشط
   OR status = 'تم الإلغاء'
   OR status = '4'
   OR status = '5'
   OR status = 'rejected'
   OR status = 'cancel'
   OR status = 'reject'
   OR status = 'ملغي'
   OR status = 'مرفوض';

-- تحويل جميع الحالات "قيد التوصيل" إلى processing
UPDATE orders SET status = 'processing' 
WHERE status = 'in_delivery'
   OR status = 'قيد التوصيل'
   OR status = '2'
   OR status = 'shipping'
   OR status = 'in_transit';

-- تحويل جميع الحالات "مكتملة" إلى shipped
UPDATE orders SET status = 'shipped' 
WHERE status = 'delivered'
   OR status = 'تم التوصيل'
   OR status = '3'
   OR status = 'completed'
   OR status = 'finished'
   OR status = 'done'
   OR status = 'closed';

-- 3. التحقق من النتيجة النهائية
SELECT 'Final Status Distribution (After Cleanup)' as info;
SELECT status, COUNT(*) as count 
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- 4. التأكد من عدم وجود قيم غير صحيحة
SELECT 'Invalid Status Values (Should be empty)' as info;
SELECT DISTINCT status 
FROM orders 
WHERE status NOT IN ('confirmed', 'processing', 'shipped');

-- 5. إحصائيات نهائية
SELECT 'Final Statistics' as info;
SELECT 
  'confirmed' as status_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as percentage
FROM orders 
WHERE status = 'confirmed'
UNION ALL
SELECT 
  'processing' as status_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as percentage
FROM orders 
WHERE status = 'processing'
UNION ALL
SELECT 
  'shipped' as status_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as percentage
FROM orders 
WHERE status = 'shipped';

-- 6. عرض عينة من الطلبات المحدثة
SELECT 'Sample Updated Orders' as info;
SELECT 
  id, 
  customer_name, 
  status, 
  total_amount,
  created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;
