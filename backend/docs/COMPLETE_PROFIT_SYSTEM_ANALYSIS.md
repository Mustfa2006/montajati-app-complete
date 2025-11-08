# 📊 تحليل شامل لنظام إدارة الأرباح - Montajati App

## 🎯 **نظرة عامة:**

هذا تحليل شامل لكامل نظام إدارة الأرباح في تطبيق منتجاتي، يشرح:
1. كيف تتغير الأرباح عند تغيير حالة الطلب
2. جميع الأنظمة المسؤولة عن إدارة الأرباح
3. كيف تعمل قاعدة البيانات
4. سيناريوهات التغيير الكاملة

---

## 📋 **جدول المحتويات:**

1. [هيكل قاعدة البيانات](#1-هيكل-قاعدة-البيانات)
2. [أنواع الأرباح وحالات الطلبات](#2-أنواع-الأرباح-وحالات-الطلبات)
3. [الأنظمة المسؤولة عن إدارة الأرباح](#3-الأنظمة-المسؤولة-عن-إدارة-الأرباح)
4. [تدفق البيانات الكامل](#4-تدفق-البيانات-الكامل)
5. [سيناريوهات تغيير الحالة](#5-سيناريوهات-تغيير-الحالة)
6. [آليات الحماية](#6-آليات-الحماية)
7. [أمثلة عملية](#7-أمثلة-عملية)

---

## 1. هيكل قاعدة البيانات

### **جدول `users`:**

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,

  -- 💰 الأرباح
  achieved_profits DECIMAL(15,2) DEFAULT 0,  -- الأرباح المحققة (من طلبات مسلمة)
  expected_profits DECIMAL(15,2) DEFAULT 0,  -- الأرباح المنتظرة (من طلبات نشطة)

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### **جدول `orders`:**

```sql
CREATE TABLE orders (
  id VARCHAR(50) PRIMARY KEY,
  order_number VARCHAR(100) UNIQUE,
  user_phone TEXT REFERENCES users(phone),  -- رقم هاتف صاحب الطلب
  customer_name VARCHAR(100),

  -- 📊 معلومات الطلب
  status VARCHAR(50) DEFAULT 'نشط',  -- حالة الطلب
  total DECIMAL(12,2),
  profit DECIMAL(12,2) DEFAULT 0,  -- ربح هذا الطلب

  -- 🚚 معلومات الوسيط
  waseet_status VARCHAR(50),
  waseet_status_id INTEGER,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### **جدول `profit_operations_log`:**

```sql
CREATE TABLE profit_operations_log (
  id BIGSERIAL PRIMARY KEY,
  user_phone TEXT NOT NULL,
  operation_type TEXT NOT NULL,  -- 'ADD', 'WITHDRAW', 'RESET'

  -- القيم القديمة والجديدة
  old_achieved_profits DECIMAL(15,2),
  new_achieved_profits DECIMAL(15,2),
  old_expected_profits DECIMAL(15,2),
  new_expected_profits DECIMAL(15,2),

  amount_changed DECIMAL(15,2),
  reason TEXT,
  authorized_by TEXT,
  is_authorized BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT NOW()
);
```

**الغرض:** تسجيل كل عملية تعديل على الأرباح للمراجعة والتدقيق.

---

## 2. أنواع الأرباح وحالات الطلبات

### **🎯 أنواع الأرباح:**

```dart
enum ProfitType {
  achieved,  // ربح محقق - من طلبات مسلمة
  expected,  // ربح منتظر - من طلبات نشطة/قيد التوصيل
  none,      // لا ربح - من طلبات ملغية/مرفوضة
}
```

### **📊 تصنيف حالات الطلبات:**

#### **🟢 حالات الربح المحقق (Achieved):**

| الحالة | الوصف |
|--------|-------|
| `تم التسليم للزبون` | الطلب تم تسليمه بنجاح للعميل |

**القاعدة:** فقط الطلبات المسلمة تحقق ربح فعلي.

#### **🔵 حالات الربح المنتظر (Expected):**

| الحالة | الوصف |
|--------|-------|
| `نشط` | الطلب جديد ونشط |
| `تم تغيير محافظة الزبون` | تم تغيير المحافظة |
| `تغيير المندوب` | تم تغيير المندوب |
| `قيد التوصيل الى الزبون (في عهدة المندوب)` | الطلب في طريقه للعميل |
| `مؤجل` | الطلب مؤجل لوقت لاحق |
| `مؤجل لحين اعادة الطلب لاحقا` | الطلب مؤجل بطلب من العميل |

**القاعدة:** الطلبات النشطة أو قيد التوصيل أو المؤجلة = ربح منتظر.

#### **🔴 حالات بدون ربح (None):**

| الحالة | الوصف |
|--------|-------|
| `لا يرد` | العميل لا يرد على الهاتف |
| `لا يرد بعد الاتفاق` | العميل لا يرد بعد الاتفاق |
| `مغلق` | الهاتف مغلق |
| `مغلق بعد الاتفاق` | الهاتف مغلق بعد الاتفاق |
| `الغاء الطلب` | تم إلغاء الطلب |
| `رفض الطلب` | تم رفض الطلب |
| `مفصول عن الخدمة` | الرقم مفصول |
| `طلب مكرر` | الطلب مكرر |
| `مستلم مسبقا` | تم استلامه مسبقاً |
| `الرقم غير معرف` | الرقم غير معروف |
| `الرقم غير داخل في الخدمة` | الرقم غير نشط |
| `لا يمكن الاتصال بالرقم` | لا يمكن الاتصال |
| `العنوان غير دقيق` | العنوان غير صحيح |
| `لم يطلب` | العميل لم يطلب |
| `حظر المندوب` | المندوب محظور |

**القاعدة:** الطلبات الملغية أو المرفوضة = لا ربح.

---

## 3. الأنظمة المسؤولة عن إدارة الأرباح

### **A. Frontend (Flutter):**

#### **1. `SmartProfitTransfer` - نظام نقل الأرباح الذكي**

**الموقع:** `frontend/lib/services/smart_profit_transfer.dart`

**الوظيفة الرئيسية:**
```dart
static Future<bool> transferOrderProfit({
  required String userPhone,
  required double orderProfit,
  required String oldStatus,
  required String newStatus,
  required String orderId,
  required String orderNumber,
}) async
```

**المسؤوليات:**
1. ✅ نقل ربح طلب واحد بين المنتظر والمحقق
2. ✅ التحقق من نوع الربح للحالة القديمة والجديدة
3. ✅ تحديث `achieved_profits` و `expected_profits` في جدول `users`
4. ✅ منع الأرقام السالبة
5. ✅ تسجيل العملية في `profit_operations_log`

**مثال على العملية:**
```dart
// الحالة القديمة: "نشط" → ربح منتظر
// الحالة الجديدة: "تم التسليم للزبون" → ربح محقق

// النتيجة:
expected_profits -= orderProfit;  // ينقص من المنتظر
achieved_profits += orderProfit;  // يزيد في المحقق
```

#### **2. `OrderStatusMonitor` - مراقب حالة الطلبات**

**الموقع:** `frontend/lib/services/order_status_monitor.dart`

**الوظيفة الرئيسية:**
```dart
static void startMonitoring()
```

**المسؤوليات:**
1. ✅ الاستماع لتغييرات حالة الطلبات عبر Supabase Realtime
2. ✅ استدعاء `SmartProfitTransfer.transferOrderProfit()` عند تغيير الحالة
3. ✅ إرسال إشعارات للمستخدم عند تحقيق الربح
4. ✅ تجاهل الحالات غير المهمة (فعال، في موقع فرز بغداد، في الطريق الى مكتب المحافظة)

**كيف يعمل:**
```dart
_supabase
    .channel('order_status_changes')
    .onPostgresChanges(
      event: PostgresChangeEvent.update,  // يستمع لتحديثات جدول orders
      schema: 'public',
      table: 'orders',
      callback: _handleOrderStatusChange,  // يستدعي هذه الدالة عند التحديث
    )
    .subscribe();
```

**الحماية المضافة:**
```dart
// 🚫 تجاهل إذا لم تتغير الحالة
if (oldStatus == newStatus) return;

// 🚫 تجاهل الحالات غير المهمة
const ignoredStatuses = ['فعال', 'في موقع فرز بغداد', 'في الطريق الى مكتب المحافظة'];
if (ignoredStatuses.contains(newStatus)) return;
```

#### **3. `SmartProfitsManager` - مدير الأرباح الذكي**

**الموقع:** `frontend/lib/services/smart_profits_manager.dart`

**الوظيفة الرئيسية:**
```dart
static ProfitType getProfitType(String orderStatus)
static Future<Map<String, double>> recalculateUserProfits(String userPhone)
```

**المسؤوليات:**
1. ✅ تحديد نوع الربح حسب حالة الطلب
2. ✅ إعادة حساب أرباح المستخدم من الصفر
3. ✅ جلب جميع طلبات المستخدم وحساب الأرباح المحققة والمنتظرة
4. ✅ تحديث قاعدة البيانات بالأرباح الصحيحة

**مثال على إعادة الحساب:**
```dart
// جلب جميع طلبات المستخدم
final orders = await _supabase.from('orders').select('*').eq('user_phone', userPhone);

double achievedProfits = 0.0;
double expectedProfits = 0.0;

for (var order in orders) {
  final status = order['status'];
  final profit = order['profit'];
  final profitType = getProfitType(status);

  if (profitType == ProfitType.achieved) {
    achievedProfits += profit;  // طلب مسلم
  } else if (profitType == ProfitType.expected) {
    expectedProfits += profit;  // طلب نشط/قيد التوصيل
  }
  // إذا كان ProfitType.none، لا نضيف شيء (طلب ملغي)
}

// تحديث قاعدة البيانات
await _supabase.from('users').update({
  'achieved_profits': achievedProfits,
  'expected_profits': expectedProfits,
}).eq('phone', userPhone);
```

#### **4. `ProfitsCalculatorService` - خدمة حساب الأرباح**

**الموقع:** `frontend/lib/services/profits_calculator_service.dart`

**الوظائف الرئيسية:**
```dart
static Future<bool> addToExpectedProfits({...})
static Future<bool> moveToAchievedProfits({...})
```

**المسؤوليات:**
1. ✅ إضافة ربح إلى الأرباح المنتظرة (عند تثبيت طلب جديد)
2. ✅ نقل ربح من المنتظرة إلى المحققة (عند تسليم الطلب)
3. ✅ استخدام دوال قاعدة البيانات الآمنة

---

### **B. Backend (Node.js):**

#### **1. `IntegratedWaseetSync` - مزامنة الوسيط المتكاملة**

**الموقع:** `backend/services/integrated_waseet_sync.js`

**المسؤوليات:**
1. ✅ مزامنة حالات الطلبات من API الوسيط كل 5 دقائق
2. ✅ تحديث حالة الطلب في قاعدة البيانات
3. ✅ **تجاهل الحالات غير المهمة (1, 5, 7) بدون تحديث قاعدة البيانات**

**الحماية المضافة:**
```javascript
const ignoredStatusIds = [1, 5, 7];
const ignoredStatusTexts = ['فعال', 'في موقع فرز بغداد', 'في الطريق الى مكتب المحافظة'];

if (ignoredStatusIds.includes(waseetStatusId) || ignoredStatusTexts.includes(waseetStatusText)) {
  console.log(`🚫 تم تجاهل حالة "${statusName}"`);

  // ⚠️ لا نحدث أي شيء في قاعدة البيانات!
  // أي UPDATE سيطلق realtime event ويسبب تكرار الأرباح
  continue;  // تخطي بالكامل
}
```

#### **2. `InstantStatusUpdater` - محدث الحالة الفوري**

**الموقع:** `backend/sync/instant_status_updater.js`

**المسؤوليات:**
1. ✅ تحديث حالة طلب واحد فوراً
2. ✅ **تجاهل الحالات غير المهمة بدون تحديث قاعدة البيانات**

---

### **C. Database (PostgreSQL):**

#### **1. `validate_profit_operation()` - دالة التحقق من عمليات الأرباح**

**الموقع:** `backend/database/profit_protection.sql`

**النوع:** Trigger Function

**المسؤوليات:**
1. ✅ منع النقصان غير المصرح به في الأرباح
2. ✅ منع الزيادة المشبوهة (أكثر من 1,000,000 دينار)
3. ✅ منع القيم السالبة
4. ✅ تسجيل كل عملية في `profit_operations_log`

**كيف تعمل:**
```sql
CREATE TRIGGER protect_profits_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    WHEN (OLD.achieved_profits IS DISTINCT FROM NEW.achieved_profits
          OR OLD.expected_profits IS DISTINCT FROM NEW.expected_profits)
    EXECUTE FUNCTION validate_profit_operation();
```

**القواعد:**
```sql
-- 🛡️ RULE 1: منع النقصان إلا في حالة السحب المصرح
IF (new_achieved < old_achieved OR new_expected < old_expected)
   AND operation_context NOT IN ('AUTHORIZED_WITHDRAWAL', 'AUTHORIZED_RESET') THEN
    RAISE EXCEPTION 'PROFIT_PROTECTION: محاولة غير مصرح بها لتقليل الأرباح';
END IF;

-- 🛡️ RULE 2: منع الزيادة المشبوهة (أكثر من 1,000,000 دينار)
IF (new_achieved - old_achieved) > 1000000 THEN
    RAISE EXCEPTION 'PROFIT_PROTECTION: زيادة مشبوهة في الأرباح المحققة';
END IF;

-- 🛡️ RULE 3: منع القيم السالبة
IF new_achieved < 0 OR new_expected < 0 THEN
    RAISE EXCEPTION 'PROFIT_PROTECTION: الأرباح لا يمكن أن تكون سالبة';
END IF;
```

#### **2. `safe_add_profits()` - دالة آمنة لإضافة الأرباح**

```sql
CREATE OR REPLACE FUNCTION safe_add_profits(
    p_user_phone TEXT,
    p_achieved_amount DECIMAL(15,2) DEFAULT 0,
    p_expected_amount DECIMAL(15,2) DEFAULT 0,
    p_reason TEXT DEFAULT 'إضافة أرباح',
    p_authorized_by TEXT DEFAULT 'SYSTEM'
)
RETURNS JSON
```

**كيف تعمل:**
```sql
-- تعيين سياق العملية (لتجاوز الحماية)
PERFORM set_config('app.operation_context', 'AUTHORIZED_ADD', true);
PERFORM set_config('app.authorized_by', p_authorized_by, true);

-- تنفيذ الإضافة
UPDATE users
SET achieved_profits = COALESCE(achieved_profits, 0) + p_achieved_amount,
    expected_profits = COALESCE(expected_profits, 0) + p_expected_amount,
    updated_at = NOW()
WHERE phone = p_user_phone;
```

#### **3. `safe_withdraw_profits()` - دالة آمنة لسحب الأرباح**

```sql
CREATE OR REPLACE FUNCTION safe_withdraw_profits(
    p_user_phone TEXT,
    p_amount DECIMAL(15,2),
    p_authorized_by TEXT DEFAULT 'SYSTEM'
)
RETURNS JSON
```

**كيف تعمل:**
```sql
-- التحقق من الرصيد
IF current_achieved < p_amount THEN
    RETURN json_build_object('success', false, 'error', 'الرصيد غير كافٍ');
END IF;

-- تعيين سياق العملية
PERFORM set_config('app.operation_context', 'AUTHORIZED_WITHDRAWAL', true);

-- تنفيذ السحب
UPDATE users
SET achieved_profits = achieved_profits - p_amount,
    updated_at = NOW()
WHERE phone = p_user_phone;
```

#### **4. Database Triggers الأخرى:**

**A. `log_order_status_change()` - تسجيل تغييرات حالة الطلبات**

```sql
CREATE TRIGGER trigger_order_status_change
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();
```

**الوظيفة:** تسجيل كل تغيير في حالة الطلب في جدول `order_status_history`.

**B. `queue_smart_notification()` - إضافة إشعارات ذكية**

```sql
CREATE TRIGGER smart_notification_trigger
    AFTER UPDATE ON orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION queue_smart_notification();
```

**الوظيفة:** إضافة إشعار لقائمة الانتظار عند تغيير حالة الطلب.

---

## 4. تدفق البيانات الكامل

### **السيناريو 1: تغيير حالة الطلب من "نشط" إلى "تم التسليم للزبون"**

```
1. Backend (IntegratedWaseetSync):
   ↓
   يجلب حالة الطلب من API الوسيط
   ↓
   يكتشف تغيير: "نشط" → "تم التسليم للزبون"
   ↓
   يحدث جدول orders:
   UPDATE orders SET status = 'تم التسليم للزبون' WHERE id = 'order_xxx'

2. Database (PostgreSQL):
   ↓
   Trigger: log_order_status_change() يسجل التغيير في order_status_history
   ↓
   Trigger: queue_smart_notification() يضيف إشعار لقائمة الانتظار
   ↓
   Supabase Realtime يطلق PostgresChangeEvent.update

3. Frontend (OrderStatusMonitor):
   ↓
   يستقبل PostgresChangeEvent.update
   ↓
   _handleOrderStatusChange() يتحقق من التغيير
   ↓
   يستدعي SmartProfitTransfer.transferOrderProfit()

4. Frontend (SmartProfitTransfer):
   ↓
   يحدد نوع الربح:
   - oldStatus = "نشط" → ProfitType.expected
   - newStatus = "تم التسليم للزبون" → ProfitType.achieved
   ↓
   يحسب الأرباح الجديدة:
   - expected_profits -= orderProfit
   - achieved_profits += orderProfit
   ↓
   يحدث جدول users:
   UPDATE users SET
     achieved_profits = newAchieved,
     expected_profits = newExpected
   WHERE phone = userPhone

5. Database (validate_profit_operation):
   ↓
   يتحقق من صحة العملية:
   ✅ الزيادة في achieved_profits مقبولة
   ✅ النقصان في expected_profits مقبول (لأن الزيادة في achieved تعوضه)
   ✅ لا توجد قيم سالبة
   ↓
   يسجل العملية في profit_operations_log
   ↓
   يسمح بالتحديث

6. النتيجة النهائية:
   ✅ حالة الطلب تغيرت
   ✅ الربح انتقل من المنتظر إلى المحقق
   ✅ العملية مسجلة في السجل
   ✅ المستخدم يستلم إشعار
```

---

## 5. سيناريوهات تغيير الحالة

### **📊 جدول شامل لجميع السيناريوهات:**

| الحالة القديمة | الحالة الجديدة | نوع الربح القديم | نوع الربح الجديد | التغيير في الأرباح |
|----------------|----------------|------------------|------------------|---------------------|
| `نشط` | `تم التسليم للزبون` | Expected | Achieved | `expected -= profit`<br>`achieved += profit` |
| `نشط` | `الغاء الطلب` | Expected | None | `expected -= profit` |
| `نشط` | `قيد التوصيل` | Expected | Expected | لا تغيير |
| `قيد التوصيل` | `تم التسليم للزبون` | Expected | Achieved | `expected -= profit`<br>`achieved += profit` |
| `قيد التوصيل` | `رفض الطلب` | Expected | None | `expected -= profit` |
| `قيد التوصيل` | `نشط` | Expected | Expected | لا تغيير |
| `تم التسليم للزبون` | `قيد التوصيل` | Achieved | Expected | `achieved -= profit`<br>`expected += profit` |
| `تم التسليم للزبون` | `نشط` | Achieved | Expected | `achieved -= profit`<br>`expected += profit` |
| `الغاء الطلب` | `نشط` | None | Expected | `expected += profit` |
| `الغاء الطلب` | `قيد التوصيل` | None | Expected | `expected += profit` |
| `مؤجل` | `تم التسليم للزبون` | Expected | Achieved | `expected -= profit`<br>`achieved += profit` |
| `مؤجل` | `الغاء الطلب` | Expected | None | `expected -= profit` |

---

## 6. آليات الحماية

### **A. حماية Frontend:**

#### **1. في `OrderStatusMonitor`:**

```dart
// 🚫 تجاهل إذا لم تتغير الحالة
if (oldStatus == newStatus) {
  debugPrint('⏭️ تجاهل التحديث - الحالة لم تتغير');
  return;
}

// 🚫 تجاهل الحالات غير المهمة
const ignoredStatuses = ['فعال', 'في موقع فرز بغداد', 'في الطريق الى مكتب المحافظة'];
if (ignoredStatuses.contains(newStatus)) {
  debugPrint('🚫 تجاهل حالة غير مهمة');
  return;
}
```

#### **2. في `SmartProfitTransfer`:**

```dart
// 🚫 حماية إضافية: تجاهل الحالات غير المهمة
const ignoredStatuses = ['فعال', 'في موقع فرز بغداد', 'في الطريق الى مكتب المحافظة'];
if (ignoredStatuses.contains(oldStatus) || ignoredStatuses.contains(newStatus)) {
  debugPrint('🚫 تجاهل نقل الربح - حالة غير مهمة');
  return true;
}

// 🚫 حماية من الحالات الفارغة أو المتطابقة
if (oldStatus.isEmpty || newStatus.isEmpty || oldStatus == newStatus) {
  debugPrint('⏭️ تجاهل نقل الربح - حالات فارغة أو متطابقة');
  return true;
}

// 🚫 منع الأرقام السالبة
newAchieved = newAchieved < 0 ? 0 : newAchieved;
newExpected = newExpected < 0 ? 0 : newExpected;
```

### **B. حماية Backend:**

#### **1. في `IntegratedWaseetSync`:**

```javascript
// 🚫 تجاهل الحالات غير المهمة بدون تحديث قاعدة البيانات
if (ignoredStatusIds.includes(waseetStatusId) || ignoredStatusTexts.includes(waseetStatusText)) {
  console.log(`🚫 تم تجاهل حالة "${statusName}"`);
  console.log(`⏭️ تخطي الطلب بالكامل - لا تحديث في قاعدة البيانات`);
  continue;  // لا UPDATE = لا realtime event = لا تكرار أرباح
}
```

### **C. حماية Database:**

#### **1. Trigger `validate_profit_operation()`:**

```sql
-- منع النقصان غير المصرح
IF (new_achieved < old_achieved OR new_expected < old_expected)
   AND operation_context NOT IN ('AUTHORIZED_WITHDRAWAL', 'AUTHORIZED_RESET') THEN
    RAISE EXCEPTION 'PROFIT_PROTECTION: محاولة غير مصرح بها';
END IF;

-- منع الزيادة المشبوهة
IF (new_achieved - old_achieved) > 1000000 THEN
    RAISE EXCEPTION 'PROFIT_PROTECTION: زيادة مشبوهة';
END IF;

-- منع القيم السالبة
IF new_achieved < 0 OR new_expected < 0 THEN
    RAISE EXCEPTION 'PROFIT_PROTECTION: الأرباح لا يمكن أن تكون سالبة';
END IF;
```

---



## 7. أمثلة عملية

### **مثال 1: طلب جديد يتم تثبيته**

```
الحالة الأولية:
- user_phone: "07701234567"
- achieved_profits: 50,000 د.ع
- expected_profits: 30,000 د.ع

الطلب الجديد:
- order_id: "order_123"
- profit: 5,000 د.ع
- status: "نشط"

العملية:
1. يتم إنشاء الطلب في جدول orders
2. ProfitsCalculatorService.addToExpectedProfits() يضيف 5,000 د.ع للأرباح المنتظرة

النتيجة:
- achieved_profits: 50,000 د.ع (لم يتغير)
- expected_profits: 35,000 د.ع (زاد 5,000)
```

### **مثال 2: طلب يتم تسليمه**

```
الحالة الأولية:
- user_phone: "07701234567"
- achieved_profits: 50,000 د.ع
- expected_profits: 35,000 د.ع

الطلب:
- order_id: "order_123"
- profit: 5,000 د.ع
- old_status: "قيد التوصيل الى الزبون"
- new_status: "تم التسليم للزبون"

العملية:
1. Backend يحدث حالة الطلب
2. Supabase Realtime يطلق event
3. OrderStatusMonitor يستقبل التغيير
4. SmartProfitTransfer ينقل الربح:
   - expected_profits -= 5,000
   - achieved_profits += 5,000

النتيجة:
- achieved_profits: 55,000 د.ع (زاد 5,000)
- expected_profits: 30,000 د.ع (نقص 5,000)
```

### **مثال 3: طلب يتم إلغاؤه**

```
الحالة الأولية:
- user_phone: "07701234567"
- achieved_profits: 55,000 د.ع
- expected_profits: 30,000 د.ع

الطلب:
- order_id: "order_456"
- profit: 3,000 د.ع
- old_status: "نشط"
- new_status: "الغاء الطلب"

العملية:
1. Backend يحدث حالة الطلب
2. Supabase Realtime يطلق event
3. OrderStatusMonitor يستقبل التغيير
4. SmartProfitTransfer ينقل الربح:
   - oldProfitType = Expected
   - newProfitType = None
   - expected_profits -= 3,000

النتيجة:
- achieved_profits: 55,000 د.ع (لم يتغير)
- expected_profits: 27,000 د.ع (نقص 3,000)
```

### **مثال 4: طلب مسلم يرجع لقيد التوصيل (حالة نادرة)**

```
الحالة الأولية:
- user_phone: "07701234567"
- achieved_profits: 55,000 د.ع
- expected_profits: 27,000 د.ع

الطلب:
- order_id: "order_123"
- profit: 5,000 د.ع
- old_status: "تم التسليم للزبون"
- new_status: "قيد التوصيل الى الزبون"

العملية:
1. Backend يحدث حالة الطلب
2. Supabase Realtime يطلق event
3. OrderStatusMonitor يستقبل التغيير
4. SmartProfitTransfer ينقل الربح:
   - oldProfitType = Achieved
   - newProfitType = Expected
   - achieved_profits -= 5,000
   - expected_profits += 5,000

النتيجة:
- achieved_profits: 50,000 د.ع (نقص 5,000)
- expected_profits: 32,000 د.ع (زاد 5,000)
```

### **مثال 5: طلب ملغي يتم إعادة تفعيله**

```
الحالة الأولية:
- user_phone: "07701234567"
- achieved_profits: 50,000 د.ع
- expected_profits: 32,000 د.ع

الطلب:
- order_id: "order_789"
- profit: 4,000 د.ع
- old_status: "الغاء الطلب"
- new_status: "نشط"

العملية:
1. Backend يحدث حالة الطلب
2. Supabase Realtime يطلق event
3. OrderStatusMonitor يستقبل التغيير
4. SmartProfitTransfer ينقل الربح:
   - oldProfitType = None
   - newProfitType = Expected
   - expected_profits += 4,000

النتيجة:
- achieved_profits: 50,000 د.ع (لم يتغير)
- expected_profits: 36,000 د.ع (زاد 4,000)
```

---

## 8. الخلاصة

### **✅ النظام يعمل بالشكل التالي:**

1. **عند إنشاء طلب جديد:**
   - الربح يضاف إلى `expected_profits`

2. **عند تسليم الطلب:**
   - الربح ينتقل من `expected_profits` إلى `achieved_profits`

3. **عند إلغاء الطلب:**
   - الربح يحذف من `expected_profits`

4. **عند الرجوع من حالة إلى أخرى:**
   - الربح ينتقل بين `achieved_profits` و `expected_profits` حسب نوع الحالة

### **🛡️ آليات الحماية:**

1. ✅ **Frontend:** تجاهل الحالات غير المهمة، منع الأرقام السالبة
2. ✅ **Backend:** عدم تحديث قاعدة البيانات للحالات المتجاهلة
3. ✅ **Database:** Trigger يمنع التعديلات غير المصرح بها، يسجل كل عملية

### **📊 السجلات:**

1. ✅ `profit_operations_log` - سجل كل عملية تعديل على الأرباح
2. ✅ `order_status_history` - سجل كل تغيير في حالة الطلب

### **🔍 كيف تتحقق من صحة النظام:**

#### **A. فحص السجلات:**

```sql
-- فحص سجل عمليات الأرباح
SELECT * FROM profit_operations_log
WHERE user_phone = '07701234567'
ORDER BY created_at DESC
LIMIT 20;

-- فحص سجل تغييرات حالة الطلبات
SELECT * FROM order_status_history
WHERE order_id = 'order_123'
ORDER BY changed_at DESC;
```

#### **B. فحص الأرباح الحالية:**

```sql
-- فحص أرباح مستخدم معين
SELECT phone, achieved_profits, expected_profits
FROM users
WHERE phone = '07701234567';

-- فحص جميع طلبات المستخدم
SELECT id, status, profit
FROM orders
WHERE user_phone = '07701234567';
```

#### **C. إعادة حساب الأرباح من الصفر:**

استخدم `SmartProfitsManager.recalculateUserProfits()` في Frontend:

```dart
final result = await SmartProfitsManager.recalculateUserProfits('07701234567');
print('Achieved: ${result['achieved']}');
print('Expected: ${result['expected']}');
```

---

**تاريخ التحديث:** 2025-01-03
**الإصدار:** 2.0 (بعد إصلاح مشكلة تكرار الأرباح)

---

## 📌 ملاحظات مهمة

### **⚠️ الحالات المتجاهلة:**

هذه الحالات **لا تظهر للمستخدم** ولا تؤثر على الأرباح:

1. **فعال** (ID: 1)
2. **في موقع فرز بغداد** (ID: 5)
3. **في الطريق الى مكتب المحافظة** (ID: 7)

**السبب:** هذه حالات داخلية من شركة الوسيط، غير مهمة للمستخدم النهائي.

**الحل:** Backend يتجاهلها بالكامل (لا UPDATE في قاعدة البيانات) لمنع إطلاق realtime events.

### **🔒 الحماية من تكرار الأرباح:**

**المشكلة السابقة:**
- أي UPDATE على جدول `orders` كان يطلق `PostgresChangeEvent.update`
- حتى لو كان التحديث فقط في `last_status_check`
- Frontend كان يستقبل الـ event ويحدث الأرباح مرة أخرى

**الحل:**
1. ✅ Backend لا يحدث قاعدة البيانات للحالات المتجاهلة
2. ✅ Frontend يتحقق من `oldStatus == newStatus` قبل تحديث الأرباح
3. ✅ Frontend يتجاهل الحالات غير المهمة
4. ✅ Database Trigger يمنع التعديلات المشبوهة

### **📈 أفضل الممارسات:**

1. **دائماً استخدم `SmartProfitTransfer`** لنقل الأرباح بين الحالات
2. **لا تحدث `achieved_profits` أو `expected_profits` مباشرة** في قاعدة البيانات
3. **استخدم `SmartProfitsManager.recalculateUserProfits()`** إذا كنت تشك في صحة الأرباح
4. **راقب `profit_operations_log`** بانتظام للتحقق من العمليات المشبوهة
5. **استخدم دوال قاعدة البيانات الآمنة** (`safe_add_profits`, `safe_withdraw_profits`) للعمليات الحساسة

---

**نهاية التحليل الشامل** ✅
