-- ===================================
-- 🎨 دوال نظام الألوان الذكي
-- Smart Colors System Functions
-- ===================================

-- 🔧 دالة إضافة لون جديد للمنتج
CREATE OR REPLACE FUNCTION add_product_color(
    p_product_id UUID,
    p_color_name VARCHAR(100),
    p_color_code VARCHAR(7),
    p_color_arabic_name VARCHAR(100),
    p_total_quantity INTEGER DEFAULT 0,
    p_user_phone VARCHAR(20) DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_color_id UUID;
    v_result JSON;
BEGIN
    -- التحقق من وجود المنتج
    IF NOT EXISTS (SELECT 1 FROM products WHERE id = p_product_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'المنتج غير موجود',
            'error_code', 'PRODUCT_NOT_FOUND'
        );
    END IF;
    
    -- التحقق من عدم تكرار اللون
    IF EXISTS (SELECT 1 FROM product_colors WHERE product_id = p_product_id AND color_name = p_color_name) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'هذا اللون موجود بالفعل للمنتج',
            'error_code', 'COLOR_ALREADY_EXISTS'
        );
    END IF;
    
    -- إدراج اللون الجديد
    INSERT INTO product_colors (
        product_id, color_name, color_code, color_arabic_name, 
        total_quantity, available_quantity, display_order
    ) VALUES (
        p_product_id, p_color_name, p_color_code, p_color_arabic_name,
        p_total_quantity, p_total_quantity,
        COALESCE((SELECT MAX(display_order) + 1 FROM product_colors WHERE product_id = p_product_id), 1)
    ) RETURNING id INTO v_color_id;
    
    -- تسجيل في التاريخ
    INSERT INTO product_colors_history (
        color_id, product_id, action_type, new_quantity, 
        quantity_change, reason, user_phone
    ) VALUES (
        v_color_id, p_product_id, 'created', p_total_quantity,
        p_total_quantity, 'إضافة لون جديد', p_user_phone
    );
    
    -- تحديث عداد الاستخدام للون المحدد مسبقاً
    UPDATE predefined_colors 
    SET usage_count = usage_count + 1 
    WHERE color_name = p_color_name OR color_code = p_color_code;
    
    RETURN json_build_object(
        'success', true,
        'color_id', v_color_id,
        'message', 'تم إضافة اللون بنجاح'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'خطأ في إضافة اللون: ' || SQLERRM,
        'error_code', 'INTERNAL_ERROR'
    );
END;
$$ LANGUAGE plpgsql;

-- 🔄 دالة تحديث كمية اللون
CREATE OR REPLACE FUNCTION update_color_quantity(
    p_color_id UUID,
    p_new_quantity INTEGER,
    p_reason TEXT DEFAULT 'تحديث الكمية',
    p_user_phone VARCHAR(20) DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_old_quantity INTEGER;
    v_product_id UUID;
    v_reserved_quantity INTEGER;
BEGIN
    -- الحصول على البيانات الحالية
    SELECT total_quantity, product_id, reserved_quantity 
    INTO v_old_quantity, v_product_id, v_reserved_quantity
    FROM product_colors 
    WHERE id = p_color_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'اللون غير موجود',
            'error_code', 'COLOR_NOT_FOUND'
        );
    END IF;
    
    -- التحقق من أن الكمية الجديدة لا تقل عن المحجوز
    IF p_new_quantity < v_reserved_quantity THEN
        RETURN json_build_object(
            'success', false,
            'error', 'لا يمكن تقليل الكمية أقل من المحجوز (' || v_reserved_quantity || ')',
            'error_code', 'QUANTITY_BELOW_RESERVED'
        );
    END IF;
    
    -- تحديث الكمية
    UPDATE product_colors 
    SET 
        total_quantity = p_new_quantity,
        available_quantity = p_new_quantity - reserved_quantity - sold_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_color_id;
    
    -- تسجيل في التاريخ
    INSERT INTO product_colors_history (
        color_id, product_id, action_type, old_quantity, new_quantity,
        quantity_change, reason, user_phone
    ) VALUES (
        p_color_id, v_product_id, 'updated', v_old_quantity, p_new_quantity,
        p_new_quantity - v_old_quantity, p_reason, p_user_phone
    );
    
    RETURN json_build_object(
        'success', true,
        'old_quantity', v_old_quantity,
        'new_quantity', p_new_quantity,
        'message', 'تم تحديث الكمية بنجاح'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'خطأ في تحديث الكمية: ' || SQLERRM,
        'error_code', 'INTERNAL_ERROR'
    );
END;
$$ LANGUAGE plpgsql;

-- 🛒 دالة حجز لون للطلب
CREATE OR REPLACE FUNCTION reserve_color_for_order(
    p_color_id UUID,
    p_quantity INTEGER,
    p_order_id VARCHAR(100) DEFAULT NULL,
    p_user_phone VARCHAR(20) DEFAULT NULL,
    p_reservation_type VARCHAR(50) DEFAULT 'order'
) RETURNS JSON AS $$
DECLARE
    v_available_quantity INTEGER;
    v_product_id UUID;
    v_reservation_id UUID;
BEGIN
    -- الحصول على الكمية المتاحة
    SELECT available_quantity, product_id 
    INTO v_available_quantity, v_product_id
    FROM product_colors 
    WHERE id = p_color_id AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'اللون غير موجود أو غير نشط',
            'error_code', 'COLOR_NOT_FOUND'
        );
    END IF;
    
    -- التحقق من توفر الكمية
    IF v_available_quantity < p_quantity THEN
        RETURN json_build_object(
            'success', false,
            'error', 'الكمية المطلوبة غير متوفرة. المتاح: ' || v_available_quantity,
            'error_code', 'INSUFFICIENT_QUANTITY',
            'available_quantity', v_available_quantity
        );
    END IF;
    
    -- إنشاء الحجز
    INSERT INTO color_reservations (
        color_id, product_id, order_id, user_phone, 
        reserved_quantity, reservation_type,
        expires_at
    ) VALUES (
        p_color_id, v_product_id, p_order_id, p_user_phone,
        p_quantity, p_reservation_type,
        CURRENT_TIMESTAMP + INTERVAL '30 minutes' -- انتهاء الحجز بعد 30 دقيقة
    ) RETURNING id INTO v_reservation_id;
    
    -- تحديث الكميات
    UPDATE product_colors 
    SET 
        reserved_quantity = reserved_quantity + p_quantity,
        available_quantity = available_quantity - p_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_color_id;
    
    -- تسجيل في التاريخ
    INSERT INTO product_colors_history (
        color_id, product_id, action_type, quantity_change,
        reason, user_phone, order_id
    ) VALUES (
        p_color_id, v_product_id, 'reserved', p_quantity,
        'حجز لون للطلب', p_user_phone, p_order_id
    );
    
    RETURN json_build_object(
        'success', true,
        'reservation_id', v_reservation_id,
        'reserved_quantity', p_quantity,
        'remaining_available', v_available_quantity - p_quantity,
        'message', 'تم حجز اللون بنجاح'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'خطأ في حجز اللون: ' || SQLERRM,
        'error_code', 'INTERNAL_ERROR'
    );
END;
$$ LANGUAGE plpgsql;

-- 📦 دالة الحصول على ألوان المنتج
CREATE OR REPLACE FUNCTION get_product_colors(
    p_product_id UUID,
    p_include_unavailable BOOLEAN DEFAULT false
) RETURNS JSON AS $$
DECLARE
    v_colors JSON;
BEGIN
    -- التحقق من وجود المنتج
    IF NOT EXISTS (SELECT 1 FROM products WHERE id = p_product_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'المنتج غير موجود',
            'error_code', 'PRODUCT_NOT_FOUND'
        );
    END IF;

    -- جلب الألوان
    SELECT json_agg(
        json_build_object(
            'id', pc.id,
            'product_id', pc.product_id,
            'color_name', pc.color_name,
            'color_code', pc.color_code,
            'color_arabic_name', pc.color_arabic_name,
            'total_quantity', pc.total_quantity,
            'available_quantity', pc.available_quantity,
            'reserved_quantity', pc.reserved_quantity,
            'sold_quantity', pc.sold_quantity,
            'is_active', pc.is_active,
            'display_order', pc.display_order,
            'created_at', pc.created_at,
            'updated_at', pc.updated_at
        ) ORDER BY pc.display_order, pc.created_at
    ) INTO v_colors
    FROM product_colors pc
    WHERE pc.product_id = p_product_id
      AND pc.is_active = true
      AND (p_include_unavailable OR pc.available_quantity > 0);

    RETURN json_build_object(
        'success', true,
        'colors', COALESCE(v_colors, '[]'::json)
    );

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'خطأ في جلب ألوان المنتج: ' || SQLERRM,
        'error_code', 'INTERNAL_ERROR'
    );
END;
$$ LANGUAGE plpgsql;
