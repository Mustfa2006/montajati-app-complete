# تعليمات إعداد قاعدة البيانات في Supabase

## الخطوات المطلوبة:

### 1. إنشاء مشروع جديد في Supabase
- اذهب إلى [supabase.com](https://supabase.com)
- قم بإنشاء حساب جديد أو تسجيل الدخول
- انقر على "New Project"
- اختر اسم للمشروع وكلمة مرور قوية لقاعدة البيانات
- انتظر حتى يتم إنشاء المشروع (قد يستغرق بضع دقائق)

### 2. الحصول على بيانات الاتصال
بعد إنشاء المشروع، ستحتاج إلى:
- **Project URL**: يمكن العثور عليه في Settings > API
- **Anon Key**: يمكن العثور عليه في Settings > API

### 3. تحديث ملف التكوين
قم بتحديث الملف `frontend/lib/config/supabase_config.dart` بالبيانات الصحيحة:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  static SupabaseClient get client => Supabase.instance.client;
}
```

### 4. تشغيل كود SQL لإنشاء الجدول
- اذهب إلى SQL Editor في لوحة تحكم Supabase
- انسخ والصق محتوى الملف `create_users_table.sql`
- انقر على "Run" لتنفيذ الكود

### 5. التحقق من إنشاء الجدول
- اذهب إلى Table Editor
- يجب أن ترى جدول "users" مع الأعمدة التالية:
  - id (UUID, Primary Key)
  - name (Text)
  - phone (Text, Unique)
  - email (Text, Unique)
  - password_hash (Text)
  - created_at (Timestamp)
  - updated_at (Timestamp)

### 6. اختبار التطبيق
الآن يمكنك:
- إنشاء حساب جديد باستخدام رقم هاتف (11 رقم) وكلمة مرور (6 أرقام على الأقل)
- تسجيل الدخول باستخدام رقم الهاتف وكلمة المرور

## بيانات تجريبية للاختبار:
إذا تم تشغيل كود SQL بنجاح، ستجد هذه الحسابات التجريبية:

| الاسم | رقم الهاتف | كلمة المرور |
|-------|------------|-------------|
| أحمد محمد | 01234567890 | 123456 |
| فاطمة علي | 01111111111 | secret |
| محمد أحمد | 01222222222 | 987654 |
| سارة خالد | 01333333333 | 123456 |
| عمر حسن | 01555555555 | 999999 |

## ملاحظات مهمة:
1. تأكد من أن Row Level Security (RLS) مفعل للأمان
2. كلمات المرور مشفرة بـ SHA-256
3. يتم إنشاء email مؤقت تلقائياً من رقم الهاتف
4. رقم الهاتف يجب أن يكون 11 رقم بالضبط
5. كلمة المرور يجب أن تكون 6 أرقام على الأقل

## استكشاف الأخطاء:
- إذا ظهر خطأ "null value in column email": تأكد من تشغيل كود SQL المحدث
- إذا ظهر خطأ اتصال: تحقق من صحة URL و Anon Key
- إذا ظهر خطأ في التسجيل: تحقق من أن رقم الهاتف 11 رقم وكلمة المرور 6 أرقام على الأقل
