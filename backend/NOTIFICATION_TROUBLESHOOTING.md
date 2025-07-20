# 🔧 دليل استكشاف أخطاء نظام الإشعارات

## 📋 فحص سريع للنظام

### 1️⃣ اختبار Firebase Backend
```bash
npm run test:firebase
```

### 2️⃣ اختبار قاعدة البيانات
```bash
npm run test:db
```

### 3️⃣ اختبار النظام الكامل
```bash
npm run test:notifications
```

### 4️⃣ إرسال إشعار تجريبي
```bash
# عرض المستخدمين المتاحين
npm run test:notification list

# إرسال إشعار تجريبي
npm run test:notification send +966500000000

# إرسال إعلان جماعي
npm run test:notification broadcast "رسالة للجميع"
```

---

## 🔥 مشاكل Firebase الشائعة

### ❌ خطأ: "Firebase Admin غير مهيأ"
**الحل:**
1. تحقق من متغيرات البيئة:
   ```bash
   echo $FIREBASE_SERVICE_ACCOUNT
   ```
2. تأكد من صحة JSON في Render
3. شغل: `npm run test:firebase`

### ❌ خطأ: "private_key must be a string"
**الحل:**
1. تحقق من Private Key في Service Account
2. تأكد من وجود `\n` في المواضع الصحيحة
3. في Render، استخدم متغير واحد `FIREBASE_SERVICE_ACCOUNT`

### ❌ خطأ: "registration-token-not-registered"
**الحل:**
1. هذا طبيعي مع tokens تجريبية
2. تأكد من تسجيل المستخدم في التطبيق
3. تحقق من تفعيل الإشعارات في الجهاز

---

## 📱 مشاكل Frontend (Flutter)

### ❌ خطأ: "Firebase app not initialized"
**الحل:**
1. تحقق من `firebase_options.dart`
2. تأكد من صحة App IDs
3. شغل: `flutter clean && flutter pub get`

### ❌ خطأ: "FCM Token null"
**الحل:**
1. تحقق من أذونات الإشعارات
2. اختبر على جهاز حقيقي (ليس محاكي)
3. تأكد من اتصال الإنترنت

### ❌ خطأ: "Permission denied"
**الحل:**
1. طلب أذونات الإشعارات:
   ```dart
   await FirebaseMessaging.instance.requestPermission();
   ```
2. تحقق من إعدادات النظام

---

## 📊 مشاكل قاعدة البيانات

### ❌ خطأ: "table fcm_tokens does not exist"
**الحل:**
```bash
npm run migrate
```

### ❌ خطأ: "permission denied for table fcm_tokens"
**الحل:**
1. تحقق من `SUPABASE_SERVICE_ROLE_KEY`
2. تأكد من صحة المفتاح في Render

### ❌ خطأ: "duplicate key value violates unique constraint"
**الحل:**
1. هذا طبيعي - يعني أن Token مسجل مسبقاً
2. النظام يحدث Token تلقائياً

---

## 🔧 خطوات الإصلاح المتقدمة

### 1️⃣ إعادة تعيين Firebase
```bash
# حذف التهيئة السابقة
rm -rf node_modules/.cache
npm install

# اختبار جديد
npm run test:firebase
```

### 2️⃣ إعادة إنشاء قاعدة البيانات
```bash
# تشغيل migrations
npm run migrate

# فحص الجداول
npm run test:db
```

### 3️⃣ فحص شامل للنظام
```bash
# اختبار كامل
npm run test:notifications

# فحص logs
tail -f logs/app.log
```

---

## 📱 اختبار على الأجهزة

### Android
1. تأكد من تفعيل الإشعارات في الإعدادات
2. تحقق من Battery Optimization
3. اختبر مع التطبيق مفتوح ومغلق

### iOS
1. تأكد من أذونات الإشعارات
2. تحقق من Do Not Disturb
3. اختبر مع التطبيق في Background

---

## 🚨 حالات الطوارئ

### إذا لم تصل أي إشعارات:
1. **فحص Firebase Console:**
   - تأكد من تفعيل Cloud Messaging
   - تحقق من إحصائيات الإرسال

2. **فحص Render Logs:**
   ```bash
   # في Render Dashboard
   View Logs -> Real-time logs
   ```

3. **فحص قاعدة البيانات:**
   ```sql
   SELECT * FROM fcm_tokens WHERE is_active = true;
   ```

### إذا وصلت إشعارات متأخرة:
1. تحقق من اتصال الإنترنت
2. فحص Battery Optimization
3. تحقق من إعدادات التطبيق

---

## 📞 الحصول على المساعدة

### معلومات مفيدة للدعم:
```bash
# معلومات النظام
npm run test:notifications

# معلومات Firebase
npm run test:firebase

# معلومات قاعدة البيانات
npm run test:db

# إرسال تقرير
npm run test:notification list
```

### ملفات Log مهمة:
- `logs/app.log` - سجل التطبيق
- `logs/firebase.log` - سجل Firebase
- `logs/notifications.log` - سجل الإشعارات

---

## ✅ قائمة التحقق النهائية

- [ ] Firebase Service Account صحيح في Render
- [ ] جدول fcm_tokens موجود في قاعدة البيانات
- [ ] firebase_options.dart محدث بـ App IDs صحيحة
- [ ] أذونات الإشعارات مفعلة في التطبيق
- [ ] اختبار على جهاز حقيقي
- [ ] Firebase Console يظهر إحصائيات الإرسال
- [ ] Render Logs لا تظهر أخطاء Firebase
- [ ] المستخدم مسجل في جدول fcm_tokens

---

## 🎯 نصائح للأداء الأمثل

1. **تنظيف Tokens القديمة:**
   ```sql
   DELETE FROM fcm_tokens 
   WHERE last_used_at < NOW() - INTERVAL '30 days';
   ```

2. **مراقبة معدل النجاح:**
   ```bash
   npm run test:notification list
   ```

3. **اختبار دوري:**
   ```bash
   # اختبار يومي
   npm run test:notifications
   ```

---

*آخر تحديث: 2024-12-20*
