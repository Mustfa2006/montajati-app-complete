-- ===================================
-- إعداد قاعدة البيانات للنظام الإنتاجي
-- Production System Database Setup
-- ===================================

-- جدول سجلات المزامنة
CREATE TABLE IF NOT EXISTS sync_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    operation_id TEXT NOT NULL,
    sync_type TEXT NOT NULL DEFAULT 'full_sync',
    success BOOLEAN NOT NULL,
    orders_processed INTEGER DEFAULT 0,
    orders_updated INTEGER DEFAULT 0,
    duration_ms INTEGER DEFAULT 0,
    error_message TEXT,
    sync_timestamp TIMESTAMPTZ DEFAULT NOW(),
    service_version TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- فهرس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_sync_logs_timestamp ON sync_logs(sync_timestamp);
CREATE INDEX IF NOT EXISTS idx_sync_logs_success ON sync_logs(success);
CREATE INDEX IF NOT EXISTS idx_sync_logs_type ON sync_logs(sync_type);

-- جدول سجلات النظام
CREATE TABLE IF NOT EXISTS system_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    level TEXT NOT NULL,
    category TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    pid INTEGER,
    memory_usage BIGINT,
    system_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_system_logs_timestamp ON system_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_system_logs_level ON system_logs(level);
CREATE INDEX IF NOT EXISTS idx_system_logs_category ON system_logs(category);

-- جدول التنبيهات
CREATE TABLE IF NOT EXISTS system_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    level TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    system_name TEXT,
    system_version TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    resolved_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- فهارس للتنبيهات
CREATE INDEX IF NOT EXISTS idx_system_alerts_timestamp ON system_alerts(timestamp);
CREATE INDEX IF NOT EXISTS idx_system_alerts_level ON system_alerts(level);
CREATE INDEX IF NOT EXISTS idx_system_alerts_resolved ON system_alerts(resolved);

-- جدول إحصائيات الأداء
CREATE TABLE IF NOT EXISTS performance_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC NOT NULL,
    metric_unit TEXT,
    timestamp TIMESTAMPTZ NOT NULL,
    system_component TEXT,
    additional_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- فهارس للإحصائيات
CREATE INDEX IF NOT EXISTS idx_performance_metrics_timestamp ON performance_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_name ON performance_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_component ON performance_metrics(system_component);

-- تحديث جدول الطلبات (إضافة أعمدة جديدة إذا لم تكن موجودة)
DO $$ 
BEGIN
    -- إضافة عمود last_status_check إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' AND column_name = 'last_status_check'
    ) THEN
        ALTER TABLE orders ADD COLUMN last_status_check TIMESTAMPTZ;
    END IF;

    -- إضافة عمود status_updated_at إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' AND column_name = 'status_updated_at'
    ) THEN
        ALTER TABLE orders ADD COLUMN status_updated_at TIMESTAMPTZ;
    END IF;

    -- إضافة عمود sync_metadata إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' AND column_name = 'sync_metadata'
    ) THEN
        ALTER TABLE orders ADD COLUMN sync_metadata JSONB;
    END IF;
END $$;

-- تحديث جدول تاريخ تغيير الحالات (إضافة أعمدة جديدة)
DO $$ 
BEGIN
    -- إضافة أعمدة حالة الوسيط إذا لم تكن موجودة
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'order_status_history' AND column_name = 'old_waseet_status'
    ) THEN
        ALTER TABLE order_status_history ADD COLUMN old_waseet_status TEXT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'order_status_history' AND column_name = 'new_waseet_status'
    ) THEN
        ALTER TABLE order_status_history ADD COLUMN new_waseet_status TEXT;
    END IF;

    -- إضافة عمود بيانات الوسيط إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'order_status_history' AND column_name = 'waseet_data'
    ) THEN
        ALTER TABLE order_status_history ADD COLUMN waseet_data JSONB;
    END IF;
END $$;

-- إنشاء فهارس إضافية لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_orders_last_status_check ON orders(last_status_check);
CREATE INDEX IF NOT EXISTS idx_orders_status_updated_at ON orders(status_updated_at);
CREATE INDEX IF NOT EXISTS idx_orders_waseet_order_id ON orders(waseet_order_id) WHERE waseet_order_id IS NOT NULL;

-- إنشاء view للإحصائيات السريعة
CREATE OR REPLACE VIEW sync_statistics AS
SELECT 
    DATE(sync_timestamp) as sync_date,
    COUNT(*) as total_syncs,
    COUNT(*) FILTER (WHERE success = true) as successful_syncs,
    COUNT(*) FILTER (WHERE success = false) as failed_syncs,
    ROUND(AVG(duration_ms)) as avg_duration_ms,
    SUM(orders_processed) as total_orders_processed,
    SUM(orders_updated) as total_orders_updated
FROM sync_logs
GROUP BY DATE(sync_timestamp)
ORDER BY sync_date DESC;

-- إنشاء view لإحصائيات الحالات
CREATE OR REPLACE VIEW status_distribution AS
SELECT 
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM orders
GROUP BY status
ORDER BY count DESC;

-- إنشاء view للطلبات التي تحتاج مزامنة
CREATE OR REPLACE VIEW orders_needing_sync AS
SELECT 
    id,
    order_number,
    waseet_order_id,
    status,
    waseet_status,
    last_status_check,
    CASE 
        WHEN last_status_check IS NULL THEN 'never_checked'
        WHEN last_status_check < NOW() - INTERVAL '10 minutes' THEN 'needs_check'
        ELSE 'recently_checked'
    END as sync_priority
FROM orders
WHERE waseet_order_id IS NOT NULL
ORDER BY 
    CASE 
        WHEN last_status_check IS NULL THEN 1
        WHEN last_status_check < NOW() - INTERVAL '10 minutes' THEN 2
        ELSE 3
    END,
    last_status_check ASC NULLS FIRST;

-- إنشاء view لصحة النظام
CREATE OR REPLACE VIEW system_health_summary AS
SELECT 
    'sync_service' as component,
    CASE 
        WHEN MAX(sync_timestamp) > NOW() - INTERVAL '10 minutes' THEN 'healthy'
        WHEN MAX(sync_timestamp) > NOW() - INTERVAL '30 minutes' THEN 'warning'
        ELSE 'critical'
    END as health_status,
    MAX(sync_timestamp) as last_activity,
    COUNT(*) FILTER (WHERE sync_timestamp > NOW() - INTERVAL '1 hour') as recent_activities
FROM sync_logs
UNION ALL
SELECT 
    'alert_system' as component,
    CASE 
        WHEN COUNT(*) FILTER (WHERE level = 'critical' AND timestamp > NOW() - INTERVAL '1 hour') = 0 THEN 'healthy'
        WHEN COUNT(*) FILTER (WHERE level = 'critical' AND timestamp > NOW() - INTERVAL '1 hour') < 5 THEN 'warning'
        ELSE 'critical'
    END as health_status,
    MAX(timestamp) as last_activity,
    COUNT(*) FILTER (WHERE timestamp > NOW() - INTERVAL '1 hour') as recent_activities
FROM system_alerts;

-- إنشاء functions مفيدة

-- function لتنظيف السجلات القديمة
CREATE OR REPLACE FUNCTION cleanup_old_logs(days_to_keep INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- تنظيف سجلات المزامنة القديمة
    DELETE FROM sync_logs 
    WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- تنظيف سجلات النظام القديمة
    DELETE FROM system_logs 
    WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
    
    -- تنظيف التنبيهات المحلولة القديمة
    DELETE FROM system_alerts 
    WHERE resolved = true AND resolved_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
    
    -- تنظيف إحصائيات الأداء القديمة
    DELETE FROM performance_metrics 
    WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- function لحساب إحصائيات المزامنة
CREATE OR REPLACE FUNCTION get_sync_stats(hours_back INTEGER DEFAULT 24)
RETURNS TABLE(
    total_syncs BIGINT,
    successful_syncs BIGINT,
    failed_syncs BIGINT,
    success_rate NUMERIC,
    avg_duration_ms NUMERIC,
    total_orders_processed BIGINT,
    total_orders_updated BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_syncs,
        COUNT(*) FILTER (WHERE success = true) as successful_syncs,
        COUNT(*) FILTER (WHERE success = false) as failed_syncs,
        ROUND(
            COUNT(*) FILTER (WHERE success = true) * 100.0 / NULLIF(COUNT(*), 0), 
            2
        ) as success_rate,
        ROUND(AVG(duration_ms), 0) as avg_duration_ms,
        COALESCE(SUM(orders_processed), 0) as total_orders_processed,
        COALESCE(SUM(orders_updated), 0) as total_orders_updated
    FROM sync_logs
    WHERE sync_timestamp > NOW() - (hours_back || ' hours')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- إنشاء triggers للتحديث التلقائي

-- trigger لتحديث status_updated_at عند تغيير الحالة
CREATE OR REPLACE FUNCTION update_status_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        NEW.status_updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger إذا لم يكن موجوداً
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_update_status_timestamp'
    ) THEN
        CREATE TRIGGER trigger_update_status_timestamp
            BEFORE UPDATE ON orders
            FOR EACH ROW
            EXECUTE FUNCTION update_status_timestamp();
    END IF;
END $$;

-- إدراج بيانات تجريبية للاختبار (اختياري)
INSERT INTO sync_logs (operation_id, sync_type, success, orders_processed, orders_updated, duration_ms, sync_timestamp, service_version)
VALUES 
    ('initial_setup', 'setup', true, 0, 0, 100, NOW(), '1.0.0')
ON CONFLICT DO NOTHING;

-- إنشاء مستخدم للنظام الإنتاجي (اختياري)
-- CREATE USER montajati_sync_user WITH PASSWORD 'secure_password';
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO montajati_sync_user;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO montajati_sync_user;

-- تعليقات على الجداول
COMMENT ON TABLE sync_logs IS 'سجلات عمليات المزامنة مع شركة الوسيط';
COMMENT ON TABLE system_logs IS 'سجلات النظام العامة';
COMMENT ON TABLE system_alerts IS 'تنبيهات النظام والمشاكل';
COMMENT ON TABLE performance_metrics IS 'مقاييس أداء النظام';

COMMENT ON VIEW sync_statistics IS 'إحصائيات المزامنة اليومية';
COMMENT ON VIEW status_distribution IS 'توزيع حالات الطلبات';
COMMENT ON VIEW orders_needing_sync IS 'الطلبات التي تحتاج مزامنة';
COMMENT ON VIEW system_health_summary IS 'ملخص صحة النظام';

-- إنهاء الإعداد
SELECT 'تم إعداد قاعدة البيانات للنظام الإنتاجي بنجاح' as setup_status;
