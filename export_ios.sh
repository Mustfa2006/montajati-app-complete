#!/bin/bash

# 🍎 سكريبت تصدير تطبيق منتجاتي للآيفون (IPA)
# يجب تشغيله على جهاز Mac مع Xcode

echo "🍎 بدء تصدير تطبيق منتجاتي للآيفون..."
echo "================================================"

# التحقق من النظام
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ خطأ: هذا السكريبت يعمل فقط على macOS"
    echo "💡 يرجى استخدام جهاز Mac لتصدير iOS"
    exit 1
fi

# التحقق من وجود Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ خطأ: Xcode غير مثبت"
    echo "💡 يرجى تثبيت Xcode من App Store"
    exit 1
fi

# التحقق من وجود Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ خطأ: Flutter غير مثبت"
    echo "💡 يرجى تثبيت Flutter SDK"
    exit 1
fi

# الانتقال لمجلد المشروع
cd frontend || {
    echo "❌ خطأ: مجلد frontend غير موجود"
    exit 1
}

echo "📁 المجلد الحالي: $(pwd)"

# تنظيف المشروع
echo "🧹 تنظيف المشروع..."
flutter clean

# تحديث الحزم
echo "📦 تحديث الحزم..."
flutter pub get

# تحديث iOS dependencies
echo "🔄 تحديث iOS dependencies..."
cd ios
if [ -f "Podfile" ]; then
    pod install --repo-update
else
    echo "⚠️ تحذير: ملف Podfile غير موجود"
fi
cd ..

# التحقق من إعدادات iOS
echo "🔍 التحقق من إعدادات iOS..."
if [ ! -f "ios/Runner.xcworkspace" ]; then
    echo "❌ خطأ: ملف workspace غير موجود"
    echo "💡 يرجى تشغيل 'pod install' في مجلد ios"
    exit 1
fi

# بناء التطبيق للإنتاج
echo "🔨 بناء التطبيق للإنتاج..."
flutter build ios --release --no-codesign

if [ $? -ne 0 ]; then
    echo "❌ فشل في بناء التطبيق"
    exit 1
fi

echo "✅ تم بناء التطبيق بنجاح"

# إنشاء مجلد التصدير
export_dir="build/ios_export"
mkdir -p "$export_dir"

echo "📦 إنشاء Archive..."

# إنشاء Archive
cd ios
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath "../$export_dir/Montajati.xcarchive" \
           archive \
           -allowProvisioningUpdates

if [ $? -ne 0 ]; then
    echo "❌ فشل في إنشاء Archive"
    echo "💡 تأكد من:"
    echo "   - إعدادات التوقيع صحيحة"
    echo "   - حساب Apple Developer مفعل"
    echo "   - Provisioning Profile صحيح"
    exit 1
fi

echo "✅ تم إنشاء Archive بنجاح"

# التحقق من وجود ExportOptions.plist
if [ ! -f "ExportOptions.plist" ]; then
    echo "⚠️ ملف ExportOptions.plist غير موجود، سيتم إنشاؤه..."
    
    cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF
fi

echo "📤 تصدير IPA..."

# تصدير IPA
xcodebuild -exportArchive \
           -archivePath "../$export_dir/Montajati.xcarchive" \
           -exportPath "../$export_dir" \
           -exportOptionsPlist ExportOptions.plist \
           -allowProvisioningUpdates

if [ $? -ne 0 ]; then
    echo "❌ فشل في تصدير IPA"
    echo "💡 تحقق من:"
    echo "   - ملف ExportOptions.plist"
    echo "   - إعدادات التوقيع"
    echo "   - صحة الشهادات"
    exit 1
fi

cd ..

# البحث عن ملف IPA
ipa_file=$(find "$export_dir" -name "*.ipa" | head -1)

if [ -n "$ipa_file" ]; then
    # نسخ الملف للمجلد الرئيسي
    cp "$ipa_file" "montajati-app-ios.ipa"
    
    echo "🎉 تم تصدير التطبيق بنجاح!"
    echo "================================================"
    echo "📱 ملف IPA: montajati-app-ios.ipa"
    echo "📍 المسار الكامل: $(pwd)/montajati-app-ios.ipa"
    echo "📊 حجم الملف: $(ls -lh montajati-app-ios.ipa | awk '{print $5}')"
    echo ""
    echo "📋 معلومات التطبيق:"
    echo "   🏷️  الاسم: منتجاتي - Montajati"
    echo "   🆔 Bundle ID: com.montajati.app"
    echo "   📱 الإصدار: $(grep FLUTTER_BUILD_NAME ios/Flutter/Generated.xcconfig | cut -d'=' -f2)"
    echo "   🔢 Build: $(grep FLUTTER_BUILD_NUMBER ios/Flutter/Generated.xcconfig | cut -d'=' -f2)"
    echo ""
    echo "🚀 خطوات التالية:"
    echo "   1. اختبر التطبيق على جهاز iOS"
    echo "   2. ارفع للـ App Store Connect"
    echo "   3. أضف معلومات التطبيق والصور"
    echo "   4. اطلب المراجعة من Apple"
    echo ""
    echo "📞 للدعم: راجع ملف iOS_Export_Guide.md"
    
else
    echo "❌ لم يتم العثور على ملف IPA"
    echo "💡 تحقق من مجلد: $export_dir"
fi

echo "================================================"
echo "🏁 انتهى سكريبت التصدير"
