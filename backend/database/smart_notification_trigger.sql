-- ===================================
-- نظام إشعارات ذكي مبني على تغيير عمود status
-- ===================================

-- إنشاء جدول سجل الإشعارات المرسلة لتجنب التكرار
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    user_phone VARCHAR(20) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    status_change VARCHAR(100) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    fcm_token TEXT,
    firebase_response JSONB,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_successful BOOLEAN DEFAULT false,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء فهارس للأداء
CREATE INDEX IF NOT EXISTS idx_notification_logs_order_id ON notification_logs(order_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_phone ON notification_logs(user_phone);
CREATE INDEX IF NOT EXISTS idx_notification_logs_sent_at ON notification_logs(sent_at);

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

-- إنشاء فهارس لقائمة الانتظار
CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_notification_queue_scheduled_at ON notification_queue(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_notification_queue_priority ON notification_queue(priority);

-- ===================================
-- دالة إنشاء رسالة الإشعار الذكية
-- ===================================
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

-- ===================================
-- دالة الحصول على رقم هاتف المستخدم من الطلب
-- ===================================
CREATE OR REPLACE FUNCTION get_user_phone_from_order(order_record RECORD)
RETURNS VARCHAR(20) AS $$
DECLARE
    user_phone VARCHAR(20);
BEGIN
    -- محاولة 1: من customer_id إذا كان موجود
    IF order_record.customer_id IS NOT NULL THEN
        SELECT phone INTO user_phone 
        FROM users 
        WHERE id = order_record.customer_id;
        
        IF user_phone IS NOT NULL THEN
            RETURN user_phone;
        END IF;
    END IF;
    
    -- محاولة 2: من primary_phone مباشرة
    IF order_record.primary_phone IS NOT NULL THEN
        RETURN order_record.primary_phone;
    END IF;
    
    -- محاولة 3: من customer_phone
    IF order_record.customer_phone IS NOT NULL THEN
        RETURN order_record.customer_phone;
    END IF;
    
    -- إذا لم نجد أي رقم
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- دالة التحقق من عدم تكرار الإشعار
-- ===================================
CREATE OR REPLACE FUNCTION is_notification_already_sent(
    p_order_id VARCHAR(50),
    p_user_phone VARCHAR(20),
    p_status_change VARCHAR(100)
) RETURNS BOOLEAN AS $$
DECLARE
    notification_count INTEGER;
BEGIN
    -- التحقق من وجود إشعار مرسل خلال آخر 5 دقائق
    SELECT COUNT(*) INTO notification_count
    FROM notification_logs
    WHERE order_id = p_order_id
      AND user_phone = p_user_phone
      AND status_change = p_status_change
      AND sent_at > NOW() - INTERVAL '5 minutes'
      AND is_successful = true;
    
    RETURN notification_count > 0;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- دالة إضافة إشعار لقائمة الانتظار
-- ===================================
CREATE OR REPLACE FUNCTION queue_smart_notification()
RETURNS TRIGGER AS $$
DECLARE
    user_phone VARCHAR(20);
    notification_data JSONB;
    status_change_text VARCHAR(100);
    customer_name_safe VARCHAR(255);
BEGIN
    -- التحقق من تغيير حالة الطلب فقط
    IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
        RETURN NEW;
    END IF;
    
    -- الحصول على رقم هاتف المستخدم
    user_phone := get_user_phone_from_order(NEW);
    
    IF user_phone IS NULL THEN
        RAISE NOTICE 'تحذير: لا يمكن العثور على رقم هاتف للطلب %', NEW.id;
        RETURN NEW;
    END IF;
    
    -- إعداد اسم العميل الآمن
    customer_name_safe := COALESCE(NEW.customer_name, 'عميل غير محدد');
    
    -- إنشاء نص تغيير الحالة
    status_change_text := COALESCE(OLD.status, 'غير محدد') || ' -> ' || NEW.status;
    
    -- التحقق من عدم تكرار الإشعار
    IF is_notification_already_sent(NEW.id, user_phone, status_change_text) THEN
        RAISE NOTICE 'تم تجاهل الإشعار المكرر للطلب % والمستخدم %', NEW.id, user_phone;
        RETURN NEW;
    END IF;
    
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
    
    RAISE NOTICE 'تم إضافة إشعار ذكي لقائمة الانتظار: الطلب=% المستخدم=% الحالة=%', 
                 NEW.id, user_phone, status_change_text;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- إنشاء Trigger ذكي لمراقبة تغيير status
-- ===================================
DROP TRIGGER IF EXISTS smart_notification_trigger ON orders;

CREATE TRIGGER smart_notification_trigger
    AFTER UPDATE ON orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION queue_smart_notification();

-- ===================================
-- دالة تنظيف السجلات القديمة
-- ===================================
CREATE OR REPLACE FUNCTION cleanup_old_notification_data()
RETURNS void AS $$
BEGIN
    -- حذف سجلات الإشعارات الأقدم من 30 يوم
    DELETE FROM notification_logs 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- حذف الإشعارات المرسلة من قائمة الانتظار الأقدم من 7 أيام
    DELETE FROM notification_queue 
    WHERE status = 'sent' AND processed_at < NOW() - INTERVAL '7 days';
    
    -- حذف الإشعارات الفاشلة الأقدم من 3 أيام
    DELETE FROM notification_queue 
    WHERE status = 'failed' AND created_at < NOW() - INTERVAL '3 days';
    
    RAISE NOTICE 'تم تنظيف البيانات القديمة للإشعارات';
END;
$$ LANGUAGE plpgsql;

-- إنشاء مهمة تنظيف تلقائية (إذا كان pg_cron متاح)
-- SELECT cron.schedule('cleanup-notifications', '0 2 * * *', 'SELECT cleanup_old_notification_data();');

RAISE NOTICE '✅ تم إنشاء نظام الإشعارات الذكي بنجاح!';
