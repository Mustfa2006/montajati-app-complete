-- ===================================
-- إصلاح دالة النظام الذكي للمخزون
-- Fix Smart Inventory Function
-- ===================================

-- حذف الدالة القديمة وإعادة إنشائها مع التصحيح
DROP FUNCTION IF EXISTS calculate_smart_inventory_range(INTEGER);

-- إنشاء دالة محدثة لحساب النطاق الذكي مع إصلاح نوع البيانات
CREATE OR REPLACE FUNCTION calculate_smart_inventory_range(total_quantity INTEGER)
RETURNS TABLE(min_range INTEGER, max_range INTEGER) AS $$
BEGIN
    IF total_quantity <= 0 THEN
        RETURN QUERY SELECT 0, 0;
    ELSIF total_quantity <= 10 THEN
        RETURN QUERY SELECT GREATEST(0, total_quantity - 2), total_quantity;
    ELSIF total_quantity <= 50 THEN
        -- تحويل ROUND إلى INTEGER صراحة
        RETURN QUERY SELECT GREATEST(0, total_quantity - ROUND(total_quantity * 0.1)::INTEGER), total_quantity;
    ELSIF total_quantity <= 100 THEN
        -- تحويل ROUND إلى INTEGER صراحة
        RETURN QUERY SELECT GREATEST(0, total_quantity - ROUND(total_quantity * 0.05)::INTEGER), total_quantity;
    ELSE
        -- تحويل ROUND إلى INTEGER صراحة
        RETURN QUERY SELECT GREATEST(0, total_quantity - ROUND(total_quantity * 0.03)::INTEGER), total_quantity;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- تحديث trigger function أيضاً
CREATE OR REPLACE FUNCTION update_smart_inventory_range()
RETURNS TRIGGER AS $$
DECLARE
    smart_range RECORD;
BEGIN
    -- حساب النطاق الذكي الجديد عند تغيير available_quantity
    IF NEW.available_quantity != OLD.available_quantity AND NEW.smart_range_enabled = true THEN
        SELECT * INTO smart_range FROM calculate_smart_inventory_range(NEW.available_quantity);
        
        NEW.available_from = smart_range.min_range;
        NEW.available_to = smart_range.max_range;
        NEW.minimum_stock = smart_range.min_range;
        NEW.maximum_stock = smart_range.max_range;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إعادة إنشاء trigger
DROP TRIGGER IF EXISTS trigger_update_smart_inventory_range ON products;
CREATE TRIGGER trigger_update_smart_inventory_range
    BEFORE UPDATE OF available_quantity ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_smart_inventory_range();

-- تحديث البيانات الموجودة بالنطاق الذكي المصحح
UPDATE products
SET
    available_from = CASE
        WHEN available_quantity <= 10 THEN GREATEST(0, available_quantity - 2)
        WHEN available_quantity <= 50 THEN GREATEST(0, available_quantity - ROUND(available_quantity * 0.1)::INTEGER)
        WHEN available_quantity <= 100 THEN GREATEST(0, available_quantity - ROUND(available_quantity * 0.05)::INTEGER)
        ELSE GREATEST(0, available_quantity - ROUND(available_quantity * 0.03)::INTEGER)
    END,
    available_to = available_quantity,
    maximum_stock = available_quantity,
    minimum_stock = CASE
        WHEN available_quantity <= 10 THEN GREATEST(0, available_quantity - 2)
        WHEN available_quantity <= 50 THEN GREATEST(0, available_quantity - ROUND(available_quantity * 0.1)::INTEGER)
        WHEN available_quantity <= 100 THEN GREATEST(0, available_quantity - ROUND(available_quantity * 0.05)::INTEGER)
        ELSE GREATEST(0, available_quantity - ROUND(available_quantity * 0.03)::INTEGER)
    END,
    smart_range_enabled = true
WHERE available_quantity IS NOT NULL;

-- التحقق من النتائج
SELECT 
    'تم إصلاح دالة النظام الذكي بنجاح' as status,
    COUNT(*) as total_products,
    AVG(available_quantity) as avg_available,
    AVG(minimum_stock) as avg_min_stock,
    AVG(maximum_stock) as avg_max_stock
FROM products 
WHERE is_active = true;

COMMIT;
