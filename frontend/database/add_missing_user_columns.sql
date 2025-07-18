-- إضافة الأعمدة المفقودة لجدول المستخدمين
-- يجب تشغيل هذا الكود في SQL Editor في لوحة تحكم Supabase

-- إضافة الأعمدة الأساسية المفقودة
ALTER TABLE users ADD COLUMN IF NOT EXISTS province TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS notes TEXT;

-- إضافة أعمدة الإحصائيات إذا لم تكن موجودة
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS completed_orders INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cancelled_orders INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pending_orders INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_sales DECIMAL(12,2) DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_purchases DECIMAL(12,2) DEFAULT 0;

-- إضافة أعمدة إدارة الحساب
ALTER TABLE users ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'active' 
    CHECK (account_status IN ('active', 'suspended', 'banned', 'pending'));
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspension_reason TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspension_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspension_expiry TIMESTAMP WITH TIME ZONE;

-- إضافة أعمدة النشاط
ALTER TABLE users ADD COLUMN IF NOT EXISTS login_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_activity TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_ip_address TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_info TEXT;

-- إضافة أعمدة الأدوار والصلاحيات
ALTER TABLE users ADD COLUMN IF NOT EXISTS roles TEXT[] DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}';

-- إضافة عمود is_admin إذا لم يكن موجود
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- تحديث البيانات الموجودة
UPDATE users SET 
    total_orders = 0,
    completed_orders = 0,
    cancelled_orders = 0,
    pending_orders = 0,
    total_sales = 0,
    total_purchases = 0,
    account_status = 'active',
    login_count = 0,
    roles = '{}',
    permissions = '{}',
    preferences = '{}'
WHERE total_orders IS NULL 
   OR completed_orders IS NULL 
   OR cancelled_orders IS NULL 
   OR pending_orders IS NULL 
   OR total_sales IS NULL 
   OR total_purchases IS NULL 
   OR account_status IS NULL 
   OR login_count IS NULL 
   OR roles IS NULL 
   OR permissions IS NULL 
   OR preferences IS NULL;

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_users_account_status ON users(account_status);
CREATE INDEX IF NOT EXISTS idx_users_is_admin ON users(is_admin);
CREATE INDEX IF NOT EXISTS idx_users_province ON users(province);
CREATE INDEX IF NOT EXISTS idx_users_city ON users(city);
CREATE INDEX IF NOT EXISTS idx_users_last_activity ON users(last_activity);

-- عرض هيكل الجدول المحدث
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- عرض عدد المستخدمين
SELECT COUNT(*) as total_users FROM users;

-- ملاحظات:
-- 1. هذا السكريبت آمن ولن يحذف أي بيانات موجودة
-- 2. يستخدم IF NOT EXISTS لتجنب الأخطاء إذا كانت الأعمدة موجودة
-- 3. يحدث البيانات الموجودة بقيم افتراضية
-- 4. ينشئ فهارس لتحسين الأداء
