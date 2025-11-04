# نظام تنظيف FCM Tokens التلقائي

## 📋 نظرة عامة

تم إنشاء نظام ذكي لتنظيف FCM Tokens المكررة والقديمة **داخل قاعدة البيانات (Supabase)** بدلاً من Backend.

---

## ✅ المشاكل التي تم حلها

### 1. **تكرار FCM Tokens**
- **المشكلة:** عندما يسجل المستخدم خروج ثم دخول، يتم إنشاء FCM Token جديد دون حذف القديم
- **النتيجة:** يصبح لدى المستخدم عدة tokens، فيصل الإشعار مرتين أو أكثر
- **الحل:**
  - Cron Job في Supabase يعمل كل 12 ساعة
  - يحذف جميع الـ tokens المكررة ويبقي فقط الأحدث

### 2. **استمرار الإشعارات بعد تسجيل الخروج**
- **المشكلة:** المستخدم يسجل خروج من حساب A، ثم يسجل دخول بحساب B، لكن يستمر في تلقي إشعارات من حساب A
- **الحل:**
  - عند تسجيل الخروج: يتم حذف جميع FCM Tokens للمستخدم فوراً من قاعدة البيانات
  - عند تسجيل الدخول: يتم حذف جميع الـ tokens القديمة قبل إنشاء token جديد

---

## 🗂️ الملفات المعدلة

### **Backend:**
1. ✅ **حذف أنظمة التنظيف القديمة:**
   - `backend/services/fcm_cleanup_service.js` ❌ (محذوف)
   - `backend/services/smart_fcm_refresh_service.js` ❌ (محذوف)
   - `backend/official_montajati_server.js` (إزالة استدعاء FCMCleanupService)
   - `backend/routes/fcm_tokens.js` (إزالة endpoint `/cleanup`)
   - `backend/routes/fcm.js` (إزالة endpoint `/cleanup-expired-tokens`)
   - `backend/routes/notifications.js` (إزالة endpoint `/tokens/cleanup`)

2. ✅ **إنشاء نظام تنظيف في قاعدة البيانات:**
   - `backend/database/fcm_tokens_auto_cleanup.sql` ✅ (جديد)

### **Frontend:**
1. ✅ **تعديل كود تسجيل الخروج:**
   - `frontend/lib/services/real_auth_service.dart`
   - يحذف جميع FCM Tokens للمستخدم عند تسجيل الخروج

2. ✅ **تعديل كود حفظ FCM Token:**
   - `frontend/lib/services/fcm_service.dart`
   - يحذف جميع الـ tokens القديمة قبل إنشاء token جديد

---

## 🚀 كيفية التطبيق

### **الخطوة 1: تطبيق SQL في Supabase**

1. افتح **Supabase Dashboard**
2. اذهب إلى **SQL Editor**
3. افتح ملف `backend/database/fcm_tokens_auto_cleanup.sql`
4. انسخ المحتوى بالكامل
5. الصقه في SQL Editor
6. اضغط **Run** لتنفيذ الكود

### **الخطوة 2: التحقق من تفعيل Cron Job**

بعد تنفيذ SQL، تحقق من أن Cron Job تم إنشاؤه:

```sql
SELECT * FROM cron.job WHERE jobname = 'fcm-tokens-cleanup-job';
```

يجب أن ترى:
- `jobname`: `fcm-tokens-cleanup-job`
- `schedule`: `0 */12 * * *` (كل 12 ساعة)
- `command`: `SELECT run_fcm_tokens_cleanup()`

### **الخطوة 3: اختبار التنظيف يدوياً (اختياري)**

لاختبار التنظيف فوراً دون انتظار 12 ساعة:

```sql
SELECT run_fcm_tokens_cleanup();
```

### **الخطوة 4: عرض سجل التنظيف**

لعرض سجل عمليات التنظيف:

```sql
SELECT * FROM fcm_cleanup_logs ORDER BY execution_time DESC LIMIT 10;
```

---

## 📊 كيف يعمل النظام؟

### **1. Cron Job في Supabase (كل 12 ساعة)**

```
الساعة 00:00 → تشغيل التنظيف
الساعة 12:00 → تشغيل التنظيف
```

### **2. عملية التنظيف:**

#### **أ. تنظيف الـ tokens المكررة:**
```sql
-- لكل مستخدم لديه أكثر من token:
1. جلب جميع الـ tokens
2. ترتيبها حسب last_used_at (الأحدث أولاً)
3. حذف جميع الـ tokens القديمة
4. الاحتفاظ بالـ token الأحدث فقط
```

#### **ب. حذف الـ tokens القديمة جداً:**
```sql
-- حذف tokens لم تُستخدم لأكثر من 30 يوم
DELETE FROM fcm_tokens
WHERE last_used_at < NOW() - INTERVAL '30 days';
```

### **3. عند تسجيل الخروج (Frontend):**
```dart
// حذف جميع FCM Tokens للمستخدم فوراً
await Supabase.instance.client
    .from('fcm_tokens')
    .delete()
    .eq('user_phone', currentUserPhone);
```

### **4. عند تسجيل الدخول (Frontend):**
```dart
// حذف جميع الـ tokens القديمة
await _supabase.from('fcm_tokens').delete().eq('user_phone', userPhone);

// إنشاء token جديد
await _supabase.from('fcm_tokens').insert({...});
```

---

## 🔍 مراقبة النظام

### **1. عرض عدد الـ tokens لكل مستخدم:**
```sql
SELECT 
  user_phone,
  COUNT(*) as token_count,
  MAX(created_at) as latest_token_date
FROM fcm_tokens
WHERE is_active = true
GROUP BY user_phone
ORDER BY token_count DESC;
```

### **2. عرض المستخدمين الذين لديهم tokens مكررة:**
```sql
SELECT 
  user_phone,
  COUNT(*) as token_count
FROM fcm_tokens
WHERE is_active = true
GROUP BY user_phone
HAVING COUNT(*) > 1;
```

### **3. عرض آخر 10 عمليات تنظيف:**
```sql
SELECT 
  execution_time,
  users_cleaned,
  duplicate_tokens_deleted,
  old_tokens_deleted,
  total_tokens_deleted
FROM fcm_cleanup_logs
ORDER BY execution_time DESC
LIMIT 10;
```

---

## ⚙️ إدارة Cron Job

### **إيقاف Cron Job:**
```sql
SELECT cron.unschedule('fcm-tokens-cleanup-job');
```

### **إعادة تفعيل Cron Job:**
```sql
SELECT cron.schedule(
  'fcm-tokens-cleanup-job',
  '0 */12 * * *',
  $$SELECT run_fcm_tokens_cleanup()$$
);
```

### **تغيير الجدول الزمني (مثلاً كل 6 ساعات):**
```sql
-- إيقاف القديم
SELECT cron.unschedule('fcm-tokens-cleanup-job');

-- إنشاء جديد
SELECT cron.schedule(
  'fcm-tokens-cleanup-job',
  '0 */6 * * *',  -- كل 6 ساعات
  $$SELECT run_fcm_tokens_cleanup()$$
);
```

---

## 🎯 الفوائد

1. ✅ **لا مزيد من الإشعارات المكررة**
2. ✅ **تنظيف تلقائي بدون تدخل Backend**
3. ✅ **حذف فوري عند تسجيل الخروج**
4. ✅ **أداء أفضل (tokens أقل = استعلامات أسرع)**
5. ✅ **سجل كامل لعمليات التنظيف**

---

## 📝 ملاحظات مهمة

1. **pg_cron Extension:**
   - يجب أن يكون `pg_cron` مفعلاً في Supabase
   - معظم مشاريع Supabase تدعمه افتراضياً
   - إذا لم يكن مفعلاً، اتصل بدعم Supabase

2. **الجدول الزمني:**
   - `0 */12 * * *` = كل 12 ساعة (00:00 و 12:00)
   - يمكن تغييره حسب الحاجة

3. **الـ tokens القديمة:**
   - يتم حذف tokens لم تُستخدم لأكثر من 30 يوم
   - يمكن تغيير المدة في الدالة `cleanup_old_fcm_tokens()`

4. **السجلات:**
   - يتم حفظ سجل كل عملية تنظيف في `fcm_cleanup_logs`
   - يمكن حذف السجلات القديمة يدوياً إذا لزم الأمر

---

## 🐛 استكشاف الأخطاء

### **المشكلة: Cron Job لا يعمل**
```sql
-- تحقق من وجود الـ Job
SELECT * FROM cron.job WHERE jobname = 'fcm-tokens-cleanup-job';

-- تحقق من سجل الأخطاء
SELECT * FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'fcm-tokens-cleanup-job')
ORDER BY start_time DESC
LIMIT 10;
```

### **المشكلة: pg_cron غير مفعل**
```sql
-- محاولة تفعيل pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- إذا فشل، اتصل بدعم Supabase
```

### **المشكلة: لا تزال هناك tokens مكررة**
```sql
-- تشغيل التنظيف يدوياً
SELECT run_fcm_tokens_cleanup();

-- التحقق من النتيجة
SELECT user_phone, COUNT(*) 
FROM fcm_tokens 
WHERE is_active = true 
GROUP BY user_phone 
HAVING COUNT(*) > 1;
```

---

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من سجل `fcm_cleanup_logs`
2. تحقق من سجل `cron.job_run_details`
3. شغّل التنظيف يدوياً: `SELECT run_fcm_tokens_cleanup()`
4. تحقق من أن `pg_cron` مفعل

---

**تم إنشاء هذا النظام بواسطة:** Augment Agent  
**التاريخ:** 2025-01-04  
**الإصدار:** 1.0

