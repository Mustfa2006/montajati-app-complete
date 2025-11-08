-- إنشاء جدول الصور الإعلانية
CREATE TABLE IF NOT EXISTS advertisement_banners (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    subtitle TEXT,
    image_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء فهرس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_advertisement_banners_active ON advertisement_banners(is_active);
CREATE INDEX IF NOT EXISTS idx_advertisement_banners_created_at ON advertisement_banners(created_at);

-- إضافة RLS (Row Level Security)
ALTER TABLE advertisement_banners ENABLE ROW LEVEL SECURITY;

-- سياسة للقراءة - يمكن لأي شخص قراءة الصور الإعلانية النشطة
CREATE POLICY "Anyone can view active banners" ON advertisement_banners
    FOR SELECT USING (is_active = true);

-- سياسة للإدارة - فقط المدراء يمكنهم إدارة الصور الإعلانية
CREATE POLICY "Only admins can manage banners" ON advertisement_banners
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.is_admin = true
        )
    );

-- إنشاء دالة لإنشاء الجدول (للاستخدام من Flutter)
CREATE OR REPLACE FUNCTION create_advertisement_banners_table()
RETURNS void AS $$
BEGIN
    -- التحقق من وجود الجدول
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'advertisement_banners') THEN
        -- إنشاء الجدول
        CREATE TABLE advertisement_banners (
            id SERIAL PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            subtitle TEXT,
            image_url TEXT NOT NULL,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        -- إنشاء الفهارس
        CREATE INDEX idx_advertisement_banners_active ON advertisement_banners(is_active);
        CREATE INDEX idx_advertisement_banners_created_at ON advertisement_banners(created_at);

        -- تفعيل RLS
        ALTER TABLE advertisement_banners ENABLE ROW LEVEL SECURITY;

        -- إنشاء السياسات
        CREATE POLICY "Anyone can view active banners" ON advertisement_banners
            FOR SELECT USING (is_active = true);

        CREATE POLICY "Only admins can manage banners" ON advertisement_banners
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM users 
                    WHERE users.id = auth.uid() 
                    AND users.is_admin = true
                )
            );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- إدراج بعض البيانات التجريبية
INSERT INTO advertisement_banners (title, subtitle, image_url, is_active) VALUES
('تسوق أونلاين', 'أفضل المنتجات بأسعار مميزة', 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800&h=400&fit=crop', true),
('عروض خاصة', 'خصومات تصل إلى 50%', 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800&h=400&fit=crop', true),
('توصيل سريع', 'توصيل مجاني لجميع المحافظات', 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=400&fit=crop', true)
ON CONFLICT DO NOTHING;
