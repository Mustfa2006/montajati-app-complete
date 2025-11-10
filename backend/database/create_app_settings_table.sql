-- 🔧 جدول إعدادات التطبيق
-- يستخدم للتحكم في ميزات التطبيق من لوحة التحكم

CREATE TABLE IF NOT EXISTS app_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key TEXT UNIQUE NOT NULL,
  setting_value TEXT NOT NULL,
  message TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 📝 إضافة تعليق على الجدول
COMMENT ON TABLE app_settings IS 'جدول إعدادات التطبيق للتحكم في الميزات';

-- 📝 إضافة تعليقات على الأعمدة
COMMENT ON COLUMN app_settings.setting_key IS 'مفتاح الإعداد (مثل: withdrawal_enabled)';
COMMENT ON COLUMN app_settings.setting_value IS 'قيمة الإعداد (true/false أو أي قيمة أخرى)';
COMMENT ON COLUMN app_settings.message IS 'رسالة مخصصة تظهر للمستخدمين';

-- 🔒 إنشاء فهرس على setting_key للبحث السريع
CREATE INDEX IF NOT EXISTS idx_app_settings_key ON app_settings(setting_key);

-- ✅ إدراج الإعدادات الافتراضية
INSERT INTO app_settings (setting_key, setting_value, message)
VALUES 
  ('withdrawal_enabled', 'true', 'عملية السحب متاحة حالياً'),
  ('orders_enabled', 'true', 'إضافة الطلبات متاحة حالياً')
ON CONFLICT (setting_key) DO NOTHING;

-- 🔄 دالة لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_app_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 🔄 إنشاء trigger لتحديث updated_at
DROP TRIGGER IF EXISTS trigger_update_app_settings_updated_at ON app_settings;
CREATE TRIGGER trigger_update_app_settings_updated_at
  BEFORE UPDATE ON app_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_app_settings_updated_at();

-- ✅ منح الصلاحيات
GRANT SELECT, INSERT, UPDATE ON app_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE ON app_settings TO anon;

