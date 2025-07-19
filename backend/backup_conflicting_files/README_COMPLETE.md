# 🚀 نظام منتجاتي - النسخة الكاملة

## 📋 نظرة عامة

نظام شامل لإدارة المنتجات والطلبات مع تكامل كامل مع شركة الوسيط للتوصيل، إشعارات Firebase، وإشعارات Telegram.

## ✨ المميزات

### 🔥 الأنظمة الأساسية
- ✅ **إدارة المستخدمين والمنتجات**
- ✅ **نظام الطلبات المتكامل**
- ✅ **مزامنة تلقائية مع شركة الوسيط**
- ✅ **إشعارات Firebase المستهدفة**
- ✅ **إشعارات Telegram**
- ✅ **مراقبة حالة الطلبات في الوقت الفعلي**
- ✅ **نظام طلبات السحب**

### 🛡️ الأمان والموثوقية
- ✅ **معالجة شاملة للأخطاء**
- ✅ **نظام تسجيل متقدم**
- ✅ **اختبارات تلقائية**
- ✅ **مراقبة صحة النظام**

## 🚀 التشغيل السريع

### 1. إعداد البيئة
```bash
# نسخ ملف البيئة
cp .env.example .env

# تحرير المتغيرات
nano .env
```

### 2. إعداد قاعدة البيانات
```bash
# إنشاء الجداول
node setup_database_complete.js
```

### 3. اختبار النظام
```bash
# اختبار شامل لجميع الأنظمة
node test_system_complete.js
```

### 4. تشغيل النظام
```bash
# تشغيل النظام الكامل
node start_system_complete.js

# أو للتطوير
npm run dev
```

## ⚙️ إعداد المتغيرات

### 🗄️ قاعدة البيانات (Supabase)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
DATABASE_URL=postgresql://postgres:password@host:5432/database
```

### 🔥 Firebase (للإشعارات)
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your-client-id
```

### 📱 Telegram
```env
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_CHAT_ID=your-chat-id
TELEGRAM_NOTIFICATIONS_ENABLED=true
```

### 🚚 شركة الوسيط
```env
ALMASEET_BASE_URL=https://api.alwaseet-iq.net
WASEET_USERNAME=your-username
WASEET_PASSWORD=your-password
```

## 🔧 الأوامر المتاحة

### 📊 اختبار النظام
```bash
# اختبار شامل
node test_system_complete.js

# اختبار مكون محدد
node -e "
const SystemTester = require('./test_system_complete');
const tester = new SystemTester();
tester.testDatabase().then(() => console.log('تم'));
"
```

### 🗄️ إدارة قاعدة البيانات
```bash
# إعداد قاعدة البيانات
node setup_database_complete.js

# إعادة تعيين قاعدة البيانات
node -e "
const DatabaseSetup = require('./setup_database_complete');
const setup = new DatabaseSetup();
setup.setupComplete();
"
```

### 🚀 تشغيل النظام
```bash
# تشغيل النظام الكامل
node start_system_complete.js

# تشغيل خادم الإنتاج
node production_server.js

# تشغيل للتطوير
npm run dev
```

## 🌐 نقاط النهاية (API Endpoints)

### 🔍 مراقبة النظام
- `GET /health` - فحص صحة النظام
- `GET /services/status` - حالة الخدمات
- `GET /test` - اختبار شامل للنظام
- `POST /services/restart` - إعادة تشغيل الخدمات

### 👥 المستخدمين
- `POST /api/auth/register` - تسجيل مستخدم جديد
- `POST /api/auth/login` - تسجيل الدخول
- `GET /api/users/profile` - الملف الشخصي

### 📦 المنتجات
- `GET /api/products` - قائمة المنتجات
- `POST /api/products` - إضافة منتج
- `PUT /api/products/:id` - تحديث منتج
- `DELETE /api/products/:id` - حذف منتج

### 🛒 الطلبات
- `GET /api/orders` - قائمة الطلبات
- `POST /api/orders` - إنشاء طلب جديد
- `GET /api/orders/:id` - تفاصيل الطلب
- `PUT /api/orders/:id/status` - تحديث حالة الطلب

## 🔔 نظام الإشعارات

### 📱 إشعارات Firebase
- إشعارات مستهدفة للمستخدمين
- تحديثات حالة الطلبات
- إشعارات طلبات السحب

### 📢 إشعارات Telegram
- تنبيهات المخزون المنخفض
- تحديثات النظام
- تقارير الأخطاء

## 🔄 نظام المزامنة

### 🚚 مزامنة شركة الوسيط
- مزامنة تلقائية كل 10 دقائق
- تحديث حالات الطلبات
- معالجة الأخطاء التلقائية
- نظام إعادة المحاولة

### 👁️ مراقبة الحالات
- مراقبة حالة الطلبات (كل 30 ثانية)
- مراقبة طلبات السحب (كل 30 ثانية)
- إرسال إشعارات فورية

## 🛠️ استكشاف الأخطاء

### ❌ مشاكل شائعة

#### 🔥 Firebase لا يعمل
```bash
# تحقق من المتغيرات
echo $FIREBASE_PROJECT_ID
echo $FIREBASE_CLIENT_EMAIL

# اختبار Firebase
node -e "
const { firebaseConfig } = require('./config/firebase');
firebaseConfig.initialize().then(console.log);
"
```

#### 📱 Telegram لا يعمل
```bash
# اختبار Telegram
node -e "
const TelegramService = require('./telegram_notification_service');
const service = new TelegramService();
service.testConnection().then(console.log);
"
```

#### 🚚 شركة الوسيط لا تعمل
```bash
# اختبار المصادقة
node -e "
const OrderSync = require('./sync/order_status_sync_service');
const sync = new OrderSync();
sync.authenticateWaseet().then(console.log);
"
```

### 📊 مراقبة الأداء
```bash
# فحص حالة النظام
curl http://localhost:3003/health

# فحص حالة الخدمات
curl http://localhost:3003/services/status

# اختبار شامل
curl http://localhost:3003/test
```

## 📁 هيكل المشروع

```
backend/
├── config/                 # إعدادات النظام
│   ├── firebase.js         # إعداد Firebase
│   └── supabase.js         # إعداد Supabase
├── services/               # الخدمات الأساسية
│   ├── notification_master_service.js
│   ├── targeted_notification_service.js
│   ├── order_status_watcher.js
│   └── withdrawal_status_watcher.js
├── sync/                   # خدمات المزامنة
│   ├── order_status_sync_service.js
│   ├── waseet_token_helper.js
│   └── status_mapper.js
├── routes/                 # مسارات API
├── database/              # ملفات قاعدة البيانات
├── test_system_complete.js    # اختبار شامل
├── setup_database_complete.js # إعداد قاعدة البيانات
├── start_system_complete.js   # تشغيل النظام الكامل
└── production_server.js       # خادم الإنتاج
```

## 🤝 المساهمة

1. Fork المشروع
2. إنشاء فرع للميزة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push للفرع (`git push origin feature/AmazingFeature`)
5. فتح Pull Request

## 📄 الترخيص

هذا المشروع مرخص تحت رخصة MIT - راجع ملف [LICENSE](LICENSE) للتفاصيل.

## 📞 الدعم

للحصول على الدعم، يرجى فتح issue في GitHub أو التواصل عبر:
- Email: support@montajati.com
- Telegram: @montajati_support

---

**تم تطوير هذا النظام بعناية فائقة لضمان الموثوقية والأداء العالي** 🚀
