-- ===================================
-- إنشاء جدول الإشعارات الجماعية
-- Create Bulk Notifications Table
-- ===================================

-- إنشاء جدول الإشعارات
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'general',
    status VARCHAR(50) DEFAULT 'sent',
    recipients_count INTEGER DEFAULT 0,
    delivery_rate INTEGER DEFAULT 0,
    sent_at TIMESTAMP WITH TIME ZONE,
    scheduled_for TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notification_data JSONB,
    created_by VARCHAR(100),
    
    -- فهارس للبحث السريع
    INDEX idx_notifications_status (status),
    INDEX idx_notifications_type (type),
    INDEX idx_notifications_created_at (created_at),
    INDEX idx_notifications_sent_at (sent_at)
);

-- إضافة تعليقات للجدول والحقول
COMMENT ON TABLE notifications IS 'جدول الإشعارات الجماعية المرسلة لجميع المستخدمين';
COMMENT ON COLUMN notifications.id IS 'المعرف الفريد للإشعار';
COMMENT ON COLUMN notifications.title IS 'عنوان الإشعار';
COMMENT ON COLUMN notifications.body IS 'محتوى الإشعار';
COMMENT ON COLUMN notifications.type IS 'نوع الإشعار (general, promotion, update, urgent)';
COMMENT ON COLUMN notifications.status IS 'حالة الإشعار (sent, scheduled, failed)';
COMMENT ON COLUMN notifications.recipients_count IS 'عدد المستقبلين';
COMMENT ON COLUMN notifications.delivery_rate IS 'معدل التسليم بالنسبة المئوية';
COMMENT ON COLUMN notifications.sent_at IS 'تاريخ ووقت الإرسال الفعلي';
COMMENT ON COLUMN notifications.scheduled_for IS 'تاريخ ووقت الإرسال المجدول';
COMMENT ON COLUMN notifications.created_at IS 'تاريخ إنشاء السجل';
COMMENT ON COLUMN notifications.updated_at IS 'تاريخ آخر تحديث';
COMMENT ON COLUMN notifications.notification_data IS 'بيانات إضافية للإشعار (JSON)';
COMMENT ON COLUMN notifications.created_by IS 'المستخدم الذي أنشأ الإشعار';

-- إنشاء جدول إحصائيات الإشعارات
CREATE TABLE IF NOT EXISTS notification_stats (
    id SERIAL PRIMARY KEY,
    total_sent INTEGER DEFAULT 0,
    total_delivered INTEGER DEFAULT 0,
    total_opened INTEGER DEFAULT 0,
    total_clicked INTEGER DEFAULT 0,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- فهرس فريد للتاريخ
    UNIQUE(date)
);

COMMENT ON TABLE notification_stats IS 'إحصائيات الإشعارات اليومية';
COMMENT ON COLUMN notification_stats.total_sent IS 'إجمالي الإشعارات المرسلة';
COMMENT ON COLUMN notification_stats.total_delivered IS 'إجمالي الإشعارات المسلمة';
COMMENT ON COLUMN notification_stats.total_opened IS 'إجمالي الإشعارات المفتوحة';
COMMENT ON COLUMN notification_stats.total_clicked IS 'إجمالي الإشعارات المنقورة';

-- إنشاء جدول تفاصيل إرسال الإشعارات
CREATE TABLE IF NOT EXISTS notification_deliveries (
    id SERIAL PRIMARY KEY,
    notification_id INTEGER REFERENCES notifications(id) ON DELETE CASCADE,
    user_phone VARCHAR(20) NOT NULL,
    fcm_token TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- فهارس للبحث السريع
    INDEX idx_deliveries_notification_id (notification_id),
    INDEX idx_deliveries_user_phone (user_phone),
    INDEX idx_deliveries_status (status)
);

COMMENT ON TABLE notification_deliveries IS 'تفاصيل إرسال الإشعارات لكل مستخدم';
COMMENT ON COLUMN notification_deliveries.notification_id IS 'معرف الإشعار';
COMMENT ON COLUMN notification_deliveries.user_phone IS 'رقم هاتف المستخدم';
COMMENT ON COLUMN notification_deliveries.fcm_token IS 'رمز FCM المستخدم';
COMMENT ON COLUMN notification_deliveries.status IS 'حالة التسليم (pending, delivered, failed)';
COMMENT ON COLUMN notification_deliveries.delivered_at IS 'تاريخ التسليم';
COMMENT ON COLUMN notification_deliveries.opened_at IS 'تاريخ فتح الإشعار';
COMMENT ON COLUMN notification_deliveries.clicked_at IS 'تاريخ النقر على الإشعار';
COMMENT ON COLUMN notification_deliveries.error_message IS 'رسالة الخطأ في حالة الفشل';

-- دالة لتحديث إحصائيات الإشعارات
CREATE OR REPLACE FUNCTION update_notification_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- تحديث الإحصائيات عند إضافة أو تحديث تسليم إشعار
    INSERT INTO notification_stats (
        date,
        total_sent,
        total_delivered,
        total_opened,
        total_clicked
    )
    VALUES (
        CURRENT_DATE,
        (SELECT COUNT(*) FROM notification_deliveries WHERE DATE(created_at) = CURRENT_DATE),
        (SELECT COUNT(*) FROM notification_deliveries WHERE DATE(delivered_at) = CURRENT_DATE),
        (SELECT COUNT(*) FROM notification_deliveries WHERE DATE(opened_at) = CURRENT_DATE),
        (SELECT COUNT(*) FROM notification_deliveries WHERE DATE(clicked_at) = CURRENT_DATE)
    )
    ON CONFLICT (date) DO UPDATE SET
        total_sent = EXCLUDED.total_sent,
        total_delivered = EXCLUDED.total_delivered,
        total_opened = EXCLUDED.total_opened,
        total_clicked = EXCLUDED.total_clicked,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger لتحديث الإحصائيات تلقائياً
CREATE TRIGGER trigger_update_notification_stats
    AFTER INSERT OR UPDATE ON notification_deliveries
    FOR EACH ROW
    EXECUTE FUNCTION update_notification_stats();

-- إدراج سجل إحصائيات أولي
INSERT INTO notification_stats (date) VALUES (CURRENT_DATE)
ON CONFLICT (date) DO NOTHING;

-- منح الصلاحيات المطلوبة
GRANT ALL PRIVILEGES ON TABLE notifications TO postgres;
GRANT ALL PRIVILEGES ON TABLE notification_stats TO postgres;
GRANT ALL PRIVILEGES ON TABLE notification_deliveries TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- إنشاء فهارس إضافية للأداء
CREATE INDEX IF NOT EXISTS idx_notifications_composite 
ON notifications(status, type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_deliveries_composite 
ON notification_deliveries(notification_id, status, delivered_at DESC);

-- دالة للحصول على إحصائيات شاملة
CREATE OR REPLACE FUNCTION get_notification_statistics()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_sent', COALESCE(SUM(total_sent), 0),
        'total_delivered', COALESCE(SUM(total_delivered), 0),
        'total_opened', COALESCE(SUM(total_opened), 0),
        'total_clicked', COALESCE(SUM(total_clicked), 0),
        'last_updated', MAX(updated_at)
    ) INTO result
    FROM notification_stats;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- دالة للحصول على تاريخ الإشعارات
CREATE OR REPLACE FUNCTION get_notification_history(limit_count INTEGER DEFAULT 50)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', id,
            'title', title,
            'body', body,
            'type', type,
            'status', status,
            'recipients_count', recipients_count,
            'delivery_rate', delivery_rate,
            'sent_at', sent_at,
            'created_at', created_at
        )
        ORDER BY created_at DESC
    ) INTO result
    FROM notifications
    LIMIT limit_count;
    
    RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_notification_statistics() IS 'دالة للحصول على إحصائيات الإشعارات الشاملة';
COMMENT ON FUNCTION get_notification_history(INTEGER) IS 'دالة للحصول على تاريخ الإشعارات المرسلة';

-- إنشاء view للإحصائيات السريعة
CREATE OR REPLACE VIEW notification_summary AS
SELECT 
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent_count,
    COUNT(CASE WHEN status = 'scheduled' THEN 1 END) as scheduled_count,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_count,
    SUM(recipients_count) as total_recipients,
    AVG(delivery_rate) as avg_delivery_rate,
    MAX(created_at) as last_notification_date
FROM notifications;

COMMENT ON VIEW notification_summary IS 'ملخص سريع لإحصائيات الإشعارات';

-- إنشاء view للإشعارات الحديثة
CREATE OR REPLACE VIEW recent_notifications AS
SELECT 
    id,
    title,
    body,
    type,
    status,
    recipients_count,
    delivery_rate,
    sent_at,
    created_at,
    CASE 
        WHEN status = 'sent' THEN '✅ تم الإرسال'
        WHEN status = 'scheduled' THEN '⏰ مجدول'
        WHEN status = 'failed' THEN '❌ فشل'
        ELSE '❓ غير معروف'
    END as status_display
FROM notifications
ORDER BY created_at DESC
LIMIT 20;

COMMENT ON VIEW recent_notifications IS 'الإشعارات الحديثة مع عرض حالة مفهومة';

-- إنشاء فهارس للـ views
CREATE INDEX IF NOT EXISTS idx_notifications_recent 
ON notifications(created_at DESC) 
WHERE created_at >= NOW() - INTERVAL '30 days';

-- إضافة constraint للتحقق من صحة البيانات
ALTER TABLE notifications 
ADD CONSTRAINT check_delivery_rate 
CHECK (delivery_rate >= 0 AND delivery_rate <= 100);

ALTER TABLE notifications 
ADD CONSTRAINT check_recipients_count 
CHECK (recipients_count >= 0);

-- إضافة constraint لأنواع الإشعارات المسموحة
ALTER TABLE notifications 
ADD CONSTRAINT check_notification_type 
CHECK (type IN ('general', 'promotion', 'update', 'urgent'));

-- إضافة constraint لحالات الإشعارات المسموحة
ALTER TABLE notifications 
ADD CONSTRAINT check_notification_status 
CHECK (status IN ('sent', 'scheduled', 'failed', 'pending'));

-- إنشاء دالة لتنظيف الإشعارات القديمة
CREATE OR REPLACE FUNCTION cleanup_old_notifications(days_old INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '1 day' * days_old
    AND status IN ('sent', 'failed');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_notifications(INTEGER) IS 'دالة لتنظيف الإشعارات القديمة (افتراضي: 90 يوم)';

-- إنشاء مهمة تنظيف دورية (يمكن تفعيلها لاحقاً)
-- SELECT cron.schedule('cleanup-old-notifications', '0 2 * * 0', 'SELECT cleanup_old_notifications(90);');

-- إنهاء السكريبت
SELECT 'تم إنشاء جداول ودوال الإشعارات بنجاح!' as result;
