# 🚀 نظام المزامنة المدمج مع الوسيط - الإنتاج

## 📋 نظرة عامة

نظام مزامنة متكامل ومستمر مع شركة الوسيط العراقية، يعمل تلقائياً مع الخادم على Render ويحدث حالات الطلبات كل دقيقة.

## ⚡ الميزات الرئيسية

- **🔄 مزامنة مستمرة**: كل 60 ثانية
- **📊 كشف فوري**: للتغييرات في حالات الطلبات
- **🛡️ موثوقية عالية**: إعادة المحاولة التلقائية
- **📈 إحصائيات مفصلة**: مراقبة الأداء
- **🔧 تحكم كامل**: عبر API endpoints

## 🏗️ البنية

```
backend/
├── services/
│   ├── integrated_waseet_sync.js    # النظام الرئيسي
│   └── official_waseet_api.js       # API الوسيط الرسمي
├── routes/
│   └── orders.js                    # API endpoints
└── server.js                        # الخادم الرئيسي
```

## 🚀 التشغيل التلقائي

النظام يبدأ تلقائياً مع الخادم على Render:

1. **بدء الخادم** → النظام يبدأ تلقائياً بعد 10 ثواني
2. **اختبار الاتصال** → التحقق من الوسيط وقاعدة البيانات
3. **مزامنة فورية** → أول مزامنة فورية
4. **مزامنة مستمرة** → كل 60 ثانية

## 📊 API Endpoints

### حالة النظام
```http
GET /api/orders/waseet-sync-status
```

### مزامنة فورية
```http
POST /api/orders/force-waseet-sync
```

### إعادة تشغيل النظام
```http
POST /api/orders/restart-waseet-sync
```

### إيقاف النظام
```http
POST /api/orders/stop-waseet-sync
```

### بدء النظام
```http
POST /api/orders/start-waseet-sync
```

## 🖥️ المراقبة المحلية

```bash
# عرض حالة النظام
node monitor_waseet_sync.js status

# مزامنة فورية
node monitor_waseet_sync.js force

# إعادة تشغيل النظام
node monitor_waseet_sync.js restart

# مراقبة مستمرة
node monitor_waseet_sync.js watch
```

## 📈 الإحصائيات

النظام يتتبع:
- **إجمالي المزامنات**
- **المزامنات الناجحة/الفاشلة**
- **عدد الطلبات المحدثة**
- **مدة التشغيل**
- **معدل النجاح**

## 🔧 الإعدادات

```env
WASEET_USERNAME=mustfaabd
WASEET_PASSWORD=65888304
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_key
```

## 🛡️ الأمان والموثوقية

- **إعادة المحاولة التلقائية** عند فشل الاتصال
- **معالجة الأخطاء** الشاملة
- **تسجيل مفصل** للعمليات
- **حماية من التداخل** في المزامنة

## 📊 مثال على الاستجابة

```json
{
  "success": true,
  "data": {
    "isRunning": true,
    "isCurrentlySyncing": false,
    "syncIntervalSeconds": 60,
    "lastSyncTime": "2025-01-29T11:30:00.000Z",
    "nextSyncIn": 45000,
    "uptime": "2:15",
    "totalSyncs": 150,
    "successfulSyncs": 148,
    "failedSyncs": 2,
    "ordersUpdated": 25,
    "lastError": null
  }
}
```

## 🎯 كيفية العمل

1. **النظام يجلب** جميع الطلبات من API الوسيط الرسمي
2. **يقارن** مع الطلبات في قاعدة البيانات
3. **يحدث** الطلبات التي تغيرت حالتها
4. **يسجل** التغييرات في تاريخ الحالات
5. **يكرر** العملية كل 60 ثانية

## 🚨 استكشاف الأخطاء

### النظام لا يعمل
```bash
# تحقق من حالة النظام
curl https://your-app.onrender.com/api/orders/waseet-sync-status

# إعادة تشغيل النظام
curl -X POST https://your-app.onrender.com/api/orders/restart-waseet-sync
```

### لا توجد تحديثات
- تحقق من صحة بيانات الوسيط
- تأكد من وجود طلبات في قاعدة البيانات
- راجع سجلات الأخطاء

## 📞 الدعم

النظام مصمم ليعمل بشكل مستقل ومستمر. في حالة وجود مشاكل:

1. **راجع الإحصائيات** عبر API
2. **استخدم المراقب المحلي** للتشخيص
3. **أعد تشغيل النظام** إذا لزم الأمر

---

## ✅ النظام جاهز للإنتاج!

النظام الآن يعمل بشكل كامل ومستمر على Render ويزامن الطلبات مع الوسيط كل دقيقة. 🎉
