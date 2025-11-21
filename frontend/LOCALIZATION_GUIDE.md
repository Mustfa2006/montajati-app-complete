# 🌍 دليل نظام الترجمة في تطبيق منتجاتي

## 📋 نظرة عامة

تطبيق منتجاتي يدعم 3 لغات:
- 🇮🇶 العربية (ar) - اللغة الافتراضية
- 🇬🇧 الإنكليزية (en)
- 🇮🇶 الكردية السورانية (ku)

---

## 🏗️ البنية الأساسية

### 1. ملفات الترجمة
```
frontend/assets/l10n/
├── ar.json  # الترجمة العربية
├── en.json  # الترجمة الإنكليزية
└── ku.json  # الترجمة الكردية
```

### 2. الملفات الأساسية
- `lib/l10n/app_localizations.dart` - نظام الترجمة
- `lib/providers/language_provider.dart` - إدارة اللغة
- `lib/main.dart` - إعدادات اللغة في التطبيق

---

## 📝 كيفية استخدام الترجمات في الصفحات

### الخطوة 1: استيراد المكتبات المطلوبة

```dart
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
```

### الخطوة 2: الحصول على كائن الترجمة

في دالة `build`:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final languageProvider = Provider.of<LanguageProvider>(context);
  
  // الآن يمكنك استخدام l10n للحصول على الترجمات
  return Text(l10n.myAccount); // بدلاً من: Text('حسابي')
}
```

### الخطوة 3: استبدال النصوص الثابتة

❌ **قبل:**
```dart
Text('الطلبات')
Text('المنتجات')
Text('الإحصائيات')
```

✅ **بعد:**
```dart
Text(l10n.orders)
Text(l10n.products)
Text(l10n.statistics)
```

---

## 🔑 المفاتيح المتوفرة

### مفاتيح عامة
- `appName` - اسم التطبيق
- `loading` - جاري التحميل
- `error` - خطأ
- `success` - نجح
- `save` - حفظ
- `delete` - حذف
- `edit` - تعديل
- `add` - إضافة
- `search` - بحث
- `filter` - تصفية
- `cancel` - إلغاء
- `confirm` - تأكيد

### مفاتيح الحساب
- `myAccount` - حسابي
- `editProfile` - تعديل الملف الشخصي
- `language` - اللغة
- `logout` - تسجيل الخروج
- `joinedOn` - انضم في

### مفاتيح الطلبات
- `orders` - الطلبات
- `myOrders` - طلباتي
- `orderDetails` - تفاصيل الطلب
- `orderNumber` - رقم الطلب
- `orderDate` - تاريخ الطلب
- `orderStatus` - حالة الطلب

### مفاتيح المنتجات
- `products` - المنتجات
- `productName` - اسم المنتج
- `productPrice` - سعر المنتج
- `productDescription` - وصف المنتج
- `addToCart` - أضف إلى السلة

### مفاتيح الإحصائيات
- `statistics` - الإحصائيات
- `profits` - الأرباح
- `totalOrders` - إجمالي الطلبات
- `totalProfits` - إجمالي الأرباح

**📌 ملاحظة:** يوجد أكثر من 200 مفتاح ترجمة متوفر في ملفات JSON!

---

## 🎯 مثال عملي كامل

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myAccount),
      ),
      body: Column(
        children: [
          Text(l10n.orders),
          Text(l10n.products),
          Text(l10n.statistics),
          
          // زر تغيير اللغة
          ElevatedButton(
            onPressed: () {
              // تغيير اللغة إلى الإنكليزية
              languageProvider.setLanguage('en');
            },
            child: Text(l10n.language),
          ),
        ],
      ),
    );
  }
}
```

---

## ✅ قائمة التحقق للمطورين

عند إضافة صفحة جديدة أو تعديل صفحة موجودة:

- [ ] استيراد `AppLocalizations` و `LanguageProvider`
- [ ] الحصول على `l10n` في دالة `build`
- [ ] استبدال جميع النصوص الثابتة بمفاتيح الترجمة
- [ ] التأكد من وجود المفاتيح في جميع ملفات JSON الثلاثة
- [ ] اختبار الصفحة بجميع اللغات الثلاثة

---

## 🔧 إضافة مفاتيح ترجمة جديدة

### 1. أضف المفتاح في ملفات JSON الثلاثة

**ar.json:**
```json
{
  "new_key": "النص بالعربية"
}
```

**en.json:**
```json
{
  "new_key": "Text in English"
}
```

**ku.json:**
```json
{
  "new_key": "دەق بە کوردی"
}
```

### 2. أضف getter في `app_localizations.dart`

```dart
String get newKey => translate('new_key');
```

### 3. استخدمه في الكود

```dart
Text(l10n.newKey)
```

---

## 🐛 حل المشاكل الشائعة

### المشكلة: "MaterialLocalizations not found"
**الحل:** تأكد من إضافة `flutter_localizations` في `pubspec.yaml` وإضافة delegates في `main.dart`

### المشكلة: اللغة لا تتغير في الصفحة
**الحل:** تأكد من استخدام `Provider.of<LanguageProvider>(context)` بدون `listen: false`

### المشكلة: النص يظهر كمفتاح بدلاً من الترجمة
**الحل:** تأكد من وجود المفتاح في ملف JSON المناسب

---

## 📚 موارد إضافية

- [Flutter Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Provider Package](https://pub.dev/packages/provider)
- [Intl Package](https://pub.dev/packages/intl)

---

**تم إنشاء هذا الدليل بواسطة فريق تطوير منتجاتي 🚀**

