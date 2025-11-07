# 🔍 دليل نظام الرصد المتقدم للأرباح

## ✅ تم التطبيق بنجاح!

تم تطبيق **أقوى نظام رصد للأرباح في العالم** على قاعدة البيانات!

---

## 📊 ما الذي تم إنشاؤه؟

### 1️⃣ جدول الرصد المتقدم: `advanced_profit_audit`

هذا الجدول يحتوي على **كل التفاصيل الممكنة** عن كل تغيير في الأرباح:

**معلومات المستخدم والطلب:**
- `user_id`, `user_phone` - معلومات المستخدم
- `order_id`, `order_status` - معلومات الطلب

**معلومات الأرباح:**
- `old_expected_profits`, `new_expected_profits`, `expected_profits_change`
- `old_achieved_profits`, `new_achieved_profits`, `achieved_profits_change`
- `total_change` - إجمالي التغيير

**🔍 معلومات الجلسة (Session Info):**
- `session_pid` - معرف العملية
- `session_application_name` - اسم التطبيق (postgrest, node, etc.)
- `session_client_addr` - عنوان IP للعميل
- `session_client_port` - منفذ العميل
- `session_backend_start` - وقت بدء الجلسة
- `session_xact_start` - وقت بدء المعاملة
- `session_query_start` - وقت بدء الاستعلام
- `session_state` - حالة الجلسة (active, idle, etc.)

**🔍 معلومات الاستعلام (Query Info):**
- `current_query` - **الاستعلام الكامل الذي قام بالتغيير!**
- `query_length` - طول الاستعلام

**🔍 تحليل المصدر (Source Analysis):**
- `source_type` - نوع المصدر:
  - `DATABASE_TRIGGER` - من Database Trigger (smart_profit_manager)
  - `SUPABASE_API` - من Supabase API (PostgREST)
  - `BACKEND_DIRECT` - من Backend مباشرة
  - `FRONTEND_DIRECT` - من Frontend مباشرة
  - `UNKNOWN` - غير معروف
- `source_detail` - تفاصيل المصدر
- `source_file` - **اسم الملف المتوقع الذي قام بالتغيير!**
- `source_confidence` - نسبة الثقة في تحديد المصدر (0-100%)

**🔍 تحليل ذكي (Smart Analysis):**
- `is_suspicious` - هل العملية مشبوهة؟
- `suspicious_reason` - سبب الشك
- `is_duplicate` - هل هذا تكرار؟
- `duplicate_of` - معرف السجل المكرر

**🔍 بيانات خام (Raw Data):**
- `raw_data` - كل البيانات في صيغة JSONB

---

## 🎯 كيف تستخدم النظام؟

### الخطوة 1: أضف طلب جديد

قم بإضافة طلب جديد من التطبيق للمستخدم `07566666666`

### الخطوة 2: غير حالة الطلب

غير حالة الطلب من "نشط" إلى "قيد التوصيل"

### الخطوة 3: راقب النتائج

استخدم هذا الاستعلام لرؤية **كل التفاصيل**:

```sql
SELECT 
    id,
    audit_timestamp,
    user_phone,
    order_id,
    order_status,
    expected_profits_change,
    achieved_profits_change,
    source_type,
    source_detail,
    source_file,
    source_confidence,
    is_suspicious,
    suspicious_reason,
    is_duplicate,
    LEFT(current_query, 200) as query_preview
FROM advanced_profit_audit
WHERE user_phone = '07566666666'
ORDER BY audit_timestamp DESC
LIMIT 20;
```

---

## 🔍 استعلامات مفيدة

### 1. عرض آخر 20 تغيير:

```sql
SELECT * FROM advanced_profit_audit 
ORDER BY audit_timestamp DESC 
LIMIT 20;
```

### 2. عرض التغييرات المشبوهة فقط:

```sql
SELECT 
    id,
    audit_timestamp,
    user_phone,
    order_id,
    expected_profits_change,
    achieved_profits_change,
    source_type,
    source_file,
    suspicious_reason,
    LEFT(current_query, 300) as query_preview
FROM advanced_profit_audit
WHERE is_suspicious = TRUE
ORDER BY audit_timestamp DESC;
```

### 3. عرض التكرارات فقط:

```sql
SELECT 
    id,
    audit_timestamp,
    user_phone,
    order_id,
    expected_profits_change,
    achieved_profits_change,
    duplicate_of,
    source_type,
    source_file
FROM advanced_profit_audit
WHERE is_duplicate = TRUE
ORDER BY audit_timestamp DESC;
```

### 4. عرض التفاصيل الكاملة لسجل معين:

```sql
SELECT 
    id,
    audit_timestamp,
    user_phone,
    order_id,
    order_status,
    old_expected_profits,
    new_expected_profits,
    expected_profits_change,
    old_achieved_profits,
    new_achieved_profits,
    achieved_profits_change,
    total_change,
    session_pid,
    session_application_name,
    session_client_addr,
    session_state,
    source_type,
    source_detail,
    source_file,
    source_confidence,
    is_suspicious,
    suspicious_reason,
    is_duplicate,
    duplicate_of,
    current_query,
    raw_data
FROM advanced_profit_audit
WHERE id = 1; -- غير الرقم حسب السجل الذي تريد
```

### 5. عرض الاستعلام الكامل الذي قام بالتغيير:

```sql
SELECT 
    id,
    audit_timestamp,
    user_phone,
    expected_profits_change,
    source_type,
    source_file,
    current_query -- الاستعلام الكامل!
FROM advanced_profit_audit
WHERE id = 1; -- غير الرقم حسب السجل الذي تريد
```

### 6. تحليل شامل لمستخدم معين:

```sql
SELECT 
    user_phone,
    COUNT(*) as total_changes,
    COUNT(*) FILTER (WHERE is_suspicious) as suspicious_count,
    COUNT(*) FILTER (WHERE is_duplicate) as duplicate_count,
    SUM(expected_profits_change) as total_expected_change,
    SUM(achieved_profits_change) as total_achieved_change,
    array_agg(DISTINCT source_type) as sources_used
FROM advanced_profit_audit
WHERE user_phone = '07566666666'
  AND audit_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_phone;
```

### 7. عرض التغييرات من Supabase API فقط:

```sql
SELECT 
    id,
    audit_timestamp,
    user_phone,
    order_id,
    expected_profits_change,
    achieved_profits_change,
    source_detail,
    source_file,
    source_confidence,
    is_suspicious,
    suspicious_reason,
    LEFT(current_query, 300) as query_preview
FROM advanced_profit_audit
WHERE source_type = 'SUPABASE_API'
ORDER BY audit_timestamp DESC;
```

### 8. عرض التغييرات من Database Trigger فقط:

```sql
SELECT 
    id,
    audit_timestamp,
    user_phone,
    order_id,
    expected_profits_change,
    achieved_profits_change,
    source_detail,
    source_file
FROM advanced_profit_audit
WHERE source_type = 'DATABASE_TRIGGER'
ORDER BY audit_timestamp DESC;
```

---

## 🚨 ما الذي يجعل العملية مشبوهة؟

النظام يعتبر العملية مشبوهة إذا:

1. **تغيير كبير جداً**: أكثر من 500,000 دينار في مرة واحدة
2. **تكرار سريع**: نفس التغيير حدث خلال 10 ثواني
3. **مصدر غير معروف**: لم نستطع تحديد المصدر بثقة عالية (أقل من 50%)
4. **تحديث من Supabase API بدون سياق**: تحديث من PostgREST بدون `order_id`

---

## 🎯 كيف تجد المشكلة؟

### السيناريو: الربح يتضاعف 3 مرات

1. **أضف طلب جديد** للمستخدم `07566666666`
2. **غير حالة الطلب** من "نشط" إلى "قيد التوصيل"
3. **شاهد النتائج**:

```sql
SELECT 
    id,
    audit_timestamp,
    expected_profits_change,
    source_type,
    source_file,
    source_confidence,
    is_suspicious,
    suspicious_reason,
    is_duplicate,
    duplicate_of,
    LEFT(current_query, 500) as query_preview
FROM advanced_profit_audit
WHERE user_phone = '07566666666'
ORDER BY audit_timestamp DESC
LIMIT 20;
```

4. **ابحث عن**:
   - هل هناك 3 سجلات بنفس `expected_profits_change`؟
   - ما هو `source_type` لكل سجل؟
   - ما هو `source_file` لكل سجل؟
   - هل `is_duplicate = TRUE`؟
   - ما هو `current_query` الذي قام بالتغيير؟

5. **الآن ستعرف بالضبط**:
   - من أين جاء التغيير (Backend/Frontend/Database)
   - أي ملف قام بالتغيير
   - الكود الفعلي الذي قام بالتغيير (في `current_query`)

---

## 📝 ملاحظات مهمة

1. **النظام يعمل تلقائياً**: لا تحتاج لفعل أي شيء، فقط أضف طلب وغير حالته
2. **كل تغيير يُسجل**: حتى التغييرات الصغيرة
3. **التحليل ذكي**: النظام يحدد المصدر تلقائياً بنسبة ثقة عالية
4. **التحذيرات التلقائية**: إذا كانت العملية مشبوهة، سيظهر تحذير في PostgreSQL logs

---

## 🧹 تنظيف البيانات القديمة

بعد حل المشكلة، يمكنك حذف السجلات القديمة:

```sql
-- حذف السجلات الأقدم من 7 أيام
DELETE FROM advanced_profit_audit
WHERE audit_timestamp < NOW() - INTERVAL '7 days';
```

أو حذف كل السجلات:

```sql
TRUNCATE TABLE advanced_profit_audit;
```

---

## ✅ الخلاصة

الآن لديك **أقوى نظام رصد للأرباح**! 

فقط:
1. أضف طلب
2. غير حالته
3. شاهد النتائج في `advanced_profit_audit`
4. ستجد **بالضبط** من أين جاءت المشكلة!

**حظاً موفقاً! 🎯**

