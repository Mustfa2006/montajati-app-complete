-- إنشاء جداول لوحة التحكم الإدارية
-- يجب تشغيل هذا الكود في SQL Editor في لوحة تحكم Supabase

-- 1. تحديث جدول المستخدمين لإضافة صلاحية المدير
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- إنشاء مدير افتراضي للاختبار
UPDATE users SET is_admin = TRUE WHERE phone = '01234567890';

-- 2. إنشاء جدول المنتجات
CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  wholesale_price DECIMAL(10,2) NOT NULL,
  min_price DECIMAL(10,2) NOT NULL,
  max_price DECIMAL(10,2) NOT NULL,
  available_quantity INTEGER DEFAULT 0,
  category TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. إنشاء جدول الطلبات
CREATE TABLE IF NOT EXISTS orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_address TEXT NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'in_delivery', 'delivered', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. إنشاء جدول عناصر الطلبات
CREATE TABLE IF NOT EXISTS order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  customer_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. إنشاء جدول طلبات سحب الأرباح
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  withdrawal_method TEXT NOT NULL,
  account_details TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء الفهارس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user_id ON withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);

-- إنشاء دوال التحديث التلقائي
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- إنشاء triggers للتحديث التلقائي
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON products 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON orders 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_withdrawal_requests_updated_at ON withdrawal_requests;
CREATE TRIGGER update_withdrawal_requests_updated_at 
    BEFORE UPDATE ON withdrawal_requests 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- إنشاء Row Level Security
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- سياسات الأمان للمنتجات
DROP POLICY IF EXISTS "Anyone can read products" ON products;
CREATE POLICY "Anyone can read products" ON products
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage products" ON products;
CREATE POLICY "Admins can manage products" ON products
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

-- سياسات الأمان للطلبات
DROP POLICY IF EXISTS "Users can read own orders" ON orders;
CREATE POLICY "Users can read own orders" ON orders
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

DROP POLICY IF EXISTS "Users can create orders" ON orders;
CREATE POLICY "Users can create orders" ON orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can update orders" ON orders;
CREATE POLICY "Admins can update orders" ON orders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

-- سياسات الأمان لعناصر الطلبات
DROP POLICY IF EXISTS "Users can read own order items" ON order_items;
CREATE POLICY "Users can read own order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND (orders.user_id = auth.uid() OR 
                 EXISTS (
                     SELECT 1 FROM users 
                     WHERE users.id = auth.uid() 
                     AND users.is_admin = true
                 ))
        )
    );

DROP POLICY IF EXISTS "Users can create order items" ON order_items;
CREATE POLICY "Users can create order items" ON order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- سياسات الأمان لطلبات السحب
DROP POLICY IF EXISTS "Users can read own withdrawal requests" ON withdrawal_requests;
CREATE POLICY "Users can read own withdrawal requests" ON withdrawal_requests
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

DROP POLICY IF EXISTS "Users can create withdrawal requests" ON withdrawal_requests;
CREATE POLICY "Users can create withdrawal requests" ON withdrawal_requests
    FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can update withdrawal requests" ON withdrawal_requests;
CREATE POLICY "Admins can update withdrawal requests" ON withdrawal_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

-- إدراج بيانات تجريبية للمنتجات
INSERT INTO products (name, description, image_url, wholesale_price, min_price, max_price, available_quantity, category) VALUES 
('هاتف ذكي Samsung Galaxy', 'هاتف ذكي بمواصفات عالية', 'https://via.placeholder.com/300x300', 250000, 300000, 400000, 50, 'إلكترونيات'),
('ساعة ذكية Apple Watch', 'ساعة ذكية متطورة', 'https://via.placeholder.com/300x300', 150000, 200000, 280000, 30, 'إلكترونيات'),
('سماعات لاسلكية', 'سماعات بلوتوث عالية الجودة', 'https://via.placeholder.com/300x300', 50000, 70000, 120000, 100, 'إلكترونيات'),
('حقيبة يد نسائية', 'حقيبة أنيقة للنساء', 'https://via.placeholder.com/300x300', 30000, 45000, 80000, 25, 'أزياء'),
('حذاء رياضي', 'حذاء رياضي مريح', 'https://via.placeholder.com/300x300', 40000, 60000, 100000, 40, 'أزياء')
ON CONFLICT DO NOTHING;

-- إدراج بيانات تجريبية للطلبات
INSERT INTO orders (user_id, customer_name, customer_phone, customer_address, total_amount, status) 
SELECT 
    u.id,
    'أحمد محمد',
    '07801234567',
    'بغداد - الكرادة - شارع الرئيسي',
    350000,
    'active'
FROM users u WHERE u.phone = '01111111111'
ON CONFLICT DO NOTHING;

INSERT INTO orders (user_id, customer_name, customer_phone, customer_address, total_amount, status) 
SELECT 
    u.id,
    'فاطمة علي',
    '07809876543',
    'البصرة - الجمعيات - حي الحسين',
    280000,
    'delivered'
FROM users u WHERE u.phone = '01222222222'
ON CONFLICT DO NOTHING;

-- إدراج بيانات تجريبية لطلبات السحب
INSERT INTO withdrawal_requests (user_id, amount, withdrawal_method, account_details, status) 
SELECT 
    u.id,
    50000,
    'تحويل بنكي',
    'بنك بغداد - 1234567890',
    'pending'
FROM users u WHERE u.phone = '01111111111'
ON CONFLICT DO NOTHING;

-- عرض البيانات للتأكد
SELECT 'المنتجات' as table_name, COUNT(*) as count FROM products
UNION ALL
SELECT 'الطلبات' as table_name, COUNT(*) as count FROM orders
UNION ALL
SELECT 'طلبات السحب' as table_name, COUNT(*) as count FROM withdrawal_requests;

-- ملاحظات مهمة:
-- 1. يجب تشغيل هذا الكود بعد إنشاء جدول المستخدمين
-- 2. تأكد من أن المستخدم بالهاتف 01234567890 موجود ليصبح مدير
-- 3. جميع الجداول محمية بـ RLS للأمان
-- 4. البيانات التجريبية للاختبار فقط
