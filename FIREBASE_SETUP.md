# 🔥 إعداد Firebase للإشعارات المستهدفة

## 📋 الخطوات المطلوبة:

### 1. إنشاء مشروع Firebase
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "Add project" أو "إضافة مشروع"
3. اختر اسم للمشروع (مثل: `montajati-notifications`)
4. اتبع الخطوات لإنشاء المشروع

### 2. تفعيل Firebase Cloud Messaging (FCM)
1. في لوحة تحكم Firebase، اذهب إلى "Project Settings" → "Cloud Messaging"
2. تأكد من تفعيل Firebase Cloud Messaging API

### 3. إنشاء Service Account
1. اذهب إلى "Project Settings" → "Service accounts"
2. انقر على "Generate new private key"
3. سيتم تحميل ملف JSON يحتوي على المعلومات المطلوبة

### 4. استخراج المعلومات من ملف JSON
من الملف المحمل، استخرج المعلومات التالية:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "your-private-key-id", 
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "your-client-id"
}
```

### 5. تحديث ملف .env
أضف المعلومات التالية إلى ملف `.env`:

```env
# إعدادات Firebase للإشعارات
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your-client-id
```

## ⚠️ ملاحظات مهمة:

### تنسيق المفتاح الخاص:
- يجب أن يكون المفتاح محاط بعلامات اقتباس مزدوجة
- يجب استخدام `\n` للأسطر الجديدة
- يجب أن يبدأ بـ `-----BEGIN PRIVATE KEY-----`
- يجب أن ينتهي بـ `-----END PRIVATE KEY-----`

### مثال صحيح:
```env
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----"
```

### مثال خاطئ:
```env
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
-----END PRIVATE KEY-----
```

## 🧪 اختبار الإعداد:

بعد إضافة المتغيرات، أعد تشغيل الخادم:

```bash
npm run dev
```

يجب أن ترى الرسالة:
```
✅ تم تهيئة Firebase Admin للإشعارات المستهدفة
```

إذا رأيت خطأ، تحقق من:
1. تنسيق المفتاح الخاص
2. صحة معرف المشروع
3. صحة البريد الإلكتروني للخدمة

## 🔒 الأمان:

- **لا تشارك** ملف `.env` أو معلومات Firebase
- أضف `.env` إلى `.gitignore`
- استخدم متغيرات البيئة في الإنتاج
