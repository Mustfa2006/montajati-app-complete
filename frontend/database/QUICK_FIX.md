# إصلاح سريع لمشكلة قاعدة البيانات

## المشكلة:
خطأ: `PostgresException: column "available_quantity" of relation "products" does not exist`

## الحل السريع:

### الطريقة الأولى: عبر Supabase Dashboard
1. اذهب إلى [Supabase Dashboard](https://supabase.com/dashboard)
2. اختر مشروعك
3. اذهب إلى **SQL Editor**
4. انسخ والصق هذا الكود:

```sql
ALTER TABLE products ADD COLUMN available_quantity INTEGER DEFAULT 100;
UPDATE products SET available_quantity = 100 WHERE available_quantity IS NULL;
```

5. اضغط **Run**

### الطريقة الثانية: الحل المؤقت (مطبق بالفعل)
الكود يحاول إضافة العمود، وإذا فشل يحفظ المنتج بدون هذا العمود.

## التحقق من النجاح:
بعد تشغيل الكود SQL، جرب إضافة منتج جديد من التطبيق.

## ملاحظة:
هذا العمود مطلوب لتتبع كمية المخزون المتاحة للبيع.
