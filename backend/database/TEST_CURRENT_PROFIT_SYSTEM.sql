-- ============================================================================
-- اختبار شامل لنظام الأرباح الحالي في قاعدة البيانات
-- ============================================================================
-- 
-- هذا الملف يختبر النظام الموجود حالياً (smart_profit_manager)
-- للتأكد من أنه يعمل بشكل صحيح 100%
--
-- تاريخ الإنشاء: 2025-11-03
-- ============================================================================

-- ============================================================================
-- الخطوة 1: التحقق من وجود النظام الحالي
-- ============================================================================

-- التحقق من وجود الـ Trigger
SELECT 
    tgname AS trigger_name,
    tgrelid::regclass AS table_name,
    proname AS function_name,
    tgtype AS trigger_type
FROM pg_trigger 
JOIN pg_proc ON pg_trigger.tgfoid = pg_proc.oid
WHERE tgname = 'smart_profit_trigger';

-- التحقق من وجود الدالة
SELECT 
    proname AS function_name,
    pg_get_functiondef(oid) AS definition
FROM pg_proc 
WHERE proname = 'smart_profit_manager';

-- ============================================================================
-- الخطوة 2: إنشاء مستخدم تجريبي
-- ============================================================================

-- حذف المستخدم التجريبي إذا كان موجوداً
DELETE FROM orders WHERE user_phone = '07700000000';
DELETE FROM users WHERE phone = '07700000000';

-- إنشاء مستخدم تجريبي
INSERT INTO users (
    phone, 
    name, 
    expected_profits, 
    achieved_profits
) VALUES (
    '07700000000',
    'مستخدم تجريبي',
    0,
    0
) ON CONFLICT (phone) DO UPDATE SET
    expected_profits = 0,
    achieved_profits = 0;

-- التحقق من المستخدم
SELECT 
    phone,
    name,
    expected_profits,
    achieved_profits
FROM users 
WHERE phone = '07700000000';

-- ============================================================================
-- الخطوة 3: اختبار إنشاء طلب جديد نشط
-- ============================================================================

-- إنشاء طلب جديد
INSERT INTO orders (
    user_phone,
    customer_name,
    customer_phone,
    customer_address,
    profit_amount,
    status
) VALUES (
    '07700000000',
    'زبون تجريبي 1',
    '07711111111',
    'بغداد',
    5000,
    'نشط'
);

-- التحقق من الأرباح المتوقعة
SELECT 
    phone,
    expected_profits AS expected,
    achieved_profits AS achieved
FROM users 
WHERE phone = '07700000000';
-- يجب أن تكون: expected = 5000, achieved = 0

-- التحقق من سجل المعاملات
SELECT 
    transaction_type,
    amount,
    old_status,
    new_status,
    notes
FROM profit_transactions 
WHERE user_id = (SELECT id FROM users WHERE phone = '07700000000')
ORDER BY created_at DESC 
LIMIT 1;
-- يجب أن يكون: transaction_type = 'expected', amount = 5000

-- ============================================================================
-- الخطوة 4: اختبار تحديث الحالة إلى "تم التسليم للزبون"
-- ============================================================================

-- تحديث الحالة
UPDATE orders 
SET status = 'تم التسليم للزبون'
WHERE user_phone = '07700000000' 
  AND customer_name = 'زبون تجريبي 1';

-- التحقق من الأرباح
SELECT 
    phone,
    expected_profits AS expected,
    achieved_profits AS achieved
FROM users 
WHERE phone = '07700000000';
-- يجب أن تكون: expected = 0, achieved = 5000

-- التحقق من سجل المعاملات
SELECT 
    transaction_type,
    amount,
    old_status,
    new_status,
    notes
FROM profit_transactions 
WHERE user_id = (SELECT id FROM users WHERE phone = '07700000000')
ORDER BY created_at DESC 
LIMIT 1;
-- يجب أن يكون: transaction_type = 'achieved', amount = 5000

-- ============================================================================
-- الخطوة 5: اختبار إرجاع الطلب من "تم التسليم" إلى "نشط"
-- ============================================================================

-- إرجاع الحالة
UPDATE orders 
SET status = 'نشط'
WHERE user_phone = '07700000000' 
  AND customer_name = 'زبون تجريبي 1';

-- التحقق من الأرباح
SELECT 
    phone,
    expected_profits AS expected,
    achieved_profits AS achieved
FROM users 
WHERE phone = '07700000000';
-- يجب أن تكون: expected = 5000, achieved = 0

-- التحقق من سجل المعاملات
SELECT 
    transaction_type,
    amount,
    old_status,
    new_status,
    notes
FROM profit_transactions 
WHERE user_id = (SELECT id FROM users WHERE phone = '07700000000')
ORDER BY created_at DESC 
LIMIT 1;
-- يجب أن يكون: transaction_type = 'reversed', amount = 5000

-- ============================================================================
-- الخطوة 6: اختبار إلغاء طلب نشط
-- ============================================================================

-- إلغاء الطلب
UPDATE orders 
SET status = 'الغاء الطلب'
WHERE user_phone = '07700000000' 
  AND customer_name = 'زبون تجريبي 1';

-- التحقق من الأرباح
SELECT 
    phone,
    expected_profits AS expected,
    achieved_profits AS achieved
FROM users 
WHERE phone = '07700000000';
-- يجب أن تكون: expected = 0, achieved = 0

-- التحقق من سجل المعاملات
SELECT 
    transaction_type,
    amount,
    old_status,
    new_status,
    notes
FROM profit_transactions 
WHERE user_id = (SELECT id FROM users WHERE phone = '07700000000')
ORDER BY created_at DESC 
LIMIT 1;
-- يجب أن يكون: transaction_type = 'cancelled_expected', amount = 5000

-- ============================================================================
-- الخطوة 7: اختبار إعادة تفعيل طلب ملغي
-- ============================================================================

-- إعادة تفعيل الطلب
UPDATE orders 
SET status = 'نشط'
WHERE user_phone = '07700000000' 
  AND customer_name = 'زبون تجريبي 1';

-- التحقق من الأرباح
SELECT 
    phone,
    expected_profits AS expected,
    achieved_profits AS achieved
FROM users 
WHERE phone = '07700000000';
-- يجب أن تكون: expected = 5000, achieved = 0

-- التحقق من سجل المعاملات
SELECT 
    transaction_type,
    amount,
    old_status,
    new_status,
    notes
FROM profit_transactions 
WHERE user_id = (SELECT id FROM users WHERE phone = '07700000000')
ORDER BY created_at DESC 
LIMIT 1;
-- يجب أن يكون: transaction_type = 'restored_expected', amount = 5000

-- ============================================================================
-- الخطوة 8: اختبار طلبات متعددة
-- ============================================================================

-- إنشاء طلب ثاني
INSERT INTO orders (
    user_phone,
    customer_name,
    customer_phone,
    customer_address,
    profit_amount,
    status
) VALUES (
    '07700000000',
    'زبون تجريبي 2',
    '07722222222',
    'البصرة',
    3000,
    'قيد التوصيل الى الزبون (في عهدة المندوب)'
);

-- إنشاء طلب ثالث
INSERT INTO orders (
    user_phone,
    customer_name,
    customer_phone,
    customer_address,
    profit_amount,
    status
) VALUES (
    '07700000000',
    'زبون تجريبي 3',
    '07733333333',
    'أربيل',
    7000,
    'نشط'
);

-- التحقق من الأرباح
SELECT 
    phone,
    expected_profits AS expected,
    achieved_profits AS achieved
FROM users 
WHERE phone = '07700000000';
-- يجب أن تكون: expected = 15000 (5000 + 3000 + 7000), achieved = 0

-- تسليم الطلب الثاني
UPDATE orders 
SET status = 'تم التسليم للزبون'
WHERE user_phone = '07700000000' 
  AND customer_name = 'زبون تجريبي 2';

-- التحقق من الأرباح
SELECT 
    phone,
    expected_profits AS expected,
    achieved_profits AS achieved
FROM users 
WHERE phone = '07700000000';
-- يجب أن تكون: expected = 12000 (5000 + 7000), achieved = 3000

-- تسليم الطلب الثالث
UPDATE orders 
SET status = 'تم التسليم للزبون'
WHERE user_phone = '07700000000' 
  AND customer_name = 'زبون تجريبي 3';

-- التحقق من الأرباح
SELECT 
    phone,
    expected_profits AS expected,
    achieved_profits AS achieved
FROM users 
WHERE phone = '07700000000';
-- يجب أن تكون: expected = 5000, achieved = 10000 (3000 + 7000)

-- ============================================================================
-- الخطوة 9: عرض جميع المعاملات
-- ============================================================================

SELECT 
    transaction_type,
    amount,
    old_status,
    new_status,
    notes,
    created_at
FROM profit_transactions 
WHERE user_id = (SELECT id FROM users WHERE phone = '07700000000')
ORDER BY created_at ASC;

-- ============================================================================
-- الخطوة 10: التنظيف (اختياري)
-- ============================================================================

-- حذف البيانات التجريبية
-- DELETE FROM orders WHERE user_phone = '07700000000';
-- DELETE FROM users WHERE phone = '07700000000';

-- ============================================================================
-- النتيجة المتوقعة
-- ============================================================================
--
-- إذا نجحت جميع الاختبارات، فهذا يعني:
--
-- ✅ النظام الحالي (smart_profit_manager) يعمل بشكل صحيح 100%
-- ✅ الأرباح المتوقعة تُحدث بشكل صحيح
-- ✅ الأرباح المحققة تُحدث بشكل صحيح
-- ✅ نقل الأرباح من المتوقعة إلى المحققة يعمل بشكل صحيح
-- ✅ إلغاء الطلبات يعمل بشكل صحيح
-- ✅ إعادة تفعيل الطلبات يعمل بشكل صحيح
-- ✅ سجل المعاملات يعمل بشكل صحيح
--
-- ============================================================================

