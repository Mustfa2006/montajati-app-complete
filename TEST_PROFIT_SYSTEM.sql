-- 🧪 اختبار شامل لنظام الأرباح المحسّن
-- هذا السكريبت يختبر جميع السيناريوهات

-- ============================================
-- 1️⃣ إعداد البيانات الاختبارية
-- ============================================

-- اختر مستخدم اختبار (أو أنشئ واحد)
-- SELECT * FROM users LIMIT 1;

-- ============================================
-- 2️⃣ اختبار السيناريو 1: طلب جديد عادي
-- ============================================

-- قبل الاختبار: سجل الأرباح الحالية
SELECT 'قبل إضافة طلب جديد عادي' as test_name;
SELECT phone, expected_profits, achieved_profits 
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- أضف طلب جديد عادي
INSERT INTO orders (
    id, user_id, user_phone, customer_name, customer_phone,
    status, profit_amount, profit, created_at
) VALUES (
    'test_order_' || NOW()::text,
    (SELECT id FROM users WHERE phone = '07888888888' LIMIT 1),
    '07888888888',
    'عميل اختبار',
    '07777777777',
    'active',
    10000,
    10000,
    NOW()
);

-- بعد الاختبار: تحقق من الأرباح
SELECT 'بعد إضافة طلب جديد عادي' as test_name;
SELECT phone, expected_profits, achieved_profits 
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- ============================================
-- 3️⃣ اختبار السيناريو 2: تغيير من عادي إلى مسلم
-- ============================================

-- قبل الاختبار: سجل الأرباح الحالية
SELECT 'قبل تغيير الحالة إلى مسلم' as test_name;
SELECT phone, expected_profits, achieved_profits 
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- غير الحالة إلى مسلم
UPDATE orders 
SET status = 'تم التسليم للزبون'
WHERE id LIKE 'test_order_%'
AND user_phone = '07888888888'
LIMIT 1;

-- بعد الاختبار: تحقق من الأرباح
SELECT 'بعد تغيير الحالة إلى مسلم' as test_name;
SELECT phone, expected_profits, achieved_profits 
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- ============================================
-- 4️⃣ اختبار السيناريو 3: إرجاع من مسلم إلى عادي
-- ============================================

-- قبل الاختبار: سجل الأرباح الحالية
SELECT 'قبل إرجاع الحالة من مسلم إلى عادي' as test_name;
SELECT phone, expected_profits, achieved_profits 
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- أرجع الحالة إلى عادي
UPDATE orders 
SET status = 'active'
WHERE id LIKE 'test_order_%'
AND user_phone = '07888888888'
LIMIT 1;

-- بعد الاختبار: تحقق من الأرباح
SELECT 'بعد إرجاع الحالة من مسلم إلى عادي' as test_name;
SELECT phone, expected_profits, achieved_profits 
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- ============================================
-- 5️⃣ اختبار السيناريو 4: إلغاء طلب
-- ============================================

-- قبل الاختبار: سجل الأرباح الحالية
SELECT 'قبل إلغاء الطلب' as test_name;
SELECT phone, expected_profits, achieved_profits 
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- ألغِ الطلب
UPDATE orders 
SET status = 'الغاء الطلب'
WHERE id LIKE 'test_order_%'
AND user_phone = '07888888888'
LIMIT 1;

-- بعد الاختبار: تحقق من الأرباح
SELECT 'بعد إلغاء الطلب' as test_name;
SELECT phone, expected_profits, achieved_profits 
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- ============================================
-- 6️⃣ عرض سجل المعاملات
-- ============================================

SELECT 'سجل المعاملات' as info;
SELECT 
    order_id,
    transaction_type,
    amount,
    old_status,
    new_status,
    notes,
    created_at
FROM profit_transactions
WHERE order_id LIKE 'test_order_%'
ORDER BY created_at DESC;

-- ============================================
-- 7️⃣ التحقق من صحة النظام
-- ============================================

SELECT 'التحقق من صحة النظام' as info;
SELECT 
    phone,
    expected_profits,
    achieved_profits,
    expected_profits + achieved_profits as total_profits,
    CASE 
        WHEN expected_profits < 0 OR achieved_profits < 0 THEN '❌ خطأ: قيمة سالبة'
        WHEN (expected_profits + achieved_profits) > 10000000 THEN '⚠️ تحذير: مرتفع جداً'
        ELSE '✅ صحيح'
    END as status
FROM users 
WHERE phone = '07888888888'
LIMIT 1;

-- ============================================
-- 8️⃣ تنظيف البيانات الاختبارية (اختياري)
-- ============================================

-- DELETE FROM orders WHERE id LIKE 'test_order_%';
-- DELETE FROM profit_transactions WHERE order_id LIKE 'test_order_%';

