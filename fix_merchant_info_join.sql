-- إصلاح عرض معلومات التاجر في لوحة التحكم
-- تصحيح الـ JOIN لربط الطلب بالتاجر عبر user_phone

-- تحديث الـ view لعرض معلومات التاجر الصحيحة
CREATE OR REPLACE VIEW order_details_view AS
SELECT 
    o.id,
    o.order_number,
    o.customer_name,
    o.customer_phone,
    o.customer_alternate_phone,
    o.customer_province,
    o.customer_city,
    o.customer_address,
    o.customer_notes,
    o.status,
    o.total_amount,
    o.delivery_cost,
    o.profit_amount,
    o.created_at,
    o.updated_at,
    u.name as user_name,
    u.phone as user_phone,
    COUNT(oi.id) as items_count,
    COALESCE(SUM(oi.profit_per_item * oi.quantity), 0) as calculated_profit
FROM orders o
LEFT JOIN users u ON o.user_phone = u.phone  -- ✅ ربط صحيح بالتاجر عبر user_phone
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, u.name, u.phone
ORDER BY o.created_at DESC;
