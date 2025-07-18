# نظام التحديث بالسحب (Pull to Refresh)

## 🎯 الهدف
إضافة ميزة التحديث بالسحب لجميع الصفحات المهمة في التطبيق لتحسين تجربة المستخدم عند انقطاع وعودة الإنترنت.

## ✨ المميزات

### 1. تحديث ذكي
- **سحب للأسفل**: تحديث فوري للبيانات
- **رسائل واضحة**: إشعارات نجاح مخصصة لكل صفحة
- **معالجة أخطاء**: رسائل مفهومة عند فشل التحديث

### 2. الصفحات المدعومة
- ✅ **صفحة المنتجات**: تحديث المنتجات والمفضلة
- ✅ **صفحة معلومات الزبون**: تحديث المحافظات والمدن
- ✅ **صفحة الطلبات**: تحديث قائمة الطلبات
- ✅ **صفحة المفضلة**: تحديث المنتجات المفضلة
- ✅ **صفحة السلة**: تحديث محتويات السلة

### 3. أنواع المكونات

#### PullToRefreshWrapper (بسيط)
```dart
PullToRefreshWrapper(
  onRefresh: _refreshData,
  refreshMessage: 'تم التحديث بنجاح',
  child: YourWidget(),
)
```

#### SmartPullToRefresh (متقدم)
```dart
SmartPullToRefresh(
  onRefresh: _refreshData,
  refreshingMessage: 'جاري التحديث...',
  successMessage: 'تم التحديث بنجاح',
  showMessages: true,
  child: YourWidget(),
)
```

## 🚀 كيفية الاستخدام

### 1. استيراد المكتبة
```dart
import '../widgets/pull_to_refresh_wrapper.dart';
```

### 2. إضافة دالة التحديث
```dart
Future<void> _refreshData() async {
  debugPrint('🔄 تحديث البيانات...');
  
  // إعادة تحميل البيانات
  await _loadData();
  
  debugPrint('✅ تم التحديث بنجاح');
}
```

### 3. تطبيق المكون
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: PullToRefreshWrapper(
      onRefresh: _refreshData,
      refreshMessage: 'تم تحديث البيانات',
      child: YourContent(),
    ),
  );
}
```

## 📱 أمثلة من التطبيق

### 1. صفحة المنتجات
```dart
// في new_products_page.dart
PullToRefreshWrapper(
  onRefresh: _refreshData,
  refreshMessage: 'تم تحديث المنتجات والمفضلة',
  indicatorColor: const Color(0xFFffd700),
  child: SingleChildScrollView(...),
)

// دالة التحديث
Future<void> _refreshData() async {
  setState(() => _isLoadingProducts = true);
  await Future.wait([
    _loadProducts(), 
    _favoritesService.loadFavorites()
  ]);
  setState(() => _isLoadingProducts = false);
}
```

### 2. صفحة معلومات الزبون
```dart
// في customer_info_page.dart
PullToRefreshWrapper(
  onRefresh: _refreshData,
  refreshMessage: 'تم تحديث بيانات المحافظات',
  child: Column(...),
)

// دالة التحديث
Future<void> _refreshData() async {
  await _loadCitiesFromWaseet();
}
```

### 3. صفحة الطلبات
```dart
// في orders_page.dart
PullToRefreshWrapper(
  onRefresh: _refreshData,
  refreshMessage: 'تم تحديث الطلبات',
  child: CustomScrollView(...),
)

// دالة التحديث
Future<void> _refreshData() async {
  await _loadOrders();
}
```

## 🎨 التخصيص

### الألوان
```dart
PullToRefreshWrapper(
  indicatorColor: Colors.blue,        // لون المؤشر
  child: YourWidget(),
)
```

### الرسائل
```dart
SmartPullToRefresh(
  refreshingMessage: 'جاري التحميل...',
  successMessage: 'تم بنجاح!',
  showMessages: true,
  child: YourWidget(),
)
```

### التحكم في العرض
```dart
PullToRefreshWrapper(
  showRefreshIndicator: true,         // إظهار/إخفاء المؤشر
  onRefresh: _refreshData,
  child: YourWidget(),
)
```

## 🔧 الميزات المتقدمة

### 1. مراقبة حالة الشبكة
```dart
// في NetworkAwareRefresh
static Future<bool> checkAndRefreshIfNeeded(
  BuildContext context,
  Future<void> Function() refreshFunction,
) async {
  // فحص عودة الاتصال وتحديث تلقائي
}
```

### 2. تسجيل الأخطاء
```dart
// معالجة تلقائية للأخطاء مع ErrorHandler
catch (e) {
  ErrorHandler.showErrorSnackBar(
    context,
    e,
    onRetry: () => _refreshData(),
  );
}
```

### 3. رسائل ديناميكية
```dart
SmartPullToRefresh(
  refreshingMessage: 'جاري تحديث ${_dataType}...',
  successMessage: 'تم تحديث ${_dataCount} عنصر',
  child: YourWidget(),
)
```

## 🔄 سيناريوهات الاستخدام

### 1. عند انقطاع الإنترنت
- المستخدم يسحب للأسفل
- يظهر مؤشر التحميل
- تظهر رسالة "لا يوجد اتصال بالإنترنت"
- زر "إعادة المحاولة" متاح

### 2. عند عودة الإنترنت
- المستخدم يسحب للأسفل
- تتم إعادة تحميل البيانات
- تظهر رسالة "تم التحديث بنجاح"
- البيانات الجديدة تظهر

### 3. التحديث العادي
- المستخدم يسحب للأسفل
- تحديث سريع للبيانات
- رسالة نجاح مختصرة

## ⚡ نصائح الأداء

### 1. تحسين دوال التحديث
```dart
Future<void> _refreshData() async {
  // تجنب العمليات الثقيلة
  // استخدم Future.wait للعمليات المتوازية
  await Future.wait([
    _loadEssentialData(),
    _loadSecondaryData(),
  ]);
}
```

### 2. إدارة الحالة
```dart
bool _isRefreshing = false;

Future<void> _refreshData() async {
  if (_isRefreshing) return;
  _isRefreshing = true;
  
  try {
    await _loadData();
  } finally {
    _isRefreshing = false;
  }
}
```

### 3. تجنب التحديث المتكرر
```dart
DateTime? _lastRefresh;

Future<void> _refreshData() async {
  final now = DateTime.now();
  if (_lastRefresh != null && 
      now.difference(_lastRefresh!).inSeconds < 5) {
    return; // تجنب التحديث المتكرر
  }
  
  _lastRefresh = now;
  await _loadData();
}
```

## 🚨 ملاحظات مهمة

1. **استخدم `mounted`** قبل تحديث الحالة
2. **تجنب التحديث المتكرر** في فترة قصيرة
3. **اختبر مع انقطاع الإنترنت** للتأكد من الرسائل
4. **استخدم رسائل واضحة** لكل صفحة
5. **تأكد من معالجة الأخطاء** بشكل صحيح

## ✅ الفوائد

1. **تجربة مستخدم محسنة**: تحديث سهل وبديهي
2. **استجابة للشبكة**: تعامل ذكي مع انقطاع الإنترنت
3. **ردود فعل واضحة**: رسائل مفهومة للمستخدم
4. **سهولة الصيانة**: نظام موحد لجميع الصفحات
5. **أداء محسن**: تحديث فعال للبيانات
