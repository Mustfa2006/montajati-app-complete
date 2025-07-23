-- ===================================
-- إنشاء جداول نظام الدعم
-- Create Support System Tables
-- ===================================

-- جدول طلبات الدعم
CREATE TABLE IF NOT EXISTS support_requests (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL,
  customer_name TEXT NOT NULL,
  primary_phone TEXT NOT NULL,
  alternative_phone TEXT,
  governorate TEXT NOT NULL,
  address TEXT NOT NULL,
  order_status TEXT NOT NULL,
  notes TEXT,
  telegram_message_id BIGINT,
  status TEXT DEFAULT 'pending', -- pending, in_progress, resolved
  resolved_at TIMESTAMPTZ,
  resolved_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- إضافة أعمدة الدعم لجدول الطلبات
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS support_requested BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS support_requested_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS support_notes TEXT;

-- إنشاء فهارس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_support_requests_order_id ON support_requests(order_id);
CREATE INDEX IF NOT EXISTS idx_support_requests_status ON support_requests(status);
CREATE INDEX IF NOT EXISTS idx_support_requests_created_at ON support_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_support_requested ON orders(support_requested);

-- إنشاء trigger لتحديث updated_at
CREATE OR REPLACE FUNCTION update_support_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_support_requests_updated_at
  BEFORE UPDATE ON support_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_support_requests_updated_at();

-- إدراج البيانات الأولية لحالات الطلبات التي تحتاج معالجة
INSERT INTO order_statuses (id, name, description, needs_processing) VALUES
(25, 'لا يرد', 'العميل لا يرد على الهاتف', true),
(26, 'لا يرد بعد الاتفاق', 'العميل لا يرد بعد الاتفاق على الطلب', true),
(27, 'مغلق', 'الهاتف مغلق', true),
(28, 'مغلق بعد الاتفاق', 'الهاتف مغلق بعد الاتفاق', true),
(36, 'الرقم غير معرف', 'الرقم غير معرف أو غير صحيح', true),
(37, 'الرقم غير داخل في الخدمة', 'الرقم خارج نطاق الخدمة', true),
(41, 'لا يمكن الاتصال بالرقم', 'مشكلة تقنية في الاتصال', true),
(29, 'مؤجل', 'الطلب مؤجل', true),
(30, 'مؤجل لحين اعادة الطلب لاحقا', 'مؤجل بناء على طلب العميل', true),
(33, 'مفصول عن الخدمة', 'الرقم مفصول عن الخدمة', true),
(34, 'طلب مكرر', 'طلب مكرر من نفس العميل', true),
(35, 'مستلم مسبقا', 'العميل استلم الطلب مسبقاً', true),
(38, 'العنوان غير دقيق', 'العنوان المقدم غير دقيق', true),
(39, 'لم يطلب', 'العميل ينكر طلب المنتج', true),
(40, 'حظر المندوب', 'العميل حظر المندوب', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  needs_processing = EXCLUDED.needs_processing;

-- إنشاء view للطلبات التي تحتاج معالجة
CREATE OR REPLACE VIEW orders_need_processing AS
SELECT 
  o.*,
  os.name as status_name,
  os.description as status_description
FROM orders o
JOIN order_statuses os ON o.status_id = os.id
WHERE os.needs_processing = true
  AND (o.support_requested IS FALSE OR o.support_requested IS NULL)
ORDER BY o.created_at DESC;

-- إنشاء view لإحصائيات الدعم
CREATE OR REPLACE VIEW support_statistics AS
SELECT 
  COUNT(*) as total_requests,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
  COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress_requests,
  COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_requests,
  AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) as avg_resolution_hours
FROM support_requests
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';

-- منح الصلاحيات
GRANT ALL ON support_requests TO authenticated;
GRANT ALL ON support_requests TO service_role;
GRANT SELECT ON orders_need_processing TO authenticated;
GRANT SELECT ON support_statistics TO authenticated;
