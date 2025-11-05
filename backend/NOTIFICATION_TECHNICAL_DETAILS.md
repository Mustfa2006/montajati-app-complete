# 🔧 التفاصيل الفنية للإشعارات

## 📍 مسار الإشعار الكامل

### 1️⃣ نقطة البداية: integrated_waseet_sync.js

**الملف:** `backend/services/integrated_waseet_sync.js`

**الدالة الرئيسية:**
```javascript
async syncOrdersWithWaseet() {
  // 1. جلب الطلبات من الوسيط
  // 2. مقارنة الحالات
  // 3. اكتشاف التغييرات
  // 4. تحديث قاعدة البيانات
  // 5. استدعاء sendStatusChangeNotification()
}
```

**استدعاء الإشعار:**
```javascript
await this.sendStatusChangeNotification(
  dbOrder,           // كائن الطلب الكامل
  appStatus,         // الحالة الجديدة
  waseetStatusText   // نص حالة الوسيط
);
```

---

### 2️⃣ فحص ذكي لمنع التكرار

**الملف:** `backend/services/integrated_waseet_sync.js` (السطور 460-475)

```javascript
// ✅ فحص ذكي لمنع التكرار
if (order.last_notification_status === newStatus) {
  console.log(`⏭️ تخطي الإشعار: تم إرسال إشعار لهذه الحالة بالفعل`);
  return; // ❌ لا تفعل شيء
}

// ✅ فلترة الحالات المسموحة
if (!allowedNotificationStatuses.includes(newStatus)) {
  console.log(`🚫 تم تجاهل إشعار الحالة: غير مدرجة في القائمة المسموحة`);
  return; // ❌ لا تفعل شيء
}

// ✅ متابعة الإرسال
await targetedNotificationService.sendOrderStatusNotification(...);
```

---

### 3️⃣ البحث عن FCM Token

**الملف:** `backend/services/targeted_notification_service.js` (السطور 130-145)

```javascript
async sendOrderStatusNotification(userPhone, orderId, newStatus, customerName) {
  // 1. البحث عن FCM Token
  const fcmToken = await this.getUserFCMToken(userPhone);
  
  if (!fcmToken) {
    console.log(`⚠️ لا يوجد FCM Token للمستخدم: ${userPhone}`);
    return { success: false, error: 'لا يوجد FCM Token' };
  }
  
  // 2. متابعة الإرسال
  const result = await firebaseAdminService.sendOrderStatusNotification(...);
  
  // 3. تسجيل النتيجة
  await this.logNotification({...});
  
  return result;
}
```

**دالة البحث:**
```javascript
async getUserFCMToken(userPhone) {
  const { data, error } = await this.supabase
    .from('fcm_tokens')
    .select('fcm_token')
    .eq('user_phone', userPhone)
    .eq('is_active', true)
    .order('last_used_at', { ascending: false })
    .limit(1)
    .single();
  
  return data?.fcm_token || null;
}
```

---

### 4️⃣ إنشاء رسالة الإشعار

**الملف:** `backend/services/firebase_admin_service.js` (السطور 200-338)

```javascript
async sendOrderStatusNotification(fcmToken, orderId, newStatus, customerName) {
  // 1. تحديد العنوان والرسالة حسب الحالة
  const statusConfig = {
    'قيد التوصيل الى الزبون (في عهدة المندوب)': {
      title: '🚗 قيد التوصيل',
      message: 'قيد التوصيل'
    },
    'تم التسليم للزبون': {
      title: '✅ تم التسليم',
      message: 'تم التسليم'
    },
    'الغاء الطلب': {
      title: '❌ إلغاء الطلب',
      message: 'الغاء الطلب'
    },
    // ... 18 حالة أخرى
  };
  
  const config = statusConfig[newStatus];
  const title = config?.title || '📦 تحديث حالة طلبك';
  const body = `${customerName} - (${config?.message || newStatus})`;
  
  // 2. إنشاء رسالة FCM
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body
    },
    data: {
      type: 'order_status_update',
      orderId: orderId.toString(),
      newStatus: newStatus,
      customerName: customerName || '',
      timestamp: new Date().toISOString(),
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
    android: {
      notification: {
        channelId: 'montajati_notifications',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
        icon: '@mipmap/ic_launcher',
        color: '#FFD700'
      },
      priority: 'high'
    },
    apns: {
      payload: {
        aps: {
          alert: { title: title, body: body },
          sound: 'default',
          badge: 1
        }
      }
    }
  };
  
  // 3. إرسال الرسالة
  const response = await this.messaging.send(message);
  
  return {
    success: true,
    messageId: response,
    timestamp: new Date().toISOString()
  };
}
```

---

### 5️⃣ تحديث آخر حالة إشعار

**الملف:** `backend/services/integrated_waseet_sync.js` (السطور 495-510)

```javascript
if (result.success) {
  // ✅ تحديث آخر حالة تم إرسال إشعار لها
  await this.supabase
    .from('orders')
    .update({ last_notification_status: newStatus })
    .eq('id', order.id);
  
  console.log(`📝 تم تحديث آخر حالة إشعار: ${newStatus}`);
}
```

---

## 📊 جدول البيانات

### جدول `orders`

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  order_number VARCHAR(50),
  customer_name VARCHAR(255),
  user_phone VARCHAR(20),
  status VARCHAR(100),
  last_notification_status VARCHAR(100),  -- ✅ آخر حالة تم إرسال إشعار لها
  waseet_status_text VARCHAR(255),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### جدول `fcm_tokens`

```sql
CREATE TABLE fcm_tokens (
  id UUID PRIMARY KEY,
  user_phone VARCHAR(20),
  fcm_token TEXT,
  is_active BOOLEAN DEFAULT true,
  device_info JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  last_used_at TIMESTAMP
);
```

### جدول `notification_logs`

```sql
CREATE TABLE notification_logs (
  id UUID PRIMARY KEY,
  user_phone VARCHAR(20),
  fcm_token TEXT,
  notification_type VARCHAR(50),
  title VARCHAR(255),
  message TEXT,
  data JSONB,
  success BOOLEAN,
  error_message TEXT,
  firebase_message_id VARCHAR(255),
  created_at TIMESTAMP
);
```

---

## 🔄 دورة الحياة الكاملة

```
1. تحديث الوسيط
   ↓
2. المزامنة التلقائية (كل 5 دقائق)
   ↓
3. اكتشاف التغيير
   ↓
4. تحديث قاعدة البيانات
   ↓
5. فحص last_notification_status
   ├─ إذا كانت نفس الحالة → تخطي
   └─ إذا كانت حالة جديدة → متابعة
   ↓
6. فحص الحالات المسموحة
   ├─ إذا كانت غير مسموحة → تخطي
   └─ إذا كانت مسموحة → متابعة
   ↓
7. البحث عن FCM Token
   ├─ إذا لم يوجد → إيقاف
   └─ إذا وجد → متابعة
   ↓
8. إنشاء رسالة الإشعار
   ↓
9. إرسال عبر Firebase
   ↓
10. تسجيل في notification_logs
   ↓
11. تحديث last_notification_status
   ↓
12. ✅ انتهى
```

---

## ⚡ الأداء

| العملية | الوقت |
|---------|--------|
| جلب الطلبات من الوسيط | 1-2 ثانية |
| مقارنة الحالات | < 100 ميلي ثانية |
| تحديث قاعدة البيانات | < 500 ميلي ثانية |
| البحث عن FCM Token | < 200 ميلي ثانية |
| إرسال الإشعار | < 1 ثانية |
| **الإجمالي** | **< 5 ثوان** |

---

## 🛡️ آليات الحماية

1. ✅ **فحص التكرار** - last_notification_status
2. ✅ **فلترة الحالات** - allowedNotificationStatuses
3. ✅ **معالجة الأخطاء** - try/catch شامل
4. ✅ **تسجيل الأحداث** - notification_logs
5. ✅ **مصدر واحد** - integrated_waseet_sync.js فقط

