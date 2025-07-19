# 📱 دليل التثبيت الكامل - تطبيق منتجاتي مع الإشعارات

## 🎯 **كل شيء جاهز! فقط اتبع هذه الخطوات:**

---

## **📋 1. نسخ الملفات:**

### **انسخ هذه الملفات لمشروع التطبيق:**
```
✅ NotificationService.js  → src/services/
✅ App.js                  → src/ (استبدل الموجود)
✅ package.json            → / (استبدل الموجود)
```

---

## **🔧 2. تثبيت التبعيات:**

```bash
# انتقل لمجلد التطبيق
cd your-app

# تثبيت التبعيات
npm install

# للـ iOS فقط
cd ios && pod install && cd ..
```

---

## **⚙️ 3. تحديث رابط الخادم:**

### **في ملف `NotificationService.js`:**
```javascript
// السطر 11 - ضع رابط الخادم الحقيقي
this.serverUrl = 'https://your-actual-server.com'; // غير هذا
```

### **في ملف `App.js`:**
```javascript
// السطر 67 - ضع رابط الخادم الحقيقي
const response = await fetch('https://your-actual-server.com/api/fcm/test-notification', {
```

---

## **📱 4. تحديث رقم هاتف المستخدم:**

### **في ملف `App.js`:**
```javascript
// السطر 21 - ضع رقم هاتف المستخدم الحقيقي
const [userPhone, setUserPhone] = useState('07503597589'); // غير هذا
```

**أو احصل عليه من تسجيل الدخول:**
```javascript
// مثال: الحصول من AsyncStorage أو Context
const [userPhone, setUserPhone] = useState('');

useEffect(() => {
  getUserPhoneFromStorage().then(phone => {
    setUserPhone(phone);
  });
}, []);
```

---

## **🔥 5. إعداد Firebase (مهم جداً):**

### **أ) للأندرويد:**
1. ضع ملف `google-services.json` في `android/app/`
2. تأكد من أن `package_name` في الملف يطابق اسم التطبيق

### **ب) للـ iOS:**
1. ضع ملف `GoogleService-Info.plist` في `ios/YourApp/`
2. تأكد من أن `BUNDLE_ID` يطابق اسم التطبيق

---

## **🚀 6. بناء التطبيق:**

### **للأندرويد:**
```bash
# تطوير
npm run android

# إنتاج
npm run build-android
# الملف سيكون في: android/app/build/outputs/apk/release/app-release.apk
```

### **للـ iOS:**
```bash
# تطوير
npm run ios

# إنتاج
npm run build-ios
# الملف سيكون في: ios/MontajatiApp.xcarchive
```

---

## **🧪 7. اختبار النظام:**

### **أ) اختبار محلي:**
1. شغل التطبيق على الهاتف
2. اضغط "إعادة تفعيل الإشعارات"
3. اضغط "اختبار الإشعارات"
4. يجب أن تحصل على إشعار

### **ب) اختبار حقيقي:**
1. غير حالة طلب في النظام
2. يجب أن يحصل المستخدم على إشعار فوري

---

## **📦 8. توزيع التطبيق:**

### **للأندرويد:**
```bash
# بناء APK للتوزيع
cd android
./gradlew assembleRelease

# الملف الجاهز:
# android/app/build/outputs/apk/release/app-release.apk
```

### **رفع على Google Play:**
1. إنشاء حساب مطور
2. رفع APK
3. ملء معلومات التطبيق
4. نشر التطبيق

### **للـ iOS:**
```bash
# بناء للـ App Store
cd ios
xcodebuild -workspace MontajatiApp.xcworkspace -scheme MontajatiApp -configuration Release archive
```

---

## **✅ 9. التحقق النهائي:**

### **قائمة التحقق:**
- [ ] تم نسخ جميع الملفات
- [ ] تم تثبيت التبعيات
- [ ] تم تحديث رابط الخادم
- [ ] تم تحديث رقم الهاتف
- [ ] تم إعداد Firebase
- [ ] تم اختبار الإشعارات
- [ ] تم بناء التطبيق
- [ ] جاهز للتوزيع

---

## **🎉 النتيجة النهائية:**

### **✅ المستخدم:**
1. يحمل التطبيق
2. يثبته على الهاتف
3. يوافق على الإشعارات
4. ✅ يحصل على إشعارات تلقائياً

### **✅ أنت:**
1. تغير حالة الطلب
2. ✅ المستخدم يحصل على إشعار فوري

**💯 التطبيق جاهز 100% للتوزيع!**

---

## **🆘 في حالة وجود مشاكل:**

### **مشكلة شائعة: الإشعارات لا تعمل**
1. تأكد من رابط الخادم صحيح
2. تأكد من إعداد Firebase صحيح
3. تأكد من السماح بالإشعارات في الهاتف
4. تأكد من تشغيل الخادم

### **مشكلة: التطبيق لا يعمل**
1. تأكد من تثبيت جميع التبعيات
2. تأكد من إعداد Firebase
3. تأكد من رقم الهاتف صحيح

**📞 كل شيء جاهز! فقط اتبع الخطوات وسيعمل التطبيق مثالياً!**
