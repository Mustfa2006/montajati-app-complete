-- ===================================
-- إنشاء جدول قائمة انتظار الإشعارات
-- ===================================

-- إنشاء جدول قائمة انتظار الإشعارات
CREATE TABLE IF NOT EXISTS notification_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    user_phone VARCHAR(20) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    notification_data JSONB NOT NULL,
    priority INTEGER DEFAULT 1,
    max_retries INTEGER DEFAULT 3,
    retry_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'sent', 'failed')),
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء فهارس للأداء
CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_notification_queue_scheduled_at ON notification_queue(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_notification_queue_priority ON notification_queue(priority);
CREATE INDEX IF NOT EXISTS idx_notification_queue_user_phone ON notification_queue(user_phone);
CREATE INDEX IF NOT EXISTS idx_notification_queue_order_id ON notification_queue(order_id);

-- إنشاء دالة إنشاء رسالة الإشعار الذكية
CREATE OR REPLACE FUNCTION generate_smart_notification_message(
    customer_name VARCHAR(255),
    old_status VARCHAR(50),
    new_status VARCHAR(50)
) RETURNS JSONB AS $$
DECLARE
    notification_data JSONB;
    title TEXT;
    message TEXT;
    emoji TEXT;
    priority INTEGER;
BEGIN
    -- تحديد الرسالة والإيموجي حسب الحالة الجديدة
    CASE new_status
        WHEN 'in_delivery' THEN
            title := 'قيد التوصيل 🚗';
            message := customer_name || ' - قيد التوصيل 🚗';
            emoji := '🚗';
            priority := 2;
            
        WHEN 'delivered' THEN
            title := 'تم التوصيل 😊';
            message := customer_name || ' - تم التوصيل 😊';
            emoji := '😊';
            priority := 3;
            
        WHEN 'cancelled' THEN
            title := 'ملغي 😢';
            message := customer_name || ' - ملغي 😢';
            emoji := '😢';
            priority := 2;
            
        ELSE
            title := 'تحديث حالة الطلب';
            message := customer_name || ' - تم تحديث حالة الطلب إلى: ' || new_status;
            emoji := '📋';
            priority := 1;
    END CASE;
    
    -- إنشاء بيانات الإشعار
    notification_data := jsonb_build_object(
        'title', title,
        'message', message,
        'emoji', emoji,
        'priority', priority,
        'type', 'order_status_change',
        'old_status', old_status,
        'new_status', new_status,
        'customer_name', customer_name,
        'timestamp', EXTRACT(EPOCH FROM NOW())::bigint,
        'sound', 'default',
        'vibration', true
    );
    
    RETURN notification_data;
END;
$$ LANGUAGE plpgsql;

-- دالة الحصول على رقم هاتف المستخدم من الطلب
CREATE OR REPLACE FUNCTION get_user_phone_from_order(order_record RECORD)
RETURNS VARCHAR(20) AS $$
DECLARE
    user_phone VARCHAR(20);
BEGIN
    -- محاولة 1: من primary_phone مباشرة
    IF order_record.primary_phone IS NOT NULL THEN
        RETURN order_record.primary_phone;
    END IF;
    
    -- محاولة 2: من customer_phone
    IF order_record.customer_phone IS NOT NULL THEN
        RETURN order_record.customer_phone;
    END IF;
    
    -- إذا لم نجد أي رقم
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- دالة إضافة إشعار لقائمة الانتظار
CREATE OR REPLACE FUNCTION queue_smart_notification()
RETURNS TRIGGER AS $$
DECLARE
    user_phone VARCHAR(20);
    notification_data JSONB;
    customer_name_safe VARCHAR(255);
BEGIN
    -- التحقق من تغيير حالة الطلب فقط
    IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
        RETURN NEW;
    END IF;
    
    -- الحصول على رقم هاتف المستخدم
    user_phone := get_user_phone_from_order(NEW);
    
    IF user_phone IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- إعداد اسم العميل الآمن
    customer_name_safe := COALESCE(NEW.customer_name, 'عميل غير محدد');
    
    -- إنشاء بيانات الإشعار الذكية
    notification_data := generate_smart_notification_message(
        customer_name_safe,
        OLD.status,
        NEW.status
    );
    
    -- إضافة الإشعار لقائمة الانتظار
    INSERT INTO notification_queue (
        order_id,
        user_phone,
        customer_name,
        old_status,
        new_status,
        notification_data,
        priority,
        scheduled_at
    ) VALUES (
        NEW.id,
        user_phone,
        customer_name_safe,
        OLD.status,
        NEW.status,
        notification_data,
        (notification_data->>'priority')::INTEGER,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء Trigger ذكي لمراقبة تغيير status
DROP TRIGGER IF EXISTS smart_notification_trigger ON orders;

CREATE TRIGGER smart_notification_trigger
    AFTER UPDATE ON orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION queue_smart_notification();

-- إدراج إشعار اختبار للتأكد من عمل الجدول
INSERT INTO notification_queue (
    order_id,
    user_phone,
    customer_name,
    old_status,
    new_status,
    notification_data,
    priority,
    status
) VALUES (
    'INIT-TEST',
    '07503597589',
    'اختبار النظام',
    'active',
    'in_delivery',
    '{"title": "قيد التوصيل 🚗", "message": "اختبار النظام - قيد التوصيل 🚗", "emoji": "🚗", "type": "order_status_change"}',
    2,
    'pending'
);

-- عرض رسالة نجاح
SELECT 'تم إنشاء نظام الإشعارات الذكي بنجاح!' as status;
