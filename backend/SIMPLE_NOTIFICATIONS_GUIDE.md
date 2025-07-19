# 📱 دليل الإشعارات البسيط - للمطور

## 🎯 **ما تريده:**
- المستخدم يثبت التطبيق → يحصل على إشعارات تلقائياً
- تغيير حالة الطلب → إشعار فوري للمستخدم
- بدون تعقيدات → كل شيء يعمل تلقائياً

---

## ✅ **الخادم جاهز 100%**

النظام يعمل تلقائياً:
- ✅ قاعدة البيانات محدثة
- ✅ معالج الإشعارات يعمل
- ✅ Firebase مهيأ
- ✅ API endpoints جاهزة

---

## 📱 **المطلوب في التطبيق فقط:**

### **1. تثبيت Firebase:**
```bash
# React Native
npm install @react-native-firebase/app @react-native-firebase/messaging

# Flutter
flutter pub add firebase_messaging
```

### **2. إضافة كود بسيط في التطبيق:**

#### **React Native:**
```javascript
// App.js
import messaging from '@react-native-firebase/messaging';

// عند تشغيل التطبيق
useEffect(() => {
  setupNotifications();
}, []);

const setupNotifications = async () => {
  try {
    // طلب إذن الإشعارات
    await messaging().requestPermission();
    
    // الحصول على FCM Token
    const fcmToken = await messaging().getToken();
    
    // إرسال للخادم (تلقائياً)
    await registerToken(fcmToken);
    
  } catch (error) {
    console.log('خطأ في الإشعارات:', error);
  }
};

const registerToken = async (fcmToken) => {
  const userPhone = getUserPhone(); // هاتف المستخدم من التطبيق
  
  try {
    await fetch('https://your-api.com/api/fcm/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_phone: userPhone,
        fcm_token: fcmToken
      })
    });
    
    console.log('✅ تم تسجيل الإشعارات');
  } catch (error) {
    console.log('خطأ في التسجيل:', error);
  }
};

// استقبال الإشعارات
messaging().onMessage(async remoteMessage => {
  // عرض الإشعار
  Alert.alert(
    remoteMessage.notification.title,
    remoteMessage.notification.body
  );
});
```

#### **Flutter:**
```dart
// main.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    setupNotifications();
  }

  setupNotifications() async {
    // طلب إذن الإشعارات
    await FirebaseMessaging.instance.requestPermission();
    
    // الحصول على FCM Token
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    
    // إرسال للخادم
    await registerToken(fcmToken);
    
    // استقبال الإشعارات
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // عرض الإشعار
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(message.notification?.title ?? ''),
          content: Text(message.notification?.body ?? ''),
        ),
      );
    });
  }

  registerToken(String? fcmToken) async {
    String userPhone = getUserPhone(); // هاتف المستخدم
    
    try {
      await http.post(
        Uri.parse('https://your-api.com/api/fcm/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_phone': userPhone,
          'fcm_token': fcmToken
        })
      );
      
      print('✅ تم تسجيل الإشعارات');
    } catch (error) {
      print('خطأ في التسجيل: $error');
    }
  }
}
```

---

## 🔄 **كيف يعمل النظام:**

### **1. المستخدم يثبت التطبيق:**
- التطبيق يطلب إذن الإشعارات تلقائياً
- يحصل على FCM Token
- يرسله للخادم تلقائياً
- ✅ المستخدم مسجل للإشعارات

### **2. تغيير حالة الطلب:**
- تحديث في قاعدة البيانات
- Trigger يعمل تلقائياً
- إنشاء إشعار في قائمة الانتظار
- معالج الإشعارات يرسل للمستخدم
- ✅ المستخدم يحصل على إشعار فوري

---

## 🧪 **اختبار النظام:**

### **1. تسجيل FCM Token يدوياً:**
```bash
curl -X POST https://your-api.com/api/fcm/register \
  -H "Content-Type: application/json" \
  -d '{
    "user_phone": "07503597589",
    "fcm_token": "real-fcm-token-from-app"
  }'
```

### **2. إرسال إشعار تجريبي:**
```bash
curl -X POST https://your-api.com/api/fcm/test-notification \
  -H "Content-Type: application/json" \
  -d '{
    "user_phone": "07503597589",
    "title": "اختبار الإشعارات",
    "message": "هذا إشعار تجريبي"
  }'
```

### **3. فحص حالة التسجيل:**
```bash
curl https://your-api.com/api/fcm/status/07503597589
```

---

## 🎉 **النتيجة النهائية:**

### **✅ للمستخدم:**
1. يثبت التطبيق
2. يوافق على الإشعارات
3. ✅ يحصل على إشعارات تلقائياً

### **✅ لك:**
1. تغير حالة الطلب
2. ✅ المستخدم يحصل على إشعار فوري

### **🚀 بدون تعقيدات:**
- لا حاجة لتثبيت أي شيء إضافي
- لا حاجة لإعدادات معقدة
- كل شيء يعمل تلقائياً

---

## 📋 **ملخص المطلوب:**

### **في التطبيق (مرة واحدة فقط):**
1. تثبيت Firebase
2. إضافة 20 سطر كود
3. ✅ انتهى!

### **في الخادم:**
- ✅ كل شيء جاهز ويعمل

**💯 النظام سيعمل بشكل مثالي فور إضافة الكود للتطبيق!**
