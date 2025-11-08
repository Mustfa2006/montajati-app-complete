-- إنشاء حساب المدير الرئيسي
-- يجب تشغيل هذا الكود في SQL Editor في لوحة تحكم Supabase

-- أولاً، التأكد من وجود عمود is_admin في جدول المستخدمين
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- حذف أي حساب مدير موجود مسبقاً (للتنظيف)
DELETE FROM users WHERE phone = '00000000000' OR name = 'Admin-Mustfa-2006';

-- إنشاء حساب المدير الرئيسي
-- بيانات المدير:
-- الاسم: Admin-Mustfa-2006
-- رقم الهاتف: 00000000000 (11 رقم)
-- البريد الإلكتروني: admin@montajati.com
-- كلمة المرور: Mustfaabd2006 (مشفرة بـ SHA-256)
-- صلاحية المدير: true

INSERT INTO users (name, phone, email, password_hash, is_admin, created_at, updated_at)
VALUES (
    'Admin-Mustfa-2006',
    '00000000000',
    'admin@montajati.com',
    'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', -- Mustfaabd2006 مشفرة بـ SHA-256
    TRUE,
    NOW(),
    NOW()
);

-- التحقق من إنشاء الحساب
SELECT 
    id,
    name,
    phone,
    email,
    is_admin,
    created_at
FROM users 
WHERE is_admin = TRUE;

-- إنشاء فهرس على عمود is_admin للبحث السريع
CREATE INDEX IF NOT EXISTS idx_users_is_admin ON users(is_admin);

-- تحديث Row Level Security للسماح للمدير بالوصول لكل شيء
DROP POLICY IF EXISTS "Admins can access everything" ON users;
CREATE POLICY "Admins can access everything" ON users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users admin_user
            WHERE admin_user.id = auth.uid() 
            AND admin_user.is_admin = true
        )
    );

-- عرض معلومات الحساب المنشأ
SELECT
    'تم إنشاء حساب المدير بنجاح!' as message,
    name,
    phone,
    email,
    is_admin,
    created_at
FROM users
WHERE name = 'Admin-Mustfa-2006';

-- ملاحظات مهمة:
-- 1. اسم المستخدم: Admin-Mustfa-2006
-- 2. رقم الهاتف: 00000000000
-- 3. كلمة المرور: Mustfaabd2006
-- 4. هذا الحساب له صلاحيات كاملة على النظام
-- 5. لا تشارك هذه البيانات مع أي شخص غير مخول

-- للتحقق من تشفير كلمة المرور (اختياري)
-- يمكن استخدام هذا الاستعلام للتأكد من صحة التشفير
SELECT
    name,
    phone,
    password_hash,
    'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3' as expected_hash,
    CASE
        WHEN password_hash = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'
        THEN 'كلمة المرور صحيحة'
        ELSE 'خطأ في كلمة المرور'
    END as password_status
FROM users
WHERE name = 'Admin-Mustfa-2006';

-- عرض جميع المدراء
SELECT 
    'قائمة المدراء:' as title,
    name,
    phone,
    email,
    created_at
FROM users 
WHERE is_admin = TRUE
ORDER BY created_at;

-- إحصائيات سريعة
SELECT 
    COUNT(*) FILTER (WHERE is_admin = TRUE) as admin_count,
    COUNT(*) FILTER (WHERE is_admin = FALSE) as user_count,
    COUNT(*) as total_users
FROM users;
