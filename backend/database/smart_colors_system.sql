-- ===================================
-- 🎨 نظام الألوان الذكي المتطور
-- Smart Colors System Database Schema
-- ===================================

-- 🎯 جدول الألوان الرئيسي
CREATE TABLE IF NOT EXISTS product_colors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL,
    color_name VARCHAR(100) NOT NULL,
    color_code VARCHAR(7) NOT NULL, -- HEX color code (#FF0000)
    color_rgb VARCHAR(20), -- RGB values (255,0,0)
    color_arabic_name VARCHAR(100) NOT NULL, -- الاسم العربي للون
    total_quantity INTEGER NOT NULL DEFAULT 0,
    available_quantity INTEGER NOT NULL DEFAULT 0,
    reserved_quantity INTEGER NOT NULL DEFAULT 0,
    sold_quantity INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    
    -- Unique constraints
    UNIQUE(product_id, color_name),
    UNIQUE(product_id, color_code),
    
    -- Check constraints
    CHECK (total_quantity >= 0),
    CHECK (available_quantity >= 0),
    CHECK (reserved_quantity >= 0),
    CHECK (sold_quantity >= 0),
    CHECK (available_quantity + reserved_quantity + sold_quantity <= total_quantity),
    CHECK (color_code ~ '^#[0-9A-Fa-f]{6}$') -- Valid hex color
);

-- 📊 جدول تاريخ الألوان (للتتبع والإحصائيات)
CREATE TABLE IF NOT EXISTS product_colors_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    color_id UUID NOT NULL,
    product_id UUID NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- 'created', 'updated', 'reserved', 'sold', 'restocked'
    old_quantity INTEGER,
    new_quantity INTEGER,
    quantity_change INTEGER,
    reason TEXT,
    user_phone VARCHAR(20),
    order_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (color_id) REFERENCES product_colors(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- 🛒 جدول حجوزات الألوان (للطلبات المؤقتة)
CREATE TABLE IF NOT EXISTS color_reservations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    color_id UUID NOT NULL,
    product_id UUID NOT NULL,
    order_id VARCHAR(100),
    user_phone VARCHAR(20),
    reserved_quantity INTEGER NOT NULL,
    reservation_type VARCHAR(50) DEFAULT 'order', -- 'order', 'cart', 'temp'
    expires_at TIMESTAMP,
    is_confirmed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (color_id) REFERENCES product_colors(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    
    CHECK (reserved_quantity > 0)
);

-- 🎨 جدول الألوان المحددة مسبقاً (للاختيار السريع)
CREATE TABLE IF NOT EXISTS predefined_colors (
    id SERIAL PRIMARY KEY,
    color_name VARCHAR(100) NOT NULL UNIQUE,
    color_code VARCHAR(7) NOT NULL UNIQUE,
    color_rgb VARCHAR(20),
    color_arabic_name VARCHAR(100) NOT NULL,
    is_popular BOOLEAN DEFAULT false,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (color_code ~ '^#[0-9A-Fa-f]{6}$')
);

-- 📈 جدول إحصائيات الألوان
CREATE TABLE IF NOT EXISTS color_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    color_id UUID NOT NULL,
    product_id UUID NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    views_count INTEGER DEFAULT 0,
    cart_additions INTEGER DEFAULT 0,
    orders_count INTEGER DEFAULT 0,
    sold_quantity INTEGER DEFAULT 0,
    revenue DECIMAL(12,2) DEFAULT 0,
    
    FOREIGN KEY (color_id) REFERENCES product_colors(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    
    UNIQUE(color_id, date)
);

-- ===================================
-- 🔧 الفهارس لتحسين الأداء
-- ===================================

-- فهارس product_colors
CREATE INDEX IF NOT EXISTS idx_product_colors_product_id ON product_colors(product_id);
CREATE INDEX IF NOT EXISTS idx_product_colors_active ON product_colors(is_active);
CREATE INDEX IF NOT EXISTS idx_product_colors_available ON product_colors(available_quantity) WHERE available_quantity > 0;
CREATE INDEX IF NOT EXISTS idx_product_colors_display_order ON product_colors(product_id, display_order);

-- فهارس product_colors_history
CREATE INDEX IF NOT EXISTS idx_colors_history_color_id ON product_colors_history(color_id);
CREATE INDEX IF NOT EXISTS idx_colors_history_product_id ON product_colors_history(product_id);
CREATE INDEX IF NOT EXISTS idx_colors_history_created_at ON product_colors_history(created_at);
CREATE INDEX IF NOT EXISTS idx_colors_history_action_type ON product_colors_history(action_type);

-- فهارس color_reservations
CREATE INDEX IF NOT EXISTS idx_color_reservations_color_id ON color_reservations(color_id);
CREATE INDEX IF NOT EXISTS idx_color_reservations_order_id ON color_reservations(order_id);
CREATE INDEX IF NOT EXISTS idx_color_reservations_expires_at ON color_reservations(expires_at);
CREATE INDEX IF NOT EXISTS idx_color_reservations_user_phone ON color_reservations(user_phone);

-- فهارس color_analytics
CREATE INDEX IF NOT EXISTS idx_color_analytics_color_id ON color_analytics(color_id);
CREATE INDEX IF NOT EXISTS idx_color_analytics_date ON color_analytics(date);
CREATE INDEX IF NOT EXISTS idx_color_analytics_product_date ON color_analytics(product_id, date);

-- ===================================
-- 🎨 إدراج الألوان المحددة مسبقاً
-- ===================================

INSERT INTO predefined_colors (color_name, color_code, color_rgb, color_arabic_name, is_popular) VALUES
-- الألوان الأساسية
('Red', '#FF0000', '255,0,0', 'أحمر', true),
('Blue', '#0000FF', '0,0,255', 'أزرق', true),
('Green', '#00FF00', '0,255,0', 'أخضر', true),
('Yellow', '#FFFF00', '255,255,0', 'أصفر', true),
('Black', '#000000', '0,0,0', 'أسود', true),
('White', '#FFFFFF', '255,255,255', 'أبيض', true),
('Gray', '#808080', '128,128,128', 'رمادي', true),
('Orange', '#FFA500', '255,165,0', 'برتقالي', true),
('Purple', '#800080', '128,0,128', 'بنفسجي', true),
('Pink', '#FFC0CB', '255,192,203', 'وردي', true),

-- ألوان متقدمة
('Navy', '#000080', '0,0,128', 'كحلي', false),
('Maroon', '#800000', '128,0,0', 'عنابي', false),
('Teal', '#008080', '0,128,128', 'أزرق مخضر', false),
('Olive', '#808000', '128,128,0', 'زيتوني', false),
('Silver', '#C0C0C0', '192,192,192', 'فضي', false),
('Gold', '#FFD700', '255,215,0', 'ذهبي', false),
('Brown', '#A52A2A', '165,42,42', 'بني', false),
('Beige', '#F5F5DC', '245,245,220', 'بيج', false),
('Coral', '#FF7F50', '255,127,80', 'مرجاني', false),
('Turquoise', '#40E0D0', '64,224,208', 'فيروزي', false),

-- ألوان عصرية
('Rose Gold', '#E8B4B8', '232,180,184', 'ذهبي وردي', false),
('Mint', '#98FB98', '152,251,152', 'نعناعي', false),
('Lavender', '#E6E6FA', '230,230,250', 'خزامي', false),
('Peach', '#FFCBA4', '255,203,164', 'خوخي', false),
('Sky Blue', '#87CEEB', '135,206,235', 'أزرق سماوي', false)

ON CONFLICT (color_name) DO NOTHING;
