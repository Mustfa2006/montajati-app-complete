-- ===================================
-- إضافة الحالات المفقودة من الوسيط
-- حل مشكلة foreign key constraint violation
-- ===================================

-- إضافة الحالات المفقودة التي تسبب أخطاء
INSERT INTO waseet_statuses (id, status_text, status_category, is_active, created_at, updated_at)
VALUES 
  (5, 'في موقع فرز بغداد', 'in_transit', true, NOW(), NOW()),
  (7, 'في الطريق الى مكتب المحافظة', 'in_transit', true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  status_text = EXCLUDED.status_text,
  status_category = EXCLUDED.status_category,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- التحقق من إضافة الحالات
SELECT id, status_text, status_category, is_active 
FROM waseet_statuses 
WHERE id IN (5, 7)
ORDER BY id;

-- عرض جميع الحالات الموجودة
SELECT id, status_text, status_category, is_active 
FROM waseet_statuses 
WHERE is_active = true
ORDER BY id;

