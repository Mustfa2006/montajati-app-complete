-- ===================================
-- إعداد جداول قاعدة البيانات لنظام الإشعارات
-- Database Setup for Notification System
-- ===================================

-- جدول FCM Tokens
CREATE TABLE IF NOT EXISTS fcm_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_phone VARCHAR(20) NOT NULL,
    fcm_token TEXT NOT NULL,
    device_info JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- فهارس للبحث السريع
    UNIQUE(user_phone, fcm_token)
);

-- فهرس للبحث بالهاتف
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_phone ON fcm_tokens(user_phone);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_active ON fcm_tokens(is_active);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_last_used ON fcm_tokens(last_used_at);

-- جدول سجل الإشعارات
CREATE TABLE IF NOT EXISTS notification_logs (
    id BIGSERIAL PRIMARY KEY,
    user_phone VARCHAR(20) NOT NULL,
    fcm_token TEXT,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    additional_data JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'pending', -- pending, sent, failed, delivered
    error_message TEXT,
    firebase_message_id TEXT,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    delivered_at TIMESTAMPTZ,
    
    -- فهارس
    INDEX(user_phone),
    INDEX(status),
    INDEX(sent_at)
);

-- دالة تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- تطبيق الدالة على جدول fcm_tokens
DROP TRIGGER IF EXISTS update_fcm_tokens_updated_at ON fcm_tokens;
CREATE TRIGGER update_fcm_tokens_updated_at
    BEFORE UPDATE ON fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- إعطاء صلاحيات للخدمة
GRANT ALL PRIVILEGES ON fcm_tokens TO postgres;
GRANT ALL PRIVILEGES ON notification_logs TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- بيانات تجريبية (اختيارية)
-- INSERT INTO fcm_tokens (user_phone, fcm_token, device_info) 
-- VALUES ('0501234567', 'test_token_123', '{"platform": "test", "app": "montajati"}')
-- ON CONFLICT (user_phone, fcm_token) DO NOTHING;
