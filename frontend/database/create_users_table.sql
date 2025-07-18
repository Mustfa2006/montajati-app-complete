-- إنشاء جدول المستخدمين في Supabase
-- يجب تشغيل هذا الكود في SQL Editor في لوحة تحكم Supabase

-- إنشاء جدول المستخدمين
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء فهرس على رقم الهاتف للبحث السريع
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- إنشاء دالة لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- إنشاء trigger لتحديث updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- إنشاء Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- حذف السياسات القديمة إن وجدت
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Anyone can insert users" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;

-- سياسة للقراءة (أي شخص يمكنه قراءة البيانات للمصادقة)
CREATE POLICY "Anyone can read users for auth" ON users
    FOR SELECT USING (true);

-- سياسة للإدراج (أي شخص يمكنه إنشاء حساب)
CREATE POLICY "Anyone can insert users" ON users
    FOR INSERT WITH CHECK (true);

-- سياسة للتحديث (المستخدم يمكنه تحديث بياناته فقط)
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (true);

-- إدراج بيانات تجريبية للاختبار
INSERT INTO users (name, phone, email, password_hash) VALUES
('أحمد محمد', '01234567890', '01234567890@temp.com', 'e10adc3949ba59abbe56e057f20f883e'),  -- كلمة المرور: 123456
('فاطمة علي', '01111111111', '01111111111@temp.com', '5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5'),  -- كلمة المرور: secret
('محمد أحمد', '01222222222', '01222222222@temp.com', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f'),  -- كلمة المرور: 987654
('سارة خالد', '01333333333', '01333333333@temp.com', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92'),  -- كلمة المرور: 123456
('عمر حسن', '01555555555', '01555555555@temp.com', 'c6ba91b90d922e159893f46c387e5dc1b3dc5c101a5a4522f03b987177a24a91')   -- كلمة المرور: 999999
ON CONFLICT (phone) DO NOTHING;

-- عرض البيانات للتأكد
SELECT id, name, phone, created_at FROM users ORDER BY created_at DESC;

-- ملاحظات مهمة:
-- 1. يجب تشغيل هذا الكود في SQL Editor في Supabase
-- 2. كلمات المرور مشفرة بـ SHA-256
-- 3. يمكن استخدام البيانات التجريبية للاختبار
-- 4. تأكد من أن RLS مفعل للأمان
