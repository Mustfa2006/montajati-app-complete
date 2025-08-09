-- 🔧 إصلاح مشكلة المبلغ المرسل للوسيط
-- هذا السكريپت سيحذف بيانات الوسيط القديمة ليتم إعادة إنشاؤها بالمبلغ الصحيح

-- 1. عرض الطلبات التي لديها مشكلة في المبلغ
SELECT 
    id,
    customer_name,
    total as order_total,
    (waseet_data::jsonb->>'totalPrice')::numeric as waseet_price,
    total - (waseet_data::jsonb->>'totalPrice')::numeric as price_difference
FROM orders 
WHERE waseet_data IS NOT NULL 
AND (waseet_data::jsonb->>'totalPrice')::numeric != total
ORDER BY created_at DESC;

-- 2. حذف بيانات الوسيط للطلبات التي لديها مشكلة
UPDATE orders 
SET waseet_data = NULL,
    updated_at = NOW()
WHERE waseet_data IS NOT NULL 
AND (waseet_data::jsonb->>'totalPrice')::numeric != total;

-- 3. أو حذف جميع بيانات الوسيط لإعادة إنشائها (إذا كنت تريد إعادة تعيين كل شيء)
-- UPDATE orders 
-- SET waseet_data = NULL,
--     updated_at = NOW()
-- WHERE waseet_data IS NOT NULL;

-- 4. التحقق من النتائج
SELECT 
    COUNT(*) as total_orders,
    COUNT(waseet_data) as orders_with_waseet_data,
    COUNT(*) - COUNT(waseet_data) as orders_without_waseet_data
FROM orders;
