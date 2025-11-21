# إصلاح عاجل لمشكلة إضافة المنتجات

## المشكلة الحالية:
```
PostgresException: column "image_url" of relation "products" does not exist
```

## الحل السريع (مطلوب تنفيذه فوراً):

### الخطوة 1: تشغيل SQL في Supabase
1. اذهب إلى [Supabase Dashboard](https://supabase.com/dashboard)
2. اختر مشروعك
3. اذهب إلى **SQL Editor**
4. انسخ والصق الكود التالي:

```sql
-- إضافة الأعمدة المفقودة
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS available_quantity INTEGER DEFAULT 100;
ALTER TABLE products ADD COLUMN IF NOT EXISTS wholesale_price DECIMAL(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS min_price DECIMAL(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS max_price DECIMAL(10,2);

-- تحديث البيانات الموجودة
UPDATE products 
SET 
    available_quantity = COALESCE(available_quantity, 100),
    image_url = COALESCE(image_url, 'https://via.placeholder.com/300x300'),
    wholesale_price = COALESCE(wholesale_price, price * 0.8),
    min_price = COALESCE(min_price, price * 0.9),
    max_price = COALESCE(max_price, price * 1.2)
WHERE available_quantity IS NULL 
   OR image_url IS NULL 
   OR wholesale_price IS NULL
   OR min_price IS NULL
   OR max_price IS NULL;
```

5. اضغط **Run**

### الخطوة 2: إعادة تشغيل التطبيق
بعد تشغيل الكود SQL، أعد تشغيل التطبيق وجرب إضافة منتج جديد.

## التحقق من النجاح:
- يجب أن تتمكن من إضافة منتجات جديدة بدون أخطاء
- يجب أن تظهر الصور والأسعار بشكل صحيح

## ملاحظات مهمة:
- هذه الأعمدة ضرورية لعمل نظام إدارة المنتجات
- العمود `image_url` يحفظ رابط صورة المنتج
- العمود `available_quantity` يتتبع الكمية المتاحة
- الأعمدة `wholesale_price`, `min_price`, `max_price` تحفظ أسعار المنتج المختلفة

## في حالة استمرار المشكلة:
إذا استمرت المشكلة، تأكد من:
1. تم تشغيل الكود SQL بنجاح
2. لا توجد أخطاء في console الـ Supabase
3. تم حفظ التغييرات في قاعدة البيانات
