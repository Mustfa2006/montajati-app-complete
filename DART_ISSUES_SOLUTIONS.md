# 🔧 دليل حل مشاكل Dart Analyzer

## 📋 المشاكل الشائعة وحلولها

### **1. 🚫 Unused Import (استيراد غير مستخدم)**
```dart
// ❌ خطأ
import 'dart:typed_data'; // غير مستخدم

// ✅ الحل
// احذف السطر بالكامل
```

### **2. 🚫 Unused Local Variable (متغير محلي غير مستخدم)**
```dart
// ❌ خطأ
final String unusedVariable = 'test';

// ✅ الحل 1: احذف المتغير
// لا شيء

// ✅ الحل 2: استخدم المتغير
final String usedVariable = 'test';
print(usedVariable);

// ✅ الحل 3: أضف تعليق ignore
// ignore: unused_local_variable
final String ignoredVariable = 'test';
```

### **3. 🚫 Use Build Context Synchronously**
```dart
// ❌ خطأ
Future<void> someFunction(BuildContext context) async {
  await someAsyncOperation();
  Navigator.push(context, ...); // خطأ: context بعد await
}

// ✅ الحل
Future<void> someFunction(BuildContext context) async {
  await someAsyncOperation();
  if (context.mounted) { // تحقق من صحة context
    Navigator.push(context, ...);
  }
}
```

### **4. 🚫 Deprecated Member Use (استخدام عنصر مهجور)**
```dart
// ❌ خطأ - WillPopScope مهجور
WillPopScope(
  onWillPop: () async => false,
  child: MyWidget(),
)

// ✅ الحل - استخدم PopScope
PopScope(
  canPop: false,
  child: MyWidget(),
)
```

### **5. 🚫 Library Private Types in Public API**
```dart
// ❌ خطأ
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

// ✅ الحل
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}
```

### **6. 🚫 Super Parameters**
```dart
// ❌ خطأ - طريقة قديمة
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
}

// ✅ الحل - استخدم super parameters
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
}
```

### **7. 🚫 Don't Use Print in Production**
```dart
// ❌ خطأ
print('Debug message');

// ✅ الحل
debugPrint('Debug message');

// أو استخدم logging framework
import 'package:logging/logging.dart';
final logger = Logger('MyClass');
logger.info('Info message');
```

### **8. 🚫 Constant Names (أسماء الثوابت)**
```dart
// ❌ خطأ
static const String API_URL = 'https://api.example.com';

// ✅ الحل
static const String apiUrl = 'https://api.example.com';
```

---

## 🛠️ أدوات الإصلاح التلقائي

### **1. تشغيل Dart Fix:**
```bash
dart fix --apply
```

### **2. تشغيل Flutter Analyze:**
```bash
flutter analyze
```

### **3. تشغيل Build Runner:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📝 إعدادات Analysis Options

إنشاء ملف `analysis_options.yaml`:
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
linter:
  rules:
    # تعطيل بعض القواعد الصارمة
    avoid_print: false
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    
    # تفعيل قواعد مفيدة
    always_declare_return_types: true
    avoid_empty_else: true
    avoid_unnecessary_containers: true
    prefer_is_empty: true
    prefer_is_not_empty: true
```

---

## 🚀 سكريبت الإصلاح السريع

```bash
# تشغيل سكريبت الإصلاح
./fix_dart_issues.bat

# أو يدوياً:
flutter clean
flutter pub get
dart fix --apply
flutter analyze
```

---

## ✅ قائمة التحقق

- [ ] حذف جميع الاستيرادات غير المستخدمة
- [ ] حذف المتغيرات غير المستخدمة
- [ ] استخدام `context.mounted` قبل استخدام BuildContext
- [ ] استبدال `WillPopScope` بـ `PopScope`
- [ ] استخدام super parameters في constructors
- [ ] استبدال `print` بـ `debugPrint`
- [ ] تصحيح أسماء الثوابت لتكون lowerCamelCase
- [ ] إصلاح private types في public APIs

---

## 🎯 النتيجة المتوقعة

بعد تطبيق هذه الحلول:
- ✅ صفر أخطاء في Dart Analyzer
- ✅ كود نظيف ومتوافق مع معايير Flutter
- ✅ أداء محسن
- ✅ سهولة صيانة أكبر

---

## 🆘 إذا استمرت المشاكل

1. **تحديث Flutter:**
   ```bash
   flutter upgrade
   ```

2. **تحديث التبعيات:**
   ```bash
   flutter pub upgrade
   ```

3. **إعادة إنشاء المشروع:**
   ```bash
   flutter create --project-name montajati_app .
   ```

4. **طلب المساعدة:**
   - تحقق من وثائق Flutter الرسمية
   - ابحث في Stack Overflow
   - راجع GitHub Issues للحزم المستخدمة
