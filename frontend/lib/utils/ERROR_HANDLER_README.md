# نظام معالجة الأخطاء المحسن

## 🎯 الهدف
تحويل الأخطاء التقنية المعقدة إلى رسائل واضحة ومفهومة للمستخدم العربي.

## ✨ المميزات

### 1. رسائل خطأ واضحة
- **قبل**: `ClientException: Failed to fetch, uri=https://...`
- **بعد**: `لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.`

### 2. أنواع الأخطاء المدعومة
- ✅ **أخطاء الشبكة**: انقطاع الإنترنت، مهلة الاتصال
- ✅ **أخطاء الخادم**: خطأ 500، خطأ داخلي
- ✅ **أخطاء التفويض**: انتهاء الجلسة، عدم التفويض
- ✅ **أخطاء قاعدة البيانات**: مشاكل Supabase
- ✅ **أخطاء التحقق**: بيانات غير صحيحة

### 3. واجهات متعددة
- **SnackBar**: رسائل سريعة مع إمكانية إعادة المحاولة
- **Dialog**: رسائل مفصلة للأخطاء المهمة
- **تسجيل الأخطاء**: لتتبع المشاكل

## 🚀 كيفية الاستخدام

### 1. استيراد المكتبة
```dart
import '../utils/error_handler.dart';
```

### 2. إظهار رسالة خطأ بسيطة
```dart
try {
  // كود قد يفشل
  await someOperation();
} catch (e) {
  ErrorHandler.showErrorSnackBar(context, e);
}
```

### 3. إظهار رسالة خطأ مع إعادة المحاولة
```dart
try {
  await loadData();
} catch (e) {
  ErrorHandler.showErrorSnackBar(
    context,
    e,
    onRetry: () => loadData(),
  );
}
```

### 4. رسالة خطأ مخصصة
```dart
ErrorHandler.showErrorSnackBar(
  context,
  error,
  customMessage: 'فشل في تحميل البيانات المطلوبة',
  onRetry: () => retryOperation(),
);
```

### 5. حوار خطأ مفصل
```dart
ErrorHandler.showErrorDialog(
  context,
  error,
  title: 'خطأ في العملية',
  onRetry: () => retryOperation(),
);
```

### 6. رسائل النجاح والتحذير
```dart
// رسالة نجاح
ErrorHandler.showSuccessSnackBar(context, 'تم الحفظ بنجاح');

// رسالة تحذير
ErrorHandler.showWarningSnackBar(context, 'يرجى التحقق من البيانات');
```

## 🔍 فحص نوع الخطأ

```dart
if (ErrorHandler.isNetworkError(error)) {
  // معالجة خاصة لأخطاء الشبكة
} else if (ErrorHandler.isServerError(error)) {
  // معالجة خاصة لأخطاء الخادم
}
```

## 📝 تسجيل الأخطاء

```dart
ErrorHandler.logError(
  error,
  context: 'تحميل المحافظات',
  additionalInfo: {
    'userId': currentUserId,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

## 🎨 التخصيص

### ألوان الرسائل
- **خطأ**: `#dc3545` (أحمر)
- **نجاح**: `#28a745` (أخضر)
- **تحذير**: `#ffc107` (أصفر)

### مدة العرض
- **افتراضي**: 4 ثوانٍ للأخطاء، 3 ثوانٍ للنجاح
- **قابل للتخصيص**: `duration: Duration(seconds: 5)`

## 📱 أمثلة من التطبيق

### 1. صفحة معلومات الزبون
```dart
// في _loadCitiesFromWaseet()
catch (e) {
  ErrorHandler.showErrorSnackBar(
    context,
    e,
    customMessage: ErrorHandler.isNetworkError(e) 
        ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
        : 'حدث خطأ في تحميل المحافظات. يرجى المحاولة مرة أخرى.',
    onRetry: () => _loadCitiesFromWaseet(),
  );
}
```

### 2. إنشاء الطلبات
```dart
// في _submitOrder()
catch (e) {
  ErrorHandler.showErrorSnackBar(
    context,
    e,
    customMessage: ErrorHandler.isNetworkError(e) 
        ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
        : 'حدث خطأ في إنشاء الطلب. يرجى المحاولة مرة أخرى.',
    onRetry: () => _submitOrder(),
    duration: const Duration(seconds: 5),
  );
}
```

## 🔧 الصيانة والتطوير

### إضافة نوع خطأ جديد
1. أضف دالة فحص في `ErrorHandler`
2. أضف رسالة مناسبة في `getReadableErrorMessage()`
3. اختبر الرسالة الجديدة

### تحسين الرسائل
- راجع تعليقات المستخدمين
- حلل سجلات الأخطاء
- حدث الرسائل حسب الحاجة

## ✅ الفوائد

1. **تجربة مستخدم أفضل**: رسائل واضحة بدلاً من أكواد تقنية
2. **سهولة الصيانة**: نظام موحد لمعالجة الأخطاء
3. **تتبع أفضل**: تسجيل مفصل للأخطاء
4. **إعادة المحاولة**: إمكانية إعادة العملية بسهولة
5. **تصميم موحد**: شكل ثابت لجميع الرسائل

## 🚨 ملاحظات مهمة

- استخدم `mounted` قبل إظهار الرسائل
- لا تعرض رسائل خطأ متعددة في نفس الوقت
- استخدم الرسائل المخصصة للعمليات المهمة
- سجل الأخطاء المهمة للمراجعة لاحقاً
