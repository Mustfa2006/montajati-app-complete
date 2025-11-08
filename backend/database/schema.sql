-- إنشاء جداول قاعدة البيانات لتطبيق منتجاتي

-- جدول المستخدمين
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    avatar_url TEXT,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    is_active BOOLEAN DEFAULT true,
    is_email_verified BOOLEAN DEFAULT false,
    total_products INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_sales DECIMAL(10, 2) DEFAULT 0,
    last_login TIMESTAMP
    WITH
        TIME ZONE,
        password_changed_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        email_verification_token VARCHAR(255),
        email_verification_expires TIMESTAMP
    WITH
        TIME ZONE,
        password_reset_token VARCHAR(255),
        password_reset_expires TIMESTAMP
    WITH
        TIME ZONE,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- جدول المنتجات
CREATE TABLE IF NOT EXISTS products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    wholesale_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    sku VARCHAR(100) UNIQUE,
    category VARCHAR(100),
    tags TEXT[],
    images TEXT[],
    stock_quantity INTEGER DEFAULT 0,
    min_stock_level INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    weight DECIMAL(8,2),
    dimensions JSONB, -- {length, width, height}
    supplier_info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول الطلبات
CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    customer_id UUID REFERENCES users (id) ON DELETE SET NULL,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (
        status IN (
            'active',
            'shipping',
            'delivered',
            'rejected',
            'cancelled'
        )
    ),
    total_amount DECIMAL(10, 2) NOT NULL,
    shipping_cost DECIMAL(10, 2) DEFAULT 0,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (
        payment_status IN (
            'pending',
            'paid',
            'failed',
            'refunded'
        )
    ),
    payment_method VARCHAR(50),
    shipping_address JSONB,
    billing_address JSONB,
    notes TEXT,
    tracking_number VARCHAR(100),
    shipped_at TIMESTAMP
    WITH
        TIME ZONE,
        delivered_at TIMESTAMP
    WITH
        TIME ZONE,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- جدول عناصر الطلبات
CREATE TABLE IF NOT EXISTS order_items (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    order_id UUID REFERENCES orders (id) ON DELETE CASCADE,
    product_id UUID REFERENCES products (id) ON DELETE SET NULL,
    product_name VARCHAR(255) NOT NULL, -- نسخة من اسم المنتج وقت الطلب
    product_price DECIMAL(10, 2) NOT NULL, -- نسخة من سعر المنتج وقت الطلب
    quantity INTEGER NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- جدول الفئات
CREATE TABLE IF NOT EXISTS categories (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES categories (id) ON DELETE SET NULL,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- جدول الموردين
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    website VARCHAR(255),
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- إنشاء الفهارس للأداء
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

CREATE INDEX IF NOT EXISTS idx_products_owner_id ON products (owner_id);

CREATE INDEX IF NOT EXISTS idx_products_category ON products (category);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items (order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items (product_id);

-- إنشاء دالة لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- إضافة المشغلات لتحديث updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- إدراج بيانات تجريبية
INSERT INTO
    categories (name, description)
VALUES (
        'إلكترونيات',
        'أجهزة إلكترونية ومعدات تقنية'
    ),
    (
        'ملابس',
        'ملابس رجالية ونسائية وأطفال'
    ),
    (
        'منزل ومطبخ',
        'أدوات منزلية ومطبخية'
    ),
    (
        'رياضة',
        'معدات رياضية وملابس رياضية'
    ),
    (
        'كتب',
        'كتب ومجلات ومواد تعليمية'
    ) ON CONFLICT DO NOTHING;