#!/bin/bash

echo "========================================"
echo "   تصدير تطبيق منتجاتي - الإصدار النهائي"
echo "========================================"
echo ""

echo "🎯 الإصدار الجديد: 3.2.0+9"
echo "🔧 التحديثات المضافة:"
echo "   ✅ إصلاح عرض معرف الوسيط في تفاصيل الطلب"
echo "   ✅ إضافة زر فتح رابط الوسيط مباشرة"
echo "   ✅ تحسين واجهة عرض حالة الوسيط"
echo "   ✅ إصلاح مشكلة عدم ظهور QR ID"
echo "   ✅ تحسين نظام إرسال الطلبات للوسيط"
echo ""

echo "📱 بدء عملية التصدير..."
echo ""

cd frontend

echo "🧹 تنظيف المشروع..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ فشل في تنظيف المشروع"
    exit 1
fi

echo "📦 تحديث التبعيات..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ فشل في تحديث التبعيات"
    exit 1
fi

echo "🔍 فحص المشروع..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "⚠️ تحذير: هناك مشاكل في التحليل، لكن سنكمل التصدير"
fi

echo "🏗️ بناء APK للإنتاج..."
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
if [ $? -ne 0 ]; then
    echo "❌ فشل في بناء APK"
    exit 1
fi

echo "🏗️ بناء App Bundle للنشر على Google Play..."
flutter build appbundle --release
if [ $? -ne 0 ]; then
    echo "❌ فشل في بناء App Bundle"
    exit 1
fi

echo ""
echo "✅ تم تصدير التطبيق بنجاح!"
echo ""
echo "📁 ملفات التصدير:"
echo "   📱 APK: frontend/build/app/outputs/flutter-apk/app-release.apk"
echo "   📦 AAB: frontend/build/app/outputs/bundle/release/app-release.aab"
echo ""

echo "📊 معلومات الإصدار:"
echo "   🏷️ الإصدار: 3.2.0+9"
echo "   📅 تاريخ البناء: $(date)"
echo "   🔧 نوع البناء: Release"
echo "   🎯 المنصات: Android ARM, ARM64, x64"
echo ""

echo "🚀 التطبيق جاهز للنشر!"
echo ""

echo "📋 خطوات النشر:"
echo "   1. ارفع ملف AAB إلى Google Play Console"
echo "   2. أو شارك ملف APK مباشرة مع المستخدمين"
echo "   3. تأكد من تحديث رقم الإصدار في المتجر"
echo ""

echo "🎉 تم الانتهاء من عملية التصدير بنجاح!"
