#!/bin/bash

# ===================================
# سكريبت تصدير تطبيق منتجاتي النهائي
# Montajati App Final Export Script
# ===================================

echo "🎯 بدء تصدير تطبيق منتجاتي..."
echo "=================================="

# التحقق من وجود Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js غير مثبت. يرجى تثبيت Node.js أولاً"
    exit 1
fi

# التحقق من وجود React Native CLI
if ! command -v npx &> /dev/null; then
    echo "❌ NPX غير متاح. يرجى تثبيت Node.js بشكل صحيح"
    exit 1
fi

echo "✅ Node.js متاح"

# الانتقال إلى مجلد التطبيق
cd frontend

echo "📦 تثبيت التبعيات..."
npm install

echo "🔧 تنظيف الملفات المؤقتة..."
npx react-native start --reset-cache &
sleep 5
kill %1

# تصدير Android
echo "🤖 بدء تصدير تطبيق Android..."
echo "================================"

# إنشاء bundle
echo "📱 إنشاء bundle للأندرويد..."
npx react-native bundle \
  --platform android \
  --dev false \
  --entry-file index.js \
  --bundle-output android/app/src/main/assets/index.android.bundle \
  --assets-dest android/app/src/main/res

# التحقق من وجود Gradle
if [ -f "android/gradlew" ]; then
    echo "🔨 بناء APK..."
    cd android
    chmod +x gradlew
    ./gradlew assembleRelease
    
    if [ -f "app/build/outputs/apk/release/app-release.apk" ]; then
        echo "✅ تم إنشاء APK بنجاح!"
        echo "📍 المسار: android/app/build/outputs/apk/release/app-release.apk"
        
        # نسخ APK إلى المجلد الرئيسي
        cp app/build/outputs/apk/release/app-release.apk ../montajati-app.apk
        echo "📱 تم نسخ APK إلى: montajati-app.apk"
    else
        echo "❌ فشل في إنشاء APK"
    fi
    
    cd ..
else
    echo "❌ Gradle غير موجود. يرجى التأكد من إعداد Android"
fi

# تصدير iOS (إذا كان على macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 بدء تصدير تطبيق iOS..."
    echo "============================="
    
    if command -v xcodebuild &> /dev/null; then
        echo "🔨 بناء iOS Archive..."
        cd ios
        
        xcodebuild -workspace MontajatiApp.xcworkspace \
                   -scheme MontajatiApp \
                   -configuration Release \
                   -archivePath MontajatiApp.xcarchive \
                   archive
        
        if [ -d "MontajatiApp.xcarchive" ]; then
            echo "✅ تم إنشاء iOS Archive بنجاح!"
            echo "📍 المسار: ios/MontajatiApp.xcarchive"
        else
            echo "❌ فشل في إنشاء iOS Archive"
        fi
        
        cd ..
    else
        echo "❌ Xcode غير مثبت. يرجى تثبيت Xcode لتصدير iOS"
    fi
else
    echo "ℹ️ تصدير iOS متاح فقط على macOS"
fi

# إنشاء ملف معلومات التطبيق
echo "📋 إنشاء ملف معلومات التطبيق..."
cat > app_info.txt << EOF
🎯 تطبيق منتجاتي - معلومات التصدير
=====================================

📅 تاريخ التصدير: $(date)
📱 اسم التطبيق: منتجاتي - Montajati
🔢 الإصدار: 1.0.0
📦 الحزمة: com.montajati.app

🤖 Android:
- الحد الأدنى: Android 6.0 (API 23)
- الملف: montajati-app.apk
- الحجم: $(if [ -f "montajati-app.apk" ]; then ls -lh montajati-app.apk | awk '{print $5}'; else echo "غير متاح"; fi)

🍎 iOS:
- الحد الأدنى: iOS 11.0
- الملف: ios/MontajatiApp.xcarchive
- الحالة: $(if [[ "$OSTYPE" == "darwin"* ]] && [ -d "ios/MontajatiApp.xcarchive" ]; then echo "متاح"; else echo "غير متاح"; fi)

🌐 الخادم:
- الرابط: https://montajati-backend.onrender.com
- قاعدة البيانات: Supabase
- الإشعارات: Firebase
- التوصيل: الوسيط

✅ الميزات:
- إدارة المنتجات والطلبات
- التوصيل التلقائي مع الوسيط
- الإشعارات الفورية
- رفع الصور
- الإحصائيات والتقارير
- النسخ الاحتياطي التلقائي

🎉 التطبيق جاهز للنشر في متاجر التطبيقات!
EOF

echo "✅ تم إنشاء ملف المعلومات: app_info.txt"

# الخلاصة
echo ""
echo "🎉 انتهى تصدير التطبيق!"
echo "========================"
echo ""

if [ -f "montajati-app.apk" ]; then
    echo "✅ Android APK: متاح"
    echo "📱 الملف: montajati-app.apk"
    echo "📊 الحجم: $(ls -lh montajati-app.apk | awk '{print $5}')"
else
    echo "❌ Android APK: غير متاح"
fi

if [[ "$OSTYPE" == "darwin"* ]] && [ -d "ios/MontajatiApp.xcarchive" ]; then
    echo "✅ iOS Archive: متاح"
    echo "📱 الملف: ios/MontajatiApp.xcarchive"
else
    echo "ℹ️ iOS Archive: غير متاح (يحتاج macOS + Xcode)"
fi

echo ""
echo "📋 ملف المعلومات: app_info.txt"
echo "📖 دليل التصدير: FINAL_EXPORT_GUIDE.md"
echo ""
echo "🚀 التطبيق جاهز للنشر في متاجر التطبيقات!"
echo ""
echo "📞 للدعم: راجع FINAL_EXPORT_GUIDE.md"
