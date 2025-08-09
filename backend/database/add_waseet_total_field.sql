-- 🎯 إضافة حقل waseet_total لحفظ المبلغ الكامل المرسل للوسيط
-- هذا الحقل منفصل عن total الذي يحفظ المبلغ المدفوع من العميل

-- إضافة الحقل الجديد
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS waseet_total DECIMAL(12,2);

-- تحديث الطلبات الموجودة: نسخ total إلى waseet_total
UPDATE orders 
SET waseet_total = total 
WHERE waseet_total IS NULL;

-- إضافة تعليق للحقل
COMMENT ON COLUMN orders.waseet_total IS 'المبلغ الكامل المرسل لشركة الوسيط (يشمل رسوم التوصيل الكاملة)';
COMMENT ON COLUMN orders.total IS 'المبلغ المدفوع من العميل (قد يكون مخفض)';

-- إنشاء فهرس للأداء
CREATE INDEX IF NOT EXISTS idx_orders_waseet_total ON orders (waseet_total);

-- عرض النتائج
SELECT 
    id,
    customer_name,
    total as customer_paid,
    waseet_total as waseet_amount,
    waseet_total - total as difference
FROM orders 
WHERE waseet_total IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
