#!/bin/bash

# ===================================
# سكريبت تصدير التطبيق للإنتاج
# Production Export Script
# ===================================

echo "🚀 بدء تصدير التطبيق للإنتاج..."
echo "=================================="

# التحقق من Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js غير مثبت"
    exit 1
fi

# التحقق من Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter غير مثبت"
    exit 1
fi

echo "✅ Node.js و Flutter متوفران"

# الانتقال إلى مجلد Backend
cd backend

echo "📦 تثبيت تبعيات Backend..."
npm install --production

echo "🧪 اختبار النظام..."
node test_official_system.js

if [ $? -eq 0 ]; then
    echo "✅ اختبار Backend نجح"
else
    echo "❌ اختبار Backend فشل"
    exit 1
fi

# العودة إلى المجلد الرئيسي
cd ..

# التحقق من وجود مجلد Flutter
if [ -d "flutter_app" ]; then
    echo "📱 تصدير تطبيق Flutter..."
    cd flutter_app
    
    echo "🧹 تنظيف Flutter..."
    flutter clean
    
    echo "📦 تحديث packages..."
    flutter pub get
    
    echo "🔨 بناء APK للإنتاج..."
    flutter build apk --release
    
    if [ $? -eq 0 ]; then
        echo "✅ تم بناء APK بنجاح"
        echo "📍 الملف: flutter_app/build/app/outputs/flutter-apk/app-release.apk"
    else
        echo "❌ فشل في بناء APK"
        exit 1
    fi
    
    echo "🔨 بناء App Bundle للإنتاج..."
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        echo "✅ تم بناء App Bundle بنجاح"
        echo "📍 الملف: flutter_app/build/app/outputs/bundle/release/app-release.aab"
    else
        echo "❌ فشل في بناء App Bundle"
        exit 1
    fi
    
    cd ..
else
    echo "⚠️ مجلد flutter_app غير موجود، تخطي تصدير Flutter"
fi

echo ""
echo "🎉 تم تصدير التطبيق بنجاح!"
echo "=================================="
echo "📋 الملفات المُصدرة:"
echo "   - Backend: جاهز للنشر على Render"
echo "   - APK: flutter_app/build/app/outputs/flutter-apk/app-release.apk"
echo "   - AAB: flutter_app/build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "📚 للمزيد من التفاصيل، راجع:"
echo "   - PRODUCTION_EXPORT_GUIDE.md"
echo "   - OFFICIAL_SYSTEM_DOCUMENTATION.md"
echo ""
echo "🚀 النظام جاهز للإنتاج!"
