-- Migration: Add target_type to competitions and create competition_users table
-- Date: 2024-01-01

-- إضافة حقل نوع الهدف للمسابقات
ALTER TABLE competitions 
ADD COLUMN IF NOT EXISTS target_type VARCHAR(20) DEFAULT 'all' CHECK (target_type IN ('all', 'specific'));

-- جدول ربط المسابقات بالمستخدمين المحددين
CREATE TABLE IF NOT EXISTS competition_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(competition_id, user_id)
);

-- فهرس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_competition_users_competition ON competition_users(competition_id);
CREATE INDEX IF NOT EXISTS idx_competition_users_user ON competition_users(user_id);
CREATE INDEX IF NOT EXISTS idx_competitions_target_type ON competitions(target_type);

-- تحديث المسابقات الموجودة لتكون للجميع
UPDATE competitions SET target_type = 'all' WHERE target_type IS NULL;

