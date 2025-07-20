-- ✅ فهارس تحسين الأداء
-- Performance Optimization Indexes
-- تاريخ الإنشاء: 2024-12-20

-- فهارس جدول الطلبات (orders)
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_customer_phone ON orders(primary_phone);
CREATE INDEX IF NOT EXISTS idx_orders_customer_name ON orders(customer_name);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_status_created ON orders(status, created_at);

-- فهارس جدول المنتجات (products)
CREATE INDEX IF NOT EXISTS idx_products_category_active ON products(category, is_active);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_stock_quantity ON products(stock_quantity);
CREATE INDEX IF NOT EXISTS idx_products_available_quantity ON products(available_quantity);
CREATE INDEX IF NOT EXISTS idx_products_name_active ON products(name, is_active);

-- فهارس جدول العملاء (customers)
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers(created_at);

-- فهارس جدول FCM Tokens
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_is_active ON fcm_tokens(is_active);

-- فهارس جدول الإشعارات
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- فهارس جدول المزامنة
CREATE INDEX IF NOT EXISTS idx_sync_logs_created_at ON sync_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_sync_logs_status ON sync_logs(status);
CREATE INDEX IF NOT EXISTS idx_sync_logs_operation_type ON sync_logs(operation_type);

-- فهارس مركبة لتحسين الاستعلامات المعقدة
CREATE INDEX IF NOT EXISTS idx_orders_status_date_customer ON orders(status, created_at, customer_name);
CREATE INDEX IF NOT EXISTS idx_products_category_stock_active ON products(category, stock_quantity, is_active);

-- إحصائيات لتحسين خطط الاستعلام
ANALYZE orders;
ANALYZE products;
ANALYZE customers;
ANALYZE fcm_tokens;
ANALYZE notifications;

-- تحديث إحصائيات الجداول
UPDATE pg_stat_user_tables SET n_tup_ins = 0, n_tup_upd = 0, n_tup_del = 0;

COMMIT;
