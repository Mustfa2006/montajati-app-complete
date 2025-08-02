# 🔍 دليل تشخيص مشكلة تحديث حالة الطلب

## 🎯 المشكلة
عند محاولة تحديث حالة الطلب في لوحة التحكم، تظهر رسالة "فشل في تحديث حالة الطلب".

---

## 📱 خطوات التشخيص في المحاكي

### **1️⃣ تشغيل التطبيق مع Debug Mode**

```bash
# في Terminal
cd "C:\Users\Mustafa\Desktop\montajati\frontend"
flutter run --debug --verbose
```

### **2️⃣ الوصول للوحة التحكم**

1. **تسجيل الدخول:**
   - البريد: `admin@montajati.com`
   - كلمة المرور: `admin123`

2. **الانتقال للطلبات:**
   - اضغط تبويب "الطلبات"
   - اختر أي طلب موجود
   - اضغط "تفاصيل الطلب"

### **3️⃣ اختبار تحديث الحالة**

1. **اضغط "تحديث الحالة"**
2. **اختر حالة جديدة** (مثل: "قيد التحضير")
3. **اضغط "تحديث"**
4. **راقب Console في Terminal**

---

## 🔍 رسائل Debug المتوقعة

### **أ. رسائل النجاح:**
```
🔄 تحديث حالة الطلب: order_123 إلى قيد التحضير
🚀 ===== بداية تحديث حالة الطلب =====
📊 الحالة الجديدة: "قيد التحضير"
📤 إرسال الطلب...
📥 استجابة الخادم: Status Code: 200
✅ تم تحديث حالة الطلب بنجاح
```

### **ب. رسائل الخطأ المحتملة:**

#### **1. خطأ الاتصال:**
```
❌ خطأ في تحديث حالة الطلب: SocketException: Failed to connect
❌ خطأ في الاتصال بالشبكة
```

#### **2. خطأ Backend:**
```
❌ فشل في تحديث الحالة - Status: 500
❌ Response: {"success": false, "error": "فشل في تحديث حالة الطلب"}
```

#### **3. خطأ قاعدة البيانات:**
```
❌ خطأ في قاعدة البيانات - تحقق من الصلاحيات والاتصال
❌ PostgrestException: permission denied
```

#### **4. خطأ Timeout:**
```
❌ خطأ في تحديث حالة الطلب: TimeoutException
❌ Request timeout after 30000ms
```

#### **5. خطأ Rate Limiting:**
```
⚠️ تجاوز الحد المسموح من الطلبات
❌ HTTP 429: Too Many Requests
```

---

## 🛠️ الحلول المحتملة

### **1️⃣ إذا كان خطأ الاتصال:**

#### **أ. تحقق من Backend:**
```bash
# اختبار Backend
curl https://montajati-backend.onrender.com/health
```

#### **ب. تحقق من URL في التطبيق:**
- افتح: `frontend/lib/services/official_order_service.dart`
- تأكد من: `static const String _baseUrl = 'https://montajati-backend.onrender.com/api';`

### **2️⃣ إذا كان خطأ Backend (500):**

#### **أ. فحص Backend Logs:**
- اذهب إلى: https://dashboard.render.com
- افتح logs للـ Backend
- ابحث عن أخطاء في وقت المحاولة

#### **ب. مشاكل محتملة في Backend:**
- خطأ في دالة `normalizeStatus`
- مشكلة في الاتصال بـ Supabase
- خطأ في Waseet API

### **3️⃣ إذا كان خطأ قاعدة البيانات:**

#### **أ. تحقق من Supabase:**
- اذهب إلى: https://supabase.com/dashboard
- تحقق من حالة المشروع
- فحص Table Editor للطلبات

#### **ب. تحقق من الصلاحيات:**
- RLS (Row Level Security) policies
- Service Role Key صحيح

### **4️⃣ إذا كان خطأ Timeout:**

#### **أ. زيادة Timeout:**
```dart
// في official_order_service.dart
static const Duration _timeout = Duration(seconds: 60); // بدلاً من 30
```

#### **ب. تحسين معالجة الأخطاء:**
```dart
try {
  final response = await http.put(/* ... */).timeout(_timeout);
} on TimeoutException {
  throw Exception('انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.');
} catch (e) {
  throw Exception('خطأ في الشبكة: $e');
}
```

---

## 📋 خطة التشخيص المنهجية

### **المرحلة 1: جمع المعلومات**
1. ✅ تشغيل التطبيق في Debug Mode
2. ✅ محاولة تحديث حالة الطلب
3. ✅ نسخ رسائل الخطأ الكاملة
4. ✅ تحديد نقطة الفشل الدقيقة

### **المرحلة 2: تحليل السبب**
1. 🔍 فحص نوع الخطأ (اتصال/backend/database)
2. 🔍 التحقق من Backend logs
3. 🔍 فحص Supabase dashboard
4. 🔍 اختبار API endpoints مباشرة

### **المرحلة 3: تطبيق الحل**
1. 🛠️ إصلاح المشكلة المحددة
2. 🛠️ اختبار الإصلاح
3. 🛠️ التأكد من عدم كسر وظائف أخرى

---

## 🎯 معلومات مهمة للتشخيص

### **URLs مهمة:**
- **Backend:** https://montajati-backend.onrender.com
- **Supabase:** https://supabase.com/dashboard
- **Render Dashboard:** https://dashboard.render.com

### **ملفات مهمة للفحص:**
- `frontend/lib/services/official_order_service.dart`
- `frontend/lib/services/admin_service.dart`
- `frontend/lib/pages/order_details_page.dart`
- `backend/routes/orders.js`

### **API Endpoint المشكوك فيه:**
```
PUT https://montajati-backend.onrender.com/api/orders/{orderId}/status
```

---

## 🚀 ابدأ التشخيص الآن!

1. **شغل المحاكي** في Android Studio
2. **شغل التطبيق** بـ `flutter run --debug`
3. **جرب تحديث حالة الطلب**
4. **انسخ رسائل الخطأ** وشاركها معي
5. **سنحل المشكلة معاً!**

---

💡 **نصيحة:** احتفظ بـ Terminal مفتوح لمراقبة الرسائل أثناء الاختبار!
