-- ===================================
-- إعداد قاعدة البيانات لنظام المزامنة التلقائية
-- إنشاء الجداول والفهارس المطلوبة
-- ===================================

-- إضافة أعمدة جديدة لجدول orders إذا لم تكن موجودة
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS last_status_check TIMESTAMP,
ADD COLUMN IF NOT EXISTS waseet_status VARCHAR(50),
ADD COLUMN IF NOT EXISTS waseet_data JSONB;

-- إنشاء جدول سجل حالات الطلبات إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS order_status_history (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES orders(id) ON DELETE CASCADE,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by VARCHAR(100),
    change_reason TEXT,
    waseet_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- إنشاء جدول الإشعارات إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES orders(id) ON DELETE SET NULL,
    customer_phone VARCHAR(20),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    sent_at TIMESTAMP,
    firebase_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- إنشاء جدول سجلات النظام إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    service VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- إضافة عمود FCM token لجدول users إذا لم يكن موجوداً
ALTER TABLE users
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- إنشاء جدول موفري التوصيل إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS delivery_providers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    token TEXT,
    token_expires_at TIMESTAMP,
    config JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- إنشاء الفهارس للأداء
CREATE INDEX IF NOT EXISTS idx_orders_last_status_check ON orders(last_status_check);
CREATE INDEX IF NOT EXISTS idx_orders_waseet_order_id ON orders(waseet_order_id);
CREATE INDEX IF NOT EXISTS idx_orders_status_sync ON orders(status) WHERE status IN ('active', 'in_delivery');

CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_created_at ON order_status_history(created_at);

CREATE INDEX IF NOT EXISTS idx_notifications_order_id ON notifications(order_id);
CREATE INDEX IF NOT EXISTS idx_notifications_customer_phone ON notifications(customer_phone);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

CREATE INDEX IF NOT EXISTS idx_system_logs_event_type ON system_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_system_logs_service ON system_logs(service);
CREATE INDEX IF NOT EXISTS idx_system_logs_created_at ON system_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON users(fcm_token) WHERE fcm_token IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_delivery_providers_name ON delivery_providers(name);
CREATE INDEX IF NOT EXISTS idx_delivery_providers_active ON delivery_providers(is_active);

-- إنشاء دالة لتنظيف السجلات القديمة
CREATE OR REPLACE FUNCTION cleanup_old_logs(retention_days INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- حذف سجلات النظام القديمة
    DELETE FROM system_logs 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- حذف الإشعارات القديمة المرسلة
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days 
    AND status = 'sent';
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- إنشاء دالة للحصول على الطلبات المؤهلة للمزامنة
CREATE OR REPLACE FUNCTION get_orders_for_sync()
RETURNS TABLE (
    id VARCHAR(50),
    order_number VARCHAR(100),
    customer_name VARCHAR(100),
    primary_phone VARCHAR(20),
    status VARCHAR(50),
    waseet_order_id VARCHAR(100),
    last_status_check TIMESTAMP,
    created_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id,
        o.order_number,
        o.customer_name,
        o.primary_phone,
        o.status,
        o.waseet_order_id,
        o.last_status_check,
        o.created_at
    FROM orders o
    WHERE o.status IN ('active', 'in_delivery')
    AND o.waseet_order_id IS NOT NULL
    AND (
        o.last_status_check IS NULL 
        OR o.last_status_check < NOW() - INTERVAL '10 minutes'
    )
    ORDER BY o.created_at ASC;
END;
$$ LANGUAGE plpgsql;

-- إنشاء دالة لتحديث حالة الطلب مع السجل
CREATE OR REPLACE FUNCTION update_order_status_with_history(
    p_order_id VARCHAR(50),
    p_old_status VARCHAR(50),
    p_new_status VARCHAR(50),
    p_waseet_status VARCHAR(50),
    p_waseet_data JSONB,
    p_changed_by VARCHAR(100) DEFAULT 'system_sync',
    p_change_reason TEXT DEFAULT 'تحديث تلقائي من شركة الوسيط'
)
RETURNS BOOLEAN AS $$
DECLARE
    update_success BOOLEAN := FALSE;
BEGIN
    -- بدء المعاملة
    BEGIN
        -- تحديث الطلب
        UPDATE orders 
        SET 
            status = p_new_status,
            waseet_status = p_waseet_status,
            waseet_data = p_waseet_data,
            last_status_check = NOW(),
            updated_at = NOW()
        WHERE id = p_order_id;
        
        -- التحقق من نجاح التحديث
        IF FOUND THEN
            -- إضافة سجل في تاريخ الحالات
            INSERT INTO order_status_history (
                order_id,
                old_status,
                new_status,
                changed_by,
                change_reason,
                waseet_response,
                created_at
            ) VALUES (
                p_order_id,
                p_old_status,
                p_new_status,
                p_changed_by,
                p_change_reason,
                p_waseet_data,
                NOW()
            );
            
            update_success := TRUE;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        -- في حالة الخطأ، إرجاع false
        update_success := FALSE;
    END;
    
    RETURN update_success;
END;
$$ LANGUAGE plpgsql;

-- إنشاء دالة للحصول على إحصائيات المزامنة
CREATE OR REPLACE FUNCTION get_sync_statistics(days_back INTEGER DEFAULT 7)
RETURNS TABLE (
    total_orders INTEGER,
    orders_needing_sync INTEGER,
    successful_syncs_today INTEGER,
    failed_syncs_today INTEGER,
    last_sync_time TIMESTAMP,
    avg_sync_duration INTERVAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM orders WHERE status IN ('active', 'in_delivery')) as total_orders,
        (SELECT COUNT(*)::INTEGER FROM get_orders_for_sync()) as orders_needing_sync,
        (SELECT COUNT(*)::INTEGER FROM system_logs 
         WHERE event_type = 'sync_cycle_complete' 
         AND created_at >= CURRENT_DATE) as successful_syncs_today,
        (SELECT COUNT(*)::INTEGER FROM system_logs 
         WHERE event_type = 'sync_cycle_error' 
         AND created_at >= CURRENT_DATE) as failed_syncs_today,
        (SELECT MAX(created_at) FROM system_logs 
         WHERE event_type = 'sync_cycle_complete') as last_sync_time,
        (SELECT AVG((event_data->>'duration_ms')::INTEGER * INTERVAL '1 millisecond') 
         FROM system_logs 
         WHERE event_type = 'sync_cycle_complete' 
         AND created_at >= NOW() - INTERVAL '1 day' * days_back) as avg_sync_duration;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger لتسجيل تغييرات حالة الطلبات
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- إذا تغيرت الحالة، سجل التغيير
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (
            order_id,
            old_status,
            new_status,
            changed_by,
            change_reason,
            created_at
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            'system_trigger',
            'تغيير تلقائي عبر trigger',
            NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger على جدول orders
DROP TRIGGER IF EXISTS trigger_order_status_change ON orders;
CREATE TRIGGER trigger_order_status_change
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();

-- إدراج بيانات تجريبية للاختبار (اختيارية)
-- INSERT INTO system_logs (event_type, event_data, service) VALUES
-- ('sync_service_initialized', '{"version": "1.0.0", "timestamp": "' || NOW() || '"}', 'order_status_sync');

-- عرض ملخص الإعداد
SELECT 
    'تم إعداد قاعدة البيانات بنجاح' as message,
    NOW() as setup_time,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('orders', 'order_status_history', 'notifications', 'system_logs', 'users')) as tables_ready,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%sync%' OR routine_name LIKE '%cleanup%') as functions_created;
