-- إصلاح قيم حالات الطلبات في قاعدة البيانات
-- Fix Order Status Values in Database

-- 1. عرض القيم الحالية لحالات الطلبات
SELECT DISTINCT status, COUNT(*) as count 
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- 2. تحديث القيم القديمة إلى القيم الجديدة المعيارية

-- تحديث الحالات العربية إلى الإنجليزية المعيارية
UPDATE orders SET status = 'confirmed' WHERE status = 'نشط';
UPDATE orders SET status = 'confirmed' WHERE status = 'active';
UPDATE orders SET status = 'confirmed' WHERE status = '1';
UPDATE orders SET status = 'confirmed' WHERE status = 'pending';

UPDATE orders SET status = 'processing' WHERE status = 'قيد التوصيل';
UPDATE orders SET status = 'processing' WHERE status = 'in_delivery';
UPDATE orders SET status = 'processing' WHERE status = 'shipping';
UPDATE orders SET status = 'processing' WHERE status = '2';

UPDATE orders SET status = 'shipped' WHERE status = 'تم التوصيل';
UPDATE orders SET status = 'shipped' WHERE status = 'delivered';
UPDATE orders SET status = 'shipped' WHERE status = 'completed';
UPDATE orders SET status = 'shipped' WHERE status = '3';

UPDATE orders SET status = 'confirmed' WHERE status = 'تم الإلغاء';
UPDATE orders SET status = 'confirmed' WHERE status = 'cancelled';
UPDATE orders SET status = 'confirmed' WHERE status = 'rejected';
UPDATE orders SET status = 'confirmed' WHERE status = '4';
UPDATE orders SET status = 'confirmed' WHERE status = '5';

-- تحديث أي قيم فارغة أو NULL إلى confirmed
UPDATE orders SET status = 'confirmed' WHERE status IS NULL OR status = '';

-- 3. التحقق من النتائج بعد التحديث
SELECT DISTINCT status, COUNT(*) as count 
FROM orders 
GROUP BY status 
ORDER BY count DESC;

-- 4. إضافة قيد للتأكد من أن القيم المستقبلية صحيحة (اختياري)
-- ALTER TABLE orders 
-- ADD CONSTRAINT check_status_values 
-- CHECK (status IN ('confirmed', 'processing', 'shipped'));

-- 5. عرض عينة من الطلبات المحدثة
SELECT id, customer_name, status, created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;
