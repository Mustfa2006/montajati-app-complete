-- إضافة عمود التبليغات الذكية للمنتجات
-- Add smart notification tags column to products table

-- إضافة العمود الجديد
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS notification_tags JSONB DEFAULT '[]'::jsonb;

-- إضافة تعليق للعمود
COMMENT ON COLUMN products.notification_tags IS 'قائمة التبليغات الذكية للمنتج (مثل: قابل للتجديد، عليها طلب، جديد)';

-- إنشاء فهرس للبحث السريع في التبليغات
CREATE INDEX IF NOT EXISTS idx_products_notification_tags 
ON products USING GIN (notification_tags);

-- تحديث المنتجات الموجودة لتحتوي على قائمة فارغة من التبليغات
UPDATE products 
SET notification_tags = '[]'::jsonb 
WHERE notification_tags IS NULL;

-- إضافة قيد للتأكد من أن التبليغات هي مصفوفة
ALTER TABLE products 
ADD CONSTRAINT check_notification_tags_is_array 
CHECK (jsonb_typeof(notification_tags) = 'array');

-- إضافة قيد للحد الأقصى لعدد التبليغات (5 تبليغات كحد أقصى)
ALTER TABLE products 
ADD CONSTRAINT check_notification_tags_max_length 
CHECK (jsonb_array_length(notification_tags) <= 5);

-- إضافة قيد للتأكد من أن كل تبليغ هو نص وليس أطول من 20 حرف
ALTER TABLE products 
ADD CONSTRAINT check_notification_tags_content 
CHECK (
  notification_tags = '[]'::jsonb OR 
  (
    SELECT bool_and(
      jsonb_typeof(tag) = 'string' AND 
      length(tag::text) <= 22 AND  -- 20 حرف + 2 للاقتباس
      length(tag::text) >= 3       -- حد أدنى 1 حرف + 2 للاقتباس
    )
    FROM jsonb_array_elements(notification_tags) AS tag
  )
);

-- إنشاء دالة مساعدة للحصول على المنتجات التي تحتوي على تبليغ معين
CREATE OR REPLACE FUNCTION get_products_with_notification_tag(tag_name TEXT)
RETURNS TABLE (
  id UUID,
  name TEXT,
  notification_tags JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.name, p.notification_tags
  FROM products p
  WHERE p.notification_tags ? tag_name;
END;
$$ LANGUAGE plpgsql;

-- إنشاء دالة لإضافة تبليغ لمنتج
CREATE OR REPLACE FUNCTION add_notification_tag(product_id UUID, tag_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  current_tags JSONB;
  new_tags JSONB;
BEGIN
  -- التحقق من طول التبليغ
  IF length(tag_name) > 20 OR length(tag_name) < 1 THEN
    RETURN FALSE;
  END IF;
  
  -- جلب التبليغات الحالية
  SELECT notification_tags INTO current_tags
  FROM products
  WHERE id = product_id;
  
  -- التحقق من وجود المنتج
  IF current_tags IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- التحقق من عدم وجود التبليغ مسبقاً
  IF current_tags ? tag_name THEN
    RETURN FALSE;
  END IF;
  
  -- التحقق من عدم تجاوز الحد الأقصى
  IF jsonb_array_length(current_tags) >= 5 THEN
    RETURN FALSE;
  END IF;
  
  -- إضافة التبليغ الجديد
  new_tags := current_tags || jsonb_build_array(tag_name);
  
  -- تحديث المنتج
  UPDATE products
  SET notification_tags = new_tags
  WHERE id = product_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- إنشاء دالة لحذف تبليغ من منتج
CREATE OR REPLACE FUNCTION remove_notification_tag(product_id UUID, tag_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  current_tags JSONB;
  new_tags JSONB;
BEGIN
  -- جلب التبليغات الحالية
  SELECT notification_tags INTO current_tags
  FROM products
  WHERE id = product_id;
  
  -- التحقق من وجود المنتج
  IF current_tags IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- التحقق من وجود التبليغ
  IF NOT (current_tags ? tag_name) THEN
    RETURN FALSE;
  END IF;
  
  -- إزالة التبليغ
  new_tags := current_tags - tag_name;
  
  -- تحديث المنتج
  UPDATE products
  SET notification_tags = new_tags
  WHERE id = product_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- إنشاء view لعرض المنتجات مع تبليغاتها بشكل مقروء
CREATE OR REPLACE VIEW products_with_notifications AS
SELECT 
  id,
  name,
  notification_tags,
  CASE 
    WHEN jsonb_array_length(notification_tags) = 0 THEN 'لا توجد تبليغات'
    ELSE (
      SELECT string_agg(tag::text, ', ')
      FROM jsonb_array_elements_text(notification_tags) AS tag
    )
  END AS notification_tags_text
FROM products;

-- إضافة تعليق للـ view
COMMENT ON VIEW products_with_notifications IS 'عرض المنتجات مع تبليغاتها بشكل مقروء';
