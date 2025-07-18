-- ===================================
-- إنشاء جدول FCM Tokens للإشعارات
-- ===================================

-- إنشاء جدول user_fcm_tokens
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_phone VARCHAR(20) NOT NULL,
    fcm_token TEXT NOT NULL,
    platform VARCHAR(20) DEFAULT 'android',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء فهرس على رقم الهاتف
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_phone ON user_fcm_tokens(user_phone);

-- إنشاء فهرس على FCM Token
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_token ON user_fcm_tokens(fcm_token);

-- إنشاء فهرس على الحالة النشطة
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active ON user_fcm_tokens(is_active);

-- إضافة قيد فريد على user_phone + platform
ALTER TABLE user_fcm_tokens 
ADD CONSTRAINT unique_user_phone_platform 
UNIQUE (user_phone, platform);

-- إنشاء دالة تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- إنشاء trigger لتحديث updated_at
CREATE TRIGGER update_user_fcm_tokens_updated_at 
    BEFORE UPDATE ON user_fcm_tokens 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- إدراج بيانات تجريبية للاختبار
INSERT INTO user_fcm_tokens (user_phone, fcm_token, platform) 
VALUES 
    ('07503597589', 'test_token_android_user1', 'android'),
    ('07801234567', 'test_token_android_user2', 'android')
ON CONFLICT (user_phone, platform) 
DO UPDATE SET 
    fcm_token = EXCLUDED.fcm_token,
    updated_at = NOW();

-- عرض الجدول المنشأ
SELECT 'تم إنشاء جدول user_fcm_tokens بنجاح' as status;
