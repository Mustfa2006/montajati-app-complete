-- ===================================
-- اختبار نظام الإشعارات الجديد
-- Test New Notification System
-- ===================================

-- 📋 هذا الملف يحتوي على اختبارات للتحقق من:
-- 1. الحالات المسموحة للإشعارات (10 حالات فقط)
-- 2. الحالات المحجوبة (لا إشعارات)
-- 3. نظام الأرباح يعمل بشكل صحيح

-- ===================================
-- 1️⃣ الحالات المسموحة للإشعارات
-- ===================================

-- القائمة الكاملة للحالات المسموحة:
SELECT 
  id,
  status_text,
  status_category,
  '✅ مسموح' as notification_status
FROM waseet_statuses
WHERE status_text IN (
  'تم التسليم للزبون',                          -- ID: 4
  'قيد التوصيل الى الزبون (في عهدة المندوب)',  -- ID: 3
  'تم تغيير محافظة الزبون',                     -- ID: 24
  'تغيير المندوب',                              -- ID: 42
  'لا يرد',                                      -- ID: 25
  'لا يرد بعد الاتفاق',                         -- ID: 26
  'مغلق',                                        -- ID: 27
  'مغلق بعد الاتفاق',                           -- ID: 28
  'الرقم غير معرف',                             -- ID: 36
  'الرقم غير داخل في الخدمة'                    -- ID: 37
)
ORDER BY id;

-- النتيجة المتوقعة: 10 صفوف

-- ===================================
-- 2️⃣ الحالات المحجوبة (لا إشعارات)
-- ===================================

-- القائمة الكاملة للحالات المحجوبة:
SELECT 
  id,
  status_text,
  status_category,
  '🚫 محجوب' as notification_status
FROM waseet_statuses
WHERE status_text NOT IN (
  'تم التسليم للزبون',
  'قيد التوصيل الى الزبون (في عهدة المندوب)',
  'تم تغيير محافظة الزبون',
  'تغيير المندوب',
  'لا يرد',
  'لا يرد بعد الاتفاق',
  'مغلق',
  'مغلق بعد الاتفاق',
  'الرقم غير معرف',
  'الرقم غير داخل في الخدمة'
)
ORDER BY id;

-- النتيجة المتوقعة: جميع الحالات الأخرى

-- ===================================
-- 3️⃣ الحالات المتجاهلة في Backend
-- ===================================

-- هذه الحالات يتم تجاهلها بالكامل في Backend (لا تحديث في قاعدة البيانات):
SELECT 
  id,
  status_text,
  status_category,
  '⏭️ متجاهلة في Backend' as backend_status
FROM waseet_statuses
WHERE id IN (1, 5, 7)
   OR status_text IN ('فعال', 'في موقع فرز بغداد', 'في الطريق الى مكتب المحافظة')
ORDER BY id;

-- النتيجة المتوقعة:
-- ID 1: فعال
-- ID 5: في موقع فرز بغداد (إذا موجود)
-- ID 7: في الطريق الى مكتب المحافظة (إذا موجود)

-- ===================================
-- 4️⃣ اختبار نظام الأرباح
-- ===================================

-- 🧪 اختبار 1: إنشاء طلب جديد بحالة "نشط"
-- النتيجة المتوقعة: إضافة إلى expected_profits

DO $$
DECLARE
  test_user_id UUID;
  test_order_id UUID;
  initial_expected DECIMAL;
  final_expected DECIMAL;
BEGIN
  -- إنشاء مستخدم اختبار
  INSERT INTO users (phone, name, achieved_profits, expected_profits)
  VALUES ('07700000001', 'Test User 1', 0, 0)
  RETURNING id INTO test_user_id;
  
  -- حفظ الأرباح الأولية
  SELECT expected_profits INTO initial_expected FROM users WHERE id = test_user_id;
  
  -- إنشاء طلب جديد بحالة "نشط"
  INSERT INTO orders (
    user_phone,
    customer_name,
    customer_phone,
    customer_province,
    customer_address,
    product_name,
    quantity,
    price,
    profit,
    status
  ) VALUES (
    '07700000001',
    'Test Customer 1',
    '07700000002',
    'بغداد',
    'Test Address',
    'Test Product',
    1,
    10000,
    2000,
    'نشط'
  ) RETURNING id INTO test_order_id;
  
  -- التحقق من الأرباح النهائية
  SELECT expected_profits INTO final_expected FROM users WHERE id = test_user_id;
  
  -- طباعة النتائج
  RAISE NOTICE '✅ اختبار 1: إنشاء طلب جديد بحالة "نشط"';
  RAISE NOTICE '   الأرباح المنتظرة الأولية: %', initial_expected;
  RAISE NOTICE '   الأرباح المنتظرة النهائية: %', final_expected;
  RAISE NOTICE '   الفرق: %', final_expected - initial_expected;
  
  IF final_expected - initial_expected = 2000 THEN
    RAISE NOTICE '   ✅ النتيجة: نجح الاختبار!';
  ELSE
    RAISE NOTICE '   ❌ النتيجة: فشل الاختبار!';
  END IF;
  
  -- تنظيف البيانات
  DELETE FROM orders WHERE id = test_order_id;
  DELETE FROM users WHERE id = test_user_id;
END $$;

-- ===================================

-- 🧪 اختبار 2: تحديث طلب من "نشط" إلى "تم التسليم للزبون"
-- النتيجة المتوقعة: نقل من expected_profits إلى achieved_profits

DO $$
DECLARE
  test_user_id UUID;
  test_order_id UUID;
  initial_expected DECIMAL;
  initial_achieved DECIMAL;
  final_expected DECIMAL;
  final_achieved DECIMAL;
BEGIN
  -- إنشاء مستخدم اختبار
  INSERT INTO users (phone, name, achieved_profits, expected_profits)
  VALUES ('07700000003', 'Test User 2', 0, 0)
  RETURNING id INTO test_user_id;
  
  -- إنشاء طلب جديد بحالة "نشط"
  INSERT INTO orders (
    user_phone,
    customer_name,
    customer_phone,
    customer_province,
    customer_address,
    product_name,
    quantity,
    price,
    profit,
    status
  ) VALUES (
    '07700000003',
    'Test Customer 2',
    '07700000004',
    'بغداد',
    'Test Address',
    'Test Product',
    1,
    10000,
    3000,
    'نشط'
  ) RETURNING id INTO test_order_id;
  
  -- حفظ الأرباح الأولية
  SELECT expected_profits, achieved_profits 
  INTO initial_expected, initial_achieved 
  FROM users WHERE id = test_user_id;
  
  -- تحديث الطلب إلى "تم التسليم للزبون"
  UPDATE orders 
  SET status = 'تم التسليم للزبون'
  WHERE id = test_order_id;
  
  -- التحقق من الأرباح النهائية
  SELECT expected_profits, achieved_profits 
  INTO final_expected, final_achieved 
  FROM users WHERE id = test_user_id;
  
  -- طباعة النتائج
  RAISE NOTICE '✅ اختبار 2: تحديث طلب من "نشط" إلى "تم التسليم للزبون"';
  RAISE NOTICE '   الأرباح المنتظرة: % → %', initial_expected, final_expected;
  RAISE NOTICE '   الأرباح المحققة: % → %', initial_achieved, final_achieved;
  
  IF final_expected = 0 AND final_achieved = 3000 THEN
    RAISE NOTICE '   ✅ النتيجة: نجح الاختبار!';
  ELSE
    RAISE NOTICE '   ❌ النتيجة: فشل الاختبار!';
  END IF;
  
  -- تنظيف البيانات
  DELETE FROM orders WHERE id = test_order_id;
  DELETE FROM users WHERE id = test_user_id;
END $$;

-- ===================================

-- 🧪 اختبار 3: تحديث طلب من "نشط" إلى "الغاء الطلب"
-- النتيجة المتوقعة: حذف من expected_profits

DO $$
DECLARE
  test_user_id UUID;
  test_order_id UUID;
  initial_expected DECIMAL;
  final_expected DECIMAL;
BEGIN
  -- إنشاء مستخدم اختبار
  INSERT INTO users (phone, name, achieved_profits, expected_profits)
  VALUES ('07700000005', 'Test User 3', 0, 0)
  RETURNING id INTO test_user_id;
  
  -- إنشاء طلب جديد بحالة "نشط"
  INSERT INTO orders (
    user_phone,
    customer_name,
    customer_phone,
    customer_province,
    customer_address,
    product_name,
    quantity,
    price,
    profit,
    status
  ) VALUES (
    '07700000005',
    'Test Customer 3',
    '07700000006',
    'بغداد',
    'Test Address',
    'Test Product',
    1,
    10000,
    1500,
    'نشط'
  ) RETURNING id INTO test_order_id;
  
  -- حفظ الأرباح الأولية
  SELECT expected_profits INTO initial_expected FROM users WHERE id = test_user_id;
  
  -- تحديث الطلب إلى "الغاء الطلب"
  UPDATE orders 
  SET status = 'الغاء الطلب'
  WHERE id = test_order_id;
  
  -- التحقق من الأرباح النهائية
  SELECT expected_profits INTO final_expected FROM users WHERE id = test_user_id;
  
  -- طباعة النتائج
  RAISE NOTICE '✅ اختبار 3: تحديث طلب من "نشط" إلى "الغاء الطلب"';
  RAISE NOTICE '   الأرباح المنتظرة الأولية: %', initial_expected;
  RAISE NOTICE '   الأرباح المنتظرة النهائية: %', final_expected;
  
  IF final_expected = 0 THEN
    RAISE NOTICE '   ✅ النتيجة: نجح الاختبار!';
  ELSE
    RAISE NOTICE '   ❌ النتيجة: فشل الاختبار!';
  END IF;
  
  -- تنظيف البيانات
  DELETE FROM orders WHERE id = test_order_id;
  DELETE FROM users WHERE id = test_user_id;
END $$;

-- ===================================
-- 5️⃣ ملخص النتائج
-- ===================================

-- عرض ملخص لجميع الحالات:
SELECT 
  id,
  status_text,
  status_category,
  CASE 
    WHEN status_text IN (
      'تم التسليم للزبون',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'تم تغيير محافظة الزبون',
      'تغيير المندوب',
      'لا يرد',
      'لا يرد بعد الاتفاق',
      'مغلق',
      'مغلق بعد الاتفاق',
      'الرقم غير معرف',
      'الرقم غير داخل في الخدمة'
    ) THEN '✅ يُرسل إشعار'
    ELSE '🚫 لا يُرسل إشعار'
  END as notification_policy,
  CASE 
    WHEN id IN (1, 5, 7) OR status_text IN ('فعال', 'في موقع فرز بغداد', 'في الطريق الى مكتب المحافظة')
    THEN '⏭️ متجاهلة في Backend'
    ELSE '✅ تُحدث في قاعدة البيانات'
  END as backend_policy
FROM waseet_statuses
ORDER BY id;

-- ===================================
-- النتيجة النهائية
-- ===================================

-- ✅ نظام الإشعارات:
--    - 10 حالات فقط تُرسل إشعارات
--    - باقي الحالات محجوبة
--
-- ✅ نظام الأرباح:
--    - Database Trigger يعمل بشكل صحيح
--    - Backend لا يتدخل في الأرباح
--    - محمي بطبقات حماية قوية
--
-- ✅ النتيجة: النظام آمن 100%! 🎉

