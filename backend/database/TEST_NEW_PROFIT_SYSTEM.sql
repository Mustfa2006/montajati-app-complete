-- ===================================
-- 🧪 اختبار النظام الجديد للأرباح التلقائية
-- ===================================
--
-- هذا الملف يحتوي على اختبارات شاملة للنظام الجديد
--
-- ===================================

-- 1️⃣ التحقق من وجود الدوال والـ Triggers
SELECT '=== التحقق من وجود المكونات ===' as test_section;

SELECT 
    'get_profit_type' as component,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_profit_type') 
        THEN '✅ موجودة' 
        ELSE '❌ غير موجودة' 
    END as status
UNION ALL
SELECT 
    'auto_update_profits_on_status_change',
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'auto_update_profits_on_status_change') 
        THEN '✅ موجودة' 
        ELSE '❌ غير موجودة' 
    END
UNION ALL
SELECT 
    'trigger_auto_update_profits',
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_auto_update_profits') 
        THEN '✅ موجود' 
        ELSE '❌ غير موجود' 
    END
UNION ALL
SELECT 
    'validate_profit_operation',
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validate_profit_operation') 
        THEN '✅ موجودة' 
        ELSE '❌ غير موجودة' 
    END;

-- 2️⃣ اختبار دالة get_profit_type
SELECT '=== اختبار دالة get_profit_type ===' as test_section;

SELECT 
    status,
    get_profit_type(status) as profit_type,
    CASE 
        WHEN status = 'تم التسليم للزبون' AND get_profit_type(status) = 'achieved' THEN '✅'
        WHEN status IN ('نشط', 'قيد التوصيل الى الزبون (في عهدة المندوب)', 'مؤجل') 
             AND get_profit_type(status) = 'expected' THEN '✅'
        WHEN status IN ('الغاء الطلب', 'رفض الطلب', 'لا يرد') 
             AND get_profit_type(status) = 'none' THEN '✅'
        ELSE '❌'
    END as test_result
FROM (
    VALUES 
        ('تم التسليم للزبون'),
        ('نشط'),
        ('قيد التوصيل الى الزبون (في عهدة المندوب)'),
        ('مؤجل'),
        ('الغاء الطلب'),
        ('رفض الطلب'),
        ('لا يرد')
) AS statuses(status);

-- 3️⃣ عرض آخر 10 عمليات في سجل الأرباح
SELECT '=== آخر 10 عمليات في سجل الأرباح ===' as test_section;

SELECT 
    created_at,
    user_phone,
    operation_type,
    old_achieved_profits,
    new_achieved_profits,
    old_expected_profits,
    new_expected_profits,
    amount_changed,
    LEFT(reason, 50) as reason_preview,
    authorized_by,
    is_authorized
FROM profit_operations_log
ORDER BY created_at DESC
LIMIT 10;

-- 4️⃣ عرض إحصائيات الأرباح الحالية
SELECT '=== إحصائيات الأرباح الحالية ===' as test_section;

SELECT 
    COUNT(*) as total_users,
    SUM(achieved_profits) as total_achieved,
    SUM(expected_profits) as total_expected,
    AVG(achieved_profits) as avg_achieved,
    AVG(expected_profits) as avg_expected,
    MAX(achieved_profits) as max_achieved,
    MAX(expected_profits) as max_expected
FROM users
WHERE role = 'user';

-- 5️⃣ عرض المستخدمين مع أرباحهم
SELECT '=== عينة من المستخدمين وأرباحهم ===' as test_section;

SELECT 
    phone,
    name,
    achieved_profits,
    expected_profits,
    (achieved_profits + expected_profits) as total_profits
FROM users
WHERE role = 'user'
ORDER BY (achieved_profits + expected_profits) DESC
LIMIT 10;

-- 6️⃣ عرض الطلبات حسب الحالة
SELECT '=== إحصائيات الطلبات حسب الحالة ===' as test_section;

SELECT 
    status,
    get_profit_type(status) as profit_type,
    COUNT(*) as count,
    SUM(profit) as total_profit,
    AVG(profit) as avg_profit
FROM orders
GROUP BY status, get_profit_type(status)
ORDER BY count DESC;

-- 7️⃣ اختبار محاكاة (اختياري - لا يُنفذ تلقائياً)
-- قم بإزالة التعليق لتنفيذ الاختبار

/*
-- إنشاء مستخدم تجريبي
INSERT INTO users (phone, name, role, achieved_profits, expected_profits)
VALUES ('07700000000', 'مستخدم تجريبي', 'user', 0, 0)
ON CONFLICT (phone) DO UPDATE SET
    achieved_profits = 0,
    expected_profits = 0;

-- إنشاء طلب تجريبي
INSERT INTO orders (
    id,
    order_number,
    user_phone,
    customer_name,
    customer_phone,
    status,
    profit,
    created_at
) VALUES (
    'test_order_' || gen_random_uuid(),
    'TEST-001',
    '07700000000',
    'عميل تجريبي',
    '07711111111',
    'نشط',
    5000,
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- عرض الأرباح قبل التغيير
SELECT 
    '=== قبل التغيير ===' as stage,
    phone,
    achieved_profits,
    expected_profits
FROM users
WHERE phone = '07700000000';

-- تغيير حالة الطلب إلى "تم التسليم للزبون"
UPDATE orders
SET status = 'تم التسليم للزبون'
WHERE order_number = 'TEST-001';

-- عرض الأرباح بعد التغيير
SELECT 
    '=== بعد التغيير ===' as stage,
    phone,
    achieved_profits,
    expected_profits
FROM users
WHERE phone = '07700000000';

-- عرض السجل
SELECT 
    '=== السجل ===' as stage,
    operation_type,
    old_achieved_profits,
    new_achieved_profits,
    old_expected_profits,
    new_expected_profits,
    reason
FROM profit_operations_log
WHERE user_phone = '07700000000'
ORDER BY created_at DESC
LIMIT 1;

-- تنظيف البيانات التجريبية
DELETE FROM orders WHERE order_number = 'TEST-001';
DELETE FROM users WHERE phone = '07700000000';
*/

-- ===================================
-- ✅ انتهى الاختبار
-- ===================================

SELECT '=== ✅ انتهى الاختبار ===' as test_section;
SELECT 'إذا كانت جميع النتائج ✅، فالنظام يعمل بشكل صحيح!' as message;

